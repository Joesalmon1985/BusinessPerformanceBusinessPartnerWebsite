#!/usr/bin/env python3
"""Generate handover deliverable HTML pages."""

import csv
import html
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
OUT = ROOT.parent / "secondment" / "deliverables"
SOURCE_PAGE_OUT = ROOT.parent / "secondment" / "source-to-report.html"

PAGES = [
    ("kpi-definitions-register.html", "Agreed KPI and definitions register", "M2", "1 of 11",
     "Layered definitions from service reality through system capture, data logic and sign-off.",
     "index.html", "All deliverables", "source-to-report-map.html"),
    ("source-to-report-map.html", "Source-to-report map", "M2", "2 of 11",
     "Operational chain from service event through source data to management decision.",
     "kpi-definitions-register.html", "KPI definitions", "migration-risk-register.html"),
    ("migration-risk-register.html", "Migration reporting risk register", "M3", "3 of 11",
     "Owned register of reporting risks — including definition drift, not just feed failure.",
     "source-to-report-map.html", "Source-to-report map", "report-catalogue.html"),
    ("report-catalogue.html", "Reporting requirements map and report catalogue", "M2", "4 of 11",
     "Who needs which question answered, which report delivers it, and what decision it supports.",
     "migration-risk-register.html", "Migration risk", "validation-and-reconciliation.html"),
    ("validation-and-reconciliation.html", "Validation checks and reconciliation outputs", "M3–M5", "5 of 11",
     "Checks that the definition chain is still intact before publish.",
     "report-catalogue.html", "Report catalogue", "reporting-confidence-model.html"),
    ("reporting-confidence-model.html", "Reporting confidence model", "M4", "6 of 11",
     "Four-tier confidence framework with fallback routes during migration.",
     "validation-and-reconciliation.html", "Validation", "demand-capacity-productivity.html"),
    ("demand-capacity-productivity.html", "Demand, capacity and productivity insight", "M4", "7 of 11",
     "Weekly demand/capacity with productivity by team — separating genuine pressure from definition change.",
     "reporting-confidence-model.html", "Confidence model", "senior-performance-brief.html"),
    ("senior-performance-brief.html", "Senior performance brief template", "M5", "8 of 11",
     "Template sections with Mar 2026 filled example and confidence column.",
     "demand-capacity-productivity.html", "Demand/capacity", "improvement-benefits-tracker.html"),
    ("improvement-benefits-tracker.html", "Improvement and benefits tracker", "M1–M6", "9 of 11",
     "Benefits tied to six-month outcomes with RAG status and evidence links.",
     "senior-performance-brief.html", "Senior brief", "handover-documentation.html"),
    ("handover-documentation.html", "Handover documentation", "M6", "10 of 11",
     "Register of documents, owners and handover status for sustain.",
     "improvement-benefits-tracker.html", "Benefits tracker", "reusable-change-model.html"),
    ("reusable-change-model.html", "Reusable model for future change", "M6", "11 of 11",
     "Ten-step playbook reusable for the next service or system migration.",
     "handover-documentation.html", "Handover docs", "index.html"),
]

LAYER_LABELS = [
    ("service_definition", "Service definition"),
    ("system_capture", "System / workflow capture"),
    ("fact_table_definition", "Data / fact-table definition"),
    ("reporting_use", "Reporting use"),
    ("exclusions_caveats", "Exclusions / caveats"),
    ("validation_check", "Validation check"),
    ("owners_sign_off", "Owner / sign-off"),
]


def esc(s: str) -> str:
    return html.escape(s or "")


def read_csv(name: str) -> list[dict]:
    path = DATA / name
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def definition_chain_flow() -> str:
    steps = [
        "Service reality", "System capture", "Source data", "Warehouse logic",
        "KPI / report", "Validation & sign-off", "Management action",
    ]
    parts = []
    for i, label in enumerate(steps):
        cls = "definition-chain-step definition-chain-step--action" if i == len(steps) - 1 else "definition-chain-step"
        parts.append(f'<span class="{cls}">{esc(label)}</span>')
    return f'<div class="definition-chain-flow" role="img" aria-label="Definition chain">{"".join(parts)}</div>'


def kpi_card(row: dict, featured: bool = False) -> str:
    extra = " definition-card--featured" if featured else ""
    layers = "".join(
        f'<div class="definition-layer"><dt>{esc(lbl)}</dt><dd>{esc(row.get(key, ""))}</dd></div>'
        for key, lbl in LAYER_LABELS
    )
    return f"""<article class="definition-card{extra}" id="{esc(row["kpi_id"])}">
      <h3>{esc(row["kpi_id"])} — {esc(row["kpi_name"])}</h3>
      <p class="definition-card-meta"><span><strong>Status:</strong> {esc(row["status"])}</span>
        <span><strong>N/L:</strong> {esc(row["national_or_local"])}</span>
        <span><strong>Phase:</strong> {esc(row["migration_phase"])}</span></p>
      <dl class="definition-layers">{layers}</dl>
    </article>"""


