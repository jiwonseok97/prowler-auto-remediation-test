#!/usr/bin/env python3
"""Convert Prowler JSON/ASFF output into normalized findings for builders."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

CATEGORY_HINTS = {
    "iam": ["iam", "mfa", "password policy", "access key", "policy"],
    "s3": ["s3", "bucket", "public", "encryption", "logging"],
    "network-ec2-vpc": ["vpc", "security group", "ec2", "network", "flow log"],
    "cloudtrail": ["cloudtrail", "trail", "log file validation"],
    "cloudwatch": ["cloudwatch", "log group", "metric filter", "alarm"],
}

SUPPORTED = set(CATEGORY_HINTS.keys())


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def detect_category(finding: dict[str, Any]) -> str | None:
    joined = " ".join(
        [
            str(finding.get("CheckID", finding.get("GeneratorId", ""))),
            str(finding.get("CheckTitle", finding.get("Title", ""))),
            str(finding.get("Description", "")),
            str(finding.get("StatusExtended", "")),
            str(finding.get("ResourceType", finding.get("Types", ""))),
            str(finding.get("ServiceName", "")),
        ]
    )
    haystack = normalize(joined)
    for category, hints in CATEGORY_HINTS.items():
        if any(h in haystack for h in hints):
            return category
    return None


def status_of(f: dict[str, Any]) -> str:
    direct = str(f.get("Status", "")).strip().lower()
    if direct:
        return direct
    compliance = f.get("Compliance", {})
    if isinstance(compliance, dict):
        return str(compliance.get("Status", "")).strip().lower()
    return ""


def load_input(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8").lstrip("\ufeff").strip()
    if not raw:
        return []
    if raw.startswith("["):
        data = json.loads(raw)
        return [x for x in data if isinstance(x, dict)]
    if raw.startswith("{"):
        data = json.loads(raw)
        if isinstance(data, dict) and isinstance(data.get("Findings"), list):
            return [x for x in data["Findings"] if isinstance(x, dict)]
        if isinstance(data, dict):
            return [data]
    rows: list[dict[str, Any]] = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
            if isinstance(item, dict):
                rows.append(item)
        except json.JSONDecodeError:
            continue
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    src = Path(args.input)
    dst = Path(args.output)

    findings = load_input(src)
    normalized: list[dict[str, Any]] = []
    unsupported = 0

    for f in findings:
        status = status_of(f)
        if status and status not in {"fail", "failed"}:
            continue
        category = detect_category(f)
        if category not in SUPPORTED:
            unsupported += 1
            continue
        normalized.append(
            {
                "category": category,
                "status": status or "fail",
                "check_id": str(f.get("CheckID", f.get("GeneratorId", "unknown"))),
                "title": str(f.get("CheckTitle", f.get("Title", "unknown"))),
                "resource_id": str(f.get("ResourceId", f.get("ResourceType", "unknown"))),
                "detail": str(f.get("StatusExtended", f.get("Description", "")))[:500],
            }
        )

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(normalized, indent=2), encoding="utf-8")

    summary = {
        "total_input": len(findings),
        "normalized_fail": len(normalized),
        "unsupported": unsupported,
    }
    print(json.dumps(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
