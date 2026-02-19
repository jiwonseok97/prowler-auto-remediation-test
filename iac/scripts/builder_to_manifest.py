#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

CATEGORIES = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build apply manifest from remediation terraform root")
    parser.add_argument("--root", required=True, help="terraform/remediation root path")
    parser.add_argument("--output", required=True, help="manifest output path")
    return parser.parse_args()


def parse_import_map(path: Path) -> List[Dict[str, str]]:
    entries: List[Dict[str, str]] = []
    if not path.exists():
        return entries
    for line in path.read_text(encoding="utf-8").splitlines():
        row = line.strip()
        if not row or row.startswith("#"):
            continue
        parts = row.split("|")
        parts = parts + [""] * (5 - len(parts))
        entries.append(
            {
                "resource_address": parts[0],
                "import_id": parts[1],
                "arn": parts[2],
                "check_id": parts[3],
                "optional_create_if_missing": parts[4] if parts[4] else "false",
            }
        )
    return entries


def build_manifest(root: Path) -> Dict[str, Any]:
    manifest: Dict[str, Any] = {
        "baseline_fail_count": 0,
        "categories": [],
        "checks": {},
    }

    base_manifest_path = root / "manifest.json"
    if base_manifest_path.exists():
        try:
            existing = json.loads(base_manifest_path.read_text(encoding="utf-8"))
            manifest["baseline_fail_count"] = int(existing.get("baseline_fail_count", 0))
            if isinstance(existing.get("checks"), dict):
                manifest["checks"].update(existing["checks"])
        except Exception:
            pass

    for category in CATEGORIES:
        category_dir = root / category
        main_tf = category_dir / "main.tf"
        if not main_tf.exists() or not main_tf.read_text(encoding="utf-8").strip():
            continue

        entry = {
            "category": category,
            "path": str(category_dir).replace("\\", "/"),
            "import_map": str((category_dir / "import-map.txt")).replace("\\", "/"),
        }
        manifest["categories"].append(entry)

        import_entries = parse_import_map(category_dir / "import-map.txt")
        for imp in import_entries:
            check_id = imp.get("check_id", "")
            if not check_id:
                continue
            manifest["checks"][check_id] = {
                "tf_file": str((category_dir / f"{check_id}.tf")).replace("\\", "/"),
                "resource_address": imp.get("resource_address", ""),
                "arn": imp.get("arn", ""),
                "import_id": imp.get("import_id", ""),
                "optional_create_if_missing": imp.get("optional_create_if_missing", "false"),
                "category": category,
            }

    return manifest


def main() -> None:
    args = parse_args()
    root = Path(args.root)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    manifest = build_manifest(root)
    output.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"output": str(output), "categories": len(manifest["categories"]), "checks": len(manifest["checks"])}))


if __name__ == "__main__":
    main()
