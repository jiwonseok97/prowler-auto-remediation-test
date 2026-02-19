#!/usr/bin/env python3
"""Compatibility entrypoint for finding normalization."""
import argparse
import json
from pathlib import Path

from normalize_findings import normalize


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--account-id", default="")
    p.add_argument("--region", default="")
    args = p.parse_args()

    raw = json.loads(Path(args.input).read_text(encoding="utf-8-sig"))
    rows = raw.get("Findings", []) if isinstance(raw, dict) else raw
    if not isinstance(rows, list):
        rows = []

    normalized = normalize(rows, args.account_id, args.region)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(normalized, indent=2), encoding="utf-8")
    print(json.dumps({"total": len(rows), "normalized_fail": len(normalized)}))


if __name__ == "__main__":
    main()
