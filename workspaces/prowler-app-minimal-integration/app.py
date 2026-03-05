#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import csv
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

from fastapi import FastAPI, Header, HTTPException, Query, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
EVENTS_FILE = DATA_DIR / "events.jsonl"
DATA_DIR.mkdir(parents=True, exist_ok=True)
EVENTS_FILE.touch(exist_ok=True)
DEFAULT_MANIFEST_PATH = BASE_DIR.parent.parent / "remediation" / "manifest.json"
MANIFEST_PATH = Path(os.getenv("REMEDIATION_MANIFEST_PATH", str(DEFAULT_MANIFEST_PATH))).expanduser()
DEFAULT_RESCAN_DIR = BASE_DIR.parent.parent / "tmp"
RESCAN_ARTIFACTS_DIR = Path(os.getenv("RESCAN_ARTIFACTS_DIR", str(DEFAULT_RESCAN_DIR))).expanduser()
RESCAN_POST_NORMALIZED = os.getenv("RESCAN_POST_NORMALIZED", "").strip()
RESCAN_CIS_CSV = os.getenv("RESCAN_CIS_CSV", "").strip()
RESCAN_ISMS_ASFF = os.getenv("RESCAN_ISMS_ASFF", "").strip()

APP_TOKEN = os.getenv("APP_API_TOKEN", "").strip()
APP_TITLE = os.getenv("APP_TITLE", "Prowler Auto-Remediation Dashboard")
APP_LANG = os.getenv("APP_LANG", "ko").strip().lower()
GH_TOKEN = os.getenv("GH_TOKEN", "").strip()
GH_REPO = os.getenv("GH_REPO", "").strip()
GH_SCAN_WORKFLOW = os.getenv("GH_SCAN_WORKFLOW", "scan-cis.yml").strip()
GH_REF = os.getenv("GH_REF", "main").strip()

lock = threading.Lock()
app = FastAPI(title=APP_TITLE)
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))
app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")

_manifest_cache: dict[str, Any] | None = None
_manifest_mtime: float | None = None
_artifact_cache: dict[str, tuple[float, Any]] = {}

PRIORITY_RANK = {"P1": 3, "P2": 2, "P3": 1}
SEVERITY_RANK = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1, "INFO": 0}
TIER_RANK = {"manual-runbook": 3, "review-then-apply": 2, "safe-auto": 1}

