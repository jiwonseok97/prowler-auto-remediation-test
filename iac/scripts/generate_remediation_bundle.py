#!/usr/bin/env python3
"""Generate remediation terraform files from prioritized findings."""
import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import boto3
import yaml

CATEGORIES = ["iam", "s3", "cloudtrail", "cloudwatch"]
OPTIONAL_IMPORT_TYPES = {
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_server_side_encryption_configuration",
}


def safe_id(x: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", x).strip("_").lower()


def load_map(path: Path) -> Dict[str, Any]:
    doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    checks = doc.get("checks", {}) if isinstance(doc, dict) else {}
    return checks if isinstance(checks, dict) else {}


def category_of(service: str, check_id: str) -> str:
    s = (service or "").lower()
    c = (check_id or "").lower()
    if s == "iam" or c.startswith("iam_"):
        return "iam"
    if s == "s3" or c.startswith("s3_"):
        return "s3"
    if s == "cloudtrail" or c.startswith("cloudtrail_"):
        return "cloudtrail"
    if s in {"cloudwatch", "logs"} or c.startswith("cloudwatch_") or c.startswith("logs_"):
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
        out = out.replace("var.bucket_name", f'"{bucket}"')
    if trail:
        out = out.replace("var.cloudtrail_name", f'"{trail}"')
    if log_group:
        out = out.replace("var.log_group_name", f'"{log_group}"')
    out = out.replace("var.kms_key_arn", f'"{kms}"')
    return out


def uniquify_resource_names(tf_code: str, suffix: str) -> Tuple[str, List[Tuple[str, str]]]:
    mapping: List[Tuple[str, str]] = []

    def repl(m: re.Match) -> str:
        rtype = m.group(1)
        rname = m.group(2)
        new_name = f"{rname}_{suffix[:12]}"
        mapping.append((f"{rtype}.{new_name}", rtype))
        return f'resource "{rtype}" "{new_name}" {{'

    out = re.sub(r'resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', repl, tf_code)
    return out, mapping


def infer_template_by_rule(check_id: str, category: str) -> Optional[str]:
    c = check_id.lower()
    if category == "iam" and "password" in c and "policy" in c:
        return "iac/snippets/iam/fix-iam_password_policy_strong.tf"
    if category == "s3" and ("public" in c or "acl" in c or "policy" in c):
        return "iac/snippets/s3/fix-s3_bucket_public_access_block.tf"
    if category == "s3" and ("encrypt" in c or "encryption" in c):
        return "iac/snippets/s3/fix-s3_bucket_default_encryption.tf"
    if category == "cloudtrail" and ("log_file_validation" in c or "validation" in c):
        return "iac/snippets/cloudtrail/fix-cloudtrail_log_file_validation_enabled.tf"
    if category == "cloudwatch" and ("kms" in c or "encrypt" in c or "encryption" in c):
        return "iac/snippets/cloudwatch/fix-cloudwatch_log_group_encrypted.tf"
    return None


def import_id_for_type(resource_type: str, finding: Dict[str, Any]) -> str:
    arn = finding.get("resource_arn", "")
    if resource_type in {"aws_s3_bucket_public_access_block", "aws_s3_bucket_server_side_encryption_configuration"}:
        return extract_bucket(arn)
    if resource_type == "aws_cloudtrail":
        return extract_trail_name(arn)
    if resource_type == "aws_cloudwatch_log_group":
        return extract_log_group(arn)
    if resource_type == "aws_iam_account_password_policy":
        return finding.get("account_id", "")
    return ""


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

    overall: Dict[str, Any] = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "account": a.account_id,
        "region": a.region,
        "baseline_fail_count": len([x for x in rows if x.get("status") == "FAIL"]),
        "categories": {},
        "import_map": {},
    }

    for cat in CATEGORIES:
        (out_root / cat).mkdir(parents=True, exist_ok=True)
        overall["categories"][cat] = []
        overall["import_map"][cat] = []

    for f in rows:
        if f.get("status") != "FAIL":
            continue

        cid = f.get("check_id", "unknown")
        cat = category_of(f.get("service", ""), cid)
        if not cat:
            continue

        key = safe_id(cid)

        if f.get("manual_required") or f.get("non_terraform"):
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "manual_or_non_terraform",
                }
            )
            continue

        file_name = f"fix-{key}.tf"
        target = out_root / cat / file_name

        template_path = ""
        mapped = snippet_map.get(cid)
        if isinstance(mapped, dict):
            template_path = mapped.get("template", "")
        if not template_path:
            template_path = infer_template_by_rule(cid, cat) or ""

        tf_code = ""
        if template_path and Path(template_path).exists():
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
        tf_code, resource_addrs = uniquify_resource_names(tf_code, key)

        if "resource " not in tf_code:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "generation_failed_or_invalid_hcl",
                }
            )
            continue

        target.write_text(tf_code.rstrip() + "\n", encoding="utf-8")

        for addr, rtype in resource_addrs:
            iid = import_id_for_type(rtype, f)
            if iid:
                overall["import_map"][cat].append(
                    {
                        "check_id": cid,
                        "address": addr,
                        "import_id": iid,
                        "resource_type": rtype,
                        "optional": rtype in OPTIONAL_IMPORT_TYPES,
                    }
                )

        overall["categories"][cat].append(
            {
                "check_id": cid,
                "manual_required": False,
                "files": [str(target).replace("\\", "/")],
                "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                "score": f.get("osfp", {}).get("priority_score", 0),
            }
        )

    for cat in CATEGORIES:
        lines = []
        for row in overall["import_map"][cat]:
            lines.append(f"{row['address']}|{row['import_id']}|{str(row['optional']).lower()}|{row['check_id']}")
        (out_root / cat / "import-map.txt").write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")

    (out_root / "_generation_manifest.json").write_text(json.dumps(overall, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()