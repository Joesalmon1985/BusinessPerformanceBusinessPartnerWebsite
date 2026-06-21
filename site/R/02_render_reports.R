# =============================================================================
# 02_render_reports.R
# Renders HTML report pages from synthetic CSV data with draft commentary blocks.
# Demonstration only — no live systems, no real Trust data.
# =============================================================================

REVIEW_BANNER <- paste0(
  '<div class="warning-box" role="alert"><strong>DRAFT — REQUIRES HUMAN REVIEW AND SIGN-OFF.</strong> ',
  'This is AI-style demonstration commentary on synthetic data. Not approved performance reporting.</div>'
)

draft_blocks <- function(commentary, stats_notes, limits) {
  paste0(
    REVIEW_BANNER,
    '<section><h2>Draft commentary (demonstration)</h2>',
    '<p><em>Illustrative AI-generated first draft — not reviewed or approved.</em></p>',
    commentary,
    '<h2>Statistical notes</h2>', stats_notes,
    '<h2>Limits and caveats</h2>', limits,
    '</section>'
  )
}

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
} else {
  script_dir <- getwd()
}
data_dir <- file.path(script_dir, "..", "data")
reports_dir <- file.path(script_dir, "..", "reports")
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

CAVEAT <- paste0(
  '<div class="caveat-box" role="note">',
  '<strong>Synthetic data:</strong> Fabricated aggregate data for demonstration only. ',
  'Not an official Dorset HealthCare report. No confidential or patient-identifiable information.',
  '</div>'
)

FOOTER <- paste0(
  '<footer class="site-footer"><div class="footer-inner">',
  '<p class="footer-caveat">Personal demonstration site — synthetic data only. Not an official Dorset HealthCare report.</p>',
  '<p style="margin-top:0.75rem;font-size:0.8rem;opacity:0.8;">Regenerate: Rscript site/R/02_render_reports.R</p>',
  '</div></footer>'
)

NAV <- paste0(
  '<header class="site-header"><div class="header-inner">',
  '<p class="site-title">Joe Salmon - Business &amp; Performance Business Partner Application</p>',
  '<p class="site-subtitle">Draft report — synthetic data only</p>',
  '<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="main-nav">Menu</button>',
  '</div><nav class="nav" id="main-nav" aria-label="Main navigation"><ul class="nav-list">',
  '<li><a href="../index.html">Home</a></li>',
  '<li><a href="../mandatory-reporting-map.html">Mandatory reporting map</a></li>',
  '<li><a href="../draft-reports.html">Draft reports</a></li>',
  '<li><a href="../agent-operating-model.html">Agent operating model</a></li>',
  '<li><a href="../governance-and-benefits.html">Governance and benefits</a></li>',
  '</ul></nav></header>'
)

html_table <- function(df, max_rows = 12) {
  n <- nrow(df)
  if (n > max_rows) df <- df[(n - max_rows + 1):n, , drop = FALSE]
  cols <- names(df)
  hdr <- paste0("<th scope=\"col\">", cols, "</th>", collapse = "")
  rows <- apply(df, 1, function(r) paste0("<td>", r, "</td>", collapse = ""))
  body <- paste0("<tr>", rows, "</tr>", collapse = "\n")
  paste0(
    '<div class="table-wrap"><table><thead><tr>', hdr, '</tr></thead>',
    '<tbody>', body, '</tbody></table></div>'
  )
}

simple_bar_chart <- function(labels, values, title = "Trend") {
  mx <- max(values, na.rm = TRUE)
  if (mx == 0) mx <- 1
  bars <- mapply(function(lab, val) {
    pct <- round(100 * val / mx)
    paste0(
      '<div class="chart-bar-row"><span class="chart-bar-label">', lab,
      '</span><div class="chart-bar-track"><div class="chart-bar-fill" style="width:',
      pct, '%;" role="presentation"></div></div></div>'
    )
  }, labels, values, SIMPLIFY = TRUE, USE.NAMES = FALSE)
  paste0('<div class="chart-container"><h3>', title, '</h3>', paste(bars, collapse = "\n"), '</div>')
}

write_report_page <- function(filename, title, body_content) {
  html <- paste0(
    '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<title>', title, '</title>',
    '<link rel="stylesheet" href="../assets/styles.css">',
    '</head><body>',
    '<a href="#main-content" class="skip-link">Skip to main content</a>',
    NAV, '<main id="main-content">',
    '<div class="hero"><h1>', title, '</h1>',
    '<p class="hero-lead">Draft report with demonstration commentary on synthetic data — not approved for operational or Board use.</p></div>',
    CAVEAT, body_content,
    '<p><a href="../draft-reports.html">&larr; Back to draft reports</a></p>',
    '</main>', FOOTER,
    '<script src="../assets/site.js"></script></body></html>'
  )
  writeLines(html, file.path(reports_dir, filename), useBytes = TRUE)
  cat("Written:", filename, "\n")
}

