#!/usr/bin/env python3
"""Nessus bridge: create scan -> launch -> poll -> export/download results."""

from __future__ import annotations

import argparse
import json
import os
import ssl
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Nessus API scan lifecycle and collect results."
    )
    parser.add_argument("--target-host", default=os.getenv("TARGET_HOST", "").strip())
    parser.add_argument("--out-dir", default="artifacts/infra-scanners/nessus")
    parser.add_argument(
        "--scan-name",
        default=f"prowler-bridge-{int(time.time())}",
        help="Nessus scan name",
    )
    parser.add_argument(
        "--template-name",
        default=os.getenv("NESSUS_TEMPLATE_NAME", "Basic Network Scan"),
        help="Template display name fallback",
    )
    parser.add_argument(
        "--template-uuid",
        default=os.getenv("NESSUS_TEMPLATE_UUID", "").strip(),
        help="Template UUID (optional; auto-discover if empty)",
    )
    parser.add_argument(
        "--folder-id",
        type=int,
        default=int(os.getenv("NESSUS_FOLDER_ID", "3")),
    )
    parser.add_argument(
        "--poll-interval",
        type=int,
        default=int(os.getenv("NESSUS_POLL_INTERVAL_SEC", "15")),
    )
    parser.add_argument(
        "--timeout-sec",
        type=int,
        default=int(os.getenv("NESSUS_TIMEOUT_SEC", "3600")),
    )
    parser.add_argument(
        "--delete-scan",
        action="store_true",
        default=os.getenv("NESSUS_DELETE_SCAN", "false").lower() == "true",
    )
    return parser.parse_args()


def build_headers() -> dict[str, str]:
    access_key = os.getenv("NESSUS_ACCESS_KEY", "").strip()
    secret_key = os.getenv("NESSUS_SECRET_KEY", "").strip()
    raw_api_key = os.getenv("NESSUS_API_KEY", "").strip()

    if access_key and secret_key:
        x_api = f"accessKey={access_key}; secretKey={secret_key}"
    elif raw_api_key:
        # Supports either:
        # 1) full "accessKey=...; secretKey=..."
        # 2) token-like value already accepted by gateway/proxy
        x_api = raw_api_key
    else:
        raise RuntimeError(
            "missing Nessus credentials: set NESSUS_API_KEY or NESSUS_ACCESS_KEY+NESSUS_SECRET_KEY"
        )

    return {"X-ApiKeys": x_api, "Content-Type": "application/json"}


def api_request(
    base_url: str,
    method: str,
    path: str,
    headers: dict[str, str],
    body: dict[str, Any] | None = None,
) -> tuple[int, Any]:
    url = f"{base_url.rstrip('/')}{path}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = Request(url=url, method=method.upper(), headers=headers, data=data)

    verify_tls = os.getenv("NESSUS_VERIFY_TLS", "false").lower() == "true"
    context = None
    if not verify_tls:
        context = ssl._create_unverified_context()  # noqa: SLF001

    try:
        with urlopen(req, timeout=60, context=context) as resp:
            raw = resp.read()
            text = raw.decode("utf-8", errors="ignore")
            if not text:
                return int(resp.status), None
            try:
                return int(resp.status), json.loads(text)
            except json.JSONDecodeError:
                return int(resp.status), text
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Nessus HTTP {exc.code} {path}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"Nessus connection error {path}: {exc}") from exc


def get_template_uuid(
    base_url: str,
    headers: dict[str, str],
    configured_uuid: str,
    template_name: str,
) -> str:
    if configured_uuid:
        return configured_uuid
    _, data = api_request(base_url, "GET", "/editor/scan/templates", headers)
    templates = (data or {}).get("templates", []) if isinstance(data, dict) else []
    if not templates:
        raise RuntimeError("Nessus template list is empty")
    for t in templates:
        if str(t.get("title", "")).strip().lower() == template_name.strip().lower():
            return str(t.get("uuid", "")).strip()
    # Fallback first template
    return str(templates[0].get("uuid", "")).strip()


def poll_scan_state(
    base_url: str,
    headers: dict[str, str],
    scan_id: int,
    poll_interval: int,
    timeout_sec: int,
) -> str:
    started = time.time()
    while True:
        _, scan_resp = api_request(base_url, "GET", f"/scans/{scan_id}", headers)
        info = (scan_resp or {}).get("info", {}) if isinstance(scan_resp, dict) else {}
        status = str(info.get("status", "unknown"))
        if status in {"completed", "canceled", "aborted", "stopped"}:
            return status
        if (time.time() - started) > timeout_sec:
            raise TimeoutError(f"Nessus scan polling timed out: scan_id={scan_id}")
        time.sleep(max(3, poll_interval))


