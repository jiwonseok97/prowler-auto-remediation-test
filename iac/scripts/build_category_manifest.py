#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    a = p.parse_args()

    root = Path(a.input)
    generated = json.loads((root / "_generation_manifest.json").read_text(encoding="utf-8"))

    result: Dict[str, object] = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "account": a.account_id,
        "region": a.region,
        "baseline_fail_count": generated.get("baseline_fail_count", 0),
        "categories": [],
        "check_map": {},
    }

    for category, items in generated.get("categories", {}).items():
        if not items:
            continue

        top = sorted(items, key=lambda x: x.get("score", 0), reverse=True)[:5]
        result["categories"].append(
            {
                "category": category,
                "path": f"remediation/{category}",
                "checks": len(items),
                "top5": [x.get("check_id") for x in top],
                "manual_required": [x.get("check_id") for x in items if x.get("manual_required")],
            }
        )

        cat_manifest = {
            "category": category,
            "account": a.account_id,
            "region": a.region,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "items": items,
        }
        (root / category / "manifest.json").write_text(json.dumps(cat_manifest, indent=2), encoding="utf-8")

        for it in items:
            cid = it.get("check_id")
            result["check_map"][cid] = {
                "category": category,
                "priority": it.get("priority", "P3"),
                "osfp_score": it.get("score", 0),
                "files": it.get("files", []),
                "account": a.account_id,
                "region": a.region,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }

    Path(a.output).write_text(json.dumps(result, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()