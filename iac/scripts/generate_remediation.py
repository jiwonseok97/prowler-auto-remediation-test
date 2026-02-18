#!/usr/bin/env python3
"""Generate Terraform remediation code from Prowler JSON findings."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

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


def read_findings(path: Path) -> list[dict]:
    raw = path.read_text(encoding="utf-8").strip()
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


def render_remediation(snippet_root: Path, categories: set[str], run_id: str) -> str:
    sections = [
        "# This file is generated. Do not edit manually.",
        f"# remediation_run_id: {run_id}",
        "",
    ]
    for cat in SUPPORTED_CATEGORIES:
        if cat not in categories:
            continue
        snippet = snippet_root / cat / "main.tf"
        if snippet.exists():
            sections.append(f"# category: {cat}")
            sections.append(snippet.read_text(encoding="utf-8").rstrip())
            sections.append("")
    return "\n".join(sections).strip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prowler-json", default="artifacts/prowler-findings.json")
    parser.add_argument("--snippet-root", default="iac/snippets")
    parser.add_argument("--output", default="terraform/remediation/main.tf")
    parser.add_argument("--run-id", default="manual")
    parser.add_argument("--log", default="artifacts/remediation.log")
    args = parser.parse_args()

    findings = read_findings(Path(args.prowler_json))
    categories: set[str] = set()
    unsupported = 0

    for f in findings:
        status = finding_status(f)
        if status and status not in {"fail", "failed"}:
            continue
        cat = detect_category(f)
        if cat in SUPPORTED_CATEGORIES:
            categories.add(cat)
        else:
            unsupported += 1

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    rendered = render_remediation(Path(args.snippet_root), categories, args.run_id)

    prelude = (
        'terraform {\n'
        '  required_version = ">= 1.5.0"\n'
        '  required_providers {\n'
        '    aws = { source = "hashicorp/aws", version = ">= 5.0" }\n'
        '  }\n'
        '}\n\n'
        'provider "aws" {\n'
        '  region = var.aws_region\n'
        '}\n\n'
    )
    output_path.write_text(prelude + rendered, encoding="utf-8")

    log_path = Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(
        "\n".join(
            [
                f"total_findings={len(findings)}",
                f"applied_categories={','.join(sorted(categories)) if categories else 'none'}",
                f"unsupported_findings={unsupported}",
                "unsupported examples: fms, organizations, root-mfa",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"generated={output_path}")
    print(f"categories={','.join(sorted(categories)) if categories else 'none'}")
    print(f"unsupported_findings={unsupported}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