def build_kpi_register_body() -> str:
    rows = read_csv("kpi_definitions_register.csv")
    featured = next(r for r in rows if r["kpi_id"] == "KPI-01")
    summary_rows = "".join(
        f'<tr><td>{esc(r["kpi_id"])}</td><td>{esc(r["kpi_name"])}</td>'
        f'<td>{esc(r["service_definition"][:80] + ("…" if len(r["service_definition"]) > 80 else ""))}</td>'
        f'<td>{esc(r["status"])}</td><td>{esc(r["sign_off_owner"] or r["owner"])}</td></tr>'
        for r in rows
    )
    other = []
    for r in rows:
        if r["kpi_id"] == "KPI-01":
            continue
        card = kpi_card(r)
        other.append(
            f'<details class="definition-detail"><summary>{esc(r["kpi_id"])} — {esc(r["kpi_name"])} ({esc(r["status"])})</summary>{card}</details>'
        )
    return f"""
    <div class="definition-chain-intro" role="note">
      <p><strong>Definition chain:</strong> A measure is only safe to use when we can trace it from the real service event, through system capture and data logic, into the final report and the action taken from it.</p>
      <p>I would not just ask BI to fix the report. I would help the service, BI, IM&amp;T and performance colleagues agree what the report now needs to mean.</p>
    </div>
    {definition_chain_flow()}
    <section class="slide-frame"><h2>Featured example — referrals (KPI-01)</h2>
    {kpi_card(featured, featured=True)}
    <p class="analysis-narrative">Anchor patient <strong>DRH-PAT-002896</strong> shows why the chain matters: old case counts rejected referral as received; new default excludes unless clinical triage. See <a href="../definition-migration.html#anchor-vignette">definition migration vignette</a>. Source-to-report map: <a href="../source-to-report.html?preset=referral-received">referral received preset</a> · <a href="../reports/mhsds-like-submission.html">MHSDS-like submission</a>.</p>
    </section>
    <section class="slide-frame"><h2>Register at a glance</h2>
    <div class="table-wrap definition-summary-table"><table>
    <thead><tr><th>KPI</th><th>Measure</th><th>Service question</th><th>Status</th><th>Sign-off</th></tr></thead>
    <tbody>{summary_rows}</tbody></table></div></section>
    <section class="slide-frame"><h2>Full definition chains</h2>
    {"".join(other)}
    <div class="sign-off-block"><strong>Sign-off:</strong> KPI-01 Mar 2026 referrals — agreed pending directorate workshop (2026-03-25). Performance lead + mandatory reporting owner.</div>
    <p><a href="../../secondment-demo/data/kpi_definitions_register.csv">kpi_definitions_register.csv</a> · <a href="../../docs-html/secondment-demo/data_dictionary.html">data dictionary</a></p></section>"""


def build_migration_risk_body() -> str:
    rows = read_csv("migration_risk_register.csv")
    trs = "".join(
        f'<tr><td>{esc(r["risk_id"])}</td><td>{esc(r["risk_description"])}</td>'
        f'<td>{esc(r["owner"])}</td><td>{esc(r["status"])}</td><td>{esc(r["residual_risk"])}</td></tr>'
        for r in rows
    )
    return f"""
    <section class="slide-frame"><h2>Migration reporting risk register</h2>
    <p>Technical feed success does not mean a measure is safe. Phase D (Feb–Mar 2026) combines definition drift with two source models.</p>
    <div class="table-wrap"><table><thead><tr><th>ID</th><th>Risk</th><th>Owner</th><th>Status</th><th>Residual</th></tr></thead>
    <tbody>{trs}</tbody></table></div>
    <p class="analysis-narrative">R008–R013 are definition-drift risks: case object gone, rejected-referral logic, pathway start, admin in activity, local/national divergence, dashboard meaning change. Each links to a deliverable artefact.</p>
    <div class="sign-off-block"><strong>Sign-off:</strong> Performance lead — register reviewed 2026-03-18; residual High risks escalated to directorate.</div>
    <p><a href="../migration-scenario.html#slide-timeline">Migration timeline</a> · <a href="../../secondment-demo/data/migration_risk_register.csv">CSV</a></p></section>"""


def trunc(s: str, n: int) -> str:
    s = s or ""
    return s if len(s) <= n else s[:n] + "…"


def _norm_attr(s: str) -> str:
    return (s or "").strip()


def _risk_bucket(risk: str) -> str:
    r = (risk or "").lower()
    if "high" in r:
        return "High"
    if "medium" in r:
        return "Medium"
    if "low" in r:
        return "Low"
    return risk or ""


def _confidence_bucket(conf: str) -> str:
    c = (conf or "").lower()
    if "low" in c:
        return "Low"
    if "high" in c:
        return "High"
    if "medium" in c:
        return "Medium"
    if "review" in c or "n/a" in c:
        return "Review"
    return conf or ""