def poll_export_ready(
    base_url: str,
    headers: dict[str, str],
    scan_id: int,
    file_id: int,
    poll_interval: int,
    timeout_sec: int,
) -> None:
    started = time.time()
    while True:
        _, status_resp = api_request(
            base_url, "GET", f"/scans/{scan_id}/export/{file_id}/status", headers
        )
        state = str((status_resp or {}).get("status", "unknown"))
        if state == "ready":
            return
        if state in {"error", "canceled"}:
            raise RuntimeError(f"Nessus export failed: file_id={file_id} state={state}")
        if (time.time() - started) > timeout_sec:
            raise TimeoutError(
                f"Nessus export polling timed out: scan_id={scan_id} file_id={file_id}"
            )
        time.sleep(max(3, poll_interval))


def parse_summary(download_json: dict[str, Any]) -> dict[str, Any]:
    vulns = download_json.get("vulnerabilities", [])
    info = download_json.get("info", {})
    return {
        "vulnerability_count": len(vulns) if isinstance(vulns, list) else 0,
        "host_count": info.get("hostcount"),
        "policy": info.get("policy"),
        "status": info.get("status"),
    }


def main() -> int:
    args = parse_args()
    if not args.target_host:
        raise RuntimeError("target host is required (--target-host or TARGET_HOST)")

    base_url = os.getenv("NESSUS_URL", "").strip()
    if not base_url:
        raise RuntimeError("missing NESSUS_URL")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    headers = build_headers()

    template_uuid = get_template_uuid(
        base_url, headers, args.template_uuid, args.template_name
    )

    create_body = {
        "uuid": template_uuid,
        "settings": {
            "name": args.scan_name,
            "folder_id": args.folder_id,
            "enabled": False,
            "text_targets": args.target_host,
        },
    }
    _, created = api_request(base_url, "POST", "/scans", headers, create_body)
    scan_id = int((created or {}).get("scan", {}).get("id", 0))
    if scan_id <= 0:
        raise RuntimeError(f"failed to create Nessus scan: {created}")

    _, launch = api_request(base_url, "POST", f"/scans/{scan_id}/launch", headers, {})
    scan_uuid = str((launch or {}).get("scan_uuid", ""))

    final_state = poll_scan_state(
        base_url, headers, scan_id, args.poll_interval, args.timeout_sec
    )

    if final_state != "completed":
        raise RuntimeError(f"Nessus scan ended with non-completed state: {final_state}")

    _, exported = api_request(
        base_url, "POST", f"/scans/{scan_id}/export", headers, {"format": "json"}
    )
    file_id = int((exported or {}).get("file", 0))
    if file_id <= 0:
        raise RuntimeError(f"failed to request Nessus export: {exported}")

    poll_export_ready(
        base_url,
        headers,
        scan_id,
        file_id,
        args.poll_interval,
        args.timeout_sec,
    )

    # Download export as raw and parse JSON.
    _, download_resp = api_request(
        base_url, "GET", f"/scans/{scan_id}/export/{file_id}/download", headers
    )
    if not isinstance(download_resp, dict):
        raise RuntimeError("unexpected Nessus download response format")

    (out_dir / "nessus_scan_result.json").write_text(
        json.dumps(download_resp, indent=2), encoding="utf-8"
    )

    summary = {
        "target_host": args.target_host,
        "scan_name": args.scan_name,
        "scan_id": scan_id,
        "scan_uuid": scan_uuid,
        "export_file_id": file_id,
        "state": final_state,
    }
    summary.update(parse_summary(download_resp))
    (out_dir / "nessus_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )

    md = [
        "## Nessus Real Scan Result",
        "",
        f"- target_host: `{summary['target_host']}`",
        f"- scan_id: `{summary['scan_id']}`",
        f"- state: `{summary['state']}`",
        f"- vulnerability_count: `{summary.get('vulnerability_count', 0)}`",
        f"- host_count: `{summary.get('host_count', 'n/a')}`",
        f"- policy: `{summary.get('policy', 'n/a')}`",
    ]
    (out_dir / "nessus_summary.md").write_text("\n".join(md) + "\n", encoding="utf-8")

    if args.delete_scan:
        api_request(base_url, "DELETE", f"/scans/{scan_id}", headers, None)

    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

