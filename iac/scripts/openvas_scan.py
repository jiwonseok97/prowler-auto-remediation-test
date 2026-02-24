#!/usr/bin/env python3
"""OpenVAS GMP (Greenbone Management Protocol) scan runner.

환경 변수 설정:
  OPENVAS_HOST      OpenVAS GVM 서버 호스트 (기본: localhost)
  OPENVAS_PORT      GVM 소켓 포트 (기본: 9390)
  OPENVAS_USERNAME  GVM 로그인 사용자 (기본: admin)
  OPENVAS_PASSWORD  GVM 로그인 비밀번호 (필수)
  OPENVAS_TARGET    스캔 대상 IP/FQDN (필수)
  OPENVAS_SCAN_NAME 스캔 이름 (기본: Auto Pipeline Scan)
  OPENVAS_OUT_DIR   결과 저장 디렉터리 (기본: artifacts/openvas)

GitHub Actions 시크릿 매핑:
  OPENVAS_PASSWORD → secrets.OPENVAS_PASSWORD
  OPENVAS_TARGET   → secrets.OPENVAS_TARGET (또는 동적 EC2 IP)
"""

from __future__ import annotations

import json
import os
import sys
import time
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path


def _env(key: str, default: str = "") -> str:
    return os.getenv(key, default).strip()


HOST     = _env("OPENVAS_HOST", "localhost")
PORT     = int(_env("OPENVAS_PORT", "9390"))
USERNAME = _env("OPENVAS_USERNAME", "admin")
PASSWORD = _env("OPENVAS_PASSWORD")
TARGET   = _env("OPENVAS_TARGET")
SCAN_NAME = _env("OPENVAS_SCAN_NAME", "Auto Pipeline Scan")
OUT_DIR  = Path(_env("OPENVAS_OUT_DIR", "artifacts/openvas"))

# Greenbone Full and Fast 스캔 설정 UUID (표준 GVM UUID)
SCAN_CONFIG_UUID = "daba56c8-73ec-11df-a475-002264764cea"  # Full and fast
SCANNER_UUID     = "08b69003-5fc2-4037-a479-93b440211c73"  # OpenVAS Default Scanner


def gmp_connect():
    """gvm-tools의 GMP 클라이언트를 반환합니다."""
    try:
        from gvm.connections import TLSConnection
        from gvm.protocols.gmp import Gmp
        from gvm.transforms import EtreeTransform
    except ImportError:
        print("ERROR: gvm-tools not installed. Run: pip install gvm-tools", file=sys.stderr)
        sys.exit(1)

    conn = TLSConnection(hostname=HOST, port=PORT)
    return Gmp(connection=conn, transform=EtreeTransform())


