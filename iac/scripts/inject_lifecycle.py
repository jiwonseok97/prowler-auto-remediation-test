#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Inject lifecycle block when missing")
    parser.add_argument("--target", required=True, help="Terraform file path")
    return parser.parse_args()


def inject_lifecycle(tf_text: str) -> str:
    resource_pattern = re.compile(r'resource\s+"[^"]+"\s+"[^"]+"\s*\{', re.MULTILINE)
    matches = list(resource_pattern.finditer(tf_text))
    if not matches:
        return tf_text

    result = []
    last_idx = 0

    for m in matches:
        start = m.start()
        result.append(tf_text[last_idx:start])

        block_start = start
        brace = 0
        i = m.end() - 1
        while i < len(tf_text):
            ch = tf_text[i]
            if ch == '{':
                brace += 1
            elif ch == '}':
                brace -= 1
                if brace == 0:
                    break
            i += 1
        block_end = i + 1
        block = tf_text[block_start:block_end]

        if "lifecycle" in block:
            result.append(block)
        else:
            injected = block[:-1].rstrip() + "\n\n  lifecycle {\n    ignore_changes = []\n  }\n}\n"
            result.append(injected)

        last_idx = block_end

    result.append(tf_text[last_idx:])
    return "".join(result)


def main() -> None:
    args = parse_args()
    target = Path(args.target)
    if not target.exists():
        return
    original = target.read_text(encoding="utf-8")
    updated = inject_lifecycle(original)
    if updated != original:
        target.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    main()