limits_std <- '<ul><li>All figures are synthetic aggregates</li><li>Not for operational, contractual or Board use</li><li>Metric definitions must be validated against authoritative sources before real use</li><li>Human owner must review and sign off any derived narrative</li></ul>'

cyp <- read.csv(file.path(data_dir, "synthetic_cyp_waiting_list.csv"), stringsAsFactors = FALSE)
mh <- read.csv(file.path(data_dir, "synthetic_mental_health_access.csv"), stringsAsFactors = FALSE)
ld <- read.csv(file.path(data_dir, "synthetic_learning_disability.csv"), stringsAsFactors = FALSE)
dc <- read.csv(file.path(data_dir, "synthetic_demand_capacity.csv"), stringsAsFactors = FALSE)
returns <- read.csv(file.path(data_dir, "mandatory_returns_register.csv"), stringsAsFactors = FALSE)

# --- Report 1: CYP ---
latest <- cyp[nrow(cyp), ]
prev <- cyp[nrow(cyp) - 1, ]
cyp_commentary <- paste0(
  '<p>Over the last six months the synthetic waiting list peaked in September before declining to ', latest$waiting_list,
  ' by March 2026. Long waits over 18 weeks have reduced from 45 to ', latest$waits_over_18w,
  ', suggesting some recovery — but this must be validated against pathway definitions and referral mix.</p>',
  '<p>Referrals remain broadly stable while discharges have not fully matched inflow in earlier months. ',
  'A service lead should confirm whether the recent decline is sustained or reflects seasonal variation.</p>'
)
cyp_stats <- paste0(
  '<ul><li>Median wait: ', latest$median_wait_weeks, ' weeks (down from ', prev$median_wait_weeks, ')</li>',
  '<li>Denominator for long-wait count depends on local access standard definition</li>',
  '<li>Trend based on 12 synthetic monthly points only</li></ul>'
)
cyp_body <- paste0(
  draft_blocks(cyp_commentary, cyp_stats, limits_std),
  '<section><h2>Summary KPIs</h2><div class="kpi-row">',
  '<div class="kpi-box"><span class="kpi-value">', latest$waiting_list, '</span><span class="kpi-label">Waiting list</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest$waits_over_18w, '</span><span class="kpi-label">Waits over 18w</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest$median_wait_weeks, '</span><span class="kpi-label">Median wait (weeks)</span></div>',
  '</div>',
  simple_bar_chart(tail(cyp$month, 6), tail(cyp$waiting_list, 6), "Waiting list trend"),
  '<h2>Monthly data</h2>', html_table(cyp), '</section>'
)
write_report_page("cyp-waiting-list-overview.html", "CYP Waiting List Overview", cyp_body)

# --- Report 2: MH ---
latest_mh <- mh[nrow(mh), ]
mh_commentary <- paste0(
  '<p>Synthetic data shows capacity pressure easing from 80 to ', latest_mh$capacity_pressure_index,
  ' over six months, with DNA rate improving slightly to ', latest_mh$dna_rate_pct,
  '%. Caseload has reduced modestly while contacts remain high — worth testing whether contact intensity is sustainable.</p>',
  '<p>Before any operational action, confirm whether the capacity pressure index is a locally defined composite and whether DNA exclusions match service protocol.</p>'
)
mh_stats <- '<ul><li>DNA rate denominator: attended + DNA appointments (verify locally)</li><li>Caseload is point-in-month snapshot</li><li>Public MHSDS data could provide external context — not linked in this demo</li></ul>'
mh_body <- paste0(
  draft_blocks(mh_commentary, mh_stats, limits_std),
  '<section><h2>Summary KPIs</h2><div class="kpi-row">',
  '<div class="kpi-box"><span class="kpi-value">', latest_mh$referrals, '</span><span class="kpi-label">Referrals</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest_mh$caseload, '</span><span class="kpi-label">Caseload</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest_mh$dna_rate_pct, '%</span><span class="kpi-label">DNA rate</span></div>',
  '</div>',
  simple_bar_chart(tail(mh$month, 6), tail(mh$capacity_pressure_index, 6), "Capacity pressure"),
  '<h2>Monthly data</h2>', html_table(mh), '</section>'
)
write_report_page("all-age-mental-health-access.html", "All Age Mental Health Access Dashboard", mh_body)

