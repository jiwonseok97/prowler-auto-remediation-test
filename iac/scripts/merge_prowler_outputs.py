#!/usr/bin/env python3
"""Merge multiple Prowler JSON/ASFF outputs into a single findings array."""
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_rows(path: Path) -> List[Dict[str, Any]]:
    text = path.read_text(encoding="utf-8-sig").strip()
    if not text:
        return []

    try:
        obj = json.loads(text)
    except json.JSONDecodeError:
        rows: List[Dict[str, Any]] = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                parsed = json.loads(line)
                if isinstance(parsed, dict):
                    rows.append(parsed)
            except json.JSONDecodeError:
                continue
        return rows

    if isinstance(obj, dict):
        findings = obj.get("Findings", [])
        return findings if isinstance(findings, list) else []
    if isinstance(obj, list):
        return [x for x in obj if isinstance(x, dict)]
    return []


def dedupe(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        key = str(row.get("Id") or row.get("GeneratorId") or row.get("CheckID") or "")
        if not key:
            key = json.dumps(row, sort_keys=True)
        if key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--dir", required=True)
    p.add_argument("--prefix", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()

    root = Path(args.dir)
    output = Path(args.output)
    rows: List[Dict[str, Any]] = []
    for f in sorted(root.glob(f"{args.prefix}*.json*")):
        if f.resolve() == output.resolve():
            continue
        rows.extend(load_rows(f))
    rows = dedupe(rows)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    print(json.dumps({"files_merged": len(list(root.glob(f'{args.prefix}*.json*'))), "findings": len(rows)}))


if __name__ == "__main__":
    main()
