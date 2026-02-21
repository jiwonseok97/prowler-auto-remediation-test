#!/usr/bin/env python3
"""Build infra scanner bridge readiness report from environment variables."""

from __future__ import annotations

import json
import os
from pathlib import Path


TOOLS = [
    ("Nessus", ["NESSUS_URL", "NESSUS_API_KEY"], "NESSUS_URL"),
    ("Qualys", ["QUALYS_API_URL", "QUALYS_USERNAME", "QUALYS_PASSWORD"], "QUALYS_API_URL"),
    ("InsightVM", ["INSIGHTVM_URL", "INSIGHTVM_API_KEY"], "INSIGHTVM_URL"),
    ("OpenVAS", ["OPENVAS_URL", "OPENVAS_USERNAME", "OPENVAS_PASSWORD"], "OPENVAS_URL"),
]


def main() -> None:
    out_dir = Path(os.getenv("INFRA_SCANNER_OUT_DIR", "artifacts/infra-scanners"))
    out_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    ready_urls = []
    for tool, keys, url_key in TOOLS:
        missing = [k for k in keys if not os.getenv(k)]
        if missing:
            rows.append(
                {
                    "tool": tool,
                    "status": "later",
                    "detail": f"missing secrets: {', '.join(missing)}",
                    "url_env": url_key,
                    "url": os.getenv(url_key, ""),
                }
            )
        else:
            url = os.getenv(url_key, "")
            rows.append(
                {
                    "tool": tool,
                    "status": "ready",
                    "detail": "API bridge prerequisites satisfied",
                    "url_env": url_key,
                    "url": url,
                }
            )
            if url:
                ready_urls.append({"tool": tool, "url": url})

    out = {
        "target_host": os.getenv("TARGET_HOST", ""),
        "tools": rows,
        "ready_urls": ready_urls,
    }
    (out_dir / "bridge-readiness.json").write_text(json.dumps(out, indent=2), encoding="utf-8")

    lines = [
        "## Infra Scanner Bridge Readiness",
        "",
        f"- target_host: `{out['target_host'] or 'not provided'}`",
        "",
        "| Tool | Status | Detail | URL |",
        "|---|---|---|---|",
    ]
    for row in rows:
        url = row.get("url", "")
        lines.append(
            f"| `{row['tool']}` | `{row['status']}` | {row['detail']} | `{url or 'n/a'}` |"
        )
    (out_dir / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    # machine-readable list for workflow HTTP connectivity checks
    (out_dir / "ready-urls.json").write_text(json.dumps(ready_urls, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