# --- Report 3: LD ---
latest_ld <- ld[nrow(ld), ]
ld_commentary <- paste0(
  '<p>Health check completion against due cohort is ', latest_ld$health_checks_completed, ' of ',
  latest_ld$health_checks_due, ' in the latest synthetic month. Long waits have reduced to ',
  latest_ld$long_waits, '. Safeguarding flags remain low but require clinical context — never interpret from aggregate demo data alone.</p>'
)
ld_stats <- '<ul><li>Small numbers apply in real LD reporting — suppression rules mandatory</li><li>Health check definitions must match local protocol</li></ul>'
ld_body <- paste0(
  draft_blocks(ld_commentary, ld_stats, limits_std),
  '<section><h2>Summary KPIs</h2><div class="kpi-row">',
  '<div class="kpi-box"><span class="kpi-value">', latest_ld$open_caseload, '</span><span class="kpi-label">Caseload</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest_ld$health_checks_completed, '/', latest_ld$health_checks_due, '</span><span class="kpi-label">Health checks</span></div>',
  '</div>',
  simple_bar_chart(tail(ld$month, 6), tail(ld$health_checks_completed, 6), "Health checks completed"),
  '<h2>Monthly data</h2>', html_table(ld), '</section>'
)
write_report_page("learning-disability-performance.html", "Learning Disability Performance Summary", ld_body)

# --- Report 4: D&C ---
latest_dc <- dc[nrow(dc), ]
dc_commentary <- paste0(
  '<p>Demand exceeds capacity in most recent synthetic weeks. Backlog stands at ', latest_dc$backlog,
  ' with forecast clearance of ', latest_dc$forecast_clearance_weeks,
  ' weeks assuming static assumptions. Any real plan must state workforce, DNA and triage assumptions explicitly.</p>'
)
dc_stats <- '<ul><li>Clearance forecast is illustrative arithmetic only</li><li>Weekly granularity — check for holiday/weekend effects in real data</li></ul>'
dc_body <- paste0(
  draft_blocks(dc_commentary, dc_stats, limits_std),
  '<section><h2>Summary KPIs</h2><div class="kpi-row">',
  '<div class="kpi-box"><span class="kpi-value">', latest_dc$backlog, '</span><span class="kpi-label">Backlog</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', latest_dc$forecast_clearance_weeks, '</span><span class="kpi-label">Clearance (weeks)</span></div>',
  '</div>',
  simple_bar_chart(tail(dc$week, 6), tail(dc$backlog, 6), "Backlog trend"),
  '<h2>Weekly data</h2>', html_table(dc), '</section>'
)
write_report_page("demand-and-capacity-prototype.html", "Demand and Capacity Prototype", dc_body)

# --- Report 5: Assurance log ---
assurance_cols <- returns[, c("return_name", "owner_team", "next_due_date", "assurance_status",
                               "risk", "issues", "escalation_route", "confidence")]
names(assurance_cols)[3] <- "next_due"
high_risk <- sum(returns$risk == "High")
needs_validation <- sum(grepl("validation|Manual|Needs|Not applicable", returns$assurance_status, ignore.case = TRUE))
assurance_commentary <- paste0(
  '<p>This assurance view tracks ', nrow(returns), ' mandatory returns with ', high_risk,
  ' flagged high risk and ', needs_validation, ' requiring validation or manual processing. ',
  'An agent could help maintain this log from specification documents; owners must confirm due dates and status before reliance.</p>'
)
assurance_limits <- '<ul><li>Due dates and statuses are synthetic demo metadata</li><li>Not a Trust compliance record</li><li>Escalation routes are illustrative</li></ul>'
assurance_body <- paste0(
  draft_blocks(assurance_commentary,
    '<ul><li>Cross-check next due dates against national publication calendars</li><li>Validate owner assignments with service leads</li></ul>',
    assurance_limits),
  '<section><h2>Assurance summary</h2><div class="kpi-row">',
  '<div class="kpi-box"><span class="kpi-value">', nrow(returns), '</span><span class="kpi-label">Returns tracked</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', high_risk, '</span><span class="kpi-label">High risk</span></div>',
  '<div class="kpi-box"><span class="kpi-value">', needs_validation, '</span><span class="kpi-label">Need validation</span></div>',
  '</div><h2>Returns assurance log</h2>', html_table(assurance_cols, max_rows = 20), '</section>'
)
write_report_page("mandatory-returns-assurance-log.html", "Mandatory Returns Assurance Log", assurance_body)

cat("All reports written to:", normalizePath(reports_dir), "\n")
