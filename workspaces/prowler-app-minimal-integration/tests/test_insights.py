from app import (
    build_category_patterns,
    build_check_stats,
    build_quick_wins,
    build_triage,
    compute_risk_score,
    intersect_cis_isms,
)


def test_compute_risk_score_prefers_severity_over_exposure() -> None:
    high = compute_risk_score("HIGH", 1)
    medium = compute_risk_score("MEDIUM", 100)
    assert high > medium


def test_build_triage_splits_immediate_and_short_term() -> None:
    stats = {
        "check_a": {"severity": "CRITICAL", "exposure": 1},
        "check_b": {"severity": "MEDIUM", "exposure": 10},
    }
    triage = build_triage(stats, manifest=None)
    immediate = [item["check_id"] for item in triage["immediate"]]
    short_term = [item["check_id"] for item in triage["short_term"]]
    assert "check_a" in immediate
    assert "check_b" in short_term


def test_build_quick_wins_picks_high_impact_low_difficulty() -> None:
    stats = {
        "check_a": {"severity": "HIGH", "exposure": 1, "remediation_tier": "safe-auto"},
        "check_b": {"severity": "HIGH", "exposure": 1, "remediation_tier": "manual-runbook"},
    }
    quick = build_quick_wins(stats)
    assert [item["check_id"] for item in quick] == ["check_a"]


def test_build_category_patterns_top3() -> None:
    findings = [
        {"check_id": "x", "severity": "HIGH", "status": "FAIL"},
        {"check_id": "y", "severity": "MEDIUM", "status": "FAIL"},
        {"check_id": "x", "severity": "HIGH", "status": "FAIL"},
    ]
    stats = build_check_stats(findings)
    manifest = {"check_map": {"x": {"category": "s3"}, "y": {"category": "iam"}}}
    categories = build_category_patterns(stats, manifest, top=3)
    assert categories[0]["category"] == "s3"


def test_intersect_cis_isms_returns_sorted() -> None:
    stats = {
        "a": {"severity": "CRITICAL", "exposure": 2},
        "b": {"severity": "MEDIUM", "exposure": 5},
    }
    result = intersect_cis_isms({"a", "b"}, {"b", "a"}, stats, top=2)
    assert [item["check_id"] for item in result] == ["a", "b"]