def run_scan() -> dict:
    """스캔 실행 → 결과 딕셔너리 반환."""
    if not PASSWORD:
        raise ValueError("OPENVAS_PASSWORD 환경 변수가 설정되지 않았습니다.")
    if not TARGET:
        raise ValueError("OPENVAS_TARGET 환경 변수가 설정되지 않았습니다.")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    gmp = gmp_connect()

    with gmp:
        # 인증
        gmp.authenticate(USERNAME, PASSWORD)
        print(f"[OpenVAS] 인증 성공: {USERNAME}@{HOST}:{PORT}")

        # 스캔 대상 생성
        target_name = f"{SCAN_NAME}-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}"
        res = gmp.create_target(name=target_name, hosts=[TARGET], port_list_id="33d0cd82-57c6-11e1-8ed1-406186ea4fc5")
        target_id = res.get("id")
        print(f"[OpenVAS] 스캔 대상 생성: {target_id} ({TARGET})")

        # 스캔 태스크 생성
        task_res = gmp.create_task(
            name=target_name,
            config_id=SCAN_CONFIG_UUID,
            target_id=target_id,
            scanner_id=SCANNER_UUID,
        )
        task_id = task_res.get("id")
        print(f"[OpenVAS] 스캔 태스크 생성: {task_id}")

        # 스캔 시작
        gmp.start_task(task_id)
        print(f"[OpenVAS] 스캔 시작됨")

        # 완료 대기 (최대 60분)
        timeout = int(_env("OPENVAS_TIMEOUT_SEC", "3600"))
        poll_interval = 30
        elapsed = 0
        report_id = None
        while elapsed < timeout:
            time.sleep(poll_interval)
            elapsed += poll_interval
            task = gmp.get_task(task_id)
            status = task.find(".//status")
            progress = task.find(".//progress")
            st = status.text if status is not None else "unknown"
            prog = progress.text if progress is not None else "0"
            print(f"[OpenVAS] 진행: {prog}% ({st}) elapsed={elapsed}s")
            if st in ("Done", "Stopped"):
                last_report = task.find(".//last_report/report")
                if last_report is not None:
                    report_id = last_report.get("id")
                break

        if not report_id:
            raise RuntimeError(f"스캔 타임아웃 또는 실패 (elapsed={elapsed}s)")

        # 결과 가져오기
        print(f"[OpenVAS] 보고서 다운로드: {report_id}")
        report_xml = gmp.get_report(
            report_id,
            report_format_id="a994b278-1f62-11e1-96ac-406186ea4fc5",  # XML
            ignore_pagination=True,
            details=True,
        )

        # XML 저장
        xml_path = OUT_DIR / "openvas-report.xml"
        ET.ElementTree(report_xml).write(str(xml_path), encoding="unicode")
        print(f"[OpenVAS] XML 저장: {xml_path}")

        # 결과 파싱
        results = []
        for r in report_xml.findall(".//result"):
            sev_el = r.find("severity")
            severity = float(sev_el.text) if sev_el is not None and sev_el.text else 0.0
            results.append({
                "name":        (r.find("name") or r).text or "",
                "host":        getattr(r.find("host"), "text", "") or "",
                "port":        getattr(r.find("port"), "text", "") or "",
                "severity":    severity,
                "cvss":        _cvss_label(severity),
                "cve":         [ref.get("id","") for ref in r.findall(".//ref[@type='cve']")],
                "description": (r.find("description") or r).text or "",
                "nvt_oid":     (r.find(".//nvt") or r).get("oid",""),
            })

        # CVSS 기준 정렬
        results.sort(key=lambda x: -x["severity"])

        summary = {
            "scan_target": TARGET,
            "scan_name":   SCAN_NAME,
            "report_id":   report_id,
            "scan_date":   datetime.now(timezone.utc).isoformat(),
            "total":       len(results),
            "critical":    sum(1 for r in results if r["severity"] >= 9.0),
            "high":        sum(1 for r in results if 7.0 <= r["severity"] < 9.0),
            "medium":      sum(1 for r in results if 4.0 <= r["severity"] < 7.0),
            "low":         sum(1 for r in results if 0.0 < r["severity"] < 4.0),
            "info":        sum(1 for r in results if r["severity"] == 0.0),
            "results":     results,
        }

        # JSON 저장
        json_path = OUT_DIR / "openvas-report.json"
        json_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"[OpenVAS] JSON 저장: {json_path}")

        # Markdown 요약
        _write_summary(summary)

        return summary


def _cvss_label(score: float) -> str:
    if score >= 9.0: return "CRITICAL"
    if score >= 7.0: return "HIGH"
    if score >= 4.0: return "MEDIUM"
    if score >  0.0: return "LOW"
    return "INFO"


def _write_summary(s: dict) -> None:
    cves_found = sorted({cve for r in s["results"] for cve in r["cve"] if cve})

    md  = f"## OpenVAS 스캔 결과 요약\n\n"
    md += f"- **스캔 대상:** `{s['scan_target']}`\n"
    md += f"- **스캔 일시:** {s['scan_date']}\n"
    md += f"- **보고서 ID:** `{s['report_id']}`\n\n"
    md += f"### 취약점 심각도 분류\n\n"
    md += f"| 등급 | 건수 |\n|---|---:|\n"
    md += f"| 🔴 CRITICAL (CVSS ≥ 9.0) | {s['critical']} |\n"
    md += f"| 🟠 HIGH (7.0–8.9) | {s['high']} |\n"
    md += f"| 🟡 MEDIUM (4.0–6.9) | {s['medium']} |\n"
    md += f"| 🟢 LOW (0.1–3.9) | {s['low']} |\n"
    md += f"| ℹ️ INFO | {s['info']} |\n"
    md += f"| **합계** | **{s['total']}** |\n\n"

    if cves_found:
        md += f"### 발견된 CVE ({len(cves_found)}건)\n\n"
        md += ", ".join(f"`{c}`" for c in cves_found[:30])
        if len(cves_found) > 30:
            md += f" ... 외 {len(cves_found)-30}건"
        md += "\n\n"

    if s["results"]:
        md += "### 상위 취약점 (CVSS 기준)\n\n"
        md += "| CVSS | 등급 | 취약점명 | 호스트 | 포트 |\n|---:|---|---|---|---|\n"
        for r in s["results"][:15]:
            md += f"| {r['severity']:.1f} | {r['cvss']} | {r['name'][:50]} | `{r['host']}` | `{r['port']}` |\n"

    (OUT_DIR / "openvas-summary.md").write_text(md, encoding="utf-8")
    print(md)


if __name__ == "__main__":
    try:
        run_scan()
    except Exception as exc:
        print(f"[OpenVAS] ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