LABELS = {
    "ko": {
        "app_title": "Prowler 자동 개선 대시보드",
        "status_loading": "로딩 중",
        "status_refreshing": "갱신 중",
        "status_ok": "정상",
        "status_error": "오류",
        "api_token_enabled": "API 토큰 활성",
        "api_token_disabled": "API 토큰 미설정",
        "latest_run": "최신 스캔 실행",
        "latest_run_none": "최신 스캔 실행: 없음",
        "latest_run_unavailable": "최신 스캔 실행: 사용 불가",
        "latest_run_error": "최신 스캔 실행: 오류",
        "launch_scan": "스캔 시작",
        "launching": "시작 중...",
        "launch_failed": "시작 실패",
        "scan_queued": "스캔 대기열에 추가됨",
        "filters": "필터",
        "kpi_total": "전체 이벤트",
        "kpi_baseline": "최신 베이스라인 FAIL",
        "kpi_post": "최신 리스캔 FAIL",
        "kpi_reduced": "최신 FAIL 감소",
        "event_breakdown": "이벤트 유형 분포",
        "fail_trend": "FAIL 추이",
        "top5_title": "최신 리스캔 Top 5 위험",
        "top5_empty": "리스캔 Top 5 데이터가 없습니다.",
        "rescan_insights": "리스캔 인사이트",
        "triage_title": "즉시 조치 vs 단기 조치",
        "quick_wins_title": "고영향/저난이도(Quick Wins)",
        "category_title": "취약 카테고리 Top 3",
        "cis_isms_title": "CIS 1.4 & ISMS-P 공통 고영향",
        "auto_manual_title": "자동 vs 수동",
        "roadmap_title": "30% 감소 로드맵",
        "report_title": "5줄 요약(비기술용)",
        "event_list": "이벤트 목록",
    },
    "en": {
        "app_title": "Prowler Auto-Remediation Dashboard",
        "status_loading": "Loading",
        "status_refreshing": "Refreshing",
        "status_ok": "OK",
        "status_error": "Error",
        "api_token_enabled": "API token enabled",
        "api_token_disabled": "API token not set",
        "latest_run": "Latest scan run",
        "latest_run_none": "Latest scan run: none",
        "latest_run_unavailable": "Latest scan run: unavailable",
        "latest_run_error": "Latest scan run: error",
        "launch_scan": "Launch Scan",
        "launching": "launching...",
        "launch_failed": "launch failed",
        "scan_queued": "scan queued",
        "filters": "Filters",
        "kpi_total": "Total Events",
        "kpi_baseline": "Latest Baseline FAIL",
        "kpi_post": "Latest Post-Apply FAIL",
        "kpi_reduced": "Latest FAIL Reduction",
        "event_breakdown": "Event Type Breakdown",
        "severity_breakdown": "Latest Rescan Severity Breakdown",
        "fail_trend": "FAIL Trend",
        "severity_trend": "Severity Trend",
        "kpi_note": "Dashboard counts are total findings; latest rescan FAIL shown below.",
        "top5_title": "Top 5 Risks (Latest Rescan)",
        "top5_empty": "No rescan top 5 data yet.",
        "rescan_insights": "Rescan Insights",
        "triage_title": "Immediate vs Short-Term",
        "quick_wins_title": "Quick Wins (High Impact / Low Effort)",
        "category_title": "Top 3 Categories",
        "cis_isms_title": "CIS 1.4 & ISMS-P Common High Impact",
        "auto_manual_title": "Auto vs Manual",
        "roadmap_title": "Roadmap (30% Reduction)",
        "report_title": "5-Line Executive Summary",
        "event_list": "Event List",
    },
}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_bearer(auth: str | None) -> str:
    if not auth:
        return ""
    if not auth.lower().startswith("bearer "):
        return ""
    return auth.split(" ", 1)[1].strip()


def get_labels(lang: str) -> dict[str, str]:
    lang = (lang or "").strip().lower()
    if lang in LABELS:
        return LABELS[lang]
    return LABELS["en"]


def compute_metrics(event_name: str, payload: dict[str, Any]) -> dict[str, Any]:
    baseline_fail = payload.get("baseline_fail_count")
    if baseline_fail is None:
        baseline_fail = payload.get("baseline_fail")
    post_fail = payload.get("post_fail")
    reduced = payload.get("reduced")
    findings = payload.get("findings")
    return {
        "baseline_fail": int(baseline_fail) if isinstance(baseline_fail, int) else None,
        "post_fail": int(post_fail) if isinstance(post_fail, int) else None,
        "reduced": int(reduced) if isinstance(reduced, int) else None,
        "findings": int(findings) if isinstance(findings, int) else None,
        "event_name": event_name,
    }


def read_events() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with lock:
        for line in EVENTS_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    rows.sort(key=lambda x: x.get("received_at", ""), reverse=True)
    return rows


def write_event(doc: dict[str, Any]) -> None:
    line = json.dumps(doc, ensure_ascii=False)
    with lock:
        with EVENTS_FILE.open("a", encoding="utf-8") as f:
            f.write(line + "\n")


def gh_enabled() -> bool:
    return bool(GH_TOKEN and GH_REPO and GH_SCAN_WORKFLOW)


def load_manifest() -> dict[str, Any] | None:
    global _manifest_cache, _manifest_mtime
    if not MANIFEST_PATH.exists():
        return None
    try:
        mtime = MANIFEST_PATH.stat().st_mtime
        if _manifest_cache is None or _manifest_mtime != mtime:
            _manifest_cache = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
            _manifest_mtime = mtime
        return _manifest_cache
    except Exception:
        return None


