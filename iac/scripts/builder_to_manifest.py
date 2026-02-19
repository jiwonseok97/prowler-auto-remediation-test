#!/usr/bin/env python3
"""Compatibility entrypoint for category manifest building."""
import argparse
import subprocess
import sys


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    args = p.parse_args()

    cmd = [
        sys.executable,
        "iac/scripts/build_category_manifest.py",
        "--input",
        args.input,
        "--output",
        args.output,
        "--account-id",
        args.account_id,
        "--region",
        args.region,
    ]
    raise SystemExit(subprocess.call(cmd))


if __name__ == "__main__":
    main()
