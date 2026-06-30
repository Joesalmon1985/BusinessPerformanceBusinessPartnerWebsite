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
    ("kpi-definitions-register.html", "Agreed KPI and definitions register", "M2", "1 of 6",
     "Layered definitions from service reality through system capture, data logic and sign-off.",
     "index.html", "All deliverables", "source-to-report-map.html"),
    ("source-to-report-map.html", "Source-to-report map", "M2", "2 of 6",
     "Operational chain from service event through source data to management decision — includes report inventory.",
     "kpi-definitions-register.html", "KPI definitions", "reporting-assurance-during-migration.html"),
    ("reporting-assurance-during-migration.html", "Reporting assurance during migration", "M3–M5", "3 of 6",
     "Risks we are watching, checks and reconciliation, and confidence before publish — one narrative.",
     "source-to-report-map.html", "Source-to-report map", "demand-capacity-productivity.html"),
    ("demand-capacity-productivity.html", "Demand, capacity and productivity insight", "M4", "4 of 6",
     "Weekly operational analysis with productivity by team and insights that drive service action.",
     "reporting-assurance-during-migration.html", "Reporting assurance", "senior-performance-brief.html"),
    ("senior-performance-brief.html", "Senior performance brief template", "M5", "5 of 6",
     "Template sections with Mar 2026 filled example and confidence column.",
     "demand-capacity-productivity.html", "Demand/capacity", "ideas-under-test.html"),
    ("ideas-under-test.html", "Ideas under test", "M1–M6", "6 of 6",
     "Portfolio of ideas tested, promoted, parked or dismissed — <a href=\"../three-principles.html#test-and-scale\">Test and Scale</a> in practice.",
     "senior-performance-brief.html", "Senior brief", "index.html"),
]

PLAIN_ENGLISH = {
    "kpi-definitions-register.html": (
        "In plain English",
        "This is the agreed dictionary of what we count and what it means. When someone asks "
        "“how many referrals did we have?”, this register records the answer everyone has signed "
        "up to — starting in everyday service language, not computer jargon. During a system "
        "change, the biggest risk is that the number still updates but means something different. "
        "This document is how we stop that happening.",
    ),
    "source-to-report-map.html": (
        "In plain English",
        "This is a route map from the ward or clinic to the board report. For every figure that "
        "appears in a report, it shows where that number comes from in the clinical systems, who "
        "owns it, and whether we trust it right now. It also lists which reports exist, who they "
        "are for, and which business questions they answer. If a figure looks wrong, you can trace "
        "it back without needing to be a data specialist.",
    ),
    "reporting-assurance-during-migration.html": (
        "In plain English",
        "This is the safety checklist for reporting during the IT migration. First we list what "
        "could go wrong and who owns each risk. Then we show the checks we ran and whether the "
        "numbers still match what we agreed. Finally we say which reports are safe to publish, "
        "which need a caveat, and which we withheld from the Board. It replaces three separate "
        "registers that were saying the same thing in different ways.",
    ),
    "demand-capacity-productivity.html": (
        "In plain English",
        "This is a weekly operational view for service managers: how much demand is coming in, "
        "how much capacity we have, how long people are waiting, and how productive teams are. "
        "The important part is the analysis — what the data suggests we should do differently, "
        "what we are piloting, and what we ruled out because it would mislead during the migration.",
    ),
    "senior-performance-brief.html": (
        "In plain English",
        "This is the short monthly narrative for directors and the Board — the story behind the "
        "numbers, not just the spreadsheet. Each section includes a confidence rating so leaders "
        "know which headlines are safe and which need a “handle with care” conversation. The "
        "Mar 2026 example shows how to explain when the dashboard says one thing but the agreed "
        "figure says another.",
    ),
    "ideas-under-test.html": (
        "In plain English",
        "This is a visible list of improvement ideas I would try in a real secondment — not "
        "every suggestion becomes a permanent dashboard. For each idea it records what problem "
        "we were solving, what small test we ran, what evidence we looked for, and whether to "
        "promote, park or stop. That is Test and Scale in practice: test cheaply, scale only "
        "when managers actually use the output to make decisions.",
    ),
}