def priority_rank(priority: str | None) -> int:
    return PRIORITY_RANK.get(str(priority).upper(), 0) if priority else 0


def _coerce_entries(entry: Any) -> list[dict[str, Any]]:
    if isinstance(entry, dict):
        return [entry]
    if isinstance(entry, list):
        return [e for e in entry if isinstance(e, dict)]
    return []


def _best_entry(entries: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not entries:
        return None

    def key(e: dict[str, Any]) -> tuple[int, float]:
        score = e.get("osfp_score")
        if score is None:
            score = e.get("score")
        return (priority_rank(e.get("priority")), float(score or 0))

    return max(entries, key=key)


def severity_rank(label: str | None) -> int:
    return SEVERITY_RANK.get(str(label).upper(), 0) if label else 0


def compute_risk_score(severity: str | None, exposure: int, priority: str | None = None) -> int:
    sev_score = severity_rank(severity) * 100
    exposure_score = min(max(exposure, 0), 99)
    priority_score = priority_rank(priority) * 10
    return int(sev_score + exposure_score + priority_score)


def find_latest_file(pattern: str, base_dir: Path) -> Path | None:
    if not base_dir.exists():
        return None
    candidates = list(base_dir.rglob(pattern))
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def load_json_cached(path: Path) -> Any | None:
    try:
        mtime = path.stat().st_mtime
        cached = _artifact_cache.get(str(path))
        if cached and cached[0] == mtime:
            return cached[1]
        data = json.loads(path.read_text(encoding="utf-8"))
        _artifact_cache[str(path)] = (mtime, data)
        return data
    except Exception:
        return None


def load_latest_post_normalized() -> tuple[Path | None, list[dict[str, Any]]]:
    path = Path(RESCAN_POST_NORMALIZED) if RESCAN_POST_NORMALIZED else find_latest_file("post_normalized.json", RESCAN_ARTIFACTS_DIR)
    if not path:
        return None, []
    data = load_json_cached(path)
    return path, data if isinstance(data, list) else []


def load_latest_cis_csv() -> Path | None:
    return Path(RESCAN_CIS_CSV) if RESCAN_CIS_CSV else find_latest_file("post_cis_cis_1.4_aws.csv", RESCAN_ARTIFACTS_DIR)


def load_latest_isms_asff() -> Path | None:
    return Path(RESCAN_ISMS_ASFF) if RESCAN_ISMS_ASFF else find_latest_file("post_isms_p.asff.json", RESCAN_ARTIFACTS_DIR)



def load_latest_rescan_summary() -> tuple[Path | None, dict[str, Any]]:
    path = find_latest_file("rescan_summary.json", RESCAN_ARTIFACTS_DIR)
    if not path:
        return None, {}
    data = load_json_cached(path)
    return path, data if isinstance(data, dict) else {}


def parse_cis_fail_ids(path: Path | None) -> set[str]:
    if not path or not path.exists():
        return set()
    fail_ids: set[str] = set()
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            status = str(row.get("STATUS", "")).upper()
            if status != "FAIL":
                continue
            check_id = str(row.get("CHECKID", "")).strip()
            if check_id:
                if not check_id.startswith("prowler-"):
                    check_id = f"prowler-{check_id}"
                fail_ids.add(check_id)
    return fail_ids


def parse_isms_fail_ids(path: Path | None) -> set[str]:
    if not path or not path.exists():
        return set()
    data = load_json_cached(path)
    if not isinstance(data, list):
        return set()
    fail_ids: set[str] = set()
    for entry in data:
        if not isinstance(entry, dict):
            continue
        compliance = entry.get("Compliance") or {}
        status = str(compliance.get("Status", "")).upper()
        if status not in {"FAILED", "FAIL"}:
            continue
        check_id = str(entry.get("GeneratorId", "")).strip()
        if check_id:
            if not check_id.startswith("prowler-"):
                check_id = f"prowler-{check_id}"
            fail_ids.add(check_id)
    return fail_ids


def build_check_stats(findings: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    stats: dict[str, dict[str, Any]] = {}
    for row in findings:
        if not isinstance(row, dict):
            continue
        status = str(row.get("status", row.get("Status", ""))).upper()
        if status and status != "FAIL":
            continue
        check_id = str(row.get("check_id") or row.get("GeneratorId") or "").strip()
        if not check_id:
            continue
        stats.setdefault(
            check_id,
            {
                "check_id": check_id,
                "exposure": 0,
                "severity": None,
                "remediation_tier": None,
                "manual_required": False,
                "service": row.get("service"),
                "example_resource": row.get("resource_arn") or row.get("resourceArn"),
            },
        )
        item = stats[check_id]
        item["exposure"] += 1
        sev = row.get("severity") or (row.get("Severity", {}) or {}).get("Label")
        if severity_rank(sev) > severity_rank(item["severity"]):
            item["severity"] = str(sev).upper() if sev else item["severity"]
        tier = row.get("remediation_tier") or row.get("remediationTier")
        if tier and TIER_RANK.get(tier, 0) > TIER_RANK.get(item["remediation_tier"], 0):
            item["remediation_tier"] = tier
        if row.get("manual_required") is True:
            item["manual_required"] = True
    return stats



def build_severity_counts(findings: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0, "INFO": 0}
    for row in findings:
        if not isinstance(row, dict):
            continue
        status = str(row.get("status", row.get("Status", ""))).upper()
        if status and status != "FAIL":
            continue
        sev = row.get("severity") or (row.get("Severity", {}) or {}).get("Label")
        sev = str(sev).upper() if sev else "INFO"
        if sev not in counts:
            sev = "INFO"
        counts[sev] += 1
    return counts


def build_severity_timeline(limit: int = 20) -> list[dict[str, Any]]:
    if not RESCAN_ARTIFACTS_DIR.exists():
        return []
    files = list(RESCAN_ARTIFACTS_DIR.rglob("post_normalized.json"))
    if not files:
        return []
    files = sorted(files, key=lambda p: p.stat().st_mtime)[-limit:]
    timeline: list[dict[str, Any]] = []
    for path in files:
        data = load_json_cached(path)
        if not isinstance(data, list):
            continue
        counts = build_severity_counts(data)
        ts = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        timeline.append({"timestamp": ts, "label": path.parent.name, "counts": counts})
    return timeline


def build_category_patterns(stats: dict[str, dict[str, Any]], manifest: dict[str, Any] | None, top: int = 3) -> list[dict[str, Any]]:
    check_map = manifest.get("check_map", {}) if isinstance(manifest, dict) else {}
    by_category: dict[str, dict[str, Any]] = {}
    for check_id, item in stats.items():
        entry = _best_entry(_coerce_entries(check_map.get(check_id)))
        category = entry.get("category") if entry else None
        if not category:
            category = item.get("service") or check_id.split("_", 1)[0].replace("prowler-", "")
        bucket = by_category.setdefault(category, {"category": category, "count": 0, "checks": {}})
        bucket["count"] += int(item.get("exposure", 0))
        bucket["checks"][check_id] = bucket["checks"].get(check_id, 0) + int(item.get("exposure", 0))
    ranked = sorted(by_category.values(), key=lambda x: x["count"], reverse=True)[:top]
    out: list[dict[str, Any]] = []
    for cat in ranked:
        checks = sorted(cat["checks"].items(), key=lambda x: x[1], reverse=True)[:3]
        out.append(
            {
                "category": cat["category"],
                "count": cat["count"],
                "top_checks": [{"check_id": cid, "count": cnt, "pattern": cid.replace("prowler-", "")} for cid, cnt in checks],
            }
        )
    return out


def build_triage(stats: dict[str, dict[str, Any]], manifest: dict[str, Any] | None) -> dict[str, list[dict[str, Any]]]:
    check_map = manifest.get("check_map", {}) if isinstance(manifest, dict) else {}
    immediate: list[dict[str, Any]] = []
    short_term: list[dict[str, Any]] = []
    for check_id, item in stats.items():
        entry = _best_entry(_coerce_entries(check_map.get(check_id)))
        priority = entry.get("priority") if entry else None
        severity = item.get("severity")
        risk = compute_risk_score(severity, int(item.get("exposure", 0)), priority)
        payload = {
            "check_id": check_id,
            "severity": severity,
            "priority": priority,
            "exposure": item.get("exposure"),
            "risk_score": risk,
        }
        if severity in {"CRITICAL", "HIGH"} or priority == "P1":
            immediate.append(payload)
        else:
            short_term.append(payload)
    immediate.sort(key=lambda x: x["risk_score"], reverse=True)
    short_term.sort(key=lambda x: x["risk_score"], reverse=True)
    return {"immediate": immediate, "short_term": short_term}


def build_quick_wins(stats: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    picks: list[dict[str, Any]] = []
    for check_id, item in stats.items():
        if item.get("severity") in {"CRITICAL", "HIGH"} and item.get("remediation_tier") == "safe-auto":
            picks.append(
                {
                    "check_id": check_id,
                    "severity": item.get("severity"),
                    "exposure": item.get("exposure"),
                    "remediation_tier": item.get("remediation_tier"),
                }
            )
    return sorted(picks, key=lambda x: x.get("exposure", 0), reverse=True)


def intersect_cis_isms(cis_fail_ids: set[str], isms_fail_ids: set[str], stats: dict[str, dict[str, Any]], top: int = 10) -> list[dict[str, Any]]:
    common = cis_fail_ids.intersection(isms_fail_ids)
    items = []
    for check_id in common:
        item = stats.get(check_id, {})
        items.append(
            {
                "check_id": check_id,
                "severity": item.get("severity"),
                "exposure": item.get("exposure", 0),
            }
        )
    items.sort(key=lambda x: (severity_rank(x.get("severity")), x.get("exposure", 0)), reverse=True)
    return items[:top]


def split_auto_manual(stats: dict[str, dict[str, Any]], manifest: dict[str, Any] | None) -> dict[str, Any]:
    check_map = manifest.get("check_map", {}) if isinstance(manifest, dict) else {}
    auto: list[str] = []
    manual: list[str] = []
    for check_id, item in stats.items():
        entry = _best_entry(_coerce_entries(check_map.get(check_id)))
        tier = item.get("remediation_tier") or (entry.get("remediation_tier") if entry else None)
        if tier == "safe-auto":
            auto.append(check_id)
        else:
            manual.append(check_id)
    return {"terraform_auto": sorted(set(auto)), "manual": sorted(set(manual))}


def build_rescan_insights() -> dict[str, Any]:
    manifest = load_manifest()
    post_path, findings = load_latest_post_normalized()
    stats = build_check_stats(findings)

    top5 = []
    check_map = manifest.get("check_map", {}) if isinstance(manifest, dict) else {}
    for check_id, item in stats.items():
        entry = _best_entry(_coerce_entries(check_map.get(check_id)))
        priority = entry.get("priority") if entry else None
        score = compute_risk_score(item.get("severity"), int(item.get("exposure", 0)), priority)
        top5.append(
            {
                "check_id": check_id,
                "severity": item.get("severity"),
                "exposure": item.get("exposure"),
                "risk_score": score,
                "priority": priority,
                "osfp_score": entry.get("osfp_score") if entry else None,
                "remediation_tier": item.get("remediation_tier") or (entry.get("remediation_tier") if entry else None),
                "category": entry.get("category") if entry else None,
            }
        )
    top5.sort(key=lambda x: x["risk_score"], reverse=True)
    top5 = top5[:5]

    triage = build_triage(stats, manifest)
    quick_wins = build_quick_wins(stats)
    categories = build_category_patterns(stats, manifest, top=3)
    cis_fail_ids = parse_cis_fail_ids(load_latest_cis_csv())
    isms_fail_ids = parse_isms_fail_ids(load_latest_isms_asff())
    common = intersect_cis_isms(cis_fail_ids, isms_fail_ids, stats, top=5)
    auto_manual = split_auto_manual(stats, manifest)

    total_exposure = sum(item.get("exposure", 0) for item in stats.values())
    quick_exposure = sum(item.get("exposure", 0) for item in quick_wins)
    roadmap = {
        "target_reduction": "30%",
        "week_1": {
            "focus": "High impact + safe-auto quick wins",
            "estimated_reduction": f"{min(quick_exposure, total_exposure):d}/{total_exposure} findings",
            "items": [q["check_id"] for q in quick_wins[:5]],
        },
        "week_2": {
            "focus": "Remaining high severity + top exposure checks",
            "items": [i["check_id"] for i in triage["immediate"][:5]],
        },
        "month_1": {
            "focus": "Manual-runbook items and policy/process changes",
            "items": [i["check_id"] for i in triage["short_term"][:5]],
        },
    }

    summary_lines = [
        f"이번 최신 재스캔 기준 실패 항목은 {len(stats)}개 체크에서 발생했습니다.",
        f"가장 위험한 Top 5는 {', '.join([x['check_id'] for x in top5])} 입니다.",
        f"즉시 조치 대상은 {len(triage['immediate'])}개 체크, 단기 조치 대상은 {len(triage['short_term'])}개 체크입니다.",
        f"수정 난이도 낮은 고위험 항목(quick wins)은 {len(quick_wins)}개 체크입니다.",
        "CIS 1.4와 ISMS-P 공통 위반 중 영향도가 큰 항목을 별도로 추렸습니다.",
    ]

    return {
        "generated_at": utc_now_iso(),
        "rescan_post_normalized": str(post_path) if post_path else None,
        "total_checks": len(stats),
        "total_findings": total_exposure,
        "severity_counts": build_severity_counts(findings),
        "top5_risks": top5,
        "triage": triage,
        "quick_wins": quick_wins[:10],
        "categories_top3": categories,
        "cis_isms_common_high_impact": common,
        "auto_vs_manual": auto_manual,
        "roadmap": roadmap,
        "report_5_lines": summary_lines,
    }


def build_top5(payload: dict[str, Any], manifest: dict[str, Any] | None) -> list[dict[str, Any]]:
    raw_ids = payload.get("remaining_fail_check_ids")
    if not isinstance(raw_ids, list):
        return []

    check_map = manifest.get("check_map", {}) if isinstance(manifest, dict) else {}
    seen: set[str] = set()
    items: list[dict[str, Any]] = []

    for check_id in raw_ids:
        if not isinstance(check_id, str) or not check_id or check_id in seen:
            continue
        seen.add(check_id)
        entry = _best_entry(_coerce_entries(check_map.get(check_id)))
        priority = entry.get("priority") if entry else None
        score = entry.get("osfp_score") if entry else None
        if score is None and entry:
            score = entry.get("score")
        item = {
            "check_id": check_id,
            "priority": priority,
            "priority_rank": priority_rank(priority),
            "score": float(score) if isinstance(score, (int, float)) else None,
            "remediation_tier": entry.get("remediation_tier") if entry else None,
            "category": entry.get("category") if entry else None,
        }
        items.append(item)

    items.sort(key=lambda x: (x.get("priority_rank", 0), x.get("score") or 0), reverse=True)
    top5 = items[:5]
    for item in top5:
        item.pop("priority_rank", None)
    return top5


def gh_request(method: str, path: str, body: dict[str, Any] | None = None) -> tuple[int, dict[str, Any] | list[Any] | None]:
    if not gh_enabled():
        raise HTTPException(status_code=503, detail="github integration not configured")
    url = f"https://api.github.com{path}"
    payload = json.dumps(body).encode("utf-8") if body is not None else None
    req = Request(
        url=url,
        data=payload,
        method=method,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {GH_TOKEN}",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
            "User-Agent": "prowler-minimal-dashboard",
        },
    )
    try:
        with urlopen(req, timeout=30) as res:
            raw = res.read().decode("utf-8").strip()
            data = json.loads(raw) if raw else None
            return int(res.status), data
    except HTTPError as e:
        detail = e.read().decode("utf-8", errors="ignore")
        raise HTTPException(status_code=e.code, detail=f"github api error: {detail}")


@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request) -> HTMLResponse:
    labels = get_labels(APP_LANG)
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "title": APP_TITLE if APP_TITLE else labels["app_title"],
            "api_token_set": bool(APP_TOKEN),
            "gh_enabled": gh_enabled(),
            "labels": labels,
            "labels_js": json.dumps(labels, ensure_ascii=False),
        },
    )


