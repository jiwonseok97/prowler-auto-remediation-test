#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

SEVERITY_ORDER = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL"]
SEVERITY_WEIGHTS = {
    "CRITICAL": 10,
    "HIGH": 6,
    "MEDIUM": 3,
    "LOW": 1,
    "INFORMATIONAL": 0,
}

SERVICE_GROUP_MAP = {
    "s3": "storage",
    "efs": "storage",
    "fsx": "storage",
    "ec2": "compute",
    "ebs": "compute",
    "autoscaling": "compute",
    "elasticloadbalancing": "network",
    "elbv2": "network",
    "elb": "network",
    "lambda": "serverless",
    "apprunner": "serverless",
    "cloudfront": "network",
    "ecs": "container",
    "eks": "container",
    "ecr": "container",
    "fargate": "container",
    "rds": "database",
    "dynamodb": "database",
    "redshift": "database",
    "elasticache": "database",
    "opensearch": "database",
    "vpc": "network",
    "route53": "network",
    "networkfirewall": "network",
    "wafv2": "network",
    "cloudwatch": "monitoring",
    "cloudtrail": "monitoring",
    "logs": "monitoring",
    "config": "monitoring",
    "guardduty": "security",
    "securityhub": "security",
    "inspector2": "security",
    "macie": "security",
    "iam": "IAM",
    "kms": "security",
    "organizations": "governance",
    "account": "governance",
    "budgets": "governance",
    "cloudformation": "devops",
    "codebuild": "devops",
    "codepipeline": "devops",
    "codedeploy": "devops",
    "codeartifact": "devops",
    "codecommit": "devops",
    "ssm": "devops",
    "apigateway": "api_gateway",
    "apigatewayv2": "api_gateway",
    "sagemaker": "ai_ml",
    "bedrock": "ai_ml",
    "rekognition": "ai_ml",
    "textract": "ai_ml",
    "sns": "messaging",
    "sqs": "messaging",
    "ses": "messaging",
    "athena": "analytics",
    "glue": "analytics",
    "emr": "analytics",
    "quicksight": "analytics",
    "kinesis": "analytics",
    "events": "messaging",
}

ARN_SERVICE_MAP = {
    "s3": "s3",
    "ec2": "ec2",
    "rds": "rds",
    "dynamodb": "dynamodb",
    "lambda": "lambda",
    "iam": "iam",
    "kms": "kms",
    "cloudtrail": "cloudtrail",
    "logs": "cloudwatch",
    "elasticloadbalancing": "elasticloadbalancing",
    "apigateway": "apigateway",
    "apigatewayv2": "apigatewayv2",
    "wafv2": "wafv2",
    "route53": "route53",
}


def load_json(path: Path) -> Any:
    if not path.exists():
        raise FileNotFoundError(f"input file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def load_asff_findings(path: Path) -> list[dict[str, Any]]:
    data = load_json(path)
    if isinstance(data, list):
        return [x for x in data if isinstance(x, dict)]
    if isinstance(data, dict):
        findings = data.get("Findings", [])
        return [x for x in findings if isinstance(x, dict)]
    return []


def extract_service(finding: dict[str, Any]) -> str:
    product_fields = finding.get("ProductFields") or {}
    service = str(
        product_fields.get("ServiceName")
        or product_fields.get("aws/service")
        or ""
    ).strip().lower()
    if service:
        return service
    generator_id = str(finding.get("GeneratorId") or "").lower()
    match = re.search(r"prowler-([a-z][a-z0-9]+)_", generator_id)
    if match:
        return match.group(1)

    for rid in extract_resources(finding):
        if rid.startswith("arn:"):
            parts = rid.split(":")
            if len(parts) > 2:
                arn_service = parts[2].strip().lower()
                return ARN_SERVICE_MAP.get(arn_service, arn_service)
    return "unknown"


def extract_resources(finding: dict[str, Any]) -> Iterable[str]:
    resources = finding.get("Resources", []) or []
    for res in resources:
        if not isinstance(res, dict):
            continue
        rid = str(res.get("Id") or "").strip()
        if rid:
            yield rid


def extract_severity(finding: dict[str, Any]) -> str:
    severity = finding.get("Severity") or {}
    label = str(severity.get("Label") or severity or "INFORMATIONAL").upper()
    if label == "INFO":
        return "INFORMATIONAL"
    if label not in SEVERITY_ORDER:
        return "INFORMATIONAL"
    return label


def is_failed(finding: dict[str, Any]) -> bool:
    compliance = finding.get("Compliance") or {}
    status = str(compliance.get("Status") or "").upper()
    return status in {"FAILED", "FAIL"}


def service_to_group(service: str) -> str:
    key = (service or "").strip().lower()
    return SERVICE_GROUP_MAP.get(key, "security")


def build_pipeline_summary(
    base: dict[str, Any],
    findings: list[dict[str, Any]],
) -> dict[str, Any]:
    total_fail = 0
    total_pass = 0
    severity_counts = {k.lower(): 0 for k in SEVERITY_ORDER}
    weighted_fail = 0
    weighted_total = 0

    group_data: dict[str, dict[str, Any]] = defaultdict(
        lambda: {
            "resources": set(),
            "total_findings": 0,
            "failed_findings": 0,
            "new_failed_findings": 0,
            "severity": {k.lower(): 0 for k in SEVERITY_ORDER},
        }
    )

    for finding in findings:
        failed = is_failed(finding)
        sev = extract_severity(finding)
        weight = SEVERITY_WEIGHTS.get(sev, 0)
        weighted_total += weight
        if failed:
            total_fail += 1
            weighted_fail += weight
        else:
            total_pass += 1

        service = extract_service(finding)
        group = service_to_group(service)
        entry = group_data[group]
        entry["total_findings"] += 1

        for rid in extract_resources(finding):
            entry["resources"].add(rid)

        if failed:
            entry["failed_findings"] += 1
            sev_key = sev.lower()
            entry["severity"][sev_key] += 1
            severity_counts[sev_key] += 1

    total = total_fail + total_pass
    if weighted_total:
        threat_score = round(
            100 - (weighted_fail / weighted_total * 100),
            2,
        )
    else:
        threat_score = None

    resource_inventory = []
    for group, entry in group_data.items():
        resource_inventory.append(
            {
                "id": group,
                "resources_count": len(entry["resources"]),
                "total_findings": entry["total_findings"],
                "failed_findings": entry["failed_findings"],
                "new_failed_findings": entry["new_failed_findings"],
                "severity": entry["severity"],
            }
        )

    summary = dict(base)
    summary.update(
        {
            "threat_score": threat_score,
            "findings_status": {
                "fail": total_fail,
                "pass": total_pass,
                "fail_new": 0,
                "pass_new": 0,
            },
            "severity": severity_counts,
            "resource_inventory": resource_inventory,
        }
    )
    return summary


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build pipeline summary payload")
    parser.add_argument("--base", required=False, default="", help="Base JSON file")
    parser.add_argument("--asff", required=True, help="ASFF JSON file")
    parser.add_argument("--output", required=True, help="Output JSON file")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    base: dict[str, Any] = {}
    if args.base:
        base = load_json(Path(args.base))
        if not isinstance(base, dict):
            raise ValueError("base JSON must be an object")
    findings = load_asff_findings(Path(args.asff))
    summary = build_pipeline_summary(base, findings)
    Path(args.output).write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"summary saved: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