def _select_options(values: list[str], label_all: str) -> str:
    opts = [f'<option value="">{esc(label_all)}</option>']
    for v in sorted({x for x in values if x}, key=str.lower):
        opts.append(f'<option value="{esc(v)}">{esc(v)}</option>')
    return "".join(opts)


def build_source_map_table_rows(rows: list[dict]) -> str:
    parts = []
    for r in rows:
        rid = r["map_row_id"]
        inc_exc = trunc(f"In: {r.get('inclusion_rule', '')} | Ex: {r.get('exclusion_rule', '')}", 70)
        src_field = f"{r.get('source_table', '')}.{r.get('source_field', '')}"
        data_attrs = (
            f'data-row-id="{esc(rid)}" '
            f'data-report="{esc(_norm_attr(r.get("report_name", "")))}" '
            f'data-report-field="{esc(_norm_attr(r.get("report_field", "")))}" '
            f'data-report-type="{esc(_norm_attr(r.get("report_type", "")))}" '
            f'data-source-system="{esc(_norm_attr(r.get("source_system", "")))}" '
            f'data-source-table="{esc(_norm_attr(r.get("source_table", "")))}" '
            f'data-source-field="{esc(_norm_attr(r.get("source_field", "")))}" '
            f'data-warehouse="{esc(_norm_attr(r.get("warehouse_fact_or_dimension", "")))}" '
            f'data-kpi="{esc(_norm_attr(r.get("kpi_id", "")))}" '
            f'data-confidence="{esc(_confidence_bucket(r.get("reporting_confidence", "")))}" '
            f'data-sign-off="{esc(_norm_attr(r.get("sign_off_status", "")))}" '
            f'data-risk="{esc(_risk_bucket(r.get("migration_risk", "")))}" '
            f'data-owner="{esc(_norm_attr(r.get("sign_off_owner", "")))}" '
            f'data-national-local="{esc(_norm_attr(r.get("national_or_local_use", "")))}"'
        )
        parts.append(
            f'<tr class="map-summary-row" {data_attrs}>'
            f'<td>{esc(r.get("report_name", ""))}</td>'
            f'<td>{esc(r.get("report_field", ""))}</td>'
            f'<td>{esc(trunc(r.get("source_system", ""), 28))}</td>'
            f'<td><code>{esc(trunc(src_field, 36))}</code></td>'
            f'<td><code>{esc(trunc(r.get("warehouse_fact_or_dimension", ""), 28))}</code></td>'
            f'<td class="col-notes">{esc(inc_exc)}</td>'
            f'<td>{esc(_confidence_bucket(r.get("reporting_confidence", "")))}</td>'
            f'<td>{esc(trunc(r.get("sign_off_owner", ""), 22))}</td>'
            f'<td>{esc(trunc(r.get("management_decision_supported", ""), 40))}</td>'
            f'<td><button type="button" class="btn btn-secondary btn-sm map-details-toggle" '
            f'aria-expanded="false" aria-controls="details-{esc(rid)}" data-target="details-{esc(rid)}">Details</button></td>'
            f'</tr>'
        )
        detail = (
            f'<dl class="map-details-dl">'
            f'<div><dt>Map row</dt><dd>{esc(rid)} · {esc(r.get("metric_code", ""))}</dd></div>'
            f'<div><dt>Service event</dt><dd>{esc(r.get("service_event", ""))}</dd></div>'
            f'<div><dt>Service definition</dt><dd>{esc(r.get("service_definition", ""))}</dd></div>'
            f'<div><dt>System / workflow capture</dt><dd>{esc(r.get("system_workflow_capture", ""))}</dd></div>'
            f'<div><dt>Transformation</dt><dd>{esc(r.get("transformation_rule", ""))}</dd></div>'
            f'<div><dt>Validation</dt><dd>{esc(r.get("validation_check", ""))}</dd></div>'
            f'<div><dt>Reconciliation</dt><dd>{esc(r.get("reconciliation_check", ""))}</dd></div>'
            f'<div><dt>Migration risk</dt><dd>{esc(r.get("migration_risk", ""))}</dd></div>'
            f'<div><dt>Sign-off</dt><dd>{esc(r.get("sign_off_status", ""))} — {esc(r.get("sign_off_owner", ""))}</dd></div>'
            f'<div><dt>Related output</dt><dd>{esc(r.get("related_output_file", ""))}</dd></div>'
            f'<div><dt>Notes</dt><dd>{esc(r.get("notes", ""))}</dd></div>'
            f'</dl>'
        )
        parts.append(
            f'<tr class="map-details-row hidden" id="details-{esc(rid)}">'
            f'<td colspan="10"><div class="map-details-panel">{detail}</div></td></tr>'
        )
    return "".join(parts)