@app.get("/healthz")
def healthz() -> dict[str, Any]:
    return {"ok": True, "time": utc_now_iso()}


@app.post("/api/v1/prowler/results")
def ingest(
    body: dict[str, Any],
    authorization: str | None = Header(default=None),
) -> dict[str, Any]:
    token = parse_bearer(authorization)
    if APP_TOKEN and token != APP_TOKEN:
        raise HTTPException(status_code=401, detail="invalid token")

    meta = body.get("meta") if isinstance(body.get("meta"), dict) else {}
    payload = body.get("payload") if isinstance(body.get("payload"), dict) else {}
    if not meta:
        raise HTTPException(status_code=400, detail="missing meta")

    event_name = str(meta.get("event", "unknown"))
    event = {
        "id": str(uuid.uuid4()),
        "received_at": utc_now_iso(),
        "meta": {
            "event": event_name,
            "repo": meta.get("repo"),
            "run_id": str(meta.get("run_id", "")),
            "account_id": str(meta.get("account_id", "")),
            "region": str(meta.get("region", "")),
            "framework": str(meta.get("framework", "")),
            "published_at_epoch": meta.get("published_at_epoch"),
        },
        "payload": payload,
        "metrics": compute_metrics(event_name, payload),
    }
    write_event(event)
    return {"ok": True, "id": event["id"], "received_at": event["received_at"]}


