#!/usr/bin/env python3
"""Generate remediation plan and terraform bundle."""
import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List

SUPPORTED_SERVICES = {"iam", "s3", "cloudtrail", "cloudwatch", "logs", "ec2", "vpc", "config", "kms", "accessanalyzer"}
GLOBAL_CHECK_HINTS = (
    "iam_password_policy",
    "account_level_public_access",
    "account_public_access",
)
CREATE_MISSING_HINTS = (
    "cloudtrail_cloudwatch_logging_enabled",
    "vpc_flow_logs_enabled",
    "cloudwatch_log_metric_filter",
    "cloudwatch_changes_to_",
    "cloudtrail_s3_dataevents_",
    "accessanalyzer_enabled",
    "config_recorder_all_regions_enabled",
)

def is_supported_service(finding: Dict[str, Any]) -> bool:
    service = str(finding.get("service", "")).strip().lower()
    if service in SUPPORTED_SERVICES:
        return True
    cid = str(finding.get("check_id", "")).strip().lower()
    if cid.startswith("prowler-"):
        cid = cid.split("prowler-", 1)[1]
    prefix = cid.split("_", 1)[0] if "_" in cid else cid
    return prefix in SUPPORTED_SERVICES


def infer_service(finding: Dict[str, Any]) -> str:
    service = str(finding.get("service", "")).strip().lower()
    if service:
        return service
    cid = str(finding.get("check_id", "")).strip().lower()
    if cid.startswith("prowler-"):
        cid = cid.split("prowler-", 1)[1]
    return cid.split("_", 1)[0] if "_" in cid else ""


def classify_action(finding: Dict[str, Any]) -> str:
    cid = str(finding.get("check_id", "")).strip().lower()
    arn = str(finding.get("resource_arn", "")).strip()
    tier = str(finding.get("remediation_tier", "")).strip().lower()
    if finding.get("manual_required") or finding.get("non_terraform") or tier == "manual-runbook":
        return "SKIP"
    if not is_supported_service(finding):
        return "SKIP"
    if arn:
        return "IMPORT_AND_PATCH"
    if any(hint in cid for hint in GLOBAL_CHECK_HINTS):
        return "PATCH_EXISTING"
    if any(hint in cid for hint in CREATE_MISSING_HINTS):
        return "CREATE_MISSING"
    return "SKIP"


def build_plan(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    plan_rows: List[Dict[str, Any]] = []
    for row in rows:
        if str(row.get("status", "")).upper() != "FAIL":
            continue
        action = classify_action(row)
        plan_rows.append(
            {
                "check_id": row.get("check_id", ""),
                "service": row.get("service", ""),
                "resource_arn": row.get("resource_arn", ""),
                "region": row.get("region", ""),
                "account_id": row.get("account_id", ""),
                "remediation_tier": row.get("remediation_tier", ""),
                "action": action,
            }
        )

    counts: Dict[str, int] = {"PATCH_EXISTING": 0, "IMPORT_AND_PATCH": 0, "CREATE_MISSING": 0, "SKIP": 0}
    for row in plan_rows:
        action = str(row.get("action", "SKIP"))
        counts[action] = counts.get(action, 0) + 1
    return {"summary": counts, "items": plan_rows}


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output-root", required=True)
    p.add_argument("--snippet-map", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--model-id", required=True)
    args = p.parse_args()

    in_path = Path(args.input)
    rows = json.loads(in_path.read_text(encoding="utf-8"))
    if not isinstance(rows, list):
        rows = []

    out_root = Path(args.output_root)
    out_root.mkdir(parents=True, exist_ok=True)

    full_baseline_fail = len([r for r in rows if str(r.get("status", "")).upper() == "FAIL"])
    plan = build_plan(rows)
    plan_path = out_root / "remediation_plan.json"
    plan_path.write_text(json.dumps(plan, indent=2), encoding="utf-8")

    actionable_by_key = {
        (
            str(item.get("check_id", "")),
            str(item.get("resource_arn", "")),
            str(item.get("region", "")),
            str(item.get("account_id", "")),
        )
        for item in plan.get("items", [])
        if item.get("action") in {"PATCH_EXISTING", "IMPORT_AND_PATCH", "CREATE_MISSING"}
    }
    actionable_rows = [
        row
        for row in rows
        if (
            str(row.get("check_id", "")),
            str(row.get("resource_arn", "")),
            str(row.get("region", "")),
            str(row.get("account_id", "")),
        )
        in actionable_by_key
    ]

    filtered_input = out_root / "_actionable_findings.json"
    filtered_input.write_text(json.dumps(actionable_rows, indent=2), encoding="utf-8")

    cmd = [
        sys.executable,
        "iac/scripts/generate_remediation_bundle.py",
        "--input",
        str(filtered_input),
        "--output-root",
        args.output_root,
        "--snippet-map",
        args.snippet_map,
        "--account-id",
        args.account_id,
        "--region",
        args.region,
        "--model-id",
        args.model_id,
    ]
    rc = subprocess.call(cmd)
    if rc != 0:
        raise SystemExit(rc)

    generation_manifest = out_root / "_generation_manifest.json"
    if generation_manifest.exists():
        doc = json.loads(generation_manifest.read_text(encoding="utf-8"))
        doc["baseline_fail_count"] = full_baseline_fail
        generation_manifest.write_text(json.dumps(doc, indent=2), encoding="utf-8")

    raise SystemExit(0)


if __name__ == "__main__":
    main()