def build_source_to_report_page() -> str:
    rows = read_csv("source_to_report_map.csv")
    tbody = build_source_map_table_rows(rows)
    reports = [r["report_name"] for r in rows]
    report_fields = [r["report_field"] for r in rows]
    report_types = [r["report_type"] for r in rows]
    source_systems = [r["source_system"] for r in rows]
    source_tables = [r["source_table"] for r in rows]
    source_fields = [r["source_field"] for r in rows]
    warehouses = [r["warehouse_fact_or_dimension"] for r in rows]
    kpis = [r["kpi_id"] for r in rows if r.get("kpi_id")]
    national_local = [r["national_or_local_use"] for r in rows]
    confidences = [_confidence_bucket(r["reporting_confidence"]) for r in rows]
    sign_offs = [r["sign_off_status"] for r in rows]
    risks = [_risk_bucket(r["migration_risk"]) for r in rows]
    owners = [r["sign_off_owner"] for r in rows]
    n_reports = len({r for r in reports if r})
    n_sources = len({f"{r['source_table']}.{r['source_field']}" for r in rows})

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Source-to-report stack</title>
  <link rel="stylesheet" href="../assets/styles.css">
</head>
<body class="page-register">
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <div class="secondment-nav">
    <a href="../six-months-trusted-performance.html">Six-month plan</a> &rarr; Source-to-report stack
  </div>
  <main id="main-content">
    <div class="hero">
      <h1>Source-to-report stack</h1>
      <p class="hero-lead">One source-to-report map, many views: report-first, source-first, fact-first and risk-first.</p>
    </div>

    <section class="slide-frame" aria-labelledby="explain">
      <h2 id="explain">What this map is for</h2>
      <p>A source-to-report map is a safety map. It stops a report field becoming detached from the service event it is supposed to describe. During migration, this matters because the old and new systems may both produce a referral count, but those counts may be based on different actions, definitions and exclusions.</p>
      <p>A source-to-report map can be used in two directions. <strong>Report-first:</strong> start with a report field and trace back to source and service meaning. <strong>Source-first:</strong> start with a changing source field and see which reports, KPIs and decisions are affected.</p>
      <div class="definition-chain-intro" role="note">
        <p><strong>Definition chain:</strong> Service reality → system capture → source data → warehouse logic → report field → validation → decision.</p>
        <p>Each row in the table below is one link from a report field back through that chain.</p>
      </div>
      <p class="lineage-callout"><strong>Example:</strong> use the <em>Referral received</em> preset to see OPT-C (134) vs dashboard (154) rows in the same canonical map — not a separate worked example.</p>
    </section>

    <section class="slide-frame" aria-labelledby="presets">
      <h2 id="presets">Preset views</h2>
      <div class="map-preset-bar" role="group" aria-label="Filter presets">
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="mhsds">MHSDS-like submission</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="local-demand">Local demand pack</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="senior-brief">Senior performance brief</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="pathway-risk">Pathway risk report</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="pathwayone">PathwayOne source changes</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="low-confidence">Low confidence rows</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="migration-risks">Definition migration risks</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="awaiting-signoff">Rows awaiting sign-off</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="referral-received">Example: referral received</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="central-fact">Central fact (fact_mh_referral_episode)</button>
      </div>
    </section>

    <section aria-labelledby="filters">
      <h2 id="filters">Filter the canonical map</h2>
      <div class="filter-panel">
        <div class="filter-row">
          <div class="filter-group"><label for="map-filter-report">Report name</label>
            <select id="map-filter-report">{_select_options(reports, "All reports")}</select></div>
          <div class="filter-group"><label for="map-filter-report-field">Report field</label>
            <select id="map-filter-report-field">{_select_options(report_fields, "All fields")}</select></div>
          <div class="filter-group"><label for="map-filter-report-type">Report type</label>
            <select id="map-filter-report-type">{_select_options(report_types, "All types")}</select></div>
          <div class="filter-group"><label for="map-filter-source-system">Source system</label>
            <select id="map-filter-source-system">{_select_options(source_systems, "All systems")}</select></div>
          <div class="filter-group"><label for="map-filter-source-table">Source table</label>
            <select id="map-filter-source-table">{_select_options(source_tables, "All tables")}</select></div>
          <div class="filter-group"><label for="map-filter-source-field">Source field</label>
            <select id="map-filter-source-field">{_select_options(source_fields, "All fields")}</select></div>
          <div class="filter-group"><label for="map-filter-warehouse">Warehouse fact</label>
            <select id="map-filter-warehouse">{_select_options(warehouses, "All facts")}</select></div>
          <div class="filter-group"><label for="map-filter-kpi">KPI</label>
            <select id="map-filter-kpi">{_select_options(kpis, "All KPIs")}</select></div>
          <div class="filter-group"><label for="map-filter-national-local">National / local</label>
            <select id="map-filter-national-local">{_select_options(national_local, "All uses")}</select></div>
          <div class="filter-group"><label for="map-filter-confidence">Confidence</label>
            <select id="map-filter-confidence">{_select_options(confidences, "All confidence")}</select></div>
          <div class="filter-group"><label for="map-filter-sign-off">Sign-off status</label>
            <select id="map-filter-sign-off">{_select_options(sign_offs, "All statuses")}</select></div>
          <div class="filter-group"><label for="map-filter-risk">Migration risk</label>
            <select id="map-filter-risk">{_select_options(risks, "All risks")}</select></div>
          <div class="filter-group"><label for="map-filter-owner">Owner</label>
            <select id="map-filter-owner">{_select_options(owners, "All owners")}</select></div>
          <div class="filter-group"><label for="map-filter-search">Text search</label>
            <input type="search" id="map-filter-search" placeholder="Search map rows…" aria-label="Search source-to-report map"></div>
          <div class="filter-group"><label>&nbsp;</label>
            <button type="button" class="btn btn-secondary" id="map-filter-clear">Clear filters</button></div>
        </div>
        <p class="filter-count" id="map-filter-count" aria-live="polite">Showing map rows</p>
      </div>
    </section>

    <section aria-labelledby="map-table-heading">
      <h2 id="map-table-heading">Canonical source-to-report map</h2>
      <p>{len(rows)} rows · {n_reports} reports · {n_sources} source fields. Download: <a href="../secondment-demo/data/source_to_report_map.csv">source_to_report_map.csv</a> · Handover: <a href="deliverables/source-to-report-map.html">deliverable register</a></p>
      <div class="table-wrap table-wrap--register">
        <table id="source-map-table" class="register-table source-map-table">
          <thead>
            <tr>
              <th scope="col">Report name</th>
              <th scope="col">Report field</th>
              <th scope="col">Source system</th>
              <th scope="col">Source table.field</th>
              <th scope="col">Warehouse fact</th>
              <th scope="col">Inclusion / exclusion</th>
              <th scope="col">Confidence</th>
              <th scope="col">Owner</th>
              <th scope="col">Decision supported</th>
              <th scope="col">Details</th>
            </tr>
          </thead>
          <tbody>{tbody}</tbody>
        </table>
      </div>
    </section>

    <p><a href="definition-migration.html#reconciliation">Definition migration</a> ·
    <a href="reports/mhsds-like-submission.html">MHSDS-like submission</a> ·
    <a href="../docs-html/secondment-demo/mhsds_like_sources.html">Official sources consulted</a></p>
  </main>
  <footer class="site-footer"><div class="footer-inner"><p class="footer-caveat">Synthetic DRH demonstration only. MHSDS-like — not an official national return.</p></div></footer>
  <script src="../assets/site.js"></script>