INDEX_ROWS = [
    ("M2–M3", "Amber", "Agreed KPI and definitions register", "kpi-definitions-register.html"),
    ("M2", "Draft", "Source-to-report map", "source-to-report-map.html"),
    ("M3–M5", "Active", "Reporting assurance during migration", "reporting-assurance-during-migration.html"),
    ("M4", "Prototype", "Demand, capacity and productivity insight", "demand-capacity-productivity.html"),
    ("M5", "Template ready", "Senior performance brief template", "senior-performance-brief.html"),
    ("M1–M6", "Tracking", "Ideas under test", "ideas-under-test.html"),
]

def esc(s: str) -> str:
    return html.escape(s or "")


def plain_english_block(fname: str) -> str:
    heading, text = PLAIN_ENGLISH[fname]
    return (
        f'<section class="deliverable-plain-english" aria-labelledby="plain-{fname.replace(".html", "")}">'
        f'<h2 id="plain-{fname.replace(".html", "")}">{esc(heading)}</h2>'
        f"<p>{esc(text)}</p></section>"
    )


def build_index_page() -> str:
    rows = "".join(
        f'<tr><td>{i}</td><td>{esc(title)}</td><td>{esc(month)}</td><td>{esc(status)}</td>'
        f'<td><a href="{esc(href)}">View</a></td></tr>'
        for i, (month, status, title, href) in enumerate(INDEX_ROWS, 1)
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Handover deliverables — DRH worked examples</title>
  <link rel="stylesheet" href="../../assets/styles.css">
</head>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <div class="secondment-nav">
    <a href="../../six-months-trusted-performance.html">Six-month plan</a> &rarr; <strong>Handover deliverables</strong>
  </div>
  <main id="main-content">
    <div class="hero">
      <h1>Handover deliverables</h1>
      <p class="hero-lead">Six worked examples for Demo Rivers Health (DRH) — Legendary Care to PathwayOne migration. Each artefact shows what I would leave behind, with layered definitions where measures matter.</p>
    </div>
    <section class="slide-frame">
      <h2>Deliverable register</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th scope="col">#</th><th scope="col">Artefact</th><th scope="col">Month</th><th scope="col">Status</th><th scope="col">Link</th></tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
      </div>
      <p>Centrepiece evidence: <a href="../definition-migration.html">definition migration</a> (case-based vs action-based, Mar 2026 reconciliation). Reusable approach: <a href="../../six-months-trusted-performance.html#reusable-approach">ten-step playbook</a> · <a href="../../six-months-trusted-performance.html#ideas-under-test">ideas under test</a>.</p>
    </section>
  </main>
  <footer class="site-footer"><div class="footer-inner"><p class="footer-caveat">Synthetic DRH demonstration only. DRH ≠ RDY.</p></div></footer>
  <script src="../../assets/site.js"></script>
</body>
</html>
"""

LAYER_LABELS = [
    ("service_definition", "Service definition"),
    ("system_capture", "System / workflow capture"),
    ("fact_table_definition", "Data / fact-table definition"),
    ("reporting_use", "Reporting use"),
    ("exclusions_caveats", "Exclusions / caveats"),
    ("validation_check", "Validation check"),
    ("owners_sign_off", "Owner / sign-off"),
]


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


def _status_badge(status: str) -> str:
    s = (status or "").lower().replace(" ", "-")
    if "promoted" in s:
        cls = "idea-status--promoted"
    elif "test" in s:
        cls = "idea-status--test"
    elif "parked" in s:
        cls = "idea-status--parked"
    elif "dismissed" in s:
        cls = "idea-status--dismissed"
    else:
        cls = "idea-status--test"
    return f'<span class="idea-status {cls}">{esc(status)}</span>'


def _idea_artefact_link(artefact: str) -> str:
    links = {
        "demand-capacity-productivity": "demand-capacity-productivity.html",
        "reporting-assurance-during-migration": "reporting-assurance-during-migration.html",
        "kpi-definitions-register": "kpi-definitions-register.html",
        "senior-performance-brief": "senior-performance-brief.html",
        "ideas-under-test": "ideas-under-test.html",
        "source-to-report-map": "source-to-report-map.html",
        "deliverables/index": "index.html",
        "demand_capacity_insights.csv": "../../secondment-demo/data/demand_capacity_insights.csv",
        "six-months-trusted-performance": "../../six-months-trusted-performance.html#ideas-under-test",
    }
    href = links.get(artefact, f"../../secondment-demo/data/{artefact}")
    labels = {
        "demand-capacity-productivity": "Demand capacity pack",
        "reporting-assurance-during-migration": "Reporting assurance pack",
        "kpi-definitions-register": "KPI definitions register",
        "senior-performance-brief": "Senior performance brief",
        "ideas-under-test": "Ideas under test",
        "source-to-report-map": "Source-to-report map",
        "deliverables/index": "Deliverables register",
    }
    label = labels.get(artefact, artefact.replace("-", " ").replace(".csv", "").replace("/", " — ").title())
    if href.endswith(".html") and "/" not in artefact:
        return f'<a href="{href}">{esc(label)}</a>'
    return f'<a href="{href}">{esc(artefact)}</a>'


def build_reporting_assurance_body() -> str:
    risks = read_csv("migration_risk_register.csv")
    featured_ids = {"R001", "R002", "R009", "R013"}
    featured = [r for r in risks if r["risk_id"] in featured_ids]
    other = [r for r in risks if r["risk_id"] not in featured_ids]
    feat_rows = "".join(
        f'<tr><td>{esc(r["risk_id"])}</td><td>{esc(r["risk_description"])}</td>'
        f'<td>{esc(r["owner"])}</td><td>{esc(r["status"])}</td><td>{esc(r["residual_risk"])}</td></tr>'
        for r in featured
    )
    other_rows = "".join(
        f'<tr><td>{esc(r["risk_id"])}</td><td>{esc(r["risk_description"])}</td>'
        f'<td>{esc(r["owner"])}</td><td>{esc(r["status"])}</td><td>{esc(r["residual_risk"])}</td></tr>'
        for r in other
    )
    checks = read_csv("validation_checks_register.csv")
    check_rows = "".join(
        f'<tr><td>{esc(c["check_id"])}</td><td>{esc(c["rule_description"])}</td>'
        f'<td>{esc(c["mar2026_result"])}</td><td>{esc(c["pass_fail"])}</td></tr>'
        for c in checks
    )
    recon = read_csv("reconciliation_detail_mar2026.csv")
    recon_rows = "".join(
        f'<tr><td>{esc(r["team_code"])}</td><td>{esc(r["old_case_referrals"])}</td>'
        f'<td>{esc(r["new_action_referrals"])}</td><td>{esc(r["agreed_referrals"])}</td>'
        f'<td>{esc(r["dashboard_referrals"])}</td></tr>'
        for r in recon
    )
    conf = read_csv("reporting_confidence_register.csv")
    conf_rows = "".join(
        f'<tr><td>{esc(c["report_name"])}</td><td>{esc(c["confidence_level"])}</td>'
        f'<td>{esc(c["fallback_route"])}</td><td>{esc(c.get("publish_decision", ""))}</td></tr>'
        for c in conf
    )
    return f"""
    <section class="slide-frame"><h2>A — Risks we are watching</h2>
    <p>These are not IT tickets — they are reporting <em>meaning</em> risks with named owners. Phase D (Feb–Mar 2026) combines definition drift with two source models.</p>
    <div class="table-wrap"><table><thead><tr><th>ID</th><th>Risk</th><th>Owner</th><th>Status</th><th>Residual</th></tr></thead>
    <tbody>{feat_rows}</tbody></table></div>
    <details class="definition-detail"><summary>All migration risks ({len(risks)} rows)</summary>
    <div class="table-wrap"><table><thead><tr><th>ID</th><th>Risk</th><th>Owner</th><th>Status</th><th>Residual</th></tr></thead>
    <tbody>{other_rows}</tbody></table></div></details>
    <p><a href="../../secondment-demo/data/migration_risk_register.csv">migration_risk_register.csv</a></p></section>
    <section class="slide-frame"><h2>B — Checks and reconciliation</h2>
    <p>Mar 2026 validation — is the definition chain still intact?</p>
    <div class="table-wrap"><table><thead><tr><th>Check</th><th>Rule</th><th>Result</th><th>Pass?</th></tr></thead>
    <tbody>{check_rows}</tbody></table></div>
    <h3>Reconciliation by team — Mar 2026</h3>
    <div class="table-wrap"><table><thead><tr><th>Team</th><th>Old</th><th>New default</th><th>Agreed</th><th>Dashboard</th></tr></thead>
    <tbody>{recon_rows}</tbody></table></div>
    <p class="analysis-narrative">VAL-03 and VAL-06 failed: dashboard still refreshes (+14.9% vs agreed) but OPT-C shows −11%. Publication held until definition chain is signed off.</p>
    <p><a href="../definition-migration.html#slide-dm-reconcile">Definition migration reconciliation</a> ·
    <a href="../source-to-report.html?preset=low-confidence">Low-confidence rows in map</a> ·
    <a href="../../secondment-demo/data/validation_checks_register.csv">validation_checks_register.csv</a></p></section>
    <section class="slide-frame"><h2>C — Confidence and publish decisions</h2>
    <div class="confidence-ladder">
    <span class="confidence-step confidence-step--high">High — definition chain signed off</span>
    <span class="confidence-step confidence-step--medium">Medium — owner confirmation required</span>
    <span class="confidence-step confidence-step--low">Low — do not use for Board</span>
    <span class="confidence-step confidence-step--blocked">Do not use — chain broken or unvalidated</span></div>
    <p>During phase D, default to Medium or below for any KPI touching both Legendary Care and PathwayOne.</p>
    <div class="table-wrap"><table><thead><tr><th>Report</th><th>Confidence</th><th>Fallback</th><th>Publish decision</th></tr></thead>
    <tbody>{conf_rows}</tbody></table></div>
    <div class="sign-off-block"><strong>Mar 2026 actions:</strong> Executive dashboard withheld from Board (Low). MHSDS-like submit 134 not 154. Demand-capacity pack safe for service review.</div>
    <p><a href="../reports/data-quality-confidence.html">Formatted confidence report</a> ·
    <a href="../../secondment-demo/data/reporting_confidence_register.csv">reporting_confidence_register.csv</a></p></section>"""


def build_demand_capacity_body() -> str:
    weekly = read_csv("demand_capacity_weekly.csv")
    w21 = next(r for r in weekly if r["week"] == "2026-W21")
    week_rows = "".join(
        f'<tr><td>{esc(r["week"].replace("2026-", ""))}</td><td>{esc(r["demand"])}</td>'
        f'<td>{esc(r["capacity"])}</td><td>{esc(r["backlog"])}</td><td>{esc(r["workforce_availability_index"])}</td>'
        f'<td>£{int(r["agency_spend_gbp"]):,}</td><td>{esc(r["median_wait_days"])}d</td>'
        f'<td>{esc(r["opt_c_referrals"])}/{esc(r["dashboard_referrals"])}</td></tr>'
        for r in weekly
    )
    prod = read_csv("productivity_by_team.csv")
    w14 = {r["team_code"]: r for r in prod if r["week"] == "2026-W14"}
    w21p = {r["team_code"]: r for r in prod if r["week"] == "2026-W21"}
    teams = sorted(set(w14) | set(w21p))
    prod_rows = "".join(
        f'<tr><td>{esc(t)}</td>'
        f'<td>{esc(w14.get(t, {}).get("contacts_per_wte", "—"))}</td>'
        f'<td>{esc(w21p.get(t, {}).get("contacts_per_wte", "—"))}</td>'
        f'<td>{esc(w21p.get(t, {}).get("wte_available", "—"))}</td>'
        f'<td>{"£" + f"{int(w21p[t]["agency_spend_gbp"]):,}" if t in w21p and w21p[t].get("agency_spend_gbp") else "—"}</td>'
        f'<td>{esc(w21p.get(t, {}).get("cost_per_contact", "—"))}</td></tr>'
        for t in teams
    )
    insights = read_csv("demand_capacity_insights.csv")
    insight_cards = "".join(
        f'<article class="insight-card insight-card--{esc(r["status"].lower().replace(" ", "-"))}">'
        f'<p class="insight-card-meta">{_status_badge(r["status"])} · {esc(r["week"])} · {esc(r["owner"])}</p>'
        f'<h3>{esc(r["headline"])}</h3>'
        f'<p><strong>Evidence:</strong> {esc(r["evidence"])}</p>'
        f'<p><strong>Action:</strong> {esc(r["suggested_action"])}</p></article>'
        for r in insights
    )
    return f"""
    <section class="slide-frame"><h2>Headline indicators — W21</h2>
    <div class="kpi-headline-row">
      <div class="kpi-headline"><span class="kpi-headline-value">{esc(w21["backlog"])}</span><span class="kpi-headline-label">Backlog</span></div>
      <div class="kpi-headline"><span class="kpi-headline-value">{esc(w21["workforce_availability_index"])}</span><span class="kpi-headline-label">Workforce availability</span></div>
      <div class="kpi-headline"><span class="kpi-headline-value">£{int(w21["agency_spend_gbp"]):,}</span><span class="kpi-headline-label">Agency spend (week)</span></div>
      <div class="kpi-headline"><span class="kpi-headline-value">{esc(w21["median_wait_days"])}d</span><span class="kpi-headline-label">Median wait</span></div>
    </div>
    <p class="analysis-narrative">OPT-C referrals {esc(w21["opt_c_referrals"])} vs dashboard {esc(w21["dashboard_referrals"])} in week — separate genuine demand pressure from definition artefact.</p></section>
    <section class="slide-frame"><h2>Weekly trend (W06–W21)</h2>
    <div class="table-wrap"><table><thead><tr><th>Week</th><th>Demand</th><th>Capacity</th><th>Backlog</th><th>WFA</th><th>Agency</th><th>Wait</th><th>OPT-C / dash refs</th></tr></thead>
    <tbody>{week_rows}</tbody></table></div></section>
    <section class="slide-frame"><h2>Productivity by team (W14 vs W21)</h2>
    <div class="table-wrap"><table><thead><tr><th>Team</th><th>Contacts/WTE W14</th><th>Contacts/WTE W21</th><th>WTE W21</th><th>Agency W21</th><th>£/contact W21</th></tr></thead>
    <tbody>{prod_rows}</tbody></table></div></section>
    <section class="slide-frame"><h2>Insights from analysis</h2>
    <p class="analysis-narrative">Analysis turned data into two service conversations, one pilot, and ruled out one forecast we would not trust yet during definition change.</p>
    <div class="insight-card-grid">{insight_cards}</div>
    <div class="sign-off-block"><strong>Sign-off:</strong> CMHT service manager — prototype agreed for local use; INS-01 and INS-04 actions in capacity meeting.</div>
    <p><a href="../reports/local-demand-capacity-pack.html">Formatted demand pack</a> ·
    <a href="../../secondment-demo/data/demand_capacity_weekly.csv">demand_capacity_weekly.csv</a> ·
    <a href="../../secondment-demo/data/productivity_by_team.csv">productivity_by_team.csv</a> ·
    <a href="../../secondment-demo/data/demand_capacity_insights.csv">demand_capacity_insights.csv</a></p></section>"""


def build_ideas_under_test_body() -> str:
    rows = read_csv("ideas_under_test_register.csv")
    idea_rows = "".join(
        f'<tr><td>{esc(r["idea_id"])}</td><td>{esc(r["idea_name"])}</td>'
        f'<td>{_status_badge(r["status"])}</td><td>{esc(r["month"])}</td>'
        f'<td>{esc(r.get("decision", ""))}</td></tr>'
        for r in rows
    )
    cards = "".join(
        f'<article class="insight-card insight-card--{esc(r["status"].lower().replace(" ", "-"))}">'
        f'<p class="insight-card-meta">{_status_badge(r["status"])} · {esc(r["month"])} · {esc(r["idea_id"])}</p>'
        f'<h3>{esc(r["idea_name"])}</h3>'
        f'<p class="idea-card-field"><strong>Problem:</strong> {esc(r.get("problem", ""))}</p>'
        f'<p class="idea-card-field"><strong>Small test:</strong> {esc(r.get("small_test", ""))}</p>'
        f'<p class="idea-card-field"><strong>Evidence:</strong> {esc(r.get("evidence", ""))}</p>'
        f'<p class="idea-card-field"><strong>Decision it supports:</strong> {esc(r.get("decision", ""))}</p>'
        f'<p class="idea-card-field"><strong>Next step:</strong> {esc(r.get("next_step", ""))}</p>'
        + (f'<p class="idea-card-field"><strong>Safe to scale when:</strong> {esc(r["scale_safe_when"])}</p>'
           if r.get("scale_safe_when") and not r["scale_safe_when"].startswith("n/a") else "")
        + f'<p>{_idea_artefact_link(r["linked_artefact"])}</p></article>'
        for r in rows
    )
    return f"""
    <section class="slide-frame">
    <p><a href="../three-principles.html#test-and-scale">Test and Scale</a> in practice: test cheaply with real users, test against evidence, stop ideas that mislead, park what is not ready, promote what improves decisions, scale only when the evidence is strong enough.</p>
    </section>
    <section class="slide-frame"><h2>What this register is for</h2>
    <p>A controlled way to test improvement ideas without turning every suggestion into a permanent report or dashboard. During a six-month secondment there is not time to build everything — there is time to learn what deserves further investment and what should stop.</p>
    </section>
    <section class="slide-frame"><h2>How an idea moves through the register</h2>
    <ul class="idea-status-list">
      <li><strong>Under test</strong> — limited pilot with named users; scope and duration agreed upfront.</li>
      <li><strong>Promoted</strong> — evidence strong enough to become a deliverable or regular product with an owner.</li>
      <li><strong>Parked</strong> — potentially useful, but timing, data quality or dependencies not right yet.</li>
      <li><strong>Dismissed</strong> — tested and found misleading, not useful, or not worth scaling in current conditions.</li>
    </ul>
    </section>
    <section class="slide-frame"><h2>What makes an idea safe to scale</h2>
    <ul class="idea-scale-criteria">
      <li>Service users understand what they are looking at</li>
      <li>It answers a real decision question — not just “interesting data”</li>
      <li>Definitions are agreed and stable enough to trust</li>
      <li>Data confidence is adequate for the decision being made</li>
      <li>It changes behaviour or decisions — managers actually use it</li>
      <li>Ownership is clear after the secondment ends</li>
      <li>The process can be sustained without heroics</li>
    </ul>
    </section>
    <section class="slide-frame"><h2>Summary table</h2>
    <div class="table-wrap"><table><thead><tr><th>ID</th><th>Idea</th><th>Status</th><th>Month</th><th>Decision supported</th></tr></thead>
    <tbody>{idea_rows}</tbody></table></div></section>
    <section class="slide-frame"><h2>Idea cards</h2>
    <div class="insight-card-grid">{cards}</div>
    <p><a href="../../secondment-demo/data/ideas_under_test_register.csv">ideas_under_test_register.csv</a></p></section>"""


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
        conf = _confidence_bucket(r.get("reporting_confidence", ""))
        conf_cls = f"map-conf map-conf--{conf.lower()}" if conf else "map-conf"
        parts.append(
            f'<tr class="map-summary-row" {data_attrs}>'
            f'<td class="map-col-id"><span class="map-row-id">{esc(rid)}</span>'
            f'<span class="map-metric-code">{esc(r.get("metric_code", ""))}</span></td>'
            f'<td class="map-col-report">'
            f'<span class="map-report-name">{esc(r.get("report_name", ""))}</span>'
            f'<span class="map-report-field">{esc(r.get("report_field", ""))}</span></td>'
            f'<td class="map-col-source">'
            f'<span class="map-source-system">{esc(r.get("source_system", ""))}</span>'
            f'<code class="map-source-field">{esc(src_field)}</code></td>'
            f'<td class="map-col-fact"><code>{esc(r.get("warehouse_fact_or_dimension", ""))}</code></td>'
            f'<td class="map-col-confidence"><span class="{conf_cls}">{esc(conf)}</span></td>'
            f'<td class="map-col-owner">{esc(r.get("sign_off_owner", ""))}</td>'
            f'<td class="map-col-action">'
            f'<details class="map-row-details">'
            f'<summary>Lineage</summary>'
            f'<div class="map-details-panel">{_map_detail_dl(r)}</div>'
            f'</details></td></tr>'
        )
    return "".join(parts)


def _map_detail_dl(r: dict) -> str:
    inc_exc = (
        f"<strong>Inclusion:</strong> {esc(r.get('inclusion_rule', '') or '—')}<br>"
        f"<strong>Exclusion:</strong> {esc(r.get('exclusion_rule', '') or '—')}"
    )
    return (
        f'<dl class="map-details-dl">'
        f'<div><dt>Service event</dt><dd>{esc(r.get("service_event", ""))}</dd></div>'
        f'<div><dt>Service definition</dt><dd>{esc(r.get("service_definition", ""))}</dd></div>'
        f'<div><dt>System capture</dt><dd>{esc(r.get("system_workflow_capture", ""))}</dd></div>'
        f'<div><dt>Transformation</dt><dd>{esc(r.get("transformation_rule", ""))}</dd></div>'
        f'<div><dt>Inclusion / exclusion</dt><dd>{inc_exc}</dd></div>'
        f'<div><dt>Validation</dt><dd>{esc(r.get("validation_check", ""))}</dd></div>'
        f'<div><dt>Reconciliation</dt><dd>{esc(r.get("reconciliation_check", ""))}</dd></div>'
        f'<div><dt>Decision supported</dt><dd>{esc(r.get("management_decision_supported", ""))}</dd></div>'
        f'<div><dt>Migration risk</dt><dd>{esc(r.get("migration_risk", ""))}</dd></div>'
        f'<div><dt>Sign-off</dt><dd>{esc(r.get("sign_off_status", ""))}</dd></div>'
        f'<div><dt>Related output</dt><dd>{esc(r.get("related_output_file", ""))}</dd></div>'
        f'<div><dt>Notes</dt><dd>{esc(r.get("notes", "") or "—")}</dd></div>'
        f'</dl>'
    )


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
<body class="page-source-map">
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <div class="secondment-nav">
    <a href="../six-months-trusted-performance.html">Six-month plan</a> &rarr; Source-to-report stack
  </div>
  <main id="main-content" class="source-map-page">
    <header class="source-map-header">
      <h1>Source-to-report map</h1>
      <p class="hero-lead">One canonical map, many views — report-first, source-first, fact-first and risk-first.</p>
      <p class="source-map-intro">A safety map linking each report field back to the service event it describes. During migration, old and new systems may both produce a referral count — but with different actions, definitions and exclusions. <strong>Report-first:</strong> trace from report field to source. <strong>Source-first:</strong> see which reports change when a source field changes.</p>
      <p class="source-map-meta">{len(rows)} rows · {n_reports} reports · {n_sources} source fields · <a href="../secondment-demo/data/source_to_report_map.csv">Download CSV</a></p>
    </header>

    <div class="map-toolbar">
      <div class="map-preset-bar" role="group" aria-label="Filter presets">
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="mhsds">MHSDS-like</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="local-demand">Local demand</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="senior-brief">Senior brief</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="pathway-risk">Pathway risk</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="pathwayone">PathwayOne changes</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="low-confidence">Low confidence</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="migration-risks">High migration risk</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="awaiting-signoff">Awaiting sign-off</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="referral-received">Referral received</button>
        <button type="button" class="btn btn-secondary map-preset-btn" data-preset="central-fact">Central fact</button>
      </div>
      <div class="map-search-row">
        <label for="map-filter-search" class="visually-hidden">Search map</label>
        <input type="search" id="map-filter-search" class="map-search-input" placeholder="Search rows…" aria-label="Search source-to-report map">
        <button type="button" class="btn btn-secondary" id="map-filter-clear">Clear filters</button>
        <p class="filter-count" id="map-filter-count" aria-live="polite">Showing map rows</p>
      </div>
      <details class="map-filter-advanced">
        <summary>Advanced filters</summary>
        <div class="filter-panel filter-panel--compact">
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
          </div>
        </div>
      </details>
    </div>

    <div class="table-wrap table-wrap--source-map">
      <table id="source-map-table" class="source-map-table">
        <thead>
          <tr>
            <th scope="col">ID</th>
            <th scope="col">Report</th>
            <th scope="col">Source</th>
            <th scope="col">Warehouse fact</th>
            <th scope="col">Conf.</th>
            <th scope="col">Owner</th>
            <th scope="col">Lineage</th>
          </tr>
        </thead>
        <tbody>{tbody}</tbody>
      </table>
    </div>

    <footer class="source-map-footer">
      <p><a href="definition-migration.html#reconciliation">Definition migration</a> ·
      <a href="reports/mhsds-like-submission.html">MHSDS-like submission</a> ·
      <a href="../docs-html/secondment-demo/mhsds_like_sources.html">Official sources</a></p>
    </footer>
  </main>
  <footer class="site-footer"><div class="footer-inner"><p class="footer-caveat">Synthetic DRH demonstration only. MHSDS-like — not an official national return.</p></div></footer>
  <script src="../assets/site.js"></script>
</body>
</html>
"""


def build_source_to_report_body() -> str:
    catalogue = read_csv("report_catalogue.csv")
    requirements = read_csv("reporting_requirements_map.csv")
    cat_rows = "".join(
        f'<tr><td>{esc(r["report_name"])}</td><td>{esc(r["audience"])}</td>'
        f'<td>{esc(r["frequency"])}</td><td>{esc(r["owner"])}</td>'
        f'<td>{esc(r["confidence_mar2026"])}</td></tr>'
        for r in catalogue
    )
    req_rows = "".join(
        f'<tr><td>{esc(r["stakeholder"])}</td><td>{esc(r["business_question"])}</td>'
        f'<td>{esc(r["kpi_ref"])}</td><td>{esc(r["report_ref"])}</td></tr>'
        for r in requirements
    )
    return f"""<section class="slide-frame">
    <p>The canonical source-to-report map is a single filterable table — report inventory, field lineage, owners and confidence in one place.</p>
    <p><a class="btn btn-primary" href="../source-to-report.html">Open source-to-report map</a>
    <a class="btn btn-secondary" href="../../secondment-demo/data/source_to_report_map.csv">Download map CSV</a></p>
    </section>
    <section class="slide-frame"><h2>Reports at a glance</h2>
    <div class="table-wrap"><table><thead><tr><th>Report</th><th>Audience</th><th>Freq.</th><th>Owner</th><th>Confidence Mar 26</th></tr></thead>
    <tbody>{cat_rows}</tbody></table></div>
    <p><a href="../../secondment-demo/data/report_catalogue.csv">report_catalogue.csv</a></p></section>
    <section class="slide-frame"><h2>Stakeholder questions</h2>
    <div class="table-wrap"><table><thead><tr><th>Stakeholder</th><th>Question</th><th>KPI</th><th>Report</th></tr></thead>
    <tbody>{req_rows}</tbody></table></div>
    <p><a href="../../secondment-demo/data/reporting_requirements_map.csv">reporting_requirements_map.csv</a></p></section>"""


BODY = {
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
}

GENERATORS = {
    "kpi-definitions-register.html": build_kpi_register_body,
    "source-to-report-map.html": build_source_to_report_body,
    "reporting-assurance-during-migration.html": build_reporting_assurance_body,
    "demand-capacity-productivity.html": build_demand_capacity_body,
    "ideas-under-test.html": build_ideas_under_test_body,
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
    {plain_english}
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


REMOVED_DELIVERABLES = (
    "report-catalogue.html",
    "improvement-benefits-tracker.html",
    "handover-documentation.html",
    "reusable-change-model.html",
    "migration-risk-register.html",
    "validation-and-reconciliation.html",
    "reporting-confidence-model.html",
)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE_PAGE_OUT.write_text(build_source_to_report_page(), encoding="utf-8")
    print(f"Wrote {SOURCE_PAGE_OUT.name}")
    (OUT / "index.html").write_text(build_index_page(), encoding="utf-8")
    print("Wrote index.html")
    for fname, title, month, badge, lead, prev_href, prev_label, next_href in PAGES:
        next_label = "All deliverables" if next_href == "index.html" else next_href.replace(".html", "").replace("-", " ").title()
        html_out = TEMPLATE.format(
            title=title, badge=badge, month=month, lead=lead,
            body=get_body(fname),
            plain_english=plain_english_block(fname),
            prev_href=prev_href, prev_label=f"Previous: {prev_label}",
            next_href=next_href, next_label=f"Next: {next_label}",
        )
        (OUT / fname).write_text(html_out, encoding="utf-8")
        print(f"Wrote {fname}")
    for old in REMOVED_DELIVERABLES:
        path = OUT / old
        if path.exists():
            path.unlink()
            print(f"Removed {old}")


if __name__ == "__main__":
    main()
