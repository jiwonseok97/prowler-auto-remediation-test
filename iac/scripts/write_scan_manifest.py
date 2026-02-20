#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--normalized", required=True)
    p.add_argument("--prioritized", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--framework", default="cis_1.4_only")
    a = p.parse_args()

    normalized = json.loads(Path(a.normalized).read_text(encoding="utf-8"))
    prioritized = json.loads(Path(a.prioritized).read_text(encoding="utf-8"))
    fail = len([x for x in normalized if x.get("status") == "FAIL"])

    doc = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "account_id": a.account_id,
        "region": a.region,
        "framework": a.framework,
        "baseline_fail_count": fail,
        "findings": len(prioritized),
    }
    Path(a.output).write_text(json.dumps(doc, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
