#!/usr/bin/env python3
"""Build apply manifest from remediation builder outputs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="terraform/remediation")
    parser.add_argument("--output", default="artifacts/remediation_manifest.json")
    args = parser.parse_args()

    root = Path(args.root)
    categories = []

    for d in sorted(root.iterdir() if root.exists() else []):
        if not d.is_dir():
            continue
        main_tf = d / "main.tf"
        if not main_tf.exists():
            continue
        imports_sh = d / "imports.sh"
        categories.append(
            {
                "category": d.name,
                "path": str(d).replace('\\', '/'),
                "imports_script": str(imports_sh).replace('\\', '/') if imports_sh.exists() else "",
            }
        )

    manifest = {"categories": categories}
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(json.dumps({"category_count": len(categories), "output": str(out)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