@app.post("/")
def ingest_root(
    body: dict[str, Any],
    authorization: str | None = Header(default=None),
) -> dict[str, Any]:
    # Compatibility: allow posting directly to tunnel root URL.
    return ingest(body=body, authorization=authorization)


@app.get("/api/v1/github/scan-latest")
def scan_latest() -> dict[str, Any]:
    wf = quote(GH_SCAN_WORKFLOW, safe="")
    path = f"/repos/{GH_REPO}/actions/workflows/{wf}/runs?per_page=1"
    _, data = gh_request("GET", path)
    runs = (data or {}).get("workflow_runs", []) if isinstance(data, dict) else []
    if not runs:
        return {"ok": True, "latest": None}
    run = runs[0]
    return {
        "ok": True,
        "latest": {
            "id": run.get("id"),
            "html_url": run.get("html_url"),
            "status": run.get("status"),
            "conclusion": run.get("conclusion"),
            "created_at": run.get("created_at"),
            "display_title": run.get("display_title"),
        },
    }


@app.post("/api/v1/github/launch-scan")
def launch_scan(body: dict[str, Any]) -> dict[str, Any]:
    account_id = str(body.get("account_id", "")).strip()
    if not account_id:
        raise HTTPException(status_code=400, detail="account_id is required")
    deploy_vulnerable = bool(body.get("deploy_vulnerable", False))
    compliance_mode = str(body.get("compliance_mode", "cis_1.4_plus_isms_p")).strip()
    ref = str(body.get("ref", GH_REF)).strip() or GH_REF
    wf = quote(GH_SCAN_WORKFLOW, safe="")
    path = f"/repos/{GH_REPO}/actions/workflows/{wf}/dispatches"
    dispatch_body = {
        "ref": ref,
        "inputs": {
            "deploy_vulnerable": "true" if deploy_vulnerable else "false",
            "account_id": account_id,
            "compliance_mode": compliance_mode,
        },
    }
    status, _ = gh_request("POST", path, dispatch_body)
    return {"ok": status in (201, 204), "status_code": status, "queued_at": utc_now_iso()}


