#!/usr/bin/env python3
"""Minimal placeholder to publish scan summary to an external API."""

import json
from pathlib import Path


def main() -> None:
    payload = {"status": "placeholder", "message": "implement API publish here"}
    out = Path(__file__).resolve().parent.parent / "payload.sample.json"
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
