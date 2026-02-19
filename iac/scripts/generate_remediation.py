#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

SUPPORTED_SERVICES = {"iam", "s3", "cloudtrail", "cloudwatch", "ec2", "vpc", "logs"}
CATEGORIES = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]
OPTIONAL_IMPORT_NONFATAL_TYPES = {
    "aws_s3_bucket_policy",
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_ownership_controls",
    "aws_s3_bucket_logging",
    "aws_s3_bucket_server_side_encryption_configuration",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate remediation Terraform from normalized findings")
    parser.add_argument("--normalized-findings", required=True)
    parser.add_argument("--snippet-root", required=False, default="iac/snippets")
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--run-id", required=False, default="")
    parser.add_argument("--log", required=False, default="")
    return parser.parse_args()


def safe_name(value: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9_]+", "_", value or "unknown")
    cleaned = re.sub(r"_+", "_", cleaned).strip("_")
    if not cleaned:
        cleaned = "unknown"
    return cleaned.lower()


def arn_is_global(arn: str) -> bool:
    if not arn.startswith("arn:"):
        return False
    parts = arn.split(":")
    if len(parts) < 6:
        return False
    return parts[3] == ""


def parse_bucket_from_arn(arn: str) -> str:
    if not arn:
        return ""
    if arn.startswith("arn:aws:s3:::"):
        return arn.split("arn:aws:s3:::", 1)[1].split("/")[0]
    return arn


def parse_cloudtrail_name(arn: str) -> str:
    if ":trail/" in arn:
        return arn.split(":trail/", 1)[1]
    return arn


def parse_log_group_name(arn: str) -> str:
    if ":log-group:" in arn:
        return arn.split(":log-group:", 1)[1].split(":", 1)[0]
    return arn


def parse_sg_id(arn: str) -> str:
    if arn.startswith("sg-"):
        return arn
    if ":security-group/" in arn:
        return arn.split(":security-group/", 1)[1]
    return arn


def infer_category(service: str, check_id: str) -> Optional[str]:
    c = (check_id or "").lower()
    s = (service or "").lower()
    if s == "iam" or c.startswith("iam_"):
        return "iam"
    if s == "s3" or c.startswith("s3_"):
        return "s3"
    if s == "cloudtrail" or c.startswith("cloudtrail_"):
        return "cloudtrail"
    if s in {"cloudwatch", "logs"} or c.startswith("cloudwatch_") or c.startswith("logs_"):
        return "cloudwatch"
    if s in {"ec2", "vpc"} or c.startswith("ec2_") or c.startswith("vpc_"):
        return "network-ec2-vpc"
    return None


def remediation_mode(resource_arn: str, service: str) -> str:
    if resource_arn:
        return "IMPORT_AND_PATCH"
    if service in {"iam", "account", "cloudtrail"}:
        return "PATCH_EXISTING"
    return "CREATE_MISSING"


def build_iam_password_policy(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    content = f'''resource "aws_iam_account_password_policy" "{tf_name}" {{
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false

  lifecycle {{
    ignore_changes = []
  }}
}}
'''
    return {
        "action": "PATCH_EXISTING",
        "resource_address": f"aws_iam_account_password_policy.{tf_name}",
        "import_id": "",
        "optional_create_if_missing": False,
        "tf": content,
        "status": "PLANNED",
    }


def build_s3_public_access(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    bucket = parse_bucket_from_arn(item.get("resource_arn", ""))
    if not bucket:
        return {"status": "SKIPPED", "reason": "missing_bucket_arn"}

    content = f'''resource "aws_s3_bucket_public_access_block" "{tf_name}" {{
  bucket                  = "{bucket}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {{
    ignore_changes = []
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_s3_bucket_public_access_block.{tf_name}",
        "import_id": bucket,
        "optional_create_if_missing": True,
        "tf": content,
        "status": "PLANNED",
    }


def build_s3_encryption(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    bucket = parse_bucket_from_arn(item.get("resource_arn", ""))
    if not bucket:
        return {"status": "SKIPPED", "reason": "missing_bucket_arn"}

    content = f'''resource "aws_s3_bucket_server_side_encryption_configuration" "{tf_name}" {{
  bucket = "{bucket}"

  rule {{
    apply_server_side_encryption_by_default {{
      sse_algorithm = "AES256"
    }}
  }}

  lifecycle {{
    ignore_changes = []
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_s3_bucket_server_side_encryption_configuration.{tf_name}",
        "import_id": bucket,
        "optional_create_if_missing": True,
        "tf": content,
        "status": "PLANNED",
    }


def build_s3_ownership(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    bucket = parse_bucket_from_arn(item.get("resource_arn", ""))
    if not bucket:
        return {"status": "SKIPPED", "reason": "missing_bucket_arn"}

    content = f'''resource "aws_s3_bucket_ownership_controls" "{tf_name}" {{
  bucket = "{bucket}"

  rule {{
    object_ownership = "BucketOwnerEnforced"
  }}

  lifecycle {{
    ignore_changes = []
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_s3_bucket_ownership_controls.{tf_name}",
        "import_id": bucket,
        "optional_create_if_missing": True,
        "tf": content,
        "status": "PLANNED",
    }


def build_cloudtrail_validation(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    trail_name = parse_cloudtrail_name(item.get("resource_arn", ""))
    if not trail_name:
        return {"status": "SKIPPED", "reason": "missing_cloudtrail_arn"}

    content = f'''resource "aws_cloudtrail" "{tf_name}" {{
  name                          = "{trail_name}"
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  lifecycle {{
    ignore_changes = [
      event_selector,
      insight_selector,
      kms_key_id,
      s3_bucket_name,
      s3_key_prefix,
      sns_topic_name,
      tags,
      tags_all
    ]
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_cloudtrail.{tf_name}",
        "import_id": trail_name,
        "optional_create_if_missing": False,
        "tf": content,
        "status": "PLANNED",
    }


def build_cloudwatch_encryption(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    log_group = parse_log_group_name(item.get("resource_arn", ""))
    region = item.get("region", "")
    account_id = item.get("account_id", "")
    if not log_group or not region or not account_id:
        return {"status": "SKIPPED", "reason": "missing_log_group_or_context"}

    key_arn = f"arn:aws:kms:{region}:{account_id}:alias/aws/logs"
    content = f'''resource "aws_cloudwatch_log_group" "{tf_name}" {{
  name       = "{log_group}"
  kms_key_id = "{key_arn}"

  lifecycle {{
    ignore_changes = [
      retention_in_days,
      skip_destroy,
      tags,
      tags_all
    ]
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_cloudwatch_log_group.{tf_name}",
        "import_id": log_group,
        "optional_create_if_missing": False,
        "tf": content,
        "status": "PLANNED",
    }


def build_sg_restrict(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    sg_id = parse_sg_id(item.get("resource_arn", ""))
    if not sg_id:
        return {"status": "SKIPPED", "reason": "missing_sg_arn"}

    content = f'''resource "aws_security_group" "{tf_name}" {{
  name = "{sg_id}"

  ingress = []

  egress = [
    {{
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }}
  ]

  lifecycle {{
    ignore_changes = [
      description,
      name,
      name_prefix,
      revoke_rules_on_delete,
      tags,
      tags_all,
      vpc_id
    ]
  }}
}}
'''
    return {
        "action": "IMPORT_AND_PATCH",
        "resource_address": f"aws_security_group.{tf_name}",
        "import_id": sg_id,
        "optional_create_if_missing": False,
        "tf": content,
        "status": "PLANNED",
    }


def build_vpc_flow_logs(item: Dict[str, Any], tf_name: str) -> Dict[str, Any]:
    return {"status": "SKIPPED", "reason": "unsupported_safe_autoremediation_vpc_flow_logs"}


def plan_for_finding(item: Dict[str, Any]) -> Dict[str, Any]:
    service = (item.get("service") or "").lower()
    check_id = item.get("check_id") or "unknown"
    check_lower = check_id.lower()
    category = infer_category(service, check_lower)

    base = {
        "check_id": check_id,
        "service": service,
        "resource_arn": item.get("resource_arn", ""),
        "region": item.get("region", ""),
        "account_id": item.get("account_id", ""),
        "category": category,
        "mode": remediation_mode(item.get("resource_arn", ""), service),
    }

    if service not in SUPPORTED_SERVICES and not category:
        base.update({"action": "SKIP", "status": "SKIPPED", "reason": "unsupported_service"})
        return base

    tf_name = safe_name(check_id)

    if "password" in check_lower and "policy" in check_lower and category == "iam":
        result = build_iam_password_policy(item, tf_name)
    elif category == "s3" and ("public" in check_lower or "acl" in check_lower or "policy" in check_lower):
        result = build_s3_public_access(item, tf_name)
    elif category == "s3" and ("encrypt" in check_lower or "encryption" in check_lower):
        result = build_s3_encryption(item, tf_name)
    elif category == "s3" and "ownership" in check_lower:
        result = build_s3_ownership(item, tf_name)
    elif category == "cloudtrail" and ("validation" in check_lower or "log_file" in check_lower or "multi_region" in check_lower):
        result = build_cloudtrail_validation(item, tf_name)
    elif category == "cloudwatch" and ("kms" in check_lower or "encrypt" in check_lower or "encryption" in check_lower):
        result = build_cloudwatch_encryption(item, tf_name)
    elif category == "network-ec2-vpc" and "securitygroup" in check_lower:
        result = build_sg_restrict(item, tf_name)
    elif category == "network-ec2-vpc" and "flow_log" in check_lower:
        result = build_vpc_flow_logs(item, tf_name)
    else:
        result = {"status": "SKIPPED", "reason": "unsupported_check"}

    base.update(result)
    if base.get("status") == "PLANNED":
        base["action"] = base.get("action", base.get("mode", "IMPORT_AND_PATCH"))
    else:
        base["action"] = "SKIP"
    return base


def write_tf_files(output_root: Path, plan: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    categories: Dict[str, List[Dict[str, Any]]] = {c: [] for c in CATEGORIES}

    for item in plan:
        if item.get("status") != "PLANNED":
            continue
        category = item.get("category")
        if category not in categories:
            continue
        categories[category].append(item)

    for category, items in categories.items():
        category_dir = output_root / category
        category_dir.mkdir(parents=True, exist_ok=True)

        main_parts: List[str] = []
        import_lines: List[str] = []

        for item in items:
            check_id = item["check_id"]
            tf_path = category_dir / f"{check_id}.tf"
            tf_content = item.get("tf", "")
            tf_path.write_text(tf_content, encoding="utf-8")
            main_parts.append(f"# check_id={check_id}\n{tf_content.strip()}\n")

            import_id = item.get("import_id", "")
            resource_address = item.get("resource_address", "")
            resource_arn = item.get("resource_arn", "")
            optional = str(bool(item.get("optional_create_if_missing", False))).lower()
            if import_id and resource_address:
                import_lines.append(f"{resource_address}|{import_id}|{resource_arn}|{check_id}|{optional}")

        main_tf = category_dir / "main.tf"
        if main_parts:
            main_tf.write_text("\n\n".join(main_parts) + "\n", encoding="utf-8")
        else:
            main_tf.write_text("", encoding="utf-8")

        import_map = category_dir / "import-map.txt"
        import_map.write_text("\n".join(import_lines) + ("\n" if import_lines else ""), encoding="utf-8")

    return categories


def build_manifest(output_root: Path, plan: List[Dict[str, Any]], categories: Dict[str, List[Dict[str, Any]]], baseline_fail_count: int) -> Dict[str, Any]:
    checks: Dict[str, Dict[str, str]] = {}

    for item in plan:
        check_id = item.get("check_id", "")
        category = item.get("category")
        if not check_id:
            continue

        tf_file = f"terraform/remediation/{category}/{check_id}.tf" if category else ""
        checks[check_id] = {
            "tf_file": tf_file,
            "resource_address": item.get("resource_address", ""),
            "arn": item.get("resource_arn", ""),
            "status": item.get("status", ""),
            "action": item.get("action", "SKIP"),
        }

    category_list: List[Dict[str, str]] = []
    for category in CATEGORIES:
        if categories.get(category):
            category_list.append(
                {
                    "category": category,
                    "path": f"terraform/remediation/{category}",
                    "import_map": f"terraform/remediation/{category}/import-map.txt",
                }
            )

    manifest = {
        "baseline_fail_count": baseline_fail_count,
        "categories": category_list,
        "checks": checks,
    }
    return manifest


def main() -> None:
    args = parse_args()
    normalized_path = Path(args.normalized_findings)
    output_root = Path(args.output_root)
    log_path = Path(args.log) if args.log else None

    findings = json.loads(normalized_path.read_text(encoding="utf-8-sig")) if normalized_path.exists() else []
    if not isinstance(findings, list):
        findings = []

    output_root.mkdir(parents=True, exist_ok=True)

    plan = [plan_for_finding(item) for item in findings if isinstance(item, dict)]
    categories = write_tf_files(output_root, plan)

    manifest = build_manifest(output_root, plan, categories, baseline_fail_count=len(findings))

    remediation_plan_path = output_root / "remediation_plan.json"
    remediation_plan_path.write_text(json.dumps(plan, indent=2), encoding="utf-8")

    manifest_path = output_root / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    summary = {
        "run_id": args.run_id,
        "normalized_fail": len(findings),
        "planned": len([x for x in plan if x.get("status") == "PLANNED"]),
        "skipped": len([x for x in plan if x.get("status") != "PLANNED"]),
        "manifest": str(manifest_path),
    }

    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        lines = [
            f"run_id={summary['run_id']}",
            f"normalized_fail={summary['normalized_fail']}",
            f"planned={summary['planned']}",
            f"skipped={summary['skipped']}",
        ]
        for item in plan:
            if item.get("status") != "PLANNED":
                lines.append(
                    f"SKIPPED check_id={item.get('check_id')} reason={item.get('reason', 'n/a')} service={item.get('service')}"
                )
        log_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
