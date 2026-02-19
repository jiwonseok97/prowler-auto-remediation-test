#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--baseline", required=True)
    p.add_argument("--post", required=True)
    p.add_argument("--output", required=True)
    a = p.parse_args()

    baseline_doc = json.loads(Path(a.baseline).read_text(encoding="utf-8"))
    post_rows = json.loads(Path(a.post).read_text(encoding="utf-8"))

    baseline_fail = int(baseline_doc.get("baseline_fail_count", 0))
    post_fail = len([x for x in post_rows if x.get("status") == "FAIL"])
    reduced = baseline_fail - post_fail

    remaining = [x.get("check_id", "unknown") for x in post_rows if x.get("status") == "FAIL"]
    out = {
        "baseline_fail": baseline_fail,
        "post_fail": post_fail,
        "reduced": reduced,
        "remaining_fail_check_ids": sorted(set(remaining)),
    }
    Path(a.output).write_text(json.dumps(out, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()