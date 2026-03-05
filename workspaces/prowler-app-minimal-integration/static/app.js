const qs = (id) => document.getElementById(id);
const L = window.APP_LABELS || {};

let eventsChart;
let trendChart;
let severityTimelineChart;

async function refreshLatestRun() {
  const link = qs("latestRunLink");
  try {
    const res = await fetch("/api/v1/github/scan-latest");
    if (!res.ok) {
      link.textContent = L.latest_run_unavailable || "Latest scan run: unavailable";
      link.removeAttribute("href");
      return;
    }
    const data = await res.json();
    const run = data.latest;
    if (!run) {
      link.textContent = L.latest_run_none || "Latest scan run: none";
      link.removeAttribute("href");
      return;
    }
    const label = `${run.id} (${run.status}${run.conclusion ? "/" + run.conclusion : ""})`;
    link.textContent = `${L.latest_run || "Latest scan run"}: ${label}`;
    link.href = run.html_url;
  } catch {
    link.textContent = L.latest_run_error || "Latest scan run: error";
    link.removeAttribute("href");
  }
}

function formatNum(v) {
  return typeof v === "number" ? v.toString() : "-";
}

function queryParams() {
  const p = new URLSearchParams();
  const account = qs("fAccount").value.trim();
  const region = qs("fRegion").value.trim();
  const framework = qs("fFramework").value.trim();
  if (account) p.set("account_id", account);
  if (region) p.set("region", region);
  if (framework) p.set("framework", framework);
  return p.toString();
}

function renderEventsTable(items) {
  const body = qs("eventsBody");
  body.innerHTML = "";
  for (const row of items) {
    const tr = document.createElement("tr");
    const m = row.metrics || {};
    const meta = row.meta || {};
    tr.innerHTML = `
      <td>${row.received_at || "-"}</td>
      <td>${meta.event || "-"}</td>
      <td>${meta.account_id || "-"}</td>
      <td>${meta.region || "-"}</td>
      <td>${meta.framework || "-"}</td>
      <td>${formatNum(m.baseline_fail)}</td>
      <td>${formatNum(m.post_fail)}</td>
      <td>${formatNum(m.reduced)}</td>
      <td>${meta.run_id || "-"}</td>
    `;
    body.appendChild(tr);
  }
}

function renderEventTypeChart(byType) {
  const ctx = qs("eventsChart");
  if (eventsChart) eventsChart.destroy();
  const labelMap = {
    CRITICAL: "Critical",
    HIGH: "High",
    MEDIUM: "Medium",
    LOW: "Low",
    INFO: "Info",
  };
  const order = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"];
  const labels = order.filter((k) => k in byType).map((k) => labelMap[k] || k);
  const values = order.filter((k) => k in byType).map((k) => byType[k]);
  eventsChart = new Chart(ctx, {
    type: "doughnut",
    data: {
      labels,
      datasets: [{
        data: values,
        backgroundColor: ["#ff4d6d", "#ff8c42", "#f0b35a", "#8ccf7e", "#6ea0ff"]
      }]
    },
    options: {
      plugins: { legend: { labels: { color: "#dce9ff" } } }
    }
  });
}

function renderTrendChart(timeline) {
  const ctx = qs("trendChart");
  if (trendChart) trendChart.destroy();
  const labels = timeline.map((x) => x.received_at?.slice(11, 19) || "-");
  const baseline = timeline.map((x) => x.baseline_fail ?? null);
  const post = timeline.map((x) => x.post_fail ?? null);
  trendChart = new Chart(ctx, {
    type: "line",
    data: {
      labels,
      datasets: [
        { label: "Baseline FAIL", data: baseline, borderColor: "#f0b35a", tension: 0.2 },
        { label: "Post-Apply FAIL", data: post, borderColor: "#4dd4a8", tension: 0.2 }
      ]
    },
    options: {
      scales: {
        x: { ticks: { color: "#9db3d3" }, grid: { color: "#27415d" } },
        y: { ticks: { color: "#9db3d3" }, grid: { color: "#27415d" } }
      },
      plugins: { legend: { labels: { color: "#dce9ff" } } }
    }
  });
}

