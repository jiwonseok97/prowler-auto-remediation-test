#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List


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

        import_rows: List[Dict[str, Any]] = generated.get("import_map", {}).get(category, [])
        imports_by_check: Dict[str, List[Dict[str, Any]]] = {}
        for imp in import_rows:
            if not isinstance(imp, dict):
                continue
            cid = str(imp.get("check_id", ""))
            imports_by_check.setdefault(cid, []).append(
                {
                    "resource_address": imp.get("address", ""),
                    "arn": imp.get("import_id", ""),
                    "resource_type": imp.get("resource_type", ""),
                    "optional": bool(imp.get("optional", False)),
                }
            )

        top = sorted(items, key=lambda x: x.get("score", 0), reverse=True)[:5]
        result["categories"].append(
            {
                "category": category,
                "path": f"remediation/{category}",
                "checks": len(items),
                "top5": [x.get("check_id") for x in top],
                "tier_breakdown": {
                    "safe-auto": sum(1 for x in items if x.get("remediation_tier") == "safe-auto"),
                    "review-then-apply": sum(1 for x in items if x.get("remediation_tier") == "review-then-apply"),
                    "manual-runbook": sum(1 for x in items if x.get("remediation_tier") == "manual-runbook"),
                },
                "manual_required": [
                    x.get("check_id")
                    for x in items
                    if x.get("remediation_tier") == "manual-runbook" or x.get("manual_required")
                ],
                "import_map": f"remediation/{category}/import-map.txt",
            }
        )

        enriched_items: List[Dict[str, Any]] = []
        for it in items:
            cid = it.get("check_id")
            files = it.get("files", [])
            enriched = dict(it)
            enriched["resources"] = imports_by_check.get(str(cid), [])
            if files:
                enriched["tf_file"] = files[0]
            enriched_items.append(enriched)

        cat_manifest = {
            "category": category,
            "account": a.account_id,
            "region": a.region,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "items": enriched_items,
            "import_map": import_rows,
        }
        (root / category / "manifest.json").write_text(json.dumps(cat_manifest, indent=2), encoding="utf-8")

        for it in enriched_items:
            cid = it.get("check_id")
            entry = {
                "category": category,
                "remediation_tier": it.get("remediation_tier", "safe-auto"),
                "priority": it.get("priority", "P3"),
                "osfp_score": it.get("score", 0),
                "files": it.get("files", []),
                "tf_file": it.get("tf_file", ""),
                "resources": it.get("resources", []),
                "account": a.account_id,
                "region": a.region,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            if cid in result["check_map"]:
                prev = result["check_map"][cid]
                if isinstance(prev, list):
                    prev.append(entry)
                else:
                    result["check_map"][cid] = [prev, entry]
            else:
                result["check_map"][cid] = entry

    Path(a.output).write_text(json.dumps(result, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
