#!/usr/bin/env python3
"""Normalize Prowler ASFF/JSON findings for remediation workflows."""
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

SKIP_SERVICES = {"account", "root", "organizations", "support"}
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


def parse_service(f: Dict[str, Any]) -> str:
    service = first(f.get("Service"), f.get("service"), f.get("ProductFields", {}).get("Service")).lower()
    if service:
        return service
    arn = first(f.get("ProductArn"))
    parts = arn.split(":")
    return parts[2].lower() if len(parts) > 2 else ""


def parse_check_id(f: Dict[str, Any]) -> str:
    raw = first(f.get("CheckID"), f.get("GeneratorId"), f.get("Id"), f.get("Title"))
    return raw.replace(" ", "_")


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


def is_fail(f: Dict[str, Any]) -> bool:
    status = first(f.get("Result"), f.get("Compliance", {}).get("Status"), f.get("RecordState"), f.get("result")).upper()
    return status in {"FAIL", "FAILED", "ACTIVE", "NON_COMPLIANT"}


def normalize(rows: List[Dict[str, Any]], default_account: str, default_region: str) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for r in rows:
        if not isinstance(r, dict) or not is_fail(r):
            continue
        service = parse_service(r)
        if service in SKIP_SERVICES:
            continue
        check_id = parse_check_id(r)
        if not check_id:
            continue

        resource_arn = parse_resource_arn(r)
        account_id = first(r.get("AccountId"), r.get("AwsAccountId"), default_account)
        region = first(r.get("Region"), default_region)
        severity = first(r.get("Severity", {}).get("Label"), r.get("Severity"), "MEDIUM").upper()

        non_tf = check_id.startswith(NON_TERRAFORM_PREFIX)
        manual = non_tf or any(k in check_id.lower() for k in MANUAL_CHECK_KEYWORDS)

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