function renderSeverityTimeline(timeline) {
  const ctx = qs("severityTimelineChart");
  if (!ctx) return;
  if (severityTimelineChart) severityTimelineChart.destroy();
  const labels = timeline.map((x) => x.timestamp?.slice(11, 19) || x.label || "-");
  const pick = (key) => timeline.map((x) => (x.counts && x.counts[key]) || 0);
  severityTimelineChart = new Chart(ctx, {
    type: "line",
    data: {
      labels,
      datasets: [
        { label: "CRITICAL", data: pick("CRITICAL"), borderColor: "#ff4d6d", tension: 0.2 },
        { label: "HIGH", data: pick("HIGH"), borderColor: "#ff8c42", tension: 0.2 },
        { label: "MEDIUM", data: pick("MEDIUM"), borderColor: "#f0b35a", tension: 0.2 },
        { label: "LOW", data: pick("LOW"), borderColor: "#8ccf7e", tension: 0.2 },
        { label: "INFO", data: pick("INFO"), borderColor: "#6ea0ff", tension: 0.2 }
      ]
    },
    options: {
      scales: {
        x: { ticks: { color: "#9db3d3" }, grid: { color: "#27415d" } },
        y: { ticks: { color: "#9db3d3" }, grid: { color: "#27415d" } }
      },
      plugins: { legend: { labels: { color: "#dce9ff" } } }
    }
  });
}

