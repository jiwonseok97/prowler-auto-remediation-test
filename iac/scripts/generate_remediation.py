#!/usr/bin/env python3
"""Generate category-specific Terraform remediation from Prowler findings using Bedrock."""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

try:
    import boto3
except Exception:  # pragma: no cover
    boto3 = None

SUPPORTED_CATEGORIES = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]

CATEGORY_HINTS = {
    "iam": ["iam", "mfa", "access key", "policy"],
    "s3": ["s3", "bucket", "public", "encryption"],
    "network-ec2-vpc": ["vpc", "security group", "ec2", "network"],
    "cloudtrail": ["cloudtrail", "trail"],
    "cloudwatch": ["cloudwatch", "log group", "logs"],
}


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def detect_category(finding: dict) -> str | None:
    joined = " ".join(
        [
            str(finding.get("CheckID", "")),
            str(finding.get("CheckTitle", "")),
            str(finding.get("Title", "")),
            str(finding.get("Description", "")),
            str(finding.get("GeneratorId", "")),
            str(finding.get("ServiceName", "")),
            str(finding.get("StatusExtended", "")),
            str(finding.get("ResourceType", "")),
            str(finding.get("Types", "")),
            str(finding.get("ProductFields", "")),
        ]
    )
    haystack = normalize(joined)
    for category, hints in CATEGORY_HINTS.items():
        if any(h in haystack for h in hints):
            return category
    return None


def finding_status(finding: dict) -> str:
    direct = str(finding.get("Status", "")).strip().lower()
    if direct:
        return direct
    compliance = finding.get("Compliance", {})
    if isinstance(compliance, dict):
        status = str(compliance.get("Status", "")).strip().lower()
        if status:
            return status
    return ""


def read_findings(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8").lstrip("\ufeff").strip()
    if not raw:
        return []
    if raw[0] == "[":
        payload = json.loads(raw)
        return [x for x in payload if isinstance(x, dict)]
    if raw[0] == "{":
        payload = json.loads(raw)
        if isinstance(payload, dict) and isinstance(payload.get("Findings"), list):
            return [x for x in payload["Findings"] if isinstance(x, dict)]
        if isinstance(payload, dict):
            return [payload]
    rows = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
            if isinstance(item, dict):
                rows.append(item)
        except json.JSONDecodeError:
            continue
    return rows


def summarize_findings(findings: list[dict[str, Any]], limit: int = 25) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    for f in findings[:limit]:
        out.append(
            {
                "id": str(f.get("CheckID", f.get("GeneratorId", "unknown"))),
                "title": str(f.get("CheckTitle", f.get("Title", "unknown"))),
                "resource": str(f.get("ResourceId", f.get("ResourceType", "unknown"))),
                "details": str(f.get("StatusExtended", f.get("Description", "")))[:300],
            }
        )
    return out


def extract_tf_block(text: str) -> str:
    fenced = re.findall(r"```(?:hcl|terraform)?\s*(.*?)```", text, flags=re.S | re.I)
    if fenced:
        return "\n\n".join(x.strip() for x in fenced if x.strip()).strip() + "\n"
    return text.strip() + "\n"


def call_bedrock_for_category(
    model_id: str,
    region: str,
    category: str,
    findings: list[dict[str, Any]],
    snippet_text: str,
) -> str:
    if boto3 is None:
        raise RuntimeError("boto3 is not installed")

    client = boto3.client("bedrock-runtime", region_name=region)

    prompt = {
        "task": "Generate Terraform remediation blocks.",
        "constraints": [
            "Output Terraform/HCL only. No markdown.",
            "Only generate for this category: " + category,
            "Do not output provider/terraform/variable/output blocks.",
            "Use safe defaults and avoid destructive replacements.",
            "Use resource names prefixed with ai_remed_.",
        ],
        "findings": summarize_findings(findings),
        "snippet_reference": snippet_text,
    }

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1400,
        "temperature": 0,
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": json.dumps(prompt, ensure_ascii=False)}],
            }
        ],
    }

    resp = client.invoke_model(modelId=model_id, body=json.dumps(body), contentType="application/json")
    payload = json.loads(resp["body"].read())

    content = payload.get("content", [])
    text_parts = [part.get("text", "") for part in content if isinstance(part, dict)]
    raw_text = "\n".join(text_parts).strip()
    if not raw_text:
        raise RuntimeError("Bedrock returned empty content")

    return extract_tf_block(raw_text)


