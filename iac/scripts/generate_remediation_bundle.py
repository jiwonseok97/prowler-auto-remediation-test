#!/usr/bin/env python3
"""Generate remediation terraform files from prioritized findings."""
import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

import boto3
import yaml

CATEGORIES = ["iam", "s3", "cloudtrail", "cloudwatch"]


def safe_id(x: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", x).strip("_").lower()


def load_map(path: Path) -> Dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {}


def category_of(service: str) -> str:
    s = (service or "").lower()
    if s in {"iam"}:
        return "iam"
    if s in {"s3"}:
        return "s3"
    if s in {"cloudtrail"}:
        return "cloudtrail"
    if s in {"cloudwatch", "logs"}:
        return "cloudwatch"
    return ""


def render_with_bedrock(model_id: str, prompt: str) -> str:
    client = boto3.client("bedrock-runtime")
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1200,
        "temperature": 0,
        "messages": [{"role": "user", "content": prompt}],
    }
    resp = client.invoke_model(modelId=model_id, body=json.dumps(body))
    payload = json.loads(resp["body"].read())
    text = "".join(x.get("text", "") for x in payload.get("content", []))
    return text.strip()


def strip_code_fence(s: str) -> str:
    t = s.strip()
    if t.startswith("```"):
        t = t.split("\n", 1)[1] if "\n" in t else ""
        if t.endswith("```"):
            t = t[:-3]
    return t.strip()


def extract_bucket(arn: str) -> str:
    if arn.startswith("arn:aws:s3:::"):
        return arn.split("arn:aws:s3:::", 1)[1].split("/")[0]
    return ""


def extract_trail_name(arn: str) -> str:
    if ":trail/" in arn:
        return arn.split(":trail/", 1)[1]
    return ""


def extract_log_group(arn: str) -> str:
    if ":log-group:" in arn:
        return arn.split(":log-group:", 1)[1].split(":", 1)[0]
    return ""


def materialize_vars(tf_code: str, finding: Dict[str, Any], account_id: str, region: str) -> str:
    arn = finding.get("resource_arn", "")
    bucket = extract_bucket(arn)
    trail = extract_trail_name(arn)
    log_group = extract_log_group(arn)
    kms = f"arn:aws:kms:{region}:{account_id}:alias/aws/logs"

    out = tf_code
    if bucket:
        out = out.replace("var.bucket_name", f"\"{bucket}\"")
    if trail:
        out = out.replace("var.cloudtrail_name", f"\"{trail}\"")
    if log_group:
        out = out.replace("var.log_group_name", f"\"{log_group}\"")
    out = out.replace("var.kms_key_arn", f"\"{kms}\"")
    return out


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output-root", required=True)
    p.add_argument("--snippet-map", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--model-id", required=True)
    a = p.parse_args()

    rows: List[Dict[str, Any]] = json.loads(Path(a.input).read_text(encoding="utf-8"))
    snippet_map = load_map(Path(a.snippet_map))

    out_root = Path(a.output_root)
    out_root.mkdir(parents=True, exist_ok=True)

    overall = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "account": a.account_id,
        "region": a.region,
        "baseline_fail_count": len([x for x in rows if x.get("status") == "FAIL"]),
        "categories": {},
    }

    for cat in CATEGORIES:
        (out_root / cat).mkdir(parents=True, exist_ok=True)
        overall["categories"][cat] = []

    for f in rows:
        if f.get("status") != "FAIL":
            continue
        cat = category_of(f.get("service", ""))
        if not cat:
            continue
        cid = f.get("check_id", "unknown")
        key = safe_id(cid)

        if f.get("manual_required") or f.get("non_terraform"):
            overall["categories"][cat].append({
                "check_id": cid,
                "manual_required": True,
                "files": [],
                "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                "score": f.get("osfp", {}).get("priority_score", 0),
            })
            continue

        file_name = f"fix-{key}.tf"
        target = out_root / cat / file_name

        snippet = snippet_map.get(cid, {})
        template_path = snippet.get("template")

        tf_code = ""
        if template_path:
            tf_code = Path(template_path).read_text(encoding="utf-8")
        else:
            prompt = (
                "Output only valid Terraform HCL. No markdown, no preamble. "
                "Generate minimal-change remediation for this finding: "
                + json.dumps(f)
            )
            try:
                tf_code = strip_code_fence(render_with_bedrock(a.model_id, prompt))
            except Exception:
                tf_code = ""

        tf_code = materialize_vars(tf_code, f, a.account_id, a.region)

        if "resource " not in tf_code:
            # Safe fallback: mark as manual when generation quality gate fails.
            overall["categories"][cat].append({
                "check_id": cid,
                "manual_required": True,
                "files": [],
                "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                "score": f.get("osfp", {}).get("priority_score", 0),
                "reason": "generation_failed_or_invalid_hcl",
            })
            continue

        target.write_text(tf_code.rstrip() + "\n", encoding="utf-8")
        overall["categories"][cat].append({
            "check_id": cid,
            "manual_required": False,
            "files": [str(target).replace("\\", "/")],
            "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
            "score": f.get("osfp", {}).get("priority_score", 0),
        })

    (out_root / "_generation_manifest.json").write_text(json.dumps(overall, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
