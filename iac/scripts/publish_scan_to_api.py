#!/usr/bin/env python3
"""Publish scan/rescan results to an optional external API endpoint."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Publish pipeline result payload to API")
    parser.add_argument("--input", required=True, help="Path to JSON payload file")
    parser.add_argument("--event", required=True, help="Event name, e.g. baseline_scan/rescan")
    parser.add_argument("--api-url", required=False, default="", help="API endpoint URL")
    parser.add_argument("--api-token", required=False, default="", help="Bearer token")
    parser.add_argument("--repo", required=False, default="")
    parser.add_argument("--run-id", required=False, default="")
    parser.add_argument("--account-id", required=False, default="")
    parser.add_argument("--region", required=False, default="")
    parser.add_argument("--framework", required=False, default="")
    parser.add_argument("--max-retries", type=int, default=3)
    return parser.parse_args()


def load_json(path: Path) -> Any:
    if not path.exists():
        raise FileNotFoundError(f"input file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_api_url(raw_url: str) -> str:
    """Allow base URL secret and auto-append the ingest endpoint path."""
    url = (raw_url or "").strip()
    if not url:
        return url

    parsed = urlparse(url)
    path = (parsed.path or "").rstrip("/")
    if path in {"", "/"}:
        return urljoin(url.rstrip("/") + "/", "api/v1/pipeline-publish/events")
    if path == "/api/v1":
        return urljoin(url.rstrip("/") + "/", "pipeline-publish/events")
    return url


def post_json(url: str, token: str, body: dict[str, Any], retries: int) -> int:
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    last_error: Exception | None = None
    for attempt in range(1, retries + 1):
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "prowler-auto-remediation-pipeline",
        }
        if token:
            headers["Authorization"] = f"Bearer {token}"
        request = Request(
            url=url,
            data=data,
            method="POST",
            headers=headers,
        )
        try:
            with urlopen(request, timeout=30) as response:
                return int(response.status)
        except (HTTPError, URLError, TimeoutError) as exc:
            last_error = exc
            if attempt < retries:
                time.sleep(attempt * 2)
    raise RuntimeError(f"failed after retries: {last_error}")


def main() -> int:
    args = parse_args()
    if not args.api_url:
        print("skip publish: api url not configured")
        return 0

    payload_file = Path(args.input)
    payload = load_json(payload_file)
    envelope = {
        "meta": {
            "event": args.event,
            "repo": args.repo,
            "run_id": str(args.run_id),
            "account_id": args.account_id,
            "region": args.region,
            "framework": args.framework,
            "source_file": str(payload_file),
            "published_at_epoch": int(time.time()),
        },
        "payload": payload,
    }
    target_url = resolve_api_url(args.api_url)
    status_code = post_json(target_url, args.api_token, envelope, args.max_retries)
    print(f"published event={args.event} status={status_code} url={target_url}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"publish error: {exc}", file=sys.stderr)
        raise
