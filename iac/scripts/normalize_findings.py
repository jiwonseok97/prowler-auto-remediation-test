#!/usr/bin/env python3
"""Normalize Prowler ASFF/JSON findings for remediation workflows."""
import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List

SKIP_SERVICES = {"account", "root", "organizations", "support"}
SUPPORTED_SERVICES = {
    "iam",
    "s3",
    "cloudtrail",
    "cloudwatch",
    "logs",
    "ec2",
    "vpc",
    "config",
    "kms",
    "accessanalyzer",
}
NON_TERRAFORM_PREFIX = ("guardduty_", "securityhub_", "inspector_", "iam_root_")
MANUAL_CHECK_KEYWORDS = ("mfa", "root", "access_key", "organizations")


def first(*vals: Any) -> str:
    for v in vals:
        if v is None:
            continue
        s = str(v).strip()
        if s:
            return s
    return ""


def normalize_token(s: str) -> str:
    s = s.replace(" ", "_")
    s = re.sub(r"[^a-zA-Z0-9_:/.-]+", "_", s)
    return s


def parse_check_id(f: Dict[str, Any]) -> str:
    raw = first(f.get("CheckID"), f.get("GeneratorId"), f.get("Id"), f.get("Title"))
    raw = normalize_token(raw)
    if "/" in raw:
        raw = raw.split("/")[-1]
    if raw.startswith("arn:"):
        raw = raw.split(":")[-1]
    return raw.lower()


def parse_service(f: Dict[str, Any], check_id: str) -> str:
    explicit = first(f.get("Service"), f.get("service"), f.get("ProductFields", {}).get("Service")).lower()
    if explicit and explicit in SUPPORTED_SERVICES.union(SKIP_SERVICES):
        return explicit

    gid = first(f.get("GeneratorId"), "").lower()
    for token in ["iam", "s3", "cloudtrail", "cloudwatch", "logs"]:
        if f"/{token}/" in gid or gid.startswith(f"{token}_") or f"_{token}_" in gid:
            return token

    cid = check_id
    if cid.startswith("prowler-"):
        cid = cid.split("prowler-", 1)[1]
    prefix = cid.split("_", 1)[0] if "_" in cid else cid
    if prefix in SUPPORTED_SERVICES.union(SKIP_SERVICES):
        return prefix
    if prefix in {"ec2", "vpc"}:
        return prefix

    arn = first(f.get("ProductArn"), parse_resource_arn(f))
    parts = arn.split(":")
    if len(parts) > 2 and parts[2] in SUPPORTED_SERVICES.union(SKIP_SERVICES):
        return parts[2]

    return explicit or ""


def parse_resource_arn(f: Dict[str, Any]) -> str:
    direct = first(f.get("ResourceARN"), f.get("ResourceArn"), f.get("ResourceId"), f.get("resource_arn"))
    if direct:
        return direct
    for r in f.get("Resources", []) if isinstance(f.get("Resources"), list) else []:
        if isinstance(r, dict):
            cand = first(r.get("Id"), r.get("Arn"), r.get("ResourceArn"))
            if cand:
                return cand
    return ""


def parse_region_from_arn(arn: str) -> str:
    if not arn.startswith("arn:"):
        return ""
    parts = arn.split(":")
    if len(parts) < 4:
        return ""
    return str(parts[3]).strip()


def is_fail(f: Dict[str, Any]) -> bool:
    status = first(f.get("Result"), f.get("Compliance", {}).get("Status"), f.get("RecordState"), f.get("result")).upper()
    return status in {"FAIL", "FAILED", "ACTIVE", "NON_COMPLIANT"}


def normalize(rows: List[Dict[str, Any]], default_account: str, default_region: str) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for r in rows:
        if not isinstance(r, dict) or not is_fail(r):
            continue

        check_id = parse_check_id(r)
        if not check_id:
            continue

        service = parse_service(r, check_id)
        if service in SKIP_SERVICES:
            continue

        resource_arn = parse_resource_arn(r)
        account_id = first(r.get("AccountId"), r.get("AwsAccountId"), default_account)
        region = first(r.get("Region"), parse_region_from_arn(resource_arn), default_region)
        severity = first(r.get("Severity", {}).get("Label"), r.get("Severity"), "MEDIUM").upper()

        non_tf = check_id.startswith(NON_TERRAFORM_PREFIX)
        # Allow auto-remediation for CloudWatch metric-filter checks even if check ids
        # include keywords like root/mfa/organizations.
        cloudwatch_filter_check = (
            check_id.startswith("prowler-cloudwatch_log_metric_filter_")
            or check_id.startswith("cloudwatch_log_metric_filter_")
        )
        manual = non_tf or (any(k in check_id for k in MANUAL_CHECK_KEYWORDS) and not cloudwatch_filter_check)

        out.append(
            {
                "check_id": check_id,
                "service": service,
                "resource_arn": resource_arn,
                "region": region,
                "account_id": account_id,
                "severity": severity,
                "status": "FAIL",
                "manual_required": manual,
                "non_terraform": non_tf,
            }
        )
    return out


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--account-id", default="")
    p.add_argument("--region", default="")
    a = p.parse_args()

    raw = json.loads(Path(a.input).read_text(encoding="utf-8-sig"))
    rows = raw.get("Findings", []) if isinstance(raw, dict) else raw
    if not isinstance(rows, list):
        rows = []

    normalized = normalize(rows, a.account_id, a.region)
    out = Path(a.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(normalized, indent=2), encoding="utf-8")
    print(json.dumps({"total": len(rows), "normalized_fail": len(normalized)}))


if __name__ == "__main__":
    main()