</body>
</html>
"""


def build_source_to_report_body() -> str:
    rows = read_csv("source_to_report_map.csv")
    reports = sorted({r["report_name"] for r in rows if r["report_name"]})
    sources = sorted({r["source_table"] for r in rows if r["source_table"]})
    return f"""
    <section class="slide-frame"><h2>Maintained source-to-report map</h2>
    {definition_chain_flow()}
    <p>This deliverable <strong>is</strong> the maintained source-to-report map. The interactive page displays filtered views of the same underlying CSV — one map, many views.</p>
    <p><strong>Summary:</strong> {len(rows)} rows · {len(reports)} report names · {len(sources)} source tables.</p>
    <div class="table-wrap"><table><thead><tr><th>View</th><th>Open interactive map</th></tr></thead><tbody>
    <tr><td>Full map</td><td><a href="../source-to-report.html">source-to-report.html</a></td></tr>
    <tr><td>MHSDS-like submission</td><td><a href="../source-to-report.html?report=MHSDS-like%20monthly%20submission">Filtered view</a></td></tr>
    <tr><td>Local demand pack</td><td><a href="../source-to-report.html?report=Local%20demand%20and%20access%20performance%20pack">Filtered view</a></td></tr>
    <tr><td>Referral received (KPI-01)</td><td><a href="../source-to-report.html?preset=referral-received">Preset</a></td></tr>
    <tr><td>PathwayOne source changes</td><td><a href="../source-to-report.html?preset=pathwayone">Preset</a></td></tr>
    <tr><td>Low confidence</td><td><a href="../source-to-report.html?preset=low-confidence">Preset</a></td></tr>
    </tbody></table></div>
    <p class="analysis-narrative">Do not maintain separate hand-authored tables — add or edit rows in the canonical CSV and regenerate this site.</p>
    <div class="sign-off-block"><strong>Sign-off:</strong> BI lead + mandatory reporting owner — draft lineage, review quarterly.</div>
    <p><a href="../source-to-report.html">Interactive map</a> ·
    <a href="../../secondment-demo/data/source_to_report_map.csv">source_to_report_map.csv</a> ·
    <a href="../reports/mhsds-like-submission.html">MHSDS-like submission</a></p></section>"""


BODY = {
    "source-to-report-map.html": None,  # generated
    "migration-risk-register.html": None,
    "kpi-definitions-register.html": None,
    "report-catalogue.html": """
    <section class="slide-frame"><h2>Reporting requirements map</h2>
    <div class="table-wrap"><table><thead><tr><th>Req</th><th>Stakeholder</th><th>Question</th><th>Decision supported</th><th>KPI</th></tr></thead>
    <tbody>
    <tr><td>REQ-01</td><td>NHSE</td><td>How many MH referrals?</td><td>Mandatory return submission</td><td>KPI-01</td></tr>
    <tr><td>REQ-04</td><td>Board</td><td>Headline access trend?</td><td>SLT assurance — withhold if definition unsafe</td><td>KPI-01</td></tr>
    <tr><td>REQ-03</td><td>CMHT manager</td><td>Waiting by team?</td><td>Capacity allocation and prioritisation</td><td>KPI-03</td></tr>
    <tr><td>REQ-02</td><td>Directorate</td><td>First contact standards?</td><td>Access performance review</td><td>KPI-04</td></tr>
    <tr><td>REQ-05</td><td>CSDS owner</td><td>Community activity?</td><td>Mandatory activity return</td><td>KPI-05</td></tr>
  </tbody></table></div></section>
    <section class="slide-frame"><h2>Report catalogue</h2>
    <div class="table-wrap"><table><thead><tr><th>Report</th><th>Audience</th><th>Freq</th><th>Owner</th><th>Confidence Mar 26</th></tr></thead>
    <tbody>
    <tr><td>Executive MH dashboard</td><td>SLT</td><td>Monthly</td><td>Performance lead</td><td>Low</td></tr>
    <tr><td>MHSDS-like monthly</td><td>NHSE</td><td>Monthly</td><td>Mandatory owner</td><td>Medium</td></tr>
    <tr><td>Reconciliation pack</td><td>Performance + BI</td><td>Monthly</td><td>Performance lead</td><td>High</td></tr>
    </tbody></table></div>
    <div class="sign-off-block"><strong>Sign-off:</strong> Mandatory reporting owner + performance lead — catalogue draft; REQ-01 to REQ-07 mapped.</div>
    <p><a href="../../secondment-demo/data/reporting_requirements_map.csv">requirements map</a> · <a href="../../secondment-demo/data/report_catalogue.csv">catalogue</a></p></section>""",
    "validation-and-reconciliation.html": """
    <section class="slide-frame"><h2>Is the definition chain still intact? — Mar 2026 checks</h2>
    <div class="table-wrap"><table><thead><tr><th>Check</th><th>Rule</th><th>Result</th><th>Pass?</th></tr></thead>
    <tbody>
    <tr><td>VAL-01</td><td>No duplicate ActionId</td><td>1 duplicate found</td><td>Fail</td></tr>
    <tr><td>VAL-02</td><td>Team crosswalk complete</td><td>1 INVALID_TEAM</td><td>Fail</td></tr>
    <tr><td>VAL-03</td><td>Dashboard within 15% of agreed</td><td>+14.9%</td><td>Fail</td></tr>
    <tr><td>VAL-06</td><td>MHSDS matches agreed</td><td>154 submitted (dashboard)</td><td>Fail</td></tr>
    </tbody></table></div></section>
    <section class="slide-frame"><h2>Reconciliation — Mar 2026</h2>
    <div class="table-wrap"><table><thead><tr><th>Level</th><th>Old</th><th>New default</th><th>Agreed</th><th>Dashboard</th></tr></thead>
    <tbody><tr><td>Trust total</td><td>151</td><td>168</td><td>134</td><td>154</td></tr></tbody></table></div>
    <p class="analysis-narrative">The chain broke at the reporting step: dashboard still refreshes (+2% headline) but agreed OPT-C shows −11%. Validation fails held from publish until definition chain is signed off.</p>
    <div class="sign-off-block"><strong>Sign-off:</strong> BI lead + performance lead — Mar 2026 reconciliation pending directorate workshop.</div>
    <p><a href="../definition-migration.html#slide-dm-reconcile">Definition migration reconciliation</a> · <a href="../source-to-report.html?preset=low-confidence">View low-confidence rows in map</a> · <a href="../../secondment-demo/data/validation_checks_register.csv">validation CSV</a></p></section>""",
    "reporting-confidence-model.html": """
    <section class="slide-frame"><h2>Confidence framework</h2>
    <div class="confidence-ladder">
    <span class="confidence-step confidence-step--high">High — definition chain signed off</span>
    <span class="confidence-step confidence-step--medium">Medium — owner confirmation required</span>
    <span class="confidence-step confidence-step--low">Low — do not use for Board</span>
    <span class="confidence-step confidence-step--blocked">Do not use — chain broken or unvalidated</span></div>
    <p>During migration phase D, default to Medium or below for any KPI touching both Legendary Care and PathwayOne.</p>
    <div class="table-wrap"><table><thead><tr><th>Report</th><th>Confidence</th><th>Fallback</th></tr></thead>
    <tbody>
    <tr><td>Executive MH dashboard</td><td>Low</td><td>Manual reconciliation pack</td></tr>
    <tr><td>MHSDS-like</td><td>Medium</td><td>Legacy pipeline fallback</td></tr>
    <tr><td>Demand-capacity pack</td><td>High</td><td>n/a</td></tr>
    </tbody></table></div>
    <div class="sign-off-block"><strong>Sign-off:</strong> Performance lead — executive dashboard flagged Low for Mar 2026.</div>
    <p><a href="../reports/data-quality-confidence.html">Formatted confidence report</a> · <a href="../../secondment-demo/data/reporting_confidence_register.csv">CSV</a></p></section>""",
    "demand-capacity-productivity.html": """
    <section class="slide-frame"><h2>Weekly demand and capacity</h2>
    <div class="table-wrap"><table><thead><tr><th>Week</th><th>Demand</th><th>Capacity</th><th>Backlog</th><th>WFA</th><th>Referrals</th></tr></thead>
    <tbody>
    <tr><td>W10</td><td>185</td><td>180</td><td>125</td><td>0.92</td><td>38</td></tr>
    <tr><td>W21</td><td>218</td><td>200</td><td>264</td><td>0.82</td><td>48</td></tr>
    </tbody></table></div>
    <p class="analysis-narrative">Supports capacity meetings. Separate genuine demand pressure from Mar referral definition artefact — both belong in the senior narrative.</p></section>
    <section class="slide-frame"><h2>Productivity by team</h2>
    <div class="table-wrap"><table><thead><tr><th>Team</th><th>Week</th><th>Contacts/WTE</th><th>WTE avail</th></tr></thead>
    <tbody>
    <tr><td>AA-MH-NORTH-01</td><td>W21</td><td>39</td><td>14.2</td></tr>
    <tr><td>AA-MH-SOUTH-01</td><td>W21</td><td>38</td><td>12.9</td></tr>
    </tbody></table></div>
    <div class="sign-off-block"><strong>Sign-off:</strong> CMHT service manager — prototype agreed for local use.</div>
    <p><a href="../reports/local-demand-capacity-pack.html">Formatted demand pack</a> · <a href="../../secondment-demo/data/demand_capacity_weekly.csv">CSV</a></p></section>""",
    "senior-performance-brief.html": """
    <section class="slide-frame"><h2>Template sections</h2>
    <div class="table-wrap"><table><thead><tr><th>Section</th><th>Mar 2026 example</th><th>Confidence</th></tr></thead>
    <tbody>
    <tr><td>Bottom line</td><td>Dashboard +2% but agreed −11%; separate demand from definition</td><td>Low</td></tr>
    <tr><td>Headline figures</td><td>Referrals 154/134; backlog 264</td><td>Mixed</td></tr>
    <tr><td>Risks</td><td>R002 dashboard meaning; workforce 0.82</td><td>Medium</td></tr>
    <tr><td>Actions</td><td>Definition workshop; withhold dashboard from Board</td><td>High</td></tr>
    </tbody></table></div>
    <div class="sign-off-block"><strong>Sign-off:</strong> Directorate lead — Mar 2026 draft withheld from Board pending reconciliation.</div>
    <p><a href="../reports/senior-performance-brief.html">Formatted brief (nhs-report)</a> · <a href="../../secondment-demo/data/senior_brief_sections.csv">CSV</a></p></section>""",
    "improvement-benefits-tracker.html": """
    <section class="slide-frame"><h2>Benefits tracker</h2>
    <div class="table-wrap"><table><thead><tr><th>Benefit</th><th>Target</th><th>Status</th><th>Month</th></tr></thead>
    <tbody>
    <tr><td>Agreed referral definition</td><td>OPT-C signed off</td><td>Amber</td><td>M3</td></tr>
    <tr><td>Layered KPI register</td><td>Service-to-sign-off chains</td><td>Amber</td><td>M2</td></tr>
    <tr><td>Monthly reconciliation</td><td>Scheduled before SLT</td><td>Green</td><td>M4</td></tr>
    <tr><td>Handover pack complete</td><td>All artefacts owned</td><td>Red</td><td>M6</td></tr>
    </tbody></table></div>
    <div class="sign-off-block"><strong>Sign-off:</strong> Performance lead — benefits tracked monthly.</div>
    <p><a href="../reports/improvement-benefits-tracker.html">Formatted tracker</a> · <a href="../../secondment-demo/data/improvement_benefits_tracker.csv">CSV</a></p></section>""",
    "handover-documentation.html": """
    <section class="slide-frame"><h2>Handover documentation register</h2>
    <div class="table-wrap"><table><thead><tr><th>Document</th><th>Purpose</th><th>Owner</th><th>Status</th></tr></thead>
    <tbody>
    <tr><td>KPI definitions register</td><td>Layered definition chains</td><td>Performance lead</td><td>Draft</td></tr>
    <tr><td>Source-to-report map</td><td>Operational lineage</td><td>BI lead</td><td>Draft</td></tr>
    <tr><td>Migration risk register</td><td>Definition + technical risks</td><td>Performance lead</td><td>Ready</td></tr>
    <tr><td>Data dictionary</td><td>Field definitions</td><td>BI lead</td><td>Ready</td></tr>
    </tbody></table></div>
    <p class="analysis-narrative">M6 handover: walk through each deliverable with successor and confirm owners.</p>
    <div class="sign-off-block"><strong>Sign-off:</strong> Successor named — handover walkthrough scheduled M6 week 2.</div>
    <p><a href="../../docs-html/secondment-demo/data_dictionary.html">Data dictionary</a> · <a href="../../secondment-demo/data/handover_documentation_register.csv">CSV</a></p></section>""",
    "reusable-change-model.html": """
    <section class="slide-frame"><h2>Ten-step change playbook</h2>
    <div class="table-wrap"><table><thead><tr><th>Step</th><th>Month</th><th>Activity</th><th>Artefact</th></tr></thead>
    <tbody>
    <tr><td>1</td><td>M1</td><td>Map stakeholders and feeds</td><td>Requirements map</td></tr>
    <tr><td>3</td><td>M2</td><td>Facilitate layered KPI definitions</td><td><a href="kpi-definitions-register.html">KPI register</a></td></tr>
    <tr><td>5</td><td>M3</td><td>Migration risk register</td><td><a href="migration-risk-register.html">Risk register</a></td></tr>
    <tr><td>8</td><td>M5</td><td>Validate definition chains monthly</td><td><a href="validation-and-reconciliation.html">Reconciliation</a></td></tr>
    <tr><td>10</td><td>M6</td><td>Handover</td><td><a href="handover-documentation.html">Handover pack</a></td></tr>
    </tbody></table></div>
    <p class="analysis-narrative">Reusable for the next service migration — the artefacts change; the definition-chain discipline does not.</p>
    <div class="sign-off-block"><strong>Sign-off:</strong> Performance lead + BI lead — playbook draft for reuse.</div>
    <p><a href="../../secondment-demo/data/change_playbook.csv">change_playbook.csv</a></p></section>""",
}

GENERATORS = {
    "kpi-definitions-register.html": build_kpi_register_body,
    "migration-risk-register.html": build_migration_risk_body,
    "source-to-report-map.html": build_source_to_report_body,
}

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title} — DRH handover deliverable</title>
  <link rel="stylesheet" href="../../assets/styles.css">
</head>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <div class="secondment-nav">
    <a href="../../six-months-trusted-performance.html">Six-month plan</a> &rarr;
    <a href="index.html">Handover deliverables</a> &rarr; {title}
  </div>
  <main id="main-content">
    <div class="hero">
      <p class="deliverable-badge">Handover deliverable · {badge} · Target {month}</p>
      <h1>{title}</h1>
      <p class="hero-lead">{lead}</p>
    </div>
    <div class="info-box" role="note"><strong>DRH migration context:</strong> Legendary Care (case-based) → PathwayOne (action-based). Parallel run Dec 2025–Jan 2026; Mar 2026 definition crunch.</div>
    {body}
    <nav class="deliverable-nav" aria-label="Deliverable navigation">
      <a href="{prev_href}">&larr; {prev_label}</a>
      <a href="index.html">All deliverables</a>
      <a href="{next_href}">{next_label} &rarr;</a>
    </nav>
  </main>
  <footer class="site-footer"><div class="footer-inner"><p class="footer-caveat">Synthetic DRH demonstration only.</p></div></footer>
  <script src="../../assets/site.js"></script>
</body>
</html>
"""


def get_body(fname: str) -> str:
    if fname in GENERATORS:
        return GENERATORS[fname]()
    return BODY.get(fname, "<p>See linked CSV.</p>")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE_PAGE_OUT.write_text(build_source_to_report_page(), encoding="utf-8")
    print(f"Wrote {SOURCE_PAGE_OUT.name}")
    for fname, title, month, badge, lead, prev_href, prev_label, next_href in PAGES:
        next_label = "All deliverables" if next_href == "index.html" else next_href.replace(".html", "").replace("-", " ").title()
        html_out = TEMPLATE.format(
            title=title, badge=badge, month=month, lead=lead,
            body=get_body(fname),
            prev_href=prev_href, prev_label=f"Previous: {prev_label}",
            next_href=next_href, next_label=f"Next: {next_label}",
        )
        (OUT / fname).write_text(html_out, encoding="utf-8")
        print(f"Wrote {fname}")


if __name__ == "__main__":
    main()
