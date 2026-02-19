#!/usr/bin/env python3
"""Generate remediation terraform files from prioritized findings."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import boto3
import yaml

CATEGORIES = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]
OPTIONAL_IMPORT_TYPES = {
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_server_side_encryption_configuration",
    "aws_s3_account_public_access_block",
    "aws_s3_bucket_policy",
}
USE_BEDROCK_FALLBACK = os.getenv("BEDROCK_FALLBACK", "").strip().lower() in {"1", "true", "yes"}


def safe_id(x: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", x).strip("_").lower()


def load_map(path: Path) -> Dict[str, Any]:
    doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    checks = doc.get("checks", {}) if isinstance(doc, dict) else {}
    return checks if isinstance(checks, dict) else {}


def category_of(service: str, check_id: str) -> str:
    s = (service or "").lower()
    c = (check_id or "").lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    if s == "iam" or c.startswith("iam_"):
        return "iam"
    if s == "s3" or c.startswith("s3_"):
        return "s3"
    if s in {"ec2", "vpc"} or c.startswith("ec2_") or c.startswith("vpc_"):
        return "network-ec2-vpc"
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
    out = out.replace("var.account_id", f'"{account_id}"')
    out = out.replace("var.region", f'"{region}"')
    out = re.sub(r'variable\s+"[^"]+"\s*\{[^{}]*\}\s*', "", out, flags=re.DOTALL)
    return out


def extract_sg_id(arn: str) -> str:
    if ":security-group/" in arn:
        return arn.split(":security-group/", 1)[1]
    return ""


def lookup_vpc_for_sg(arn: str, region: str) -> str:
    sg_id = extract_sg_id(arn)
    if not sg_id:
        return ""
    try:
        ec2 = boto3.client("ec2", region_name=region)
        resp = ec2.describe_security_groups(GroupIds=[sg_id])
        for sg in resp.get("SecurityGroups", []):
            vpc_id = sg.get("VpcId", "")
            if vpc_id:
                return vpc_id
    except Exception:
        return ""
    return ""


def uniquify_resource_names(tf_code: str, suffix: str) -> Tuple[str, List[Tuple[str, str]]]:
    mapping: List[Tuple[str, str]] = []
    tag = hashlib.sha1(suffix.encode("utf-8")).hexdigest()[:10]

    def repl(m: re.Match) -> str:
        rtype = m.group(1)
        rname = m.group(2)
        new_name = f"{rname}_{tag}"
        mapping.append((f"{rtype}.{new_name}", rtype))
        return f'resource "{rtype}" "{new_name}" {{'

    out = re.sub(r'resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', repl, tf_code)
    return out, mapping


def infer_template_by_rule(check_id: str, category: str) -> Optional[str]:
    c = check_id.lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    if category == "s3" and "secure_transport" in c:
        return None
    if category == "iam" and "password" in c and "policy" in c:
        return "iac/snippets/iam/fix-iam_password_policy_strong.tf"
    if category == "s3" and ("public" in c or "acl" in c or "policy" in c):
        if "account_level_public_access" in c:
            return "iac/snippets/s3/fix-s3_account_public_access_block.tf"
        return "iac/snippets/s3/fix-s3_bucket_public_access_block.tf"
    if category == "s3" and ("encrypt" in c or "encryption" in c):
        return "iac/snippets/s3/fix-s3_bucket_default_encryption.tf"
    if category == "cloudtrail" and ("log_file_validation" in c or "validation" in c):
        return "iac/snippets/cloudtrail/fix-cloudtrail_log_file_validation_enabled.tf"
    if category == "cloudtrail" and ("kms_encryption" in c or "kms" in c):
        return "iac/snippets/cloudtrail/fix-cloudtrail_kms_encryption_enabled.tf"
    if category == "network-ec2-vpc" and "securitygroup_default_restrict_traffic" in c:
        return "iac/snippets/network-ec2-vpc/fix-ec2_securitygroup_default_restrict_traffic.tf"
    if category == "cloudwatch" and ("kms" in c or "encrypt" in c or "encryption" in c):
        return "iac/snippets/cloudwatch/fix-cloudwatch_log_group_encrypted.tf"
    return None


def import_id_for_type(resource_type: str, finding: Dict[str, Any]) -> str:
    arn = finding.get("resource_arn", "")
    if resource_type in {
        "aws_s3_bucket_public_access_block",
        "aws_s3_bucket_server_side_encryption_configuration",
        "aws_s3_bucket_policy",
    }:
        return extract_bucket(arn)
    if resource_type == "aws_cloudtrail":
        return extract_trail_name(arn)
    if resource_type == "aws_cloudwatch_log_group":
        return extract_log_group(arn)
    if resource_type == "aws_iam_account_password_policy":
        return finding.get("account_id", "")
    if resource_type == "aws_s3_account_public_access_block":
        return finding.get("account_id", "")
    if resource_type == "aws_default_security_group":
        return finding.get("_vpc_id", "")
    return ""


def validate_tf_snippet(tf_code: str) -> bool:
    terraform_bin = shutil.which("terraform")
    if not terraform_bin:
        return True

    provider_stub = """
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
""".strip()

    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        (work / "main.tf").write_text(tf_code.rstrip() + "\n", encoding="utf-8")
        (work / "_provider.tf").write_text(provider_stub + "\n", encoding="utf-8")

        init = subprocess.run(
            [terraform_bin, f"-chdir={work}", "init", "-backend=false", "-input=false", "-no-color"],
            capture_output=True,
            text=True,
        )
        if init.returncode != 0:
            return False

        validate = subprocess.run(
            [terraform_bin, f"-chdir={work}", "validate", "-no-color"],
            capture_output=True,
            text=True,
        )
        return validate.returncode == 0


def check_priority(check_id: str) -> int:
    c = (check_id or "").lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    if c == "cloudtrail_kms_encryption_enabled":
        return 100
    if c == "cloudtrail_log_file_validation_enabled":
        return 90
    if c in {"cloudtrail_s3_dataevents_read_enabled", "cloudtrail_s3_dataevents_write_enabled"}:
        return 80
    if c == "s3_bucket_secure_transport_policy":
        return 70
    return 10


def build_secure_transport_policy_tf(finding: Dict[str, Any]) -> str:
    bucket = extract_bucket(finding.get("resource_arn", ""))
    if not bucket:
        return ""

    policy_doc: Dict[str, Any] = {"Version": "2012-10-17", "Statement": []}
    try:
        s3 = boto3.client("s3")
        resp = s3.get_bucket_policy(Bucket=bucket)
        raw = resp.get("Policy", "")
        if raw:
            loaded = json.loads(raw)
            if isinstance(loaded, dict):
                policy_doc = loaded
    except Exception:
        pass

    stmts = policy_doc.get("Statement", [])
    if not isinstance(stmts, list):
        stmts = [stmts] if stmts else []

    wanted_sid = "DenyInsecureTransport"
    already = False
    for s in stmts:
        if not isinstance(s, dict):
            continue
        if s.get("Sid") == wanted_sid:
            already = True
            break
        cond = s.get("Condition", {})
        bool_cond = cond.get("Bool", {}) if isinstance(cond, dict) else {}
        if isinstance(bool_cond, dict) and str(bool_cond.get("aws:SecureTransport", "")).lower() == "false":
            already = True
            break

    if not already:
        stmts.append(
            {
                "Sid": wanted_sid,
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [f"arn:aws:s3:::{bucket}", f"arn:aws:s3:::{bucket}/*"],
                "Condition": {"Bool": {"aws:SecureTransport": "false"}},
            }
        )
    policy_doc["Statement"] = stmts
    policy_json = json.dumps(policy_doc, indent=2)
    return (
        'resource "aws_s3_bucket_policy" "fix_s3_secure_transport" {\n'
        f'  bucket = "{bucket}"\n'
        "  policy = <<POLICY\n"
        f"{policy_json}\n"
        "POLICY\n"
        "}\n"
    )


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
        "skipped": [],
    }

    for cat in CATEGORIES:
        cat_dir = out_root / cat
        cat_dir.mkdir(parents=True, exist_ok=True)
        for old_tf in cat_dir.glob("*.tf"):
            old_tf.unlink(missing_ok=True)
        overall["categories"][cat] = []
        overall["import_map"][cat] = []

    fail_rows = [x for x in rows if x.get("status") == "FAIL"]
    fail_rows.sort(key=lambda x: check_priority(x.get("check_id", "")), reverse=True)

    cloudtrail_with_kms: set[str] = set()
    cloudtrail_with_dataevents: set[str] = set()

    for f in fail_rows:
        cid = f.get("check_id", "unknown")
        cat = category_of(f.get("service", ""), cid)
        if not cat:
            overall["skipped"].append({"check_id": cid, "reason": "unsupported_category"})
            continue

        cid_l = cid.lower()
        trail_name = extract_trail_name(f.get("resource_arn", ""))
        if "cloudtrail_kms_encryption_enabled" in cid_l and trail_name:
            cloudtrail_with_kms.add(trail_name)
        if "cloudtrail_s3_dataevents_" in cid_l and trail_name:
            if trail_name in cloudtrail_with_dataevents:
                overall["categories"][cat].append(
                    {
                        "check_id": cid,
                        "manual_required": True,
                        "files": [],
                        "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                        "score": f.get("osfp", {}).get("priority_score", 0),
                        "reason": "consolidated_duplicate_dataevents",
                    }
                )
                continue
            cloudtrail_with_dataevents.add(trail_name)
        if "cloudtrail_log_file_validation_enabled" in cid_l and trail_name and trail_name in cloudtrail_with_kms:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "consolidated_into_kms_cloudtrail_fix",
                }
            )
            continue

        key = safe_id(
            f"{cid}_{f.get('resource_arn', '')}_{f.get('region', '')}_{f.get('resource_id', '')}"
        )

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
        if "s3_bucket_secure_transport_policy" in cid_l:
            tf_code = build_secure_transport_policy_tf(f)
        elif template_path and Path(template_path).exists():
            tf_code = Path(template_path).read_text(encoding="utf-8")
        elif USE_BEDROCK_FALLBACK:
            prompt = (
                "Output only valid Terraform HCL. No markdown, no preamble. "
                "Generate minimal-change remediation for this finding: "
                + json.dumps(f)
            )
            try:
                tf_code = strip_code_fence(render_with_bedrock(a.model_id, prompt))
            except Exception:
                tf_code = ""
        else:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "unsupported_no_template",
                }
            )
            continue

        if "securitygroup_default_restrict_traffic" in cid.lower():
            vpc_id = lookup_vpc_for_sg(f.get("resource_arn", ""), f.get("region", a.region))
            if vpc_id:
                f["_vpc_id"] = vpc_id
                tf_code = tf_code.replace("var.vpc_id", f'"{vpc_id}"')

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

        if "var." in tf_code:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "unresolved_variables",
                }
            )
            continue

        if not validate_tf_snippet(tf_code):
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "generated_hcl_failed_validation",
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
