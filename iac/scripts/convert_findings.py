#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

SKIP_SERVICES = {"account", "root", "organizations", "support"}


def _first_non_empty(*values: Any) -> str:
    for value in values:
        if value is None:
            continue
        text = str(value).strip()
        if text:
            return text
    return ""


def _extract_service(item: Dict[str, Any]) -> str:
    service = _first_non_empty(
        item.get("Service"),
        item.get("service"),
        item.get("ProductFields", {}).get("Service"),
    ).lower()

    if not service:
        product_arn = _first_non_empty(item.get("ProductArn"))
        parts = product_arn.split(":")
        if len(parts) > 2:
            service = parts[2].lower()

    generator = _first_non_empty(item.get("GeneratorId"), item.get("Types", [""])[0]).lower()
    if not service:
        prefixes = ["aws.", "aws/", "aws-"]
        for prefix in prefixes:
            if generator.startswith(prefix):
                service = generator.split(prefix, 1)[1].split("/")[0].split(".")[0].split("_")[0]
                break

    if not service and "/" in generator:
        service = generator.split("/")[0].split(".")[0].split("_")[0]

    return service


def _extract_check_id(item: Dict[str, Any]) -> str:
    check_id = _first_non_empty(
        item.get("CheckID"),
        item.get("check_id"),
        item.get("GeneratorId"),
        item.get("Id"),
        item.get("Title"),
    )
    return check_id.replace(" ", "_")


def _extract_account(item: Dict[str, Any]) -> str:
    account = _first_non_empty(item.get("AccountId"), item.get("AwsAccountId"), item.get("account_id"))
    if not account:
        for arn_candidate in [item.get("Id"), item.get("ProductArn")]:
            if not arn_candidate:
                continue
            parts = str(arn_candidate).split(":")
            if len(parts) > 4 and parts[4].isdigit():
                account = parts[4]
                break
    return account


def _extract_region(item: Dict[str, Any]) -> str:
    region = _first_non_empty(item.get("Region"), item.get("region"), item.get("Resources", [{}])[0].get("Region"))
    if not region:
        for arn_candidate in [item.get("ProductArn"), item.get("Id")]:
            if not arn_candidate:
                continue
            parts = str(arn_candidate).split(":")
            if len(parts) > 3 and parts[3]:
                region = parts[3]
                break
    return region


def _extract_resource_arn(item: Dict[str, Any]) -> str:
    direct = _first_non_empty(
        item.get("ResourceARN"),
        item.get("ResourceArn"),
        item.get("resource_arn"),
        item.get("ResourceId"),
        item.get("resource_id"),
    )
    if direct:
        return direct

    resources = item.get("Resources")
    if isinstance(resources, list):
        for resource in resources:
            if not isinstance(resource, dict):
                continue
            resource_arn = _first_non_empty(resource.get("Id"), resource.get("Arn"), resource.get("ResourceArn"))
            if resource_arn:
                return resource_arn

    return ""


def _is_fail(item: Dict[str, Any]) -> bool:
    result = _first_non_empty(item.get("Result"), item.get("result"), item.get("Compliance", {}).get("Status"), item.get("RecordState"))
    return result.upper() in {"FAIL", "FAILED", "NON_COMPLIANT", "ACTIVE"}


def normalize_findings(raw_findings: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    normalized: List[Dict[str, str]] = []

    for item in raw_findings:
        if not isinstance(item, dict):
            continue
        if not _is_fail(item):
            continue

        service = _extract_service(item)
        if service in SKIP_SERVICES:
            continue

        check_id = _extract_check_id(item)
        if not check_id:
            continue

        normalized.append(
            {
                "check_id": check_id,
                "service": service,
                "resource_arn": _extract_resource_arn(item),
                "region": _extract_region(item),
                "account_id": _extract_account(item),
            }
        )

    return normalized


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert raw Prowler findings to normalized remediation input")
    parser.add_argument("--input", required=True, help="Input Prowler JSON file path")
    parser.add_argument("--output", required=True, help="Output normalized findings JSON path")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        raise FileNotFoundError(f"input file not found: {input_path}")

    raw = json.loads(input_path.read_text(encoding="utf-8-sig"))
    if isinstance(raw, dict):
        findings = raw.get("Findings") or raw.get("findings") or []
    elif isinstance(raw, list):
        findings = raw
    else:
        findings = []

    normalized = normalize_findings(findings)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(normalized, indent=2), encoding="utf-8")

    summary = {
        "input": str(input_path),
        "output": str(output_path),
        "total_raw": len(findings),
        "normalized_fail": len(normalized),
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
