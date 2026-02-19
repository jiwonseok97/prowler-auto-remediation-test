#!/usr/bin/env python3
"""OSFP scoring for normalized findings."""
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

SEV = {"CRITICAL": 100, "HIGH": 80, "MEDIUM": 60, "LOW": 30, "INFO": 10}


def score_one(f: Dict[str, Any]) -> Dict[str, Any]:
    sev = SEV.get(str(f.get("severity", "MEDIUM")).upper(), 60)
    exploitability = 90 if "public" in f.get("check_id", "").lower() else 50
    blast_radius = 85 if f.get("resource_arn", "").endswith(":root") or f.get("service") == "iam" else 55
    compliance_impact = 80 if f.get("status") == "FAIL" else 10
    remediation_complexity = 20 if f.get("manual_required") else 60

    # OSFP(0..100) = 0.35*sev + 0.25*exploit + 0.20*blast + 0.15*compliance + 0.05*(100-complexity)
    score = (
        0.35 * sev
        + 0.25 * exploitability
        + 0.20 * blast_radius
        + 0.15 * compliance_impact
        + 0.05 * (100 - remediation_complexity)
    )

    if score >= 85:
        bucket = "P0"
    elif score >= 70:
        bucket = "P1"
    elif score >= 50:
        bucket = "P2"
    else:
        bucket = "P3"

    o = dict(f)
    o.update(
        {
            "osfp": {
                "severity_input": sev,
                "exploitability": exploitability,
                "blast_radius": blast_radius,
                "compliance_impact": compliance_impact,
                "remediation_complexity": remediation_complexity,
                "priority_score": round(score, 2),
                "priority_bucket": bucket,
            }
        }
    )
    return o


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    a = p.parse_args()

    rows = json.loads(Path(a.input).read_text(encoding="utf-8"))
    scored = [score_one(x) for x in rows if isinstance(x, dict)]
    scored.sort(key=lambda x: x["osfp"]["priority_score"], reverse=True)
    Path(a.output).write_text(json.dumps(scored, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()