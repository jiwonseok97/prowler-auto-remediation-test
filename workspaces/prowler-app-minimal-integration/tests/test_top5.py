from app import build_top5


def test_build_top5_sorts_by_priority_then_score() -> None:
    payload = {"remaining_fail_check_ids": ["a", "b", "c"]}
    manifest = {
        "check_map": {
            "a": {"priority": "P2", "osfp_score": 50, "category": "s3", "remediation_tier": "safe-auto"},
            "b": {"priority": "P1", "osfp_score": 40, "category": "iam", "remediation_tier": "review-then-apply"},
            "c": {"priority": "P2", "osfp_score": 90, "category": "network", "remediation_tier": "manual-runbook"},
        }
    }

    top5 = build_top5(payload, manifest)

    assert [item["check_id"] for item in top5] == ["b", "c", "a"]
    assert top5[0]["priority"] == "P1"
    assert top5[1]["score"] == 90.0


def test_build_top5_picks_best_entry_and_dedupes() -> None:
    payload = {"remaining_fail_check_ids": ["x", "x", "y"]}
    manifest = {
        "check_map": {
            "x": [
                {"priority": "P2", "osfp_score": 10, "category": "s3", "remediation_tier": "safe-auto"},
                {"priority": "P2", "osfp_score": 99, "category": "s3", "remediation_tier": "safe-auto"},
            ],
            "y": {"priority": "P3", "osfp_score": 12, "category": "iam", "remediation_tier": "manual-runbook"},
        }
    }

    top5 = build_top5(payload, manifest)

    assert len(top5) == 2
    assert top5[0]["check_id"] == "x"
    assert top5[0]["score"] == 99.0


def test_build_top5_handles_missing_manifest() -> None:
    payload = {"remaining_fail_check_ids": ["a", "b"]}
    top5 = build_top5(payload, None)

    assert [item["check_id"] for item in top5] == ["a", "b"]
    assert top5[0]["priority"] is None
