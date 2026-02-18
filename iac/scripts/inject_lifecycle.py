#!/usr/bin/env python3
"""Inject lifecycle guards into generated Terraform resources."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

RESOURCE_RE = re.compile(r'(^resource\s+"[^"]+"\s+"[^"]+"\s*\{)', re.MULTILINE)


LIFECYCLE_BLOCK = '''
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags, tags_all]
  }
'''


def inject_lifecycle(tf_text: str) -> str:
    lines = tf_text.splitlines()
    out: list[str] = []
    in_resource = False
    brace_depth = 0
    current_has_lifecycle = False

    for line in lines:
        if RESOURCE_RE.search(line):
            out.append(line)
            in_resource = True
            current_has_lifecycle = False
            brace_depth = line.count("{") - line.count("}")
            if brace_depth == 1:
                out.append(LIFECYCLE_BLOCK.rstrip("\n"))
                current_has_lifecycle = True
            continue

        out.append(line)
        if in_resource:
            brace_depth += line.count("{") - line.count("}")
            if "lifecycle {" in line:
                current_has_lifecycle = True
            if brace_depth == 1 and not current_has_lifecycle and line.strip() and not line.strip().startswith("#"):
                out.append(LIFECYCLE_BLOCK.rstrip("\n"))
                current_has_lifecycle = True
            if brace_depth <= 0:
                in_resource = False

    return "\n".join(out) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="terraform/remediation/main.tf")
    args = parser.parse_args()

    path = Path(args.target)
    tf = path.read_text(encoding="utf-8")
    updated = inject_lifecycle(tf)
    path.write_text(updated, encoding="utf-8")
    print(f"lifecycle_injected={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