@app.get("/api/v1/events")
def list_events(
    account_id: str = Query(default=""),
    region: str = Query(default=""),
    event: str = Query(default=""),
    framework: str = Query(default=""),
    limit: int = Query(default=200, ge=1, le=2000),
) -> dict[str, Any]:
    rows = read_events()
    if account_id:
        rows = [r for r in rows if str(r.get("meta", {}).get("account_id", "")) == account_id]
    if region:
        rows = [r for r in rows if str(r.get("meta", {}).get("region", "")) == region]
    if event:
        rows = [r for r in rows if str(r.get("meta", {}).get("event", "")) == event]
    if framework:
        rows = [r for r in rows if str(r.get("meta", {}).get("framework", "")) == framework]
    rows = rows[:limit]
    return {"total": len(rows), "items": rows}


@app.get("/api/v1/summary")
def summary(
    account_id: str = Query(default=""),
    region: str = Query(default=""),
    framework: str = Query(default=""),
) -> dict[str, Any]:
    rows = read_events()
    if account_id:
        rows = [r for r in rows if str(r.get("meta", {}).get("account_id", "")) == account_id]
    if region:
        rows = [r for r in rows if str(r.get("meta", {}).get("region", "")) == region]
    if framework:
        rows = [r for r in rows if str(r.get("meta", {}).get("framework", "")) == framework]

    events_by_type: dict[str, int] = {}
    timeline: list[dict[str, Any]] = []
    latest_baseline = None
    latest_rescan = None

    for row in rows:
        et = str(row.get("meta", {}).get("event", "unknown"))
        events_by_type[et] = events_by_type.get(et, 0) + 1
        m = row.get("metrics", {})
        timeline.append(
            {
                "received_at": row.get("received_at"),
                "event": et,
                "baseline_fail": m.get("baseline_fail"),
                "post_fail": m.get("post_fail"),
                "reduced": m.get("reduced"),
            }
        )
        if et == "baseline_scan" and latest_baseline is None:
            latest_baseline = row
        if et == "rescan_verify" and latest_rescan is None:
            latest_rescan = row

    latest_rescan_top5 = None
    if latest_rescan:
        manifest = load_manifest()
        payload = latest_rescan.get("payload")
        if isinstance(payload, dict):
            items = build_top5(payload, manifest)
            latest_rescan_top5 = {
                "items": items,
                "count": len(items),
                "source": "manifest" if manifest else "none",
            }

    return {
        "generated_at": utc_now_iso(),
        "total_events": len(rows),
        "events_by_type": events_by_type,
        "latest_baseline": latest_baseline,
        "latest_rescan": latest_rescan,
        "latest_rescan_top5": latest_rescan_top5,
        "latest_rescan_summary": {
            "path": str(rescan_summary_path) if rescan_summary_path else None,
            "baseline_fail": rescan_summary.get("baseline_fail"),
            "post_fail": rescan_summary.get("post_fail"),
            "reduced": rescan_summary.get("reduced"),
        },
        "severity_timeline": build_severity_timeline(),
        "timeline": list(reversed(timeline[-100:])),
    }


@app.get("/api/v1/rescan-insights")
def rescan_insights() -> dict[str, Any]:
    return build_rescan_insights()


@app.delete("/api/v1/events")
def clear_events(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    token = parse_bearer(authorization)
    if APP_TOKEN and token != APP_TOKEN:
        raise HTTPException(status_code=401, detail="invalid token")
    with lock:
        EVENTS_FILE.write_text("", encoding="utf-8")
    return {"ok": True, "cleared_at": utc_now_iso()}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