def render_category_file(run_id: str, category: str, snippet_text: str, ai_tf: str) -> str:
    return (
        f"# Generated remediation category: {category}\n"
        f"# remediation_run_id: {run_id}\n\n"
        f"# snippet_baseline\n{snippet_text.strip()}\n\n"
        f"# ai_generated\n{ai_tf.strip()}\n"
    )


def write_log(path: Path, lines: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prowler-json", default="artifacts/prowler-findings-normalized.json")
    parser.add_argument("--snippet-root", default="iac/snippets")
    parser.add_argument("--output-dir", default="terraform/remediation")
    parser.add_argument("--artifact-dir", default="artifacts/remediation")
    parser.add_argument("--run-id", default="manual")
    args = parser.parse_args()

    model_id = os.getenv("AI_MODEL", "")
    region = os.getenv("AWS_DEFAULT_REGION", "")

    findings = read_findings(Path(args.prowler_json))

    by_category: dict[str, list[dict[str, Any]]] = defaultdict(list)
    unsupported = 0
    for f in findings:
        status = finding_status(f)
        if status and status not in {"fail", "failed"}:
            continue
        cat = detect_category(f)
        if cat in SUPPORTED_CATEGORIES:
            by_category[cat].append(f)
        else:
            unsupported += 1

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    artifact_dir = Path(args.artifact_dir)
    artifact_dir.mkdir(parents=True, exist_ok=True)

    generated_categories: list[str] = []
    per_category_counts: dict[str, int] = {}

    for cat in SUPPORTED_CATEGORIES:
        cat_findings = by_category.get(cat, [])
        if not cat_findings:
            continue

        snippet_path = Path(args.snippet_root) / cat / "main.tf"
        if not snippet_path.exists():
            continue

        snippet_text = snippet_path.read_text(encoding="utf-8")
        ai_tf = ""
        bedrock_used = False
        error_text = ""

        if model_id and region:
            try:
                ai_tf = call_bedrock_for_category(model_id, region, cat, cat_findings, snippet_text)
                bedrock_used = True
            except Exception as e:
                error_text = str(e)

        if not ai_tf.strip():
            ai_tf = "# fallback_to_snippet_only"

        file_text = render_category_file(args.run_id, cat, snippet_text, ai_tf)
        out_file = out_dir / f"generated_{cat}.tf"
        out_file.write_text(file_text, encoding="utf-8")

        cat_log = artifact_dir / f"{cat}.log"
        write_log(
            cat_log,
            [
                f"category={cat}",
                f"findings={len(cat_findings)}",
                f"bedrock_used={str(bedrock_used).lower()}",
                f"model_id={model_id or 'none'}",
                f"error={error_text or 'none'}",
            ],
        )

        generated_categories.append(cat)
        per_category_counts[cat] = len(cat_findings)

    manifest = {
        "run_id": args.run_id,
        "total_findings": len(findings),
        "unsupported_findings": unsupported,
        "generated_categories": generated_categories,
        "counts": per_category_counts,
    }
    (artifact_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    summary_lines = [
        f"total_findings={len(findings)}",
        f"generated_categories={','.join(generated_categories) if generated_categories else 'none'}",
        f"unsupported_findings={unsupported}",
    ]
    write_log(artifact_dir / "summary.log", summary_lines)

    print(json.dumps(manifest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
