#!/usr/bin/env python3
"""Compatibility entrypoint for remediation generation."""
import argparse
import subprocess
import sys


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output-root", required=True)
    p.add_argument("--snippet-map", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--model-id", required=True)
    args = p.parse_args()

    cmd = [
        sys.executable,
        "iac/scripts/generate_remediation_bundle.py",
        "--input",
        args.input,
        "--output-root",
        args.output_root,
        "--snippet-map",
        args.snippet_map,
        "--account-id",
        args.account_id,
        "--region",
        args.region,
        "--model-id",
        args.model_id,
    ]
    raise SystemExit(subprocess.call(cmd))


if __name__ == "__main__":
    main()