function renderTop5(top5) {
  const body = qs("top5Body");
  const meta = qs("top5Meta");
  body.innerHTML = "";
  if (!top5 || !Array.isArray(top5.items) || top5.items.length === 0) {
    meta.textContent = L.top5_empty || "No rescan top 5 data yet.";
    return;
  }
  meta.textContent = `source=${top5.source || "-"} • items=${top5.count ?? top5.items.length}`;
  top5.items.forEach((item, idx) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${idx + 1}</td>
      <td>${item.check_id || "-"}</td>
      <td>${item.priority || "-"}</td>
      <td>${item.score ?? "-"}</td>
      <td>${item.remediation_tier || "-"}</td>
      <td>${item.category || "-"}</td>
    `;
    body.appendChild(tr);
  });
}

function renderInsights(data) {
  const triageList = qs("triageList");
  const quickWinsList = qs("quickWinsList");
  const categoryList = qs("categoryList");
  const cisIsmsList = qs("cisIsmsList");
  const autoManualList = qs("autoManualList");
  const roadmapList = qs("roadmapList");
  const reportList = qs("reportList");

  const clear = (el) => { if (el) el.innerHTML = ""; };
  [triageList, quickWinsList, categoryList, cisIsmsList, autoManualList, roadmapList, reportList].forEach(clear);

  if (!data) return;

  const immediate = data.triage?.immediate || [];
  const shortTerm = data.triage?.short_term || [];
  immediate.slice(0, 5).forEach((item) => {
    const li = document.createElement("li");
    li.textContent = `[Immediate] ${item.check_id} (${item.severity || "-"} / ${item.exposure ?? "-"} resources)`;
    triageList.appendChild(li);
  });
  shortTerm.slice(0, 5).forEach((item) => {
    const li = document.createElement("li");
    li.textContent = `[Short-Term] ${item.check_id} (${item.severity || "-"} / ${item.exposure ?? "-"} resources)`;
    triageList.appendChild(li);
  });

  (data.quick_wins || []).slice(0, 5).forEach((item) => {
    const li = document.createElement("li");
    li.textContent = `${item.check_id} (${item.severity || "-"} / ${item.exposure ?? "-"} resources)`;
    quickWinsList.appendChild(li);
  });

  (data.categories_top3 || []).forEach((cat) => {
    const li = document.createElement("li");
    const topChecks = (cat.top_checks || []).map((c) => `${c.check_id}(${c.count})`).join(", ");
    li.textContent = `${cat.category}: ${cat.count} findings • ${topChecks}`;
    categoryList.appendChild(li);
  });

  (data.cis_isms_common_high_impact || []).forEach((item) => {
    const li = document.createElement("li");
    li.textContent = `${item.check_id} (${item.severity || "-"} / ${item.exposure ?? "-"} resources)`;
    cisIsmsList.appendChild(li);
  });

  const auto = data.auto_vs_manual?.terraform_auto || [];
  const manual = data.auto_vs_manual?.manual || [];
  const autoLi = document.createElement("li");
  autoLi.textContent = `Terraform auto: ${auto.length} checks`;
  autoManualList.appendChild(autoLi);
  const manualLi = document.createElement("li");
  manualLi.textContent = `Manual: ${manual.length} checks`;
  autoManualList.appendChild(manualLi);

  const roadmap = data.roadmap || {};
  ["week_1", "week_2", "month_1"].forEach((key) => {
    if (!roadmap[key]) return;
    const li = document.createElement("li");
    li.textContent = `${key.replace("_", " ")}: ${roadmap[key].focus}`;
    roadmapList.appendChild(li);
  });

  (data.report_5_lines || []).forEach((line) => {
    const li = document.createElement("li");
    li.textContent = line;
    reportList.appendChild(li);
  });
}

async function loadDashboard() {
  const p = queryParams();
  const status = qs("statusBadge");
  status.textContent = L.status_refreshing || "Refreshing";
  try {
    const [summaryRes, eventsRes, insightsRes] = await Promise.all([
      fetch(`/api/v1/summary?${p}`),
      fetch(`/api/v1/events?${p}&limit=300`),
      fetch(`/api/v1/rescan-insights`)
    ]);
    const summary = await summaryRes.json();
    const events = await eventsRes.json();
    const insights = insightsRes.ok ? await insightsRes.json() : null;

    const latestRescan = summary.latest_rescan_summary || {};
    qs("kpiTotal").textContent = formatNum(latestRescan.post_fail);
    qs("kpiBaseline").textContent = formatNum(latestRescan.baseline_fail);
    qs("kpiPost").textContent = formatNum(latestRescan.post_fail);
    qs("kpiReduced").textContent = formatNum(latestRescan.reduced);
    const noteEl = qs("kpiNote");
    if (noteEl) {
      const postFail = latestRescan.post_fail;
      if (typeof postFail === "number") {
        noteEl.textContent = `최신 리스캔 기준 집계 (FAIL ${postFail})`;
      } else {
        noteEl.textContent = L.kpi_note || "-";
      }
    }

    renderEventTypeChart(insights?.severity_counts || {});
    renderTrendChart(summary.timeline || []);
    renderSeverityTimeline(summary.severity_timeline || []);
    renderEventsTable(events.items || []);
    renderTop5(summary.latest_rescan_top5);
    renderInsights(insights);
    status.textContent = L.status_ok || "OK";
    status.className = "badge ok";
    refreshLatestRun();
  } catch (e) {
    status.textContent = L.status_error || "Error";
    status.className = "badge warn";
  }
}

async function launchScan() {
  const result = qs("launchResult");
  result.textContent = L.launching || "launching...";
  const payload = {
    account_id: qs("launchAccount").value.trim(),
    compliance_mode: qs("launchCompliance").value,
    deploy_vulnerable: qs("launchDeploy").checked
  };
  try {
    const res = await fetch("/api/v1/github/launch-scan", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    if (!res.ok || !data.ok) {
      const base = L.launch_failed || "launch failed";
      result.textContent = `${base}: ${data.detail || res.status}`;
      return;
    }
    result.textContent = L.scan_queued || "scan queued";
    setTimeout(refreshLatestRun, 1500);
  } catch {
    const base = L.launch_failed || "launch failed";
    result.textContent = `${base}: network error`;
  }
}

qs("btnApply").addEventListener("click", loadDashboard);
qs("btnLaunch").addEventListener("click", launchScan);
qs("btnReset").addEventListener("click", () => {
  qs("fAccount").value = "";
  qs("fRegion").value = "";
  qs("fFramework").value = "";
  loadDashboard();
});

loadDashboard();
setInterval(loadDashboard, 15000);
