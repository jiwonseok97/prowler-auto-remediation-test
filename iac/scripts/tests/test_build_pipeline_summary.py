import json
from pathlib import Path

from iac.scripts.build_pipeline_summary import build_pipeline_summary, service_to_group


def test_build_pipeline_summary_counts(tmp_path: Path) -> None:
    base = {"baseline_fail": 2}
    findings = [
        {
            "Compliance": {"Status": "FAILED"},
            "Severity": {"Label": "HIGH"},
            "ProductFields": {"ServiceName": "s3"},
            "Resources": [{"Id": "arn:aws:s3:::bucket-a"}],
        },
        {
            "Compliance": {"Status": "PASSED"},
            "Severity": {"Label": "LOW"},
            "ProductFields": {"ServiceName": "s3"},
            "Resources": [{"Id": "arn:aws:s3:::bucket-a"}],
        },
        {
            "Compliance": {"Status": "FAILED"},
            "Severity": {"Label": "CRITICAL"},
            "ProductFields": {"ServiceName": "ec2"},
            "Resources": [{"Id": "arn:aws:ec2:region:acct:instance/i-1"}],
        },
        {
            "Compliance": {"Status": "FAILED"},
            "Severity": {"Label": "MEDIUM"},
            "Resources": [{"Id": "arn:aws:rds:region:acct:db:demo"}],
        },
    ]

    summary = build_pipeline_summary(base, findings)

    assert summary["threat_score"] == 5.0
    assert summary["findings_status"]["fail"] == 3
    assert summary["findings_status"]["pass"] == 1
    assert summary["severity"]["critical"] == 1
    assert summary["severity"]["high"] == 1
    assert summary["severity"]["low"] == 0
    inventory_ids = {item["id"] for item in summary["resource_inventory"]}
    assert "storage" in inventory_ids
    assert "compute" in inventory_ids
    assert "database" in inventory_ids


def test_service_to_group_fallbacks() -> None:
    assert service_to_group("s3") == "storage"
    assert service_to_group("lambda") == "serverless"
    assert service_to_group("") == "security"
