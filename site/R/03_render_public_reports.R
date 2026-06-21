# =============================================================================
# 03_render_public_reports.R
# Renders static HTML public-data reports for Dorset HealthCare (RDY) demo.
# Uses public aggregate data from site/public-data/processed/ only.
# Not an official Dorset HealthCare report — human review required.
# =============================================================================

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
} else {
  script_dir <- getwd()
}

site_dir <- normalizePath(file.path(script_dir, ".."))
reports_dir <- file.path(site_dir, "reports")
public_dir <- file.path(site_dir, "public-data")
processed_dir <- file.path(public_dir, "processed")
metadata_dir <- file.path(public_dir, "metadata")
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

# --- Helpers -----------------------------------------------------------------

esc <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x
}

load_demo <- function(filename, required = FALSE) {
  path <- file.path(processed_dir, filename)
  if (!file.exists(path)) {
    msg <- paste("Missing demo CSV:", filename)
    if (required) warning(msg)
    return(NULL)
  }
  tryCatch(
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) {
      warning("Could not read ", filename, ": ", conditionMessage(e))
      NULL
    }
  )
}

load_rdy_glob <- function(pattern) {
  files <- list.files(processed_dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) return(NULL)
  tryCatch(read.csv(files[1], stringsAsFactors = FALSE, check.names = FALSE),
           error = function(e) NULL)
}

read_note <- function(source_id) {
  path <- file.path(metadata_dir, paste0("filter_note_", source_id, ".txt"))
  if (!file.exists(path)) return("")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

NOF_VALUE_SOURCE <- "NHS England published field in NOF data CSV — not recalculated by this demo"
NOF_COMPARATOR_GROUP <- "Mental health and community trusts in NHS Oversight Framework data file for this Quarter + Metric_ID + Reporting_date"
NOF_RANK_DIRECTION <- paste(
  "NHS England published rank (1 = best in peer group per NOF methodology).",
  "Polarity not independently verified in this demo — confirm against NHS England metric definitions."
)
RDY_FILTER_TEXT <- "Trust_code=RDY OR trust name matches Dorset HealthCare / Dorset Healthcare University NHS Foundation Trust"

path_for_display <- function(p) {
  if (is.null(p) || length(p) == 0 || is.na(p) || trimws(p) == "") return("")
  p <- normalizePath(p, winslash = "/", mustWork = FALSE)
  site_norm <- normalizePath(site_dir, winslash = "/")
  sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", site_norm), "/?"), "site/", p)
}

split_register_paths <- function(s) {
  if (is.null(s) || length(s) == 0 || is.na(s) || trimws(s) == "") return(character())
  trimws(strsplit(as.character(s), ";")[[1]])
}

read_register_row <- function(source_id) {
  reg_path <- file.path(public_dir, "DATA_SOURCE_REGISTER.csv")
  if (!file.exists(reg_path)) return(NULL)
  reg <- tryCatch(
    read.csv(reg_path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
  if (is.null(reg)) return(NULL)
  row <- reg[reg$source_id == source_id, , drop = FALSE]
  if (nrow(row) == 0) return(NULL)
  row[1, , drop = FALSE]
}

load_nof_full_rdy <- function() {
  files <- list.files(processed_dir, pattern = "^rdy_nof_mh_community.*-data\\.csv$", full.names = TRUE)
  if (length(files) == 0) return(NULL)
  tryCatch(read.csv(files[1], stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
}

load_nof_raw <- function() {
  files <- list.files(file.path(public_dir, "raw"), pattern = "nof_mh_community.*-data\\.csv$", full.names = TRUE)
  if (length(files) == 0) return(NULL)
  tryCatch(read.csv(files[1], stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
}

is_nof_raw_metric <- function(id) {
  grepl("^OF0[0-9]{3}$", trimws(as.character(id)))
}

nof_quarter_sort_key <- function(q) {
  q <- trimws(as.character(q))
  m <- regmatches(q, regexpr("Q[1-4]", q))
  if (length(m) == 0) return(0)
  qn <- as.integer(sub("Q", "", m))
  y <- suppressWarnings(as.integer(sub(".*([0-9]{4}).*", "\\1", q)))
  if (is.na(y)) y <- 0
  y * 10 + qn
}

nof_latest_quarter <- function(df) {
  qs <- unique(trimws(df$Quarter))
  qs[which.max(vapply(qs, nof_quarter_sort_key, numeric(1)))]
}

count_comparator_rows <- function(raw_df, quarter, metric_id, reporting_date) {
  if (is.null(raw_df) || nrow(raw_df) == 0) return(NA_integer_)
  sub <- raw_df[
    trimws(raw_df$Quarter) == trimws(quarter) &
      trimws(raw_df$Metric_ID) == trimws(metric_id) &
      trimws(raw_df$Reporting_date) == trimws(reporting_date),
    ,
    drop = FALSE
  ]
  as.integer(sum(!is.na(to_num(sub$Value))))
}

build_nof_audit_df <- function(display_rows, raw_df, reg_row) {
  raw_paths <- split_register_paths(if (!is.null(reg_row)) reg_row$downloaded_file_path else "")
  raw_data_path <- raw_paths[grepl("-data\\.csv", raw_paths, ignore.case = TRUE)][1]
  if (length(raw_data_path) == 0 || is.na(raw_data_path)) raw_data_path <- raw_paths[1]

  proc_paths <- split_register_paths(if (!is.null(reg_row)) reg_row$processed_file_path else "")
  proc_data_path <- proc_paths[grepl("-data\\.csv", proc_paths, ignore.case = TRUE)][1]
  if (length(proc_data_path) == 0 || is.na(proc_data_path)) proc_data_path <- proc_paths[1]

  source_url <- if (!is.null(reg_row)) reg_row$source_url else ""

  rows <- lapply(seq_len(nrow(display_rows)), function(i) {
    r <- display_rows[i, , drop = FALSE]
    comp_n <- count_comparator_rows(raw_df, r$Quarter, r$Metric_ID, r$Reporting_date)
    data.frame(
      Metric_ID = r$Metric_ID,
      Metric_description = r$Metric_description,
      Quarter = r$Quarter,
      Reporting_date = r$Reporting_date,
      Source_dataset = "NHS Oversight Framework MH/community trust data",
      Raw_source_file = path_for_display(raw_data_path),
      Raw_source_url = source_url,
      Processed_extract_path = path_for_display(proc_data_path),
      Demo_csv_path = "site/public-data/processed/demo_nof_overview.csv",
      RDY_filter = RDY_FILTER_TEXT,
      RDY_row_identifier = paste(r$Trust_code, r$Quarter, r$Metric_ID, r$Reporting_date, sep = " | "),
      Comparator_group = NOF_COMPARATOR_GROUP,
      Comparator_rows_used = comp_n,
      Calculation_for_median = NOF_VALUE_SOURCE,
      Calculation_for_rank = NOF_VALUE_SOURCE,
      Value_source = NOF_VALUE_SOURCE,
      Median_source = NOF_VALUE_SOURCE,
      Rank_source = NOF_VALUE_SOURCE,
      Rank_direction_note = NOF_RANK_DIRECTION,
      Exclusions = "Score variants (OF1xxx, OF4xxx) excluded from display; missing/suppressed/non-numeric Value excluded",
      Caveat = paste(
        "Median and rank are NHS England published comparators for the peer group — not recalculated by this demo.",
        "demo_nof_overview.csv is a truncated convenience sample (first 50 RDY rows).",
        "Tie handling follows NHS England source Rank column — not reimplemented here."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

write_nof_audit_csv <- function(audit_df) {
  out <- file.path(metadata_dir, "public_report_audit_nof_overview.csv")
  write.csv(audit_df, out, row.names = FALSE)
  cat("Written:", basename(out), "\n")
  invisible(out)
}

write_nof_audit_md <- function(audit_df, latest_quarter) {
  lines <- c(
    "# NOF performance overview — audit and verification guide",
    "",
    paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    paste("Display quarter:", latest_quarter),
    "",
    "> Public-data demonstration only. Not an official Dorset HealthCare report.",
    "",
    "## How to verify a figure manually",
    "",
    "1. Open `site/public-data/metadata/public_report_audit_nof_overview.csv` or the HTML report audit section for the metric.",
    "2. Note the `RDY_row_identifier` (Trust_code | Quarter | Metric_ID | Reporting_date).",
    "3. Open the processed RDY extract (`Processed_extract_path` in the audit CSV) and locate that row.",
    "4. Open the raw NOF data CSV (`Raw_source_file` in the audit CSV) and search for `Trust_code=RDY` and the same `Metric_ID`, `Quarter`, and `Reporting_date`.",
    "5. Confirm `Value`, `Median_value`, and `Rank` match exactly — these are **NHS England published fields**, not recalculated by this demo.",
    "6. Count comparator rows in the raw file for the same Quarter + Metric_ID + Reporting_date with a numeric Value — this should match `Comparator_rows_used`.",
    "7. Check NHS England metric metadata for rank direction and clinical/operational meaning before any operational use.",
    "",
    "## Median and rank",
    "",
    "- **Median_value** and **Rank** come directly from the NHS England NOF data CSV.",
    "- This demo does **not** recompute league tables, medians, or ranks.",
    "- Rank 1 is published by NHS England as best in the MH/community trust peer group for that metric (per NOF methodology).",
    "- **Polarity is not independently verified here** — confirm against NHS England definitions.",
    "",
    "## Worked example: OF0005",
    ""
  )

  ex1 <- audit_df[audit_df$Metric_ID == "OF0005", , drop = FALSE]
  if (nrow(ex1) > 0) {
    ex1 <- ex1[1, , drop = FALSE]
    lines <- c(lines,
      paste("- **Metric:** OF0005 —", ex1$Metric_description),
      paste("- **RDY row:**", ex1$RDY_row_identifier),
      paste("- **Raw file:**", ex1$Raw_source_file),
      paste("- **Comparator rows:**", ex1$Comparator_rows_used),
      paste("- **Median/rank source:**", ex1$Median_source),
      ""
    )
  }

  lines <- c(lines, "## Worked example: OF0079", "")

  ex2 <- audit_df[audit_df$Metric_ID == "OF0079", , drop = FALSE]
  if (nrow(ex2) > 0) {
    ex2 <- ex2[1, , drop = FALSE]
    lines <- c(lines,
      paste("- **Metric:** OF0079 —", ex2$Metric_description),
      paste("- **RDY row:**", ex2$RDY_row_identifier),
      paste("- **Raw file:**", ex2$Raw_source_file),
      paste("- **Comparator rows:**", ex2$Comparator_rows_used),
      paste("- **Caveat:** Finance metric rank direction requires NHS England definition check before operational interpretation."),
      ""
    )
  }

  lines <- c(lines,
    "## Human reviewer checklist",
    "",
    "- Confirm publication quarter and whether a newer NOF release supersedes these figures.",
    "- Check provisional/final status and any NHS England revisions.",
    "- Verify RDY matching against local ODS register.",
    "- Do not treat rank or median comparisons as significance tests.",
    "- Obtain accountable sign-off before operational or Board use.",
    ""
  )

  out <- file.path(metadata_dir, "public_report_audit_nof_overview.md")
  writeLines(lines, out, useBytes = TRUE)
  cat("Written:", basename(out), "\n")
  invisible(out)
}

audit_metric_details <- function(row) {
  fields <- c(
    "Metric_ID", "Metric_description", "Quarter", "Reporting_date", "Source_dataset",
    "Raw_source_file", "Raw_source_url", "Processed_extract_path", "Demo_csv_path",
    "RDY_filter", "RDY_row_identifier", "Comparator_group", "Comparator_rows_used",
    "Value_source", "Calculation_for_median", "Calculation_for_rank",
    "Rank_direction_note", "Exclusions", "Caveat"
  )
  items <- vapply(fields, function(f) {
    val <- if (f %in% names(row)) as.character(row[[f]]) else ""
    paste0("<dt>", esc(f), "</dt><dd>", esc(val), "</dd>")
  }, character(1))
  paste0(
    '<details class="nhs-audit-details"><summary>', esc(row$Metric_ID), " — ",
    esc(substr(as.character(row$Metric_description), 1, 60)), '</summary>',
    '<dl class="nhs-audit-dl">', paste(items, collapse = ""), '</dl></details>'
  )
}

nof_audit_verify_body <- function(audit_df, raw_display_path, raw_url) {
  summary_cols <- c(
    "Metric_ID", "Quarter", "RDY_row_identifier", "Comparator_rows_used",
    "Value_source", "Rank_direction_note"
  )
  summary_df <- audit_df[, intersect(summary_cols, names(audit_df)), drop = FALSE]

  details_html <- paste(vapply(seq_len(nrow(audit_df)), function(i) {
    audit_metric_details(audit_df[i, , drop = FALSE])
  }, character(1)), collapse = "\n")

  paste0(
    '<p>Every metric in the key figures table is traceable to NHS England published fields.',
    ' Median and rank are <strong>not recalculated</strong> by this demo.</p>',
    '<div class="nhs-source-links"><p><strong>View source data:</strong></p>',
    '<ul class="nhs-list-compact">',
    '<li><a href="../public-data/processed/demo_nof_overview.csv">demo_nof_overview.csv</a> (truncated convenience sample)</li>',
    '<li><a href="../public-data/metadata/public_report_audit_nof_overview.csv">public_report_audit_nof_overview.csv</a></li>',
    '<li><a href="../public-data/metadata/public_report_audit_nof_overview.md">public_report_audit_nof_overview.md</a></li>',
    '<li><a href="../public-data/DATA_SOURCE_REGISTER.csv">DATA_SOURCE_REGISTER.csv</a></li>',
    '<li><a href="../public-data/PUBLIC_REPORTS_METHOD.md">PUBLIC_REPORTS_METHOD.md</a></li>',
    '<li><a href="../governance-and-benefits.html">Governance and benefits</a></li>',
    '</ul>',
    '<p><strong>Raw source file</strong> (not linked — large file): <code>', esc(raw_display_path), '</code></p>',
    if (nzchar(raw_url)) paste0('<p><strong>Source URL:</strong> <a href="', esc(raw_url), '" rel="noopener">', esc(raw_url), '</a></p>') else "",
    '</div>',
    '<details class="nhs-verify-details"><summary>Audit summary table (technical detail)</summary>',
    '<div class="nhs-audit-summary">', html_table(summary_df, max_rows = 50), '</div>',
    '</details>',
    '<details class="nhs-verify-details"><summary>Per-metric audit detail</summary>',
    details_html,
    '<p class="nhs-audit-note"><em>Tie handling follows the NHS England source Rank column — not reimplemented in this demo.</em></p>',
    '</details>'
  )
}

traceability_verify_body <- function(intro, demo_files, filter_note_ids, inspection_ids = character()) {
  demo_items <- vapply(demo_files, function(d) {
    paste0('<li><a href="../public-data/processed/', esc(d), '">', esc(d), '</a></li>')
  }, character(1))
  filter_items <- vapply(filter_note_ids, function(id) {
    fn <- paste0("filter_note_", id, ".txt")
    paste0('<li><a href="../public-data/metadata/', fn, '">', esc(fn), '</a></li>')
  }, character(1))
  inspect_items <- vapply(inspection_ids, function(id) {
    fn <- paste0("inspection_", id, ".txt")
    paste0('<li><a href="../public-data/metadata/', fn, '">', esc(fn), '</a></li>')
  }, character(1))

  paste0(
    '<p>', intro, '</p>',
    '<div class="nhs-source-links">',
    '<p><strong>Demo CSV(s):</strong></p><ul class="nhs-list-compact">', paste(demo_items, collapse = ""), '</ul>',
    '<p><strong>Filter / inspection notes:</strong></p><ul class="nhs-list-compact">',
    paste(c(filter_items, inspect_items), collapse = ""), '</ul>',
    '<p><strong>Method documentation:</strong> ',
    '<a href="../public-data/PUBLIC_REPORTS_METHOD.md">PUBLIC_REPORTS_METHOD.md</a> · ',
    '<a href="../public-data/DATA_SOURCE_REGISTER.csv">DATA_SOURCE_REGISTER.csv</a> · ',
    '<a href="../governance-and-benefits.html">Governance and benefits</a></p>',
    '</div>'
  )
}

is_suppressed <- function(x) {
  x <- trimws(as.character(x))
  is.na(x) | x == "" | x == "*" | toupper(x) == "NA"
}

to_num <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("", "*", "NA", "N/A")] <- NA
  suppressWarnings(as.numeric(x))
}

pct_change <- function(cur, prev) {
  if (is.na(cur) || is.na(prev) || prev == 0) return(NA)
  round(100 * (cur - prev) / prev, 1)
}

kpi_row <- function(items) {
  cards <- vapply(items, function(it) {
    paste0(
      '<div class="nhs-kpi"><span class="nhs-kpi-value">', esc(it$value),
      '</span><span class="nhs-kpi-label">', esc(it$label), '</span></div>'
    )
  }, character(1))
  paste0('<div class="nhs-kpi-row">', paste(cards, collapse = ""), '</div>')
}

html_table <- function(df, max_rows = 20, hide_cols = character()) {
  if (is.null(df) || nrow(df) == 0) {
    return('<p><em>No tabular data available for this section.</em></p>')
  }
  if (length(hide_cols) > 0) {
    df <- df[, setdiff(names(df), hide_cols), drop = FALSE]
  }
  if (nrow(df) > max_rows) df <- df[seq_len(max_rows), , drop = FALSE]
  cols <- names(df)
  hdr <- paste0("<th scope=\"col\">", esc(cols), "</th>", collapse = "")
  rows <- apply(df, 1, function(r) {
    paste0("<td>", esc(r), "</td>", collapse = "")
  })
  body <- paste0("<tr>", rows, "</tr>", collapse = "\n")
  paste0(
    '<div class="nhs-table-wrap"><table><thead><tr>', hdr,
    '</tr></thead><tbody>', body, '</tbody></table></div>'
  )
}

bar_chart <- function(labels, values, title = "Chart", max_bars = 10) {
  if (length(labels) == 0 || all(is.na(values))) {
    return('<p><em>Insufficient numeric data for chart.</em></p>')
  }
  ord <- order(values, decreasing = TRUE)
  labels <- labels[ord]
  values <- values[ord]
  if (length(labels) > max_bars) {
    labels <- labels[seq_len(max_bars)]
    values <- values[seq_len(max_bars)]
  }
  mx <- max(values, na.rm = TRUE)
  if (!is.finite(mx) || mx <= 0) mx <- 1
  bars <- mapply(function(lab, val) {
    pct <- max(2, round(100 * val / mx))
    paste0(
      '<div class="nhs-bar-row"><span class="nhs-bar-label">', esc(lab),
      '</span><div class="nhs-bar-track"><div class="nhs-bar-fill" style="width:',
      pct, '%;" role="presentation"></div></div></div>'
    )
  }, labels, values, SIMPLIFY = TRUE, USE.NAMES = FALSE)
  paste0('<div class="nhs-chart"><h3>', esc(title), '</h3>', paste(bars, collapse = "\n"), '</div>')
}

REPORT_BADGE_META <- "Agent-assisted analytical brief &middot; Public aggregate data &middot; RDY &middot; Demonstration only"

RDY_FILTER_SHORT <- paste0(
  "RDY filter: ODS code <strong>RDY</strong> and case-insensitive trust name variants ",
  "(Dorset HealthCare / Dorset Healthcare University NHS Foundation Trust). ",
  "See <code>site/public-data/metadata/filter_note_*.txt</code> for per-source notes."
)

std_caveat <- paste0(
  '<div class="nhs-caveat" role="note">',
  '<strong>Agent-assisted analytical brief — public-data demonstration:</strong> ',
  'This is not an official Dorset HealthCare report. It uses public aggregate data only ',
  'and requires human review and local owner confirmation before operational use.',
  '</div>'
)

bullet_list <- function(items) {
  if (length(items) == 0) return("")
  items_html <- paste0("<li>", esc(items), "</li>", collapse = "")
  paste0('<ul class="nhs-list-compact">', items_html, '</ul>')
}

agent_prompt_box <- function(excerpt_text) {
  paste0('<pre class="nhs-prompt-excerpt">', esc(excerpt_text), '</pre>')
}

agent_process_box <- function(steps) {
  steps_html <- paste0("<li>", esc(steps), "</li>", collapse = "")
  paste0(
    '<div class="nhs-agent-process">',
    '<ol>', steps_html, '</ol>',
    '</div>'
  )
}

cannot_conclude_box <- function(items) {
  paste0(
    '<div class="nhs-cannot-conclude" role="note">',
    bullet_list(items),
    '</div>'
  )
}

first_draft_analysis <- function(paragraphs) {
  paras <- paste0("<p>", esc(paragraphs), "</p>", collapse = "")
  paste0('<section class="nhs-section"><h2>First-draft analysis</h2>', paras, '</section>')
}

human_review_warning <- function() {
  paste0(
    '<div class="nhs-warning" role="note"><strong>Human review required:</strong> ',
    'Validate definitions, confirm publication status (provisional/final), check suppression and rounding, ',
    'and obtain accountable sign-off before any operational use.</div>'
  )
}

verify_section <- function(intro_html, body_html) {
  paste0(
    '<section class="nhs-section nhs-verify-block"><h2>How to verify these figures</h2>',
    '<div class="nhs-verify-intro">', intro_html, '</div>',
    body_html,
    '</section>'
  )
}

verify_intro_std <- paste0(
  '<ol class="nhs-list-compact">',
  '<li>Open the linked demo CSV or audit file for the figure you are checking.</li>',
  '<li>Locate the RDY row using the filter notes and ODS code <strong>RDY</strong>.</li>',
  '<li>Confirm the value matches the published source — this demo does not recalculate NHS England comparators.</li>',
  '<li>Check metric definitions, provisional/final status and suppression before any operational use.</li>',
  '</ol>'
)

key_figures_section <- function(content_html) {
  paste0(
    '<section class="nhs-section"><h2>Key figures from the agent&rsquo;s first draft</h2>',
    content_html,
    '</section>'
  )
}

NOF_METRIC_SPEC_URL <- "https://www.england.nhs.uk/long-read/nhs-oversight-framework-csv-metadata-file/"

nof_agent_flag_badge <- function(flag_label, flag_class) {
  paste0(
    '<span class="nhs-agent-flag nhs-agent-flag--', esc(flag_class), '">',
    esc(flag_label), '</span>'
  )
}

nof_format_value_compare <- function(row) {
  paste0(
    "RDY value ", trimws(as.character(row$Value)),
    " vs peer median ", trimws(as.character(row$Median_value)),
    " (published rank ", trimws(as.character(row$Rank)), ")"
  )
}

nof_how_to_read_table <- function() {
  paste0(
    '<h3>How to read this table</h3>',
    '<ul class="nhs-list-compact">',
    '<li>Each row is one NHS Oversight Framework metric for Dorset HealthCare (RDY) in the published peer group.</li>',
    '<li><strong>Value</strong> is RDY&rsquo;s published metric value from the NHS England file — not recalculated by this demo.</li>',
    '<li><strong>Median_value</strong> is the published peer median for the same metric, quarter and reporting date.</li>',
    '<li><strong>Rank</strong> is the published NHS England rank (1 = best in peer group per NOF methodology).</li>',
    '<li>Whether higher or lower is better varies by metric — confirm polarity against the ',
    '<a href="', NOF_METRIC_SPEC_URL, '" rel="noopener">official NHS England NOF technical metric specification</a> ',
    'before any operational use. This specification was not bulk-downloaded in the public-data pipeline.</li>',
    '<li>This table is part of a first-draft agent brief for demonstration — not an official Dorset HealthCare performance report.</li>',
    '</ul>'
  )
}

nof_commentary_lookup <- function() {
  list(
    OF0005 = list(
      flag = "Potential strength", flag_class = "strength",
      plain_meaning = "Percentage of patients waiting over 52 weeks for community services.",
      interpret = function(row) {
        paste0(
          "This is a long-wait metric where lower values are generally preferable. ",
          nof_format_value_compare(row), ". ",
          "RDY reports 0.00% compared with a peer median of 0.19%. ",
          "The agent would note this as a potential strength relative to peers, ",
          "but the denominator, local waiting-list definition and data quality must be checked before any operational use."
        )
      },
      human_check = "Confirm cohort, denominator, reporting period (Mar-26) and whether local community waiting lists align with the national definition."
    ),
    OF0079 = list(
      flag = "Definition check required", flag_class = "definition",
      plain_meaning = "Planned surplus/deficit for the financial year.",
      interpret = function(row) {
        paste0(
          "This finance metric relates to the Trust&rsquo;s planned financial position. ",
          nof_format_value_compare(row), ". ",
          "Positive and negative values have specific meanings in NHS finance reporting — ",
          "the agent does not assume surplus/deficit interpretation without the official metric definition. ",
          "Flag for finance-owner confirmation."
        )
      },
      human_check = "Finance team to confirm sign convention, plan version (2025/26 plan) and whether this matches internal board reporting."
    ),
    OF0081 = list(
      flag = "Definition check required", flag_class = "definition",
      plain_meaning = "Variance year-to-date to financial plan.",
      interpret = function(row) {
        paste0(
          "This shows how far year-to-date performance varies from the approved plan. ",
          nof_format_value_compare(row), ". ",
          "The agent does not treat a higher or lower variance as automatically favourable without checking NHS England&rsquo;s metric definition and local finance narrative."
        )
      },
      human_check = "Finance owner to confirm Month 12 2025/26 YTD basis, plan assumptions and whether amendments have been published."
    ),
    OF0082 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "Sickness absence rate across the workforce.",
      interpret = function(row) {
        paste0(
          "Workforce sickness absence — lower values are usually preferable. ",
          nof_format_value_compare(row), ". ",
          "RDY is below the peer median (5.47 vs 6.22), which may indicate relatively lower absence, ",
          "but reporting period (Q3 2025/26) and local workforce context should be confirmed."
        )
      },
      human_check = "Workforce/HR lead to confirm reporting period, inclusion rules and whether local sickness dashboards use the same definition."
    ),
    OF0041 = list(
      flag = "Watch / clarify", flag_class = "watch",
      plain_meaning = "Annual change in the number of children and young people accessing NHS-funded mental health services.",
      interpret = function(row) {
        paste0(
          "This measures year-on-year change in CYP mental health access (Apr 25–Mar 26 vs prior year). ",
          nof_format_value_compare(row), ". ",
          "A higher figure may indicate growth in access relative to peers, but the agent would not treat this as demand or performance without confirming cohort, comparison year and service configuration."
        )
      },
      human_check = "CYP mental health lead to confirm numerator, ICB/resident vs provider scope and whether local access data supports the direction of change."
    ),
    OF0061 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "NHS Staff Survey sub-score on raising concerns.",
      interpret = function(row) {
        paste0(
          "Staff survey theme — higher scores usually indicate more positive staff experience on this theme. ",
          nof_format_value_compare(row), ". ",
          "RDY is slightly above the peer median. The agent would not treat small differences as meaningful without checking survey methodology and response rates."
        )
      },
      human_check = "Workforce/OD lead to confirm 2025 Staff Survey methodology, response rate and whether local culture survey data aligns."
    ),
    OF0084 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "NHS Staff Survey engagement theme sub-score.",
      interpret = function(row) {
        paste0(
          "Staff engagement theme from the NHS Staff Survey — higher is usually preferable. ",
          nof_format_value_compare(row), ". ",
          "RDY is marginally above the peer median. The agent would flag for local review rather than over-interpreting a small gap."
        )
      },
      human_check = "Confirm 2025 survey cohort, theme definition and whether the difference is material in local workforce planning."
    ),
    OF0057 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "Urgent Community Response 2-hour performance.",
      interpret = function(row) {
        paste0(
          "Proportion of urgent community response contacts meeting the 2-hour standard — higher is generally preferable for access performance. ",
          nof_format_value_compare(row), ". ",
          "RDY is below the peer median (79.28 vs 87.18). ",
          "The agent would flag this for local review and ask whether the latest local UCR position, referral volumes and service model explain the gap — not assume a single cause."
        )
      },
      human_check = "Community urgent care/service owner to confirm UCR definition, Q4 2025/26 reporting period and local operational position."
    ),
    OF0016 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "Percentage of patients in mental health crisis receiving face-to-face contact within 24 hours.",
      interpret = function(row) {
        paste0(
          "Mental health crisis access metric — higher is generally preferable. ",
          nof_format_value_compare(row), ". ",
          "RDY is below the peer median (65.54 vs 71.97). ",
          "The agent would flag this as an access and patient-safety themed metric needing local narrative and definition check."
        )
      },
      human_check = "Crisis pathway owner to confirm crisis cohort, face-to-face definition, Q4 2025/26 period and alignment with local crisis standards."
    ),
    OF0086 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "Relative difference in costs (National Cost Collection Index, adjusted for Market Forces Factor).",
      interpret = function(row) {
        paste0(
          "Relative difference in costs compares provider actual cost with expected cost. ",
          "A value of 100 is approximately expected cost; values above 100 indicate costs above expected; ",
          "values below 100 indicate costs below expected. NHS England describes lower as better for this metric. ",
          nof_format_value_compare(row), ". ",
          "RDY&rsquo;s published value is above both 100 and the peer median, so the agent would flag this for finance/productivity review ",
          "rather than treating it as a definitive conclusion about efficiency or overspend."
        )
      },
      human_check = "Finance/productivity owner to confirm 2024/25 cost index basis, MFF adjustment, peer group and local cost improvement narrative."
    ),
    OF0063 = list(
      flag = "Review locally", flag_class = "review",
      plain_meaning = "Percentage of adult mental health inpatients with length of stay over 60 days.",
      interpret = function(row) {
        paste0(
          "Long-stay inpatient metric — lower values are generally preferable. ",
          nof_format_value_compare(row), ". ",
          "RDY&rsquo;s value (46.55) is substantially above the peer median (24.52). ",
          "Because lower appears better for long-stay metrics, the agent would flag this for local review. ",
          "A human reviewer would need to confirm the cohort, denominator, reporting period and whether the public figure aligns with local inpatient reporting."
        )
      },
      human_check = "Acute/inpatient mental health lead to confirm >60-day definition, Q4 2025/26 cohort and local bed management data."
    )
  )
}

nof_metric_commentary_card <- function(row, entry) {
  metric_label <- paste0(trimws(as.character(row$Metric_ID)), " — ",
                         trimws(as.character(row$Metric_description)))
  interp <- if (is.function(entry$interpret)) entry$interpret(row) else entry$interpret
  paste0(
    '<article class="nhs-metric-card">',
    '<p class="nhs-metric-card-title"><strong>', esc(metric_label), '</strong> ',
    nof_agent_flag_badge(entry$flag, entry$flag_class), '</p>',
    '<dl>',
    '<dt>Plain-English meaning</dt><dd>', esc(entry$plain_meaning), '</dd>',
    '<dt>RDY value and peer median</dt><dd>', esc(nof_format_value_compare(row)), '</dd>',
    '<dt>Agent flag</dt><dd>', esc(entry$flag), '</dd>',
    '<dt>Initial interpretation</dt><dd>', interp, '</dd>',
    '<dt>Human check required</dt><dd>', esc(entry$human_check), '</dd>',
    '</dl></article>'
  )
}

nof_metric_commentary_section <- function(ranked_df) {
  lookup <- nof_commentary_lookup()
  cards <- vapply(seq_len(nrow(ranked_df)), function(i) {
    row <- ranked_df[i, , drop = FALSE]
    id <- trimws(as.character(row$Metric_ID))
    entry <- lookup[[id]]
    if (is.null(entry)) {
      paste0(
        '<article class="nhs-metric-card"><p><strong>', esc(id), '</strong></p>',
        '<p><em>No commentary template for this metric — check NHS England definitions.</em></p></article>'
      )
    } else {
      nof_metric_commentary_card(row, entry)
    }
  }, character(1))
  paste0(
    '<section class="nhs-section"><h2>Agent commentary on selected metrics</h2>',
    '<p>Concise first-draft notes for each metric in the table above. These are agent prompts for human review — not approved performance conclusions.</p>',
    '<div class="nhs-metric-commentary">', paste(cards, collapse = "\n"), '</div>',
    '</section>'
  )
}

load_mhsds_time_series <- function() {
  load_rdy_glob("^rdy_mhsds_monthly.*time_series.*Apr2025.*Perf_2026.*\\.csv$")
}

load_tt_time_series <- function() {
  load_rdy_glob("^rdy_talking_therapies.*time_series\\.csv$")
}

parse_period_start <- function(x) {
  x <- trimws(as.character(x))
  d <- suppressWarnings(as.Date(x, format = "%d/%m/%Y"))
  if (length(d) == 0 || all(is.na(d))) {
    d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  }
  d
}

extract_mhsds_rdy_ts <- function(df, measure_id, breakdown = "Provider") {
  if (is.null(df)) return(NULL)
  sub <- df[trimws(df$MEASURE_ID) == measure_id, , drop = FALSE]
  if ("BREAKDOWN" %in% names(sub)) {
    sub <- sub[trimws(sub$BREAKDOWN) == breakdown, , drop = FALSE]
  }
  sub <- sub[trimws(sub$PRIMARY_LEVEL) == "RDY", , drop = FALSE]
  if (nrow(sub) == 0) return(NULL)
  sub$period <- parse_period_start(sub$REPORTING_PERIOD_START)
  sub$value <- to_num(sub$MEASURE_VALUE)
  sub <- sub[!is.na(sub$period) & !is.na(sub$value), , drop = FALSE]
  sub[order(sub$period), , drop = FALSE]
}

extract_tt_rdy_ts <- function(df, measure_id) {
  if (is.null(df)) return(NULL)
  sub <- df[
    trimws(df$MEASURE_ID) == measure_id &
      trimws(df$ORG_CODE2) == "RDY" &
      trimws(df$GROUP_TYPE) == "Provider",
    ,
    drop = FALSE
  ]
  if (nrow(sub) == 0) return(NULL)
  sub$period <- parse_period_start(sub$REPORTING_PERIOD_START)
  sub$value <- to_num(sub$MEASURE_VALUE)
  sub <- sub[!is.na(sub$period) & !is.na(sub$value), , drop = FALSE]
  sub[order(sub$period), , drop = FALSE]
}

compute_period_trend <- function(ts_sub, measure_label = "") {
  if (is.null(ts_sub) || nrow(ts_sub) < 2) {
    return(list(
      available = FALSE,
      n_periods = if (is.null(ts_sub)) 0L else as.integer(nrow(ts_sub)),
      measure_label = measure_label
    ))
  }
  latest <- ts_sub[nrow(ts_sub), , drop = FALSE]
  prev <- ts_sub[nrow(ts_sub) - 1L, , drop = FALSE]
  cur_v <- latest$value
  prev_v <- prev$value
  list(
    available = TRUE,
    n_periods = nrow(ts_sub),
    measure_label = measure_label,
    latest_period = format(latest$period, "%b %Y"),
    previous_period = format(prev$period, "%b %Y"),
    latest_value = cur_v,
    previous_value = prev_v,
    absolute_change = cur_v - prev_v,
    percent_change = pct_change(cur_v, prev_v),
    rolling_mean = if (nrow(ts_sub) >= 3) round(mean(ts_sub$value), 1) else NA_real_,
    series = ts_sub
  )
}

trend_summary_table <- function(trends_list) {
  rows <- lapply(trends_list, function(t) {
    if (is.null(t) || !isTRUE(t$available)) return(NULL)
    data.frame(
      Measure = t$measure_label,
      Latest = paste0(format(t$latest_value, big.mark = ","), " (", t$latest_period, ")"),
      Previous = paste0(format(t$previous_value, big.mark = ","), " (", t$previous_period, ")"),
      Absolute_change = paste0(
        if (t$absolute_change >= 0) "+" else "",
        format(t$absolute_change, big.mark = ",")
      ),
      Percent_change = if (is.na(t$percent_change)) {
        "—"
      } else {
        paste0(if (t$percent_change >= 0) "+" else "", t$percent_change, "%")
      },
      Periods_in_extract = t$n_periods,
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) return(NULL)
  do.call(rbind, rows)
}

trend_not_available_section <- function(what_needed) {
  paste0(
    '<section class="nhs-section nhs-trend-section">',
    '<h2>Trend analysis not available from current extract</h2>',
    '<p>The downloaded public data for this report does not contain multiple comparable periods ',
    'for the measures in the key figures table, or only a latest-period snapshot is present.</p>',
    '<p><strong>What would be needed:</strong></p>',
    bullet_list(what_needed),
    '</section>'
  )
}

trend_section <- function(trends_list, source_note, caveats = character()) {
  any_avail <- any(vapply(trends_list, function(t) isTRUE(t$available), logical(1)))
  if (!any_avail) {
    return(trend_not_available_section(source_note))
  }
  tbl <- trend_summary_table(trends_list)
  charts <- vapply(trends_list, function(t) {
    if (is.null(t) || !isTRUE(t$available) || t$n_periods < 2) return("")
    labels <- format(t$series$period, "%b %y")
    bar_chart(labels, t$series$value, paste0(t$measure_label, " — monthly trend (descriptive)"))
  }, character(1))
  roll_notes <- vapply(trends_list, function(t) {
    if (is.null(t) || !isTRUE(t$available) || is.na(t$rolling_mean)) return("")
    paste0(
      t$measure_label, ": rolling mean across ", t$n_periods,
      " months = ", format(t$rolling_mean, big.mark = ","),
      " (descriptive only — not a performance target)."
    )
  }, character(1))
  roll_notes <- roll_notes[nzchar(roll_notes)]
  caveats_html <- if (length(caveats) > 0) {
    paste0('<ul class="nhs-list-compact nhs-trend-caveats">',
           paste0("<li>", esc(caveats), "</li>", collapse = ""), "</ul>")
  } else {
    ""
  }
  paste0(
    '<section class="nhs-section nhs-trend-section">',
    '<h2>Trend analysis (from downloaded public time series)</h2>',
    '<p>Descriptive period-on-period change only — not causal. Figures may be provisional; ',
    'suppression, rounding and definition changes may apply between months.</p>',
    '<p><strong>Source:</strong> ', esc(source_note), '</p>',
    html_table(tbl),
    paste(charts, collapse = "\n"),
    if (length(roll_notes) > 0) paste0("<p>", esc(roll_notes), "</p>", collapse = "") else "",
    caveats_html,
    '</section>'
  )
}

how_to_read_section <- function(items) {
  paste0(
    '<section class="nhs-section"><h2>How to read this report</h2>',
    bullet_list(items),
    '</section>'
  )
}

build_commentary_card <- function(title, flag, flag_class, dl_pairs) {
  dl_html <- paste(vapply(names(dl_pairs), function(nm) {
    val <- dl_pairs[[nm]]
    paste0("<dt>", esc(nm), "</dt><dd>", esc(paste(as.character(val), collapse = " ")), "</dd>")
  }, character(1)), collapse = "")
  paste0(
    '<article class="nhs-metric-card">',
    '<p class="nhs-metric-card-title"><strong>', esc(title), '</strong> ',
    nof_agent_flag_badge(flag, flag_class), '</p>',
    '<dl>', dl_html, '</dl></article>'
  )
}

measure_commentary_section <- function(cards, intro = NULL) {
  intro_text <- intro %||%
    "Concise first-draft notes on selected measures or themes. These are agent prompts for human review — not approved performance conclusions."
  paste0(
    '<section class="nhs-section"><h2>Agent commentary on selected measures</h2>',
    '<p>', intro_text, '</p>',
    '<div class="nhs-metric-commentary">', paste(cards, collapse = "\n"), '</div>',
    '</section>'
  )
}

theme_commentary_section <- function(cards, intro = NULL) {
  intro_text <- intro %||%
    "Concise first-draft notes by assurance source or theme. Appropriate use and limits — not performance scores."
  paste0(
    '<section class="nhs-section"><h2>Agent commentary on selected measures</h2>',
    '<p>', intro_text, '</p>',
    '<div class="nhs-metric-commentary">', paste(cards, collapse = "\n"), '</div>',
    '</section>'
  )
}

bp_questions_html <- function(questions) {
  if (is.null(questions) || length(questions) == 0) return("")
  if (is.list(questions[[1]]) && !is.null(questions[[1]]$q)) {
    items <- vapply(questions, function(x) {
      paste0(
        "<li><strong>", esc(x$q), "</strong>",
        '<p class="nhs-bp-expl">', esc(x$expl), "</p></li>"
      )
    }, character(1))
    paste0('<ul class="nhs-list-compact nhs-bp-questions">', paste(items, collapse = ""), "</ul>")
  } else {
    bullet_list(unlist(questions))
  }
}

standard_bp_questions <- function() {
  list(
    list(
      q = "Is this the same definition used locally?",
      expl = paste(
        "Public datasets may use national definitions. Local dashboards may use different filters,",
        "denominators or reporting dates."
      )
    ),
    list(
      q = "Is this still the latest position?",
      expl = paste(
        "Public data may be a delayed publication. Local operational data may have moved on",
        "since the reporting period shown."
      )
    ),
    list(
      q = "Who owns the narrative?",
      expl = paste(
        "The accountable service, finance, workforce, quality or BI owner should confirm",
        "the explanation before the finding is used."
      )
    ),
    list(
      q = "Is this a performance issue, a data quality issue, or a service model issue?",
      expl = paste(
        "A public figure can be affected by coding, exclusions, small numbers, local pathways",
        "or publication rules."
      )
    )
  )
}

agent_brief_sections <- function(config, key_figures_html, verify_body_html,
                               after_key_figures_html = "") {
  paste0(
    '<section class="nhs-section"><h2>What this report demonstrates</h2>',
    '<div class="nhs-agent-box">', config$demonstrates, '</div></section>',
    '<section class="nhs-section"><h2>The question given to the agent</h2>',
    '<p>', esc(config$question), '</p></section>',
    '<section class="nhs-section"><h2>Prompt excerpt</h2>',
    agent_prompt_box(config$prompt_excerpt), '</section>',
    '<section class="nhs-section"><h2>Data used</h2>',
    config$data_used_html,
    '<p>', esc(config$period), '</p>',
    '<p>', RDY_FILTER_SHORT, '</p></section>',
    '<section class="nhs-section"><h2>Agent process demonstrated</h2>',
    agent_process_box(config$process_steps), '</section>',
    key_figures_section(key_figures_html),
    after_key_figures_html,
    first_draft_analysis(config$first_draft_paragraphs),
    '<section class="nhs-section"><h2>Agent-generated observations</h2>',
    bullet_list(config$observations), '</section>',
    '<section class="nhs-section"><h2>What cannot be concluded from this data</h2>',
    cannot_conclude_box(config$cannot_conclude), '</section>',
    '<section class="nhs-section"><h2>Questions for a Business &amp; Performance Partner</h2>',
    bp_questions_html(config$bp_questions), '</section>',
    verify_section(config$verify_intro %||% verify_intro_std, verify_body_html),
    human_review_warning()
  )
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x

write_public_report <- function(filename, title, subtitle, body) {
  html <- paste0(
    '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<title>', esc(title), '</title>',
    '<link rel="stylesheet" href="../assets/styles.css">',
    '<link rel="stylesheet" href="../assets/nhs-report.css">',
    '</head><body class="nhs-report">',
    '<a href="#main-content" class="skip-link">Skip to main content</a>',
    '<div class="nhs-report-nav"><a href="../draft-reports.html">&larr; All reports</a>',
    '<a href="../agent-operating-model.html">Agent operating model</a>',
    '<a href="../public-data/PUBLIC_REPORTS_METHOD.md">Report method</a></div>',
    '<header class="nhs-report-header"><p class="report-meta">', REPORT_BADGE_META, '</p>',
    '<h1>', esc(title), '</h1><p class="report-meta">', esc(subtitle), '</p></header>',
    '<main id="main-content" class="nhs-report-main">',
    std_caveat, body,
    '<p><a href="../draft-reports.html">&larr; Back to draft reports</a></p>',
    '</main>',
    '<footer class="nhs-report-footer"><p><strong>Human review required.</strong> ',
    'Public-data demonstration only. Not an official Dorset HealthCare report. ',
    'Not NHS-endorsed. No patient-identifiable information.</p>',
    '<p style="margin-top:0.75rem;opacity:0.85;">Regenerate: Rscript site/R/03_render_public_reports.R</p>',
    '</footer><script src="../assets/site.js"></script></body></html>'
  )
  writeLines(html, file.path(reports_dir, filename), useBytes = TRUE)
  cat("Written:", filename, "\n")
}

# --- A. Public performance overview (NOF) ------------------------------------

build_performance_overview <- function() {
  nof_full <- load_nof_full_rdy()
  nof_demo <- load_demo("demo_nof_overview.csv", required = TRUE)
  nof_raw <- load_nof_raw()
  reg_row <- read_register_row("nof_mh_community")
  assurance <- load_demo("demo_assurance_profile.csv")

  if (is.null(nof_full) && is.null(nof_demo)) {
    write_public_report(
      "public-performance-overview.html",
      "Dorset HealthCare Public Performance Overview",
      "Source data not available",
      '<section class="nhs-section"><h2>Data availability</h2><p><code>demo_nof_overview.csv</code> was not found. Run the public-data pipeline first.</p></section>'
    )
    return(invisible(NULL))
  }

  nof <- if (!is.null(nof_full)) nof_full else nof_demo
  latest_q <- nof_latest_quarter(nof)

  display <- nof[
    trimws(nof$Quarter) == latest_q &
      vapply(nof$Metric_ID, is_nof_raw_metric, logical(1)) &
      !is.na(to_num(nof$Value)),
    ,
    drop = FALSE
  ]
  display$Value_num <- to_num(display$Value)
  display$Rank_num <- to_num(display$Rank)

  ranked <- display[!is.na(display$Rank_num), , drop = FALSE]
  rank_table <- ranked[order(ranked$Rank_num), c(
    "Quarter", "Metric_ID", "Metric_description", "Domain", "Value", "Median_value", "Rank"
  )]
  audit_source <- ranked[order(ranked$Rank_num), , drop = FALSE]

  n_metrics <- nrow(display)
  n_domains <- length(unique(display$Domain))
  avg_rank <- if (nrow(ranked) > 0) round(mean(ranked$Rank_num), 1) else NA

  domain_summary <- aggregate(Value_num ~ Domain, display, function(x) length(x))
  names(domain_summary) <- c("Domain", "Metric_count")

  audit_df <- build_nof_audit_df(audit_source, nof_raw, reg_row)
  write_nof_audit_csv(audit_df)
  write_nof_audit_md(audit_df, latest_q)

  raw_paths <- split_register_paths(if (!is.null(reg_row)) reg_row$downloaded_file_path else "")
  raw_data_path <- raw_paths[grepl("-data\\.csv", raw_paths, ignore.case = TRUE)][1]
  if (length(raw_data_path) == 0 || is.na(raw_data_path)) raw_data_path <- raw_paths[1]
  raw_display <- path_for_display(raw_data_path)
  raw_url <- if (!is.null(reg_row)) reg_row$source_url else ""

  kpis <- list(
    list(value = n_metrics, label = paste("Raw NOF metrics,", latest_q)),
    list(value = n_domains, label = "Performance domains"),
    list(value = if (is.na(avg_rank)) "—" else avg_rank, label = "Mean published rank (where ranked)"),
    list(value = nrow(ranked), label = "Metrics with published rank")
  )

  assurance_html <- if (!is.null(assurance)) {
    html_table(assurance[, c("source", "label", "rdy_rows")])
  } else {
    "<p><em>Assurance summary not available.</em></p>"
  }

  period_text <- paste(latest_q, "raw metrics (OF0xxx); reporting dates vary by metric (see Reporting_date column).")

  key_figures <- paste0(
    kpi_row(kpis),
    '<p><em>Mean published rank uses NHS England Rank column — not recomputed. See &ldquo;How to read this table&rdquo; below for column definitions.</em></p>',
    '<h3>Metrics by domain (', esc(latest_q), ')</h3>', html_table(domain_summary),
    nof_how_to_read_table(),
    '<h3>Raw NOF metrics with NHS England published rank and peer median (', esc(latest_q), ')</h3>',
    html_table(rank_table, 50)
  )

  commentary_html <- nof_metric_commentary_section(audit_source)

  config <- list(
    demonstrates = paste0(
      '<p>Turning a public NHS Oversight Framework CSV into a cautious first-draft performance brief ',
      'with published peer median and rank — explaining what each metric may mean in plain English, ',
      'what the agent would flag, and what a human must verify — without recalculating league tables.</p>'
    ),
    question = paste(
      "Using the latest public NHS Oversight Framework file for mental health and community trusts,",
      "prepare a first-draft RDY performance brief: which raw metrics exist for Dorset HealthCare,",
      "what do published median/rank fields show, and what must a human verify before any operational use?"
    ),
    prompt_excerpt = paste(
      "Locate NHS England NOF MH/community trust CSV. Filter Trust_code=RDY.",
      "Use latest quarter raw metrics (OF0xxx) only. Do not recalculate median or rank.",
      "Summarise domains and ranked metrics descriptively. Add plain-English commentary per metric.",
      "Flag rank-direction uncertainty. No causal claims. Include verification paths to raw rows.",
      sep = "\n"
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>NHS Oversight Framework MH/community CSVs (<code>demo_nof_overview.csv</code> + full RDY processed extract)</li>',
      '<li>Assurance index (<code>demo_assurance_profile.csv</code>) where available</li>',
      '<li>Official NOF technical metric specification (linked — not bulk-downloaded in pipeline): ',
      '<a href="', NOF_METRIC_SPEC_URL, '" rel="noopener">NHS England NOF CSV metadata / metric definitions</a></li>',
      '</ul>'
    ),
    period = period_text,
    process_steps = c(
      "Look up NOF source in DATA_SOURCE_REGISTER.csv",
      "Filter processed extract to Trust_code=RDY",
      "Select latest quarter and raw value metrics (OF0xxx) only",
      "Apply descriptive summaries — counts by domain, ranked metric table",
      "Draft plain-English commentary per metric with agent flags and human-check prompts",
      "Pass median/rank through unchanged from NHS England published fields",
      "Document verification paths in audit CSV/MD for human review"
    ),
    first_draft_paragraphs = c(
      paste0(
        "Across ", latest_q, ", the agent identified ", n_metrics,
        " raw NOF metrics spanning ", n_domains, " domains. ",
        "Several metrics show relatively strong published ranks — notably OF0005 (community 52-week waits, rank 1) ",
        "and OF0079 (planned surplus/deficit, rank 1) — but even these are flagged as potential strengths pending definition and finance-owner confirmation, not as final conclusions."
      ),
      paste0(
        "The agent would flag for local review metrics where RDY sits below the peer median on access or long-stay measures: ",
        "OF0063 (>60-day inpatient length of stay), OF0057 (urgent community response 2-hour performance), ",
        "OF0016 (crisis face-to-face within 24 hours) and OF0086 (relative difference in costs). ",
        "OF0082 (sickness absence) appears below the peer median and may be a relative strength, subject to workforce context."
      ),
      "Finance and productivity metrics (OF0079, OF0081, OF0086) require finance-owner interpretation — the agent does not assume positive or negative meaning without the official definition. Staff survey metrics (OF0061, OF0084) need methodology checks before interpreting small differences.",
      "Overall, this public snapshot is a prompt for structured questions to service, finance and workforce owners — not a basis for operational decisions without local validation."
    ),
    observations = c(
      paste0("RDY metrics in ", latest_q, " span access, patient safety, workforce, finance and effectiveness domains."),
      "Value, median and rank are NHS England published fields — not recalculated in this demo.",
      "Metric polarity and definitions must be confirmed against the official NHS England NOF technical metric specification (linked under Data used) before operational use."
    ),
    cannot_conclude = c(
      "Why performance changed or what operational action is needed",
      "Whether rank implies favourable or unfavourable performance without checking NHS England metric polarity",
      "That demo_nof_overview.csv is complete — it is a truncated convenience sample (first 50 RDY rows)",
      "Statistical significance of rank or median differences",
      "Finance surplus/deficit or cost index meaning without finance-owner confirmation"
    ),
    bp_questions = c(
      "Is this metric already being reported locally? Check whether the same metric appears in the Trust board pack, quality report, directorate pack or service performance meeting.",
      "Are we using the same definition locally? Public NOF values may use national definitions. Local dashboards may use different filters, reporting dates or denominators.",
      "Is this the latest position? NOF is a published snapshot. Local operational data may have moved on since the publication period.",
      "Does the relative position reflect real performance, data quality or service model? A weaker relative position may reflect operational pressure, coding or data quality issues, small numbers, exclusions, or differences in how services are configured.",
      "Who owns the narrative? The accountable service, finance, workforce or BI owner should confirm the explanation before the finding is used in any report."
    )
  )

  verify_body <- nof_audit_verify_body(audit_df, raw_display, raw_url)

  body <- paste0(
    agent_brief_sections(config, key_figures, verify_body, commentary_html),
    '<section class="nhs-section"><h2>Related assurance sources index</h2>', assurance_html, '</section>'
  )

  write_public_report(
    "public-performance-overview.html",
    "Worked example: AI-assisted analysis of NHS Oversight Framework data",
    paste("NHS Oversight Framework — RDY first-draft brief (", latest_q, ")", sep = ""),
    body
  )
}

# --- B. Mental health access profile (MHSDS) ---------------------------------

build_mh_profile <- function() {
  mh <- load_demo("demo_mhsds_activity.csv", required = TRUE)
  if (is.null(mh)) {
    write_public_report("public-mh-access-profile.html", "Public Mental Health Access Profile",
      "Source data not available", '<section class="nhs-section"><p>Missing demo_mhsds_activity.csv</p></section>')
    return(invisible(NULL))
  }

  period <- paste(unique(mh$REPORTING_PERIOD_START), unique(mh$REPORTING_PERIOD_END), sep = " to ")
  prov <- mh[grepl("^RDY$", trimws(mh$SECONDARY_LEVEL)) | grepl("^RDY$", trimws(mh$PRIMARY_LEVEL)), , drop = FALSE]
  if (nrow(prov) == 0) prov <- mh

  vals <- prov$MEASURE_VALUE
  n_supp <- sum(is_suppressed(vals))
  n_numeric <- sum(!is_suppressed(vals))
  prov$MV <- to_num(prov$MEASURE_VALUE)

  prov_provider <- mh[trimws(mh$PRIMARY_LEVEL) == "RDY" & trimws(mh$BREAKDOWN) == "Provider", , drop = FALSE]
  get_prov_val <- function(mid) {
    row <- prov_provider[trimws(prov_provider$MEASURE_ID) == mid, , drop = FALSE]
    if (nrow(row) == 0) return(list(raw = NA, num = NA))
    list(raw = row$MEASURE_VALUE[1], num = to_num(row$MEASURE_VALUE[1]))
  }

  mhs23 <- get_prov_val("MHS23")
  mhs01 <- get_prov_val("MHS01")
  mhs29 <- get_prov_val("MHS29")
  mhs69 <- get_prov_val("MHS69")
  cyp32a <- get_prov_val("CYP32a")

  numeric_rows <- prov[!is.na(prov$MV), , drop = FALSE]
  top_measures <- numeric_rows[order(-numeric_rows$MV), c("MEASURE_ID", "MEASURE_NAME", "MEASURE_VALUE", "BREAKDOWN")]
  if (nrow(top_measures) > 10) top_measures <- top_measures[seq_len(10), , drop = FALSE]

  ref_src <- numeric_rows[grepl("Referral", numeric_rows$MEASURE_NAME, ignore.case = TRUE), ]
  ref_total <- if (nrow(ref_src) > 0) sum(ref_src$MV, na.rm = TRUE) else NA

  chart_labels <- if (nrow(top_measures) > 0) {
    paste0(top_measures$MEASURE_ID, ": ", substr(top_measures$MEASURE_NAME, 1, 40))
  } else {
    character()
  }
  chart_vals <- if (nrow(top_measures) > 0) top_measures$MV else numeric()

  kpis <- list(
    list(value = nrow(prov), label = "RDY measure rows"),
    list(value = n_numeric, label = "Numeric values"),
    list(value = n_supp, label = "Suppressed (*)"),
    list(value = if (is.na(ref_total)) "—" else format(ref_total, big.mark = ","), label = "Referral-related counts (sum)")
  )

  key_figures <- paste0(
    kpi_row(kpis),
    '<h3>Top numeric measures (single period — provider and breakdown rows)</h3>', html_table(top_measures, 10),
    bar_chart(chart_labels, chart_vals, "Largest numeric MHSDS values (RDY rows)")
  )

  mhsds_ts <- load_mhsds_time_series()
  ts_file_note <- if (!is.null(mhsds_ts)) {
    basename(list.files(processed_dir, pattern = "^rdy_mhsds_monthly.*time_series.*Apr2025.*Perf_2026.*\\.csv$")[1])
  } else {
    "No MHSDS time-series file in processed/"
  }

  trend_mhs01 <- compute_period_trend(extract_mhsds_rdy_ts(mhsds_ts, "MHS01"), "MHS01 — people in contact at end of RP")
  trend_mhs29 <- compute_period_trend(extract_mhsds_rdy_ts(mhsds_ts, "MHS29"), "MHS29 — contacts in reporting period")
  trend_mhs69 <- compute_period_trend(extract_mhsds_rdy_ts(mhsds_ts, "MHS69"), "MHS69 — CYP with two contacts (before 18th birthday)")

  fmt_val <- function(v) {
    if (is.na(v$num)) if (is_suppressed(v$raw)) "*" else "—" else format(v$num, big.mark = ",")
  }

  trend_note_mhs23 <- "MHS23 (open referrals) is not present in the Provider time-series extract — trend not shown for this measure."
  trend_line <- function(t) {
    if (isTRUE(t$available)) {
      paste0(
        "Latest vs previous month: ",
        format(t$latest_value, big.mark = ","), " (", t$latest_period, ") vs ",
        format(t$previous_value, big.mark = ","), " (", t$previous_period, ")"
      )
    } else {
      "Trend not available from current extract"
    }
  }

  commentary_cards <- c(
    build_commentary_card(
      "MHS23 — Open referrals at end of reporting period",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Count of people with an open referral to mental health services at the last day of the month.",
        "Latest value (provider row)" = paste0(fmt_val(mhs23), " for ", period),
        "Comparator / trend" = paste0(trend_note_mhs23, " Demo table shows a single month only for this measure."),
        "Agent flag" = "Review locally",
        "Cautious interpretation" = paste0(
          "Open referrals are a caseload-style stock measure, not new demand. ",
          "The agent would not treat ", fmt_val(mhs23), " as a headline access KPI without confirming ",
          "which open referrals are in scope (adult, CYP, LDA) and whether local PAS figures align."
        ),
        "Human check required" = "MHSDS/data owner to confirm open-referral definition, reporting period and alignment with local caseload reporting."
      )
    ),
    build_commentary_card(
      "MHS01 — People in contact with services at end of reporting period",
      if (isTRUE(trend_mhs01$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(trend_mhs01$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "People actively in contact with MH services at month end — a broad in-contact caseload measure.",
        "Latest value (provider row)" = paste0(fmt_val(mhs01), " (demo month); time series latest: ",
                                               if (isTRUE(trend_mhs01$available)) format(trend_mhs01$latest_value, big.mark = ",") else "n/a"),
        "Comparator / trend" = trend_line(trend_mhs01),
        "Agent flag" = if (isTRUE(trend_mhs01$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = paste0(
          "Month-on-month movement in in-contact counts may reflect activity, discharge, coding or submission timing — ",
          "the agent describes change only, not cause. ",
          if (isTRUE(trend_mhs01$available) && !is.na(trend_mhs01$percent_change)) {
            paste0("Latest month-on-month change: ", if (trend_mhs01$absolute_change >= 0) "+" else "",
                   format(trend_mhs01$absolute_change, big.mark = ","),
                   " (", if (trend_mhs01$percent_change >= 0) "+" else "", trend_mhs01$percent_change, "%).")
          } else {
            ""
          }
        ),
        "Human check required" = "Confirm whether local in-contact definition matches MHSDS and whether provisional month has refreshed."
      )
    ),
    build_commentary_card(
      "MHS29 — Contacts in reporting period",
      if (isTRUE(trend_mhs29$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(trend_mhs29$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "Total care contacts recorded in the month — activity volume, not unique patients.",
        "Latest value (provider row)" = if (is.na(mhs29$num)) "Not in demo provider slice — see time series" else fmt_val(mhs29),
        "Comparator / trend" = trend_line(trend_mhs29),
        "Agent flag" = if (isTRUE(trend_mhs29$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = "Contacts can rise with intensity of support, telehealth counting, or data quality — not automatically 'good' or 'bad' access.",
        "Human check required" = "Service/BI owner to confirm contact counting rules and whether month-on-month change matches operational narrative."
      )
    ),
    build_commentary_card(
      "MHS69 — CYP with at least two contacts",
      if (isTRUE(trend_mhs69$available)) "Review locally" else "Trend not available",
      if (isTRUE(trend_mhs69$available)) "review" else "definition",
      list(
        "Plain-English meaning" = "Children and young people receiving at least two contacts where first contact was before 18th birthday.",
        "Latest value" = paste0("Demo ICB-resident rows include suppression; provider time-series latest: ",
                                if (isTRUE(trend_mhs69$available)) format(trend_mhs69$latest_value, big.mark = ",") else "n/a"),
        "Comparator / trend" = trend_line(trend_mhs69),
        "Agent flag" = "Review locally",
        "Cautious interpretation" = paste0(
          n_supp, " suppressed cells in the demo extract — do not infer CYP access for all ICBs. ",
          "Dorset ICB (11J) resident row may differ from provider totals."
        ),
        "Human check required" = "CYP mental health lead to confirm resident vs provider scope and whether suppressed cells are material."
      )
    ),
    build_commentary_card(
      "CYP32a — CYP referrals starting in reporting period",
      "Definition check required", "definition",
      list(
        "Plain-English meaning" = "New referrals to CYP mental health services starting in the month.",
        "Latest value (provider row)" = paste0(fmt_val(cyp32a), " for ", period),
        "Comparator / trend" = "Single month in demo extract; not in Provider time-series file used here.",
        "Agent flag" = "Definition check required",
        "Cautious interpretation" = "Referral counts are flow measures — compare only with consistent referral-source breakdowns, not summed across incompatible rows.",
        "Human check required" = "Confirm referral source breakdown (primary care, self, LA, etc.) matches local access reporting."
      )
    ),
    build_commentary_card(
      "Suppression and breakdown mixing",
      "Watch / clarify", "watch",
      list(
        "Plain-English meaning" = paste0(n_supp, " of ", nrow(prov), " RDY rows show '*' — small numbers withheld under disclosure rules."),
        "Latest value" = paste0(n_numeric, " numeric values published in this extract"),
        "Comparator / trend" = "Suppression may differ by month — check each period separately.",
        "Agent flag" = "Watch / clarify",
        "Cautious interpretation" = paste0(
          "Provider-level and ICB-resident breakdowns coexist. Summing referral-related rows (",
          if (is.na(ref_total)) "n/a" else format(ref_total, big.mark = ","),
          ") is not a valid trust-wide headline."
        ),
        "Human check required" = "Identify which suppressed measures matter for Dorset ICB (11J) and whether local validation fills gaps."
      )
    )
  )

  how_to_read <- how_to_read_section(c(
    "Each row is one MHSDS measure for RDY with a specific breakdown (Provider, ICB-resident, referral source, etc.).",
    paste0("MEASURE_VALUE is the published count or rate for ", period, ". '*' means suppressed (small numbers)."),
    "Provider rows (PRIMARY_LEVEL=RDY, BREAKDOWN=Provider) are trust-as-provider counts; ICB-resident rows describe people registered in an ICB area.",
    "You cannot sum rows across different breakdowns to produce a single trust-wide KPI.",
    "Monthly MHSDS is typically provisional until end-of-year refresh — confirm publication status before use.",
    "This brief is a worked example using public aggregate data — not official Dorset HealthCare reporting."
  ))

  after_key <- paste0(
    how_to_read,
    measure_commentary_section(commentary_cards),
    trend_section(
      list(trend_mhs01, trend_mhs29, trend_mhs69),
      ts_file_note,
      c(
        "MHSDS monthly data are provisional; months may revise on final refresh.",
        "Missing months in the time series (e.g. August 2025 absent for MHS01) should not be interpolated.",
        "Trend labels describe direction of change only — not operational cause."
      )
    )
  )

  ref_obs <- if (!is.na(ref_total)) {
    paste0("Referral-related numeric rows sum to ", format(ref_total, big.mark = ","), " across breakdowns — not a single headline referral count.")
  } else {
    "Referral-related totals were not computed as a single headline figure."
  }

  bp_extra <- list(
    list(
      q = "Which MHSDS measures map to local directorate access KPIs?",
      expl = "Public measure IDs may not match local dashboard names — confirm mapping with the MHSDS/data owner."
    ),
    list(
      q = "Are suppressed cells material for Dorset ICB (11J) residents?",
      expl = paste0(n_supp, " suppressed values in this extract — check whether key access measures are affected for your ICB scope.")
    )
  )

  config <- list(
    demonstrates = paste0(
      '<p>Summarising mental health access and activity from public MHSDS data with plain-English measure commentary, ',
      'agent flags, and descriptive monthly trends where a downloaded time-series extract exists — ',
      'not an operational access dashboard.</p>'
    ),
    question = paste(
      "From public MHSDS data for RDY, explain what key access and activity measures mean,",
      "what the agent noticed (including suppression and breakdown limits),",
      "where month-on-month trends are supported by the downloaded time series,",
      "and what a mental health data owner must confirm before use."
    ),
    prompt_excerpt = paste(
      "Filter provider RDY from MHSDS monthly CSV.",
      "Add plain-English commentary for MHS23, MHS01, MHS29, MHS69, CYP32a and suppression.",
      "Compute trends only from downloaded time-series file (Provider breakdown).",
      "Do not sum incompatible breakdowns. No causal claims.",
      sep = "\n"
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>MHSDS Monthly Statistics (<code>demo_mhsds_activity.csv</code> — latest month slice)</li>',
      if (!is.null(mhsds_ts)) paste0('<li>MHSDS time series (<code>', esc(ts_file_note), '</code> — Apr 2025–Mar 2026 performance v2)</li>') else "",
      '</ul>'
    ),
    period = period,
    process_steps = c(
      "Locate MHSDS publication in DATA_SOURCE_REGISTER.csv",
      "Filter demo extract to RDY provider and breakdown rows",
      "Count numeric vs suppressed values; identify top measures for one period",
      "Draft plain-English commentary cards with agent flags",
      "Load time-series extract; compute latest vs previous month for Provider RDY measures where ≥2 periods exist",
      "Link to filter and inspection notes for verification"
    ),
    first_draft_paragraphs = c(
      paste0(
        "For ", period, ", the public MHSDS extract contains ", nrow(prov), " RDY measure rows (", n_numeric, " numeric, ",
        n_supp, " suppressed). Provider-level open referrals (MHS23) show ", fmt_val(mhs23),
        " — a stock measure the agent would route to the MHSDS owner before any performance use."
      ),
      if (isTRUE(trend_mhs01$available)) {
        paste0(
          "The downloaded time series (11 Provider months for MHS01) shows in-contact counts rising from ",
          format(trend_mhs01$previous_value, big.mark = ","), " (", trend_mhs01$previous_period, ") to ",
          format(trend_mhs01$latest_value, big.mark = ","), " (", trend_mhs01$latest_period,
          ") — descriptive only; the agent would not infer cause without local pathway context."
        )
      } else {
        "No comparable multi-period Provider time series was available for trend analysis in this extract."
      },
      paste0(ref_obs, " This first draft supports scoping questions for local MHSDS validation, not directorate performance conclusions.")
    ),
    observations = c(
      "Provider-level rows exist but ICB-resident and referral-source breakdowns also appear — not all rows are trust-wide totals.",
      ref_obs,
      if (isTRUE(trend_mhs01$available)) paste0("MHS01 in-contact trend available across ", trend_mhs01$n_periods, " months in time-series extract.") else "MHS01 trend not computed — insufficient periods in extract.",
      "MHS23 open referrals not in Provider time-series file — single-month demo value only.",
      "Monthly MHSDS data are typically provisional until end-of-year refresh."
    ),
    cannot_conclude = c(
      "Operational cause of access or caseload changes without local pathway and PAS context",
      "A single trust-wide referral or caseload total from summed breakdown rows",
      "ICB-resident vs provider comparability without local definition checks",
      "Clinical quality or pathway performance from activity counts alone",
      "That month-on-month movement in MHS01/MHS29 implies demand, capacity or performance without owner confirmation"
    ),
    bp_questions = c(standard_bp_questions(), bp_extra)
  )

  verify_body <- traceability_verify_body(
    "Figures trace to the demo MHSDS CSV, RDY-filtered processed extract and time-series file where cited. No derived ranks or peer medians are computed in this brief.",
    c("demo_mhsds_activity.csv", if (!is.null(mhsds_ts)) ts_file_note else NULL),
    "mhsds_monthly",
    "mhsds_monthly"
  )

  body <- agent_brief_sections(config, key_figures, verify_body, after_key)

  write_public_report("public-mh-access-profile.html",
    "Worked example: AI-assisted MHSDS public-data briefing",
    "MHSDS — RDY provider measures (provisional public data)", body)
}

# --- C. Community services (CSDS) --------------------------------------------

build_csds_profile <- function() {
  csds <- load_demo("demo_csds_activity.csv", required = TRUE)
  if (is.null(csds)) {
    write_public_report("public-community-services-profile.html", "Public Community Services Profile",
      "Source data not available", '<section class="nhs-section"><p>Missing demo_csds_activity.csv</p></section>')
    return(invisible(NULL))
  }

  period <- paste(unique(csds$REPORTING_PERIOD_START), "to", unique(csds$REPORTING_PERIOD_END))
  activity <- csds[csds$COUNT_OF == "CareActivities" & csds$DIMENSION == "ActivityType", , drop = FALSE]
  activity$MV <- to_num(activity$MEASURE_VALUE)

  act_summary <- activity[!is.na(activity$MV), c("MEASURE_DESC", "MEASURE_VALUE", "MEASURE_VALUE_0_18", "MEASURE_VALUE_19_64", "MEASURE_VALUE_65_PLUS")]
  act_summary <- act_summary[order(-to_num(act_summary$MEASURE_VALUE)), ]
  if (nrow(act_summary) > 10) act_summary <- act_summary[seq_len(10), , drop = FALSE]

  total_contacts <- sum(activity$MV, na.rm = TRUE)
  n_rows <- nrow(csds)
  n_periods <- length(unique(csds$REPORTING_PERIOD_START))

  get_act <- function(desc) {
    row <- activity[activity$MEASURE_DESC == desc, , drop = FALSE]
    if (nrow(row) == 0) return(NA)
    row$MV[1]
  }
  assess_n <- get_act("Assessment")
  clin_n <- get_act("Clinical Intervention")

  kpis <- list(
    list(value = format(total_contacts, big.mark = ","), label = "Care activity total (Mar 2026)"),
    list(value = nrow(activity), label = "Activity type rows"),
    list(value = n_rows, label = "Total RDY rows in extract"),
    list(value = "March 2026", label = "Publication month")
  )

  key_figures <- paste0(
    kpi_row(kpis),
    '<h3>Care activities by type</h3>', html_table(act_summary, 10),
    bar_chart(act_summary$MEASURE_DESC, to_num(act_summary$MEASURE_VALUE), "Care activities by type (RDY)")
  )

  commentary_cards <- c(
    build_commentary_card(
      "Care activities — Assessment",
      if (is.na(assess_n) || assess_n == 0) "Watch / clarify" else "Review locally",
      if (is.na(assess_n) || assess_n == 0) "watch" else "review",
      list(
        "Plain-English meaning" = "Count of assessment-type care activities recorded in CSDS for the month.",
        "Latest value" = if (is.na(assess_n)) "—" else format(assess_n, big.mark = ","),
        "Comparator / trend" = "Single month (March 2026) in current extract — trend not available.",
        "Agent flag" = if (is.na(assess_n) || assess_n == 0) "Watch / clarify" else "Review locally",
        "Cautious interpretation" = "Activity counts reflect coded CSDS submissions — not unique patients or completed care pathways.",
        "Human check required" = "Community services/BI owner to confirm activity coding and whether this matches local community dashboards."
      )
    ),
    build_commentary_card(
      "Care activities — Clinical Intervention",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Direct clinical intervention activities in community services for the month.",
        "Latest value" = if (is.na(clin_n)) "—" else format(clin_n, big.mark = ","),
        "Comparator / trend" = "Single month only — period-on-period change requires additional monthly downloads.",
        "Agent flag" = "Review locally",
        "Cautious interpretation" = paste0(
          "Clinical intervention (", if (is.na(clin_n)) "n/a" else format(clin_n, big.mark = ","),
          ") is the largest activity type where numeric — confirm service scope (community vs specialist) locally."
        ),
        "Human check required" = "Directorate lead to confirm which services feed this measure and coding QA for March 2026."
      )
    ),
    build_commentary_card(
      "Age-band columns (0–18, 19–64, 65+)",
      "Definition check required", "definition",
      list(
        "Plain-English meaning" = "Published splits of the same activity count by broad age band where supplied.",
        "Latest value" = "See table — e.g. assessment 65+ may include health visitor activity in CYP bands",
        "Comparator / trend" = "Trend not available from current extract.",
        "Agent flag" = "Definition check required",
        "Cautious interpretation" = "Age splits help directorate review but may not match local age definitions or service lines.",
        "Human check required" = "Validate CYP vs adult splits with the CSDS return owner before directorate use."
      )
    ),
    build_commentary_card(
      "Public aggregate CSDS limits",
      "Source validation only", "definition",
      list(
        "Plain-English meaning" = paste0(n_rows, " RDY rows in demo extract; ", n_periods, " reporting period(s) downloaded."),
        "Latest value" = paste0("Total care activities summed: ", format(total_contacts, big.mark = ",")),
        "Comparator / trend" = "Trend not available — only one month in processed extract.",
        "Agent flag" = "Source validation only",
        "Cautious interpretation" = "Public CSDS aggregates cannot support team-level or pathway conclusions without local drill-down.",
        "Human check required" = "Confirm full RDY processed extract contains all measures needed — demo slice may not surface every row."
      )
    )
  )

  how_to_read <- how_to_read_section(c(
    "Each row is a CSDS measure for RDY as provider for March 2026 (single month in current extract).",
    "This report filters to DIMENSION=ActivityType and MEASURE=CareActivities — other CSDS dimensions are not shown.",
    "MEASURE_DESC describes the activity type (e.g. Assessment, Clinical Intervention); MEASURE_VALUE is the count.",
    "Age-band columns split the same count where published — they are not additional unique patients.",
    "Public aggregate CSDS cannot prove referral demand, waiting times or team performance without local context.",
    "This brief is a worked example — not official Dorset HealthCare reporting."
  ))

  after_key <- paste0(
    how_to_read,
    measure_commentary_section(commentary_cards),
    trend_not_available_section(c(
      "Additional monthly CSDS public files for consecutive months",
      "Consistent measure and ActivityType filters across periods",
      "Local owner confirmation that coding definitions are unchanged between months"
    ))
  )

  config <- list(
    demonstrates = paste0(
      '<p>Turning public CSDS community services data into a structured briefing with plain-English activity commentary, ',
      'honest single-month limits, and agent flags — not a directorate performance dashboard.</p>'
    ),
    question = paste(
      "Using public CSDS for March 2026, explain community activity measures in plain English,",
      "what the agent noticed, why trend analysis is not available from the current extract,",
      "and what a business partner should validate locally."
    ),
    prompt_excerpt = paste(
      "Filter CSDS monthly CSV to RDY. Inspect CareActivities by ActivityType.",
      "Add commentary cards for assessment, clinical intervention, age bands and aggregate limits.",
      "State trend not available — single month only. No causal language.",
      sep = "\n"
    ),
    data_used_html = '<ul class="nhs-list-compact"><li>CSDS Monthly Statistics (<code>demo_csds_activity.csv</code> — March 2026 only)</li></ul>',
    period = period,
    process_steps = c(
      "Locate CSDS publication and filter to RDY rows",
      "Identify CareActivities / ActivityType dimension rows",
      "Sum numeric activity; prepare age-band columns where published",
      "Draft plain-English commentary with agent flags",
      "Document single-month limitation — no trend without additional downloads",
      "Link demo CSV and filter notes for verification"
    ),
    first_draft_paragraphs = c(
      paste0(
        "For ", period, ", the public CSDS extract contains ", n_rows, " RDY rows. ",
        "Care activity totals in the ActivityType slice sum to ", format(total_contacts, big.mark = ","), "."
      ),
      if (total_contacts > 0) {
        paste0(
          "Assessment (", if (is.na(assess_n)) "n/a" else format(assess_n, big.mark = ","),
          ") and clinical intervention (", if (is.na(clin_n)) "n/a" else format(clin_n, big.mark = ","),
          ") dominate numeric activity — the agent would ask the community services owner to confirm coding and service scope before any review use."
        )
      } else {
        "Sparse or zero numeric activity in this demo slice is itself a valid finding — extract scope and coding must be confirmed locally."
      },
      "Trend analysis is not available: only one reporting month exists in the current processed extract. This is a latest-period public-data brief only."
    ),
    observations = c(
      if (total_contacts > 0) "Clinical intervention and assessment dominate care activities where numeric values exist." else "No numeric care-activity totals in the ActivityType slice — check full extract and local coding.",
      "Health visitor activity may appear in CYP age bands — confirm service scope locally.",
      paste0("Single month (", n_periods, " period) in extract — trend requires additional monthly downloads."),
      "Public aggregate CSDS does not support team-level conclusions."
    ),
    cannot_conclude = c(
      "Activity trends or period-on-period change from one month",
      "Directorate-level performance or operational priorities",
      "Coding quality or submission completeness",
      "Referral demand from activity counts alone",
      "Team or pathway performance from public aggregate rows"
    ),
    bp_questions = c(standard_bp_questions(), list(
      list(
        q = "Which CSDS measures feed local community dashboards?",
        expl = "Public measure codes may differ from local dashboard labels — confirm mapping with the CSDS owner."
      ),
      list(
        q = "What was coding QA status for March 2026?",
        expl = "Activity counts depend on timely, accurate CSDS submissions — check DQ reports before using figures."
      ),
      list(
        q = "Does the full RDY processed extract contain activity rows not in the demo slice?",
        expl = "The demo CSV is a convenience sample — verify against the full processed file if figures look sparse."
      )
    ))
  )

  verify_body <- traceability_verify_body(
    "Figures trace to the demo CSDS CSV and RDY-filtered processed extract. No derived ranks or peer medians are computed in this brief.",
    "demo_csds_activity.csv",
    "csds_monthly"
  )

  body <- agent_brief_sections(config, key_figures, verify_body, after_key)

  write_public_report("public-community-services-profile.html",
    "Worked example: AI-assisted CSDS community services briefing",
    "CSDS — RDY community activity (March 2026)", body)
}

# --- D. Talking Therapies ------------------------------------------------------

build_talking_therapies <- function() {
  tt <- load_demo("demo_talking_therapies.csv", required = TRUE)
  if (is.null(tt)) {
    write_public_report("public-talking-therapies-profile.html", "Public NHS Talking Therapies Profile",
      "Source data not available", '<section class="nhs-section"><p>Missing demo_talking_therapies.csv</p></section>')
    return(invisible(NULL))
  }

  period <- paste(unique(tt$REPORTING_PERIOD_START), "to", unique(tt$REPORTING_PERIOD_END))
  prov <- tt[grepl("^RDY$", trimws(tt$ORG_CODE2)) & trimws(tt$GROUP_TYPE) == "Provider", , drop = FALSE]
  prov$MV <- to_num(prov$MEASURE_VALUE_SUPPRESSED)
  n_supp <- sum(is_suppressed(prov$MEASURE_VALUE_SUPPRESSED))

  access_ids <- c("M001", "M002", "M019", "M020", "M021", "M022")
  access <- prov[prov$MEASURE_ID %in% access_ids, c("MEASURE_ID", "MEASURE_NAME", "MEASURE_VALUE_SUPPRESSED")]
  access$MV <- to_num(access$MEASURE_VALUE_SUPPRESSED)

  refs <- prov[prov$MEASURE_ID == "M001", "MEASURE_VALUE_SUPPRESSED"]
  refs_n <- to_num(refs)[1]
  accessing_n <- to_num(prov[prov$MEASURE_ID == "M031", "MEASURE_VALUE_SUPPRESSED"])[1]

  wait_rows <- prov[prov$MEASURE_ID %in% c("M019", "M020", "M021"), ]
  wait_total <- sum(to_num(wait_rows$MEASURE_VALUE_SUPPRESSED), na.rm = TRUE)

  tt_ts <- load_tt_time_series()
  ts_file_note <- if (!is.null(tt_ts)) {
    basename(list.files(processed_dir, pattern = "^rdy_talking_therapies.*time_series\\.csv$")[1])
  } else {
    "No Talking Therapies time-series file in processed/"
  }

  trend_m001 <- compute_period_trend(extract_tt_rdy_ts(tt_ts, "M001"), "M001 — referrals received")
  trend_m031 <- compute_period_trend(extract_tt_rdy_ts(tt_ts, "M031"), "M031 — people accessing services")
  trend_m053 <- compute_period_trend(extract_tt_rdy_ts(tt_ts, "M053"), "M053 — % accessing within 6 weeks (finished course)")

  trend_line <- function(t) {
    if (isTRUE(t$available)) {
      paste0(
        format(t$latest_value, big.mark = ","), " (", t$latest_period, ") vs ",
        format(t$previous_value, big.mark = ","), " (", t$previous_period, ")"
      )
    } else {
      "Trend not available from current extract"
    }
  }

  kpis <- list(
    list(value = if (is.na(refs_n)) "—" else format(refs_n, big.mark = ","), label = "Referrals received (M001)"),
    list(value = if (is.na(accessing_n)) "—" else format(accessing_n, big.mark = ","), label = "Accessing services (M031)"),
    list(value = if (is.na(wait_total)) "—" else format(wait_total, big.mark = ","), label = "Open referrals no activity (60–120d sum)"),
    list(value = n_supp, label = "Suppressed measures")
  )

  key_figures <- paste0(
    kpi_row(kpis),
    '<h3>Access and waiting measures</h3>', html_table(access, 10),
    bar_chart(access$MEASURE_NAME, access$MV, "Selected Talking Therapies measures (numeric)")
  )

  commentary_cards <- c(
    build_commentary_card(
      "M001 — Referrals received",
      if (isTRUE(trend_m001$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(trend_m001$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "Count of new referrals received in the month — inflow measure, not caseload.",
        "Latest value" = if (is.na(refs_n)) "—" else format(refs_n, big.mark = ","),
        "Comparator / trend" = trend_line(trend_m001),
        "Agent flag" = if (isTRUE(trend_m001$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = paste0(
          "Referral counts move with demand, pathways and recording — month-on-month change is descriptive only. ",
          if (isTRUE(trend_m001$available) && !is.na(trend_m001$percent_change)) {
            paste0("Latest change: ", if (trend_m001$percent_change >= 0) "+" else "", trend_m001$percent_change, "% vs prior month.")
          } else ""
        ),
        "Human check required" = "IAPT/data owner to confirm M001 matches local referrals reporting for the same period."
      )
    ),
    build_commentary_card(
      "M031 — People accessing services",
      if (isTRUE(trend_m031$available)) "Review locally" else "Trend not available",
      if (isTRUE(trend_m031$available)) "review" else "definition",
      list(
        "Plain-English meaning" = "People who accessed talking therapies services during the month.",
        "Latest value" = if (is.na(accessing_n)) "—" else format(accessing_n, big.mark = ","),
        "Comparator / trend" = trend_line(trend_m031),
        "Agent flag" = "Review locally",
        "Cautious interpretation" = "Access counts differ from referrals received and from people finishing treatment — do not conflate.",
        "Human check required" = "Confirm access definition and whether self-referral surge affects month-on-month movement."
      )
    ),
    build_commentary_card(
      "M019–M022 — Open referrals with no activity (waiting bands)",
      "Watch / clarify", "watch",
      list(
        "Plain-English meaning" = "Open referrals with no recorded activity for 60, 61–90, 91–120 or 120+ days — waiting-style stock measures.",
        "Latest value" = paste0("60–120 day bands sum: ", if (is.na(wait_total)) "—" else format(wait_total, big.mark = ","), " (selected measures only)"),
        "Comparator / trend" = "Waiting bands not trended in this brief — confirm local wait-list definitions first.",
        "Agent flag" = "Watch / clarify",
        "Cautious interpretation" = paste0(
          "Large 'no activity' counts (e.g. M019=", if (is.na(to_num(prov[prov$MEASURE_ID == "M019", "MEASURE_VALUE_SUPPRESSED"][1]))) "n/a" else format(to_num(prov[prov$MEASURE_ID == "M019", "MEASURE_VALUE_SUPPRESSED"][1]), big.mark = ","),
          ") may reflect pathway recording, not necessarily clinical risk — local validation required."
        ),
        "Human check required" = "Pathway owner to confirm how 'no activity' is coded vs local waiting list and enter-treatment tracking."
      )
    ),
    build_commentary_card(
      "M053 — Six-week access (finished course)",
      if (isTRUE(trend_m053$available)) "Definition check required" else "Trend not available",
      "definition",
      list(
        "Plain-English meaning" = "Percentage accessing services within 6 weeks among those finishing a course of treatment — access standard measure.",
        "Latest value" = {
          v <- to_num(prov[prov$MEASURE_ID == "M053", "MEASURE_VALUE_SUPPRESSED"][1])
          if (is.na(v)) "—" else paste0(v, "%")
        },
        "Comparator / trend" = if (isTRUE(trend_m053$available)) {
          paste0(trend_m053$latest_value, "% (", trend_m053$latest_period, ") vs ",
                 trend_m053$previous_value, "% (", trend_m053$previous_period, ")")
        } else {
          "Trend not available"
        },
        "Agent flag" = "Definition check required",
        "Cautious interpretation" = "Percentage measures need denominator checks — high values may still mask subgroup gaps. Not clinical quality without outcome definitions.",
        "Human check required" = "Confirm national IAPT access definition and whether local enter-treatment waits use the same cohort."
      )
    ),
    build_commentary_card(
      "Recovery / outcome measures (not in access table)",
      "Definition check required", "definition",
      list(
        "Plain-English meaning" = "Recovery and reliable-improvement measures (e.g. M192, M186) exist in full IAPT data but are not charted in the access table above.",
        "Latest value" = "See full demo CSV — agent deliberately avoids outcome inference in this access-focused brief.",
        "Comparator / trend" = "Outcome trends require explicit definition checks — not included in key figures.",
        "Agent flag" = "Definition check required",
        "Cautious interpretation" = "Public recovery percentages must not be used to infer clinical quality without checking outcome definitions and suppression.",
        "Human check required" = "Clinical/IAPT lead to confirm recovery definitions before any outcome analysis."
      )
    ),
    build_commentary_card(
      "Suppression",
      "Watch / clarify", "watch",
      list(
        "Plain-English meaning" = paste0(n_supp, " provider measures show '*' — withheld under disclosure rules."),
        "Latest value" = paste0(nrow(prov) - n_supp, " numeric of ", nrow(prov), " provider rows"),
        "Comparator / trend" = "Suppression may vary by month — check each period.",
        "Agent flag" = "Watch / clarify",
        "Cautious interpretation" = "Do not infer from missing cells; small-number referral sources are often suppressed.",
        "Human check required" = "Review monthly IAPT DQ report and whether suppressed measures matter for your question."
      )
    )
  )

  how_to_read <- how_to_read_section(c(
    "Each row is one NHS Talking Therapies measure for RDY as provider (ORG_CODE2=RDY, GROUP_TYPE=Provider).",
    paste0("MEASURE_VALUE_SUPPRESSED is the published value for ", period, "; '*' means suppressed."),
    "M001 counts referrals received; M031 counts people accessing; M019–M022 count open referrals with no activity by waiting band.",
    "Percentage measures (e.g. M053) require denominator understanding — do not treat as simple performance scores.",
    "Monthly IAPT data are provisional — confirm refresh status. This brief does not infer clinical quality from access counts alone.",
    "Worked example only — not official Dorset HealthCare reporting."
  ))

  after_key <- paste0(
    how_to_read,
    measure_commentary_section(commentary_cards),
    trend_section(
      list(trend_m001, trend_m031, trend_m053),
      ts_file_note,
      c(
        "IAPT monthly statistics are provisional and may revise.",
        "Percentage measures (M053) should not be compared directly with count measures.",
        "Trend descriptions are not causal — pathway and recording changes may explain movement."
      )
    )
  )

  config <- list(
    demonstrates = paste0(
      '<p>Summarising access, activity and waiting-style public IAPT measures with plain-English commentary, ',
      'suppression handling, and descriptive monthly trends from the downloaded time series — ',
      'without overclaiming recovery or clinical quality.</p>'
    ),
    question = paste(
      "From public NHS Talking Therapies data for RDY, explain referrals, access and waiting measures in plain English,",
      "show trends where the time-series extract supports them, and list what outcome analysis would require."
    ),
    prompt_excerpt = paste(
      "Filter IAPT monthly CSV to ORG_CODE2=RDY, Provider group.",
      "Commentary on M001, M031, M019–M022, M053 and suppression.",
      "Trend from downloaded time-series file only. No recovery inference. No causal claims.",
      sep = "\n"
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>NHS Talking Therapies Monthly Statistics (<code>demo_talking_therapies.csv</code>)</li>',
      if (!is.null(tt_ts)) paste0('<li>Time series (<code>', esc(ts_file_note), '</code> — 13 monthly periods)</li>') else "",
      '</ul>'
    ),
    period = period,
    process_steps = c(
      "Locate Talking Therapies publication in register",
      "Filter to RDY provider rows (ORG_CODE2, Provider group)",
      "Extract access and waiting measure IDs; count suppression",
      "Draft plain-English commentary cards with agent flags",
      "Compute latest vs previous month from time-series extract where ≥2 periods exist",
      "Link demo CSV and filter notes for verification"
    ),
    first_draft_paragraphs = c(
      if (!is.na(refs_n)) {
        paste0(
          "Public data shows ", format(refs_n, big.mark = ","), " referrals received (M001) for ", period, ". ",
          if (isTRUE(trend_m001$available)) {
            paste0(
              "The time series (", trend_m001$n_periods, " months) latest month is ",
              format(trend_m001$latest_value, big.mark = ","), " vs ",
              format(trend_m001$previous_value, big.mark = ","), " prior month — descriptive only."
            )
          } else {
            "Trend not computed — insufficient periods in extract."
          }
        )
      } else {
        "Referrals received (M001) were not available as a numeric value in this extract."
      },
      if (!is.na(wait_total)) {
        paste0(
          "Open referral 'no activity' bands (60–120 days selected) total ", format(wait_total, big.mark = ","),
          " — the agent flags these for local pathway validation, not as a standalone waiting performance conclusion."
        )
      } else {
        "Waiting-band totals require local validation against pathway definitions."
      },
      paste0(n_supp, " suppressed measures. Recovery/outcome analysis (M192, M186, etc.) requires separate definition checks — not inferred in this access brief.")
    ),
    observations = c(
      if (!is.na(refs_n)) paste0(format(refs_n, big.mark = ","), " referrals received (M001) — local validation required.") else "M001 referrals not numeric in extract.",
      if (isTRUE(trend_m001$available)) paste0("M001 trend available across ", trend_m001$n_periods, " months in time-series extract.") else "M001 trend not available.",
      if (!is.na(wait_total)) paste0("Open referral no-activity bands (60–120d) sum to ", format(wait_total, big.mark = ","), " — pathway context needed.") else "Waiting bands need local definitions.",
      paste0(n_supp, " suppressed measures — do not infer from missing cells."),
      "Provisional monthly IAPT data — outcome measures exist in CSV but are not headline-charted here."
    ),
    cannot_conclude = c(
      "Recovery rates or clinical effectiveness from this access-focused brief",
      "Enter-treatment waiting performance without local pathway definitions",
      "Employment advisor subset performance unless explicitly in extract",
      "Clinical quality from access or waiting counts without outcome definition checks",
      "Causal explanation of referral or access trends from public monthly data alone"
    ),
    bp_questions = c(standard_bp_questions(), list(
      list(
        q = "Do local IAPT reporting figures match M001 for the same period?",
        expl = "Public and local dashboards may use different refresh dates or referral definitions."
      ),
      list(
        q = "How are enter-treatment waits tracked locally vs public waiting bands?",
        expl = "M019–M022 'no activity' bands may not match local RTT or enter-treatment definitions."
      ),
      list(
        q = "What did the monthly data quality report flag for this publication?",
        expl = "IAPT submissions have known DQ checks — confirm before using figures in review."
      )
    ))
  )

  verify_body <- traceability_verify_body(
    "Figures trace to the demo Talking Therapies CSV, RDY-filtered processed extract and time-series file where cited. No derived ranks or peer medians are computed in this brief.",
    c("demo_talking_therapies.csv", if (!is.null(tt_ts)) ts_file_note else NULL),
    "talking_therapies"
  )

  body <- agent_brief_sections(config, key_figures, verify_body, after_key)

  write_public_report("public-talking-therapies-profile.html",
    "Worked example: AI-assisted Talking Therapies public-data briefing",
    "IAPT monthly activity — RDY (April 2026)", body)
}

# --- E. Assurance profile ----------------------------------------------------

build_assurance_profile <- function() {
  assurance <- load_demo("demo_assurance_profile.csv", required = TRUE)
  dspt <- load_rdy_glob("^rdy_dspt_rdy.*\\.csv$")
  cqc_note <- if (file.exists(file.path(metadata_dir, "cqc_rdy_context_note.txt"))) {
    readLines(file.path(metadata_dir, "cqc_rdy_context_note.txt"), warn = FALSE)
  } else character()

  if (is.null(assurance)) {
    write_public_report("public-assurance-profile.html", "Public Assurance Profile",
      "Source data not available", '<section class="nhs-section"><p>Missing demo_assurance_profile.csv</p></section>')
    return(invisible(NULL))
  }

  dspt_latest <- if (!is.null(dspt) && nrow(dspt) > 0) dspt$Status[1] else "Not available"
  dspt_n <- if (!is.null(dspt)) nrow(dspt) else 0L

  themes <- data.frame(
    Theme = c("Written complaints (KO41a)", "Estates (ERIC)", "IG / DSPT", "FFT (public)", "CQC (context)"),
    Status = c(
      "RDY org-level row in 2024-25 extract",
      "RDY trust row in 2024/25 ERIC",
      paste0("Latest public assessment: ", dspt_latest),
      "No org-level RDY rows in downloaded FFT summary XLSX",
      "Regulatory context only — see metadata note"
    ),
    Use = c(
      "Annual complaints assurance; check small numbers",
      "Estates/facilities benchmarking; check amendments file",
      "Annual IG assurance status — not operational detail",
      "Manual setting-level XLSX may be needed",
      "Inspection/regulatory background — not performance proof"
    ),
    stringsAsFactors = FALSE
  )

  kpis <- list(
    list(value = nrow(assurance), label = "Assurance sources indexed"),
    list(value = dspt_n, label = "DSPT history rows"),
    list(value = "2024-25", label = "KO41a period"),
    list(value = "Context", label = "CQC / FFT gaps")
  )

  cqc_html <- if (length(cqc_note) > 0) {
    paste0("<pre style=\"white-space:pre-wrap;font-size:0.85rem;background:#F0F4F5;padding:1rem;border-radius:4px;\">",
           esc(paste(head(cqc_note, 12), collapse = "\n")), "</pre>")
  } else "<p><em>CQC context note not found.</em></p>"

  dspt_html <- if (!is.null(dspt)) html_table(dspt[, c("Status", "Date Published")], 8) else "<p><em>DSPT extract not available.</em></p>"

  key_figures <- paste0(
    kpi_row(kpis),
    '<h3>Assurance source summary</h3>', html_table(themes),
    '<h3>DSPT public assessment history (RDY-specific page)</h3>', dspt_html
  )

  dspt_history_note <- if (dspt_n >= 2) {
    paste0(
      "Descriptive history across ", dspt_n, " published assessment rows — ",
      "earliest: ", tail(dspt$Status, 1), " (", tail(dspt$`Date Published`, 1), "); ",
      "latest: ", dspt$Status[1], " (", dspt$`Date Published`[1], "). ",
      "Status labels are annual assurance signals, not operational IG detail."
    )
  } else {
    "Insufficient DSPT history rows for descriptive summary."
  }

  commentary_cards <- c(
    build_commentary_card(
      "KO41a — Written complaints (annual)",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Annual statutory return confirming RDY submitted written complaints data for 2024-25.",
        "Latest value / position" = "RDY org-level row present in downloaded 2024-25 extract",
        "Comparator / trend" = "Single annual snapshot in current extract — complaints trends need multiple years or local data.",
        "Agent flag" = "Review locally",
        "Cautious interpretation" = "Presence in KO41a confirms participation — volume, themes and small numbers need the complaints team, not this brief.",
        "Human check required" = "Complaints team to confirm 2024-25 figures, PALS themes and whether public row matches internal reporting."
      )
    ),
    build_commentary_card(
      "ERIC — Estates returns (annual)",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Annual estates and facilities cost/activity return — benchmarking and assurance context.",
        "Latest value / position" = "RDY trust row in 2024/25 ERIC extract",
        "Comparator / trend" = "Annual cadence — trend requires multiple ERIC years or local estates dashboards.",
        "Agent flag" = "Review locally",
        "Cautious interpretation" = "ERIC supports facilities benchmarking conversations — not a simple 'good/bad' performance score.",
        "Human check required" = "Estates/facilities owner to confirm amendments file and whether board reporting uses the same year."
      )
    ),
    build_commentary_card(
      "DSPT — Data Security and Protection Toolkit",
      "Potential strength", "strength",
      list(
        "Plain-English meaning" = "Annual IG assurance assessment status published on the DSPT organisation page.",
        "Latest value / position" = dspt_latest,
        "Comparator / trend" = dspt_history_note,
        "Agent flag" = "Potential strength",
        "Cautious interpretation" = paste0(
          "'Standards met' is an annual assurance label — it does not prove day-to-day operational IG compliance. ",
          "Historical rows show movement from 'Approaching standards' (2018-19, 2020-21) to 'Standards met' in recent years — descriptive history only."
        ),
        "Human check required" = "IG/calendar owner to confirm current-year submission status and internal IG audit programme."
      )
    ),
    build_commentary_card(
      "FFT — Friends and Family Test (org-level gap)",
      "Watch / clarify", "watch",
      list(
        "Plain-English meaning" = "Patient experience survey aggregate — org-level FFT rows expected in summary downloads.",
        "Latest value / position" = "No org-level RDY rows in downloaded FFT summary XLSX",
        "Comparator / trend" = "Trend not available until org-level or setting-level data is obtained.",
        "Agent flag" = "Watch / clarify",
        "Cautious interpretation" = "Missing org-level FFT is a workflow gap for analysts — not evidence of poor experience.",
        "Human check required" = "Patient experience lead to confirm whether setting-level XLSX download fills the gap."
      )
    ),
    build_commentary_card(
      "CQC — Regulatory context (not statistical data)",
      "Source validation only", "definition",
      list(
        "Plain-English meaning" = "Care Quality Commission provider page captured as context note — inspection and regulatory background.",
        "Latest value / position" = "Context note in metadata — not a performance metric",
        "Comparator / trend" = "Not applicable — qualitative regulatory context only.",
        "Agent flag" = "Source validation only",
        "Cautious interpretation" = "CQC information supports assurance conversations — it must not be treated as a league table or performance proxy.",
        "Human check required" = "Quality/governance lead to confirm latest inspection status and internal action plans."
      )
    )
  )

  how_to_read <- how_to_read_section(c(
    "Each theme row indexes a public assurance source — not a combined performance score.",
    "KO41a and ERIC are typically annual returns; DSPT is an annual IG assessment history.",
    "FFT org-level gap means patient experience cannot be summarised from the downloaded summary file alone.",
    "CQC content is regulatory context — not statistical performance data.",
    "Use this brief to start assurance conversations with named return owners — not as an official Trust assurance report.",
    "Demonstration only — not official Dorset HealthCare reporting."
  ))

  dspt_trend_section <- if (dspt_n >= 2) {
    paste0(
      '<section class="nhs-section nhs-trend-section">',
      '<h2>DSPT assessment history (descriptive)</h2>',
      '<p>Multiple published assessment rows exist for RDY — summarised descriptively, not as a numeric performance trend.</p>',
      html_table(dspt[, c("Status", "Date Published")]),
      '<p><em>Annual IG assurance labels only — confirm current submission with the IG owner.</em></p>',
      '</section>'
    )
  } else {
    trend_not_available_section(c(
      "Multiple DSPT assessment rows in the public organisation history",
      "Consistent status labels across publication dates",
      "IG owner confirmation of current-year submission"
    ))
  }

  after_key <- paste0(
    how_to_read,
    theme_commentary_section(commentary_cards),
    dspt_trend_section
  )

  verify_extra <- paste0(
    '<details class="nhs-verify-details"><summary>Assurance index (demo extract — full columns)</summary>',
    html_table(assurance),
    '</details>',
    '<details class="nhs-verify-details"><summary>CQC regulatory context note</summary>',
    cqc_html,
    '</details>'
  )

  config <- list(
    demonstrates = paste0(
      '<p>Bringing together KO41a, ERIC, DSPT and CQC context into an assurance briefing with per-source commentary, ',
      'appropriate-use language, and DSPT history — not a clinical performance scorecard.</p>'
    ),
    question = paste(
      "Which public assurance artefacts contain RDY rows, what is each useful for,",
      "what are the gaps (FFT org-level, CQC non-statistical context),",
      "and how should a Business & Performance Partner use this as a conversation starter?"
    ),
    prompt_excerpt = paste(
      "Index public assurance sources for RDY: KO41a, ERIC, DSPT, FFT, CQC.",
      "One commentary card per theme with appropriate-use language.",
      "Summarise DSPT history descriptively if multiple rows exist.",
      "No operational IG or complaints performance conclusions.",
      sep = "\n"
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li><code>demo_assurance_profile.csv</code></li>',
      '<li>KO41a, ERIC, DSPT processed extracts</li>',
      '<li>CQC context note (regulatory background only)</li></ul>'
    ),
    period = "KO41a 2024-25; ERIC 2024/25; DSPT public history; FFT/CQC as noted.",
    process_steps = c(
      "Check DATA_SOURCE_REGISTER for assurance-related sources",
      "Confirm RDY row presence in KO41a, ERIC and DSPT extracts",
      "Record FFT download outcome (no org-level RDY rows in summary XLSX)",
      "Capture CQC provider page as context note only",
      "Draft per-theme commentary with agent flags and appropriate use",
      "Summarise DSPT assessment history descriptively",
      "Link demo CSV, filter notes and governance documentation"
    ),
    first_draft_paragraphs = c(
      "Public open data confirms RDY participation in annual written complaints (KO41a) and ERIC estates returns, with a multi-year DSPT public assessment history.",
      paste0(
        "Latest DSPT public assessment: ", dspt_latest, ". ",
        if (dspt_n >= 2) {
          paste0("History shows ", dspt_n, " published rows — movement from earlier 'Approaching standards' to recent 'Standards met' is descriptive assurance context, not proof of operational IG detail.")
        } else {
          "Limited DSPT history in extract."
        }
      ),
      "FFT org-level rows were absent in the downloaded summary file; CQC provides regulatory context only. A business partner would route operational interpretation to named return owners before any assurance use."
    ),
    observations = c(
      "Public KO41a row confirms presence — local complaints team owns interpretation.",
      "ERIC row confirms estates return participation — check amendments file.",
      paste0("DSPT: ", dspt_n, " history rows — annual assurance signal only."),
      "FFT summary lacked RDY org rows — setting-level XLSX may be needed.",
      "CQC page is regulatory background — not performance proof."
    ),
    cannot_conclude = c(
      "Operational IG compliance from DSPT status alone",
      "Patient experience levels from missing FFT org-level data",
      "Regulatory rating or inspection outcome as a performance proxy",
      "Complaints volume trends from a single annual KO41a snapshot",
      "Estates efficiency or cost performance from ERIC row presence alone"
    ),
    bp_questions = c(standard_bp_questions(), list(
      list(
        q = "Who is the named owner for each return this cycle?",
        expl = "KO41a, ERIC, DSPT and FFT each have accountable teams — confirm before citing in assurance packs."
      ),
      list(
        q = "Is manual FFT setting-level download needed to fill the org-level gap?",
        expl = "The summary XLSX lacked RDY org rows — patient experience lead should confirm next step."
      ),
      list(
        q = "Have ERIC amendments been published post-release?",
        expl = "Estates returns may revise — check amendments file before board use."
      )
    ))
  )

  verify_body <- paste0(
    traceability_verify_body(
      "Assurance index figures trace to demo and processed extracts. No derived ranks or peer medians are computed in this brief.",
      "demo_assurance_profile.csv",
      c("ko41a_annual", "eric_annual", "dspt_rdy")
    ),
    verify_extra
  )

  body <- agent_brief_sections(config, key_figures, verify_body, after_key)

  write_public_report("public-assurance-profile.html",
    "Worked example: AI-assisted public assurance and statutory reporting brief",
    "KO41a, ERIC, DSPT and regulatory context — public data only", body)
}

# --- F. Urgent care / diagnostics check --------------------------------------

build_urgent_diagnostics <- function() {
  dm01_demo <- load_demo("demo_dm01_diagnostics.csv")
  dm01 <- load_rdy_glob("^rdy_dm01_monthly.*\\.csv$")
  ae <- load_rdy_glob("^rdy_ae_monthly.*\\.csv$")
  kh03 <- load_demo("demo_kh03_beds.csv")

  ae_ed_zero <- FALSE
  ae_other_adm <- NA
  if (!is.null(ae)) {
    ed_cols <- c("A&E attendances Type 1", "A&E attendances Type 2")
    for (col in ed_cols) {
      if (col %in% names(ae)) {
        v <- to_num(ae[[col]][1])
        if (!is.na(v) && v == 0) ae_ed_zero <- TRUE
      }
    }
    if ("Other emergency admissions" %in% names(ae)) {
      ae_other_adm <- to_num(ae[["Other emergency admissions"]][1])
    }
  }

  source_check <- data.frame(
    Source = c("A&E monthly provider", "DM01 diagnostics", "KH03 overnight beds"),
    RDY_present = c(!is.null(ae), !is.null(dm01), !is.null(kh03)),
    Notes = c(
      if (!is.null(ae)) paste0("Other emergency admissions: ", if (is.na(ae_other_adm)) "?" else ae_other_adm, "; 0 Type 1/2 A&E attendances") else "Extract not found",
      if (!is.null(dm01)) paste0(nrow(dm01), " diagnostic test rows for RDY (Mar 2026)") else "Extract not found",
      if (!is.null(kh03)) paste0(nrow(kh03), " bed rows — mixed snapshot dates") else "Extract not found"
    ),
    stringsAsFactors = FALSE
  )
  source_check$RDY_present <- ifelse(source_check$RDY_present, "Yes", "No")

  dm01_summary <- NULL
  dm01_top_test <- "n/a"
  if (!is.null(dm01) && "Diagnostic Tests" %in% names(dm01)) {
    dm01$Total_WL <- to_num(dm01$`Total WL`)
    dm01$Total_Activity <- to_num(dm01$`Total Activity`)
    dm01_summary <- dm01[, c("Diagnostic Tests", "Total WL", "Total Activity", "13+ Weeks")]
    dm01_summary <- dm01_summary[order(-dm01$Total_Activity), ]
    if (nrow(dm01_summary) > 0) dm01_top_test <- dm01_summary$`Diagnostic Tests`[1]
  }

  kh03_mi <- NULL
  kh03_trend <- list(available = FALSE, n_periods = 0L, measure_label = "KH03 — Mental illness beds")
  if (!is.null(kh03)) {
    mi <- kh03[kh03$Sector == "Mental Illness", , drop = FALSE]
    mi$Beds <- to_num(mi$Number_Of_Beds)
    mi$period <- parse_period_start(mi$Effective_Snapshot_Date)
    mi <- mi[!is.na(mi$period) & !is.na(mi$Beds), , drop = FALSE]
    mi <- mi[order(mi$period), , drop = FALSE]
    if (nrow(mi) >= 2) {
      kh03_mi <- mi[, c("Effective_Snapshot_Date", "Number_Of_Beds")]
      ts_sub <- data.frame(period = mi$period, value = mi$Beds, stringsAsFactors = FALSE)
      kh03_trend <- compute_period_trend(ts_sub, "KH03 — Mental illness overnight beds (snapshot dates)")
      kh03_trend$series <- ts_sub
    } else if (nrow(mi) > 0) {
      kh03_mi <- mi[order(mi$period, decreasing = TRUE), c("Effective_Snapshot_Date", "Number_Of_Beds")]
      kh03_mi <- kh03_mi[seq_len(min(5, nrow(kh03_mi))), , drop = FALSE]
    }
  }

  ae_summary_html <- if (!is.null(ae)) {
    cols <- intersect(c("Period", "Org Code", "Org name", "A&E attendances Type 1", "Other emergency admissions"), names(ae))
    html_table(ae[, cols, drop = FALSE])
  } else {
    "<p><em>No A&E RDY extract.</em></p>"
  }

  ae_detail_html <- if (!is.null(ae)) html_table(ae) else "<p><em>No A&E RDY extract.</em></p>"

  kpis <- list(
    list(value = if (!is.null(ae)) "Yes" else "No", label = "RDY in A&E file"),
    list(value = if (!is.null(dm01)) nrow(dm01) else 0, label = "DM01 RDY rows"),
    list(value = if (!is.null(kh03)) nrow(kh03) else 0, label = "KH03 RDY rows"),
    list(value = "Mar 2026", label = "DM01 period")
  )

  key_figures <- paste0(
    kpi_row(kpis),
    '<h3>Source presence check</h3>', html_table(source_check),
    '<h3>A&amp;E RDY row — interpretive columns only</h3>', ae_summary_html,
    if (!is.null(dm01_summary)) paste0('<h3>DM01 diagnostics summary (RDY)</h3>', html_table(dm01_summary, 15)) else "",
    if (!is.null(dm01_summary)) bar_chart(dm01_summary$`Diagnostic Tests`, to_num(dm01_summary$`Total Activity`), "DM01 total activity by test (RDY)")
  )

  commentary_cards <- c(
    build_commentary_card(
      "A&E monthly — RDY presence and zero ED attendances",
      "Source validation only", "definition",
      list(
        "Plain-English meaning" = "Monthly A&E provider statistics — attendance and emergency admission columns.",
        "Latest value / position" = paste0(
          "RDY row present; Type 1/2 A&E attendances = 0",
          if (!is.na(ae_other_adm)) paste0("; other emergency admissions = ", ae_other_adm) else ""
        ),
        "Comparator / trend" = "Single month A&E extract — no ED performance trend for RDY.",
        "Agent flag" = "Source validation only",
        "Cautious interpretation" = paste0(
          "Zero ED attendances are consistent with RDY not operating a Type 1/2 emergency department — ",
          "this row confirms source presence and coding, not urgent care performance. ",
          if (!is.na(ae_other_adm) && ae_other_adm <= 5) {
            paste0("Small other emergency admission count (", ae_other_adm, ") needs service-owner confirmation of what is included.")
          } else ""
        ),
        "Human check required" = "Urgent/emergency care lead to confirm service model and what 'other emergency admissions' represents for RDY."
      )
    ),
    build_commentary_card(
      "DM01 — Diagnostic tests (March 2026)",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Monthly diagnostic waiting list and activity by test type for RDY as provider.",
        "Latest value / position" = if (!is.null(dm01)) paste0(nrow(dm01), " test rows; highest activity: ", dm01_top_test) else "Extract not found",
        "Comparator / trend" = "Single month in current extract — DM01 trend requires additional monthly downloads.",
        "Agent flag" = "Review locally",
        "Cautious interpretation" = "Audiology and community diagnostics may dominate activity — do not infer national waiting position without local validation.",
        "Human check required" = "Diagnostics service owner to confirm DM01 mapping to local community diagnostic pathways."
      )
    ),
    build_commentary_card(
      "KH03 — Overnight mental illness beds (snapshot dates)",
      if (isTRUE(kh03_trend$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(kh03_trend$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "Quarterly overnight bed stock by sector — mental illness rows relevant to RDY as mental health provider.",
        "Latest value / position" = if (isTRUE(kh03_trend$available)) {
          paste0(format(kh03_trend$latest_value, big.mark = ","), " beds (", kh03_trend$latest_period, " snapshot)")
        } else {
          "Mixed snapshot dates in extract — verify latest quarter on NHS England site"
        },
        "Comparator / trend" = if (isTRUE(kh03_trend$available)) {
          paste0(
            "Historical snapshots span ", kh03_trend$n_periods, " dates — latest vs previous: ",
            format(kh03_trend$latest_value, big.mark = ","), " vs ",
            format(kh03_trend$previous_value, big.mark = ","),
            ". Irregular snapshot intervals — descriptive only."
          )
        } else {
          "Insufficient comparable snapshots for trend in current slice."
        },
        "Agent flag" = if (isTRUE(kh03_trend$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = "KH03 mixes historical snapshot dates (2007–2024) — cannot infer current operational capacity without confirming the latest published quarter.",
        "Human check required" = "Bed management/ estates lead to confirm latest KH03 quarter and alignment with internal bed state."
      )
    )
  )

  how_to_read <- how_to_read_section(c(
    "This report is primarily a source validation check — confirming RDY appears in public urgent/diagnostics files.",
    "A&E rows list attendances and admissions by type — zero Type 1/2 attendances at RDY must not be read as ED performance.",
    "DM01 rows show waiting list and activity by diagnostic test for one month — not a full diagnostics performance view.",
    "KH03 rows show overnight bed snapshots by sector; dates vary and may include historical quarters.",
    "Distinguish data presence (RDY row exists) from operational meaning (what services RDY actually provides).",
    "Demonstration only — not official Dorset HealthCare reporting."
  ))

  kh03_trend_html <- if (isTRUE(kh03_trend$available)) {
    trend_section(
      list(kh03_trend),
      "demo_kh03_beds.csv — Mental Illness sector snapshots (Effective_Snapshot_Date)",
      c(
        "Snapshot dates are irregular (not always consecutive quarters) — do not treat as monthly trend.",
        "Bed definitions and rounding may change between publications.",
        "Latest snapshot in extract may not be the latest NHS England publication — verify on source site."
      )
    )
  } else {
    trend_not_available_section(c(
      "Latest KH03 quarterly snapshot aligned to board reporting date",
      "Consistent sector filter (Mental Illness) across consecutive quarters",
      "Local bed management confirmation of current operational capacity"
    ))
  }

  ae_dm01_trend <- paste0(
    '<p>A&amp;E and DM01 each have only one month in the current processed extract — month-on-month trend is not shown.</p>',
    '<p><strong>What would be needed:</strong></p>',
    bullet_list(c(
      "Additional monthly A&E provider files for consecutive months",
      "Additional monthly DM01 diagnostic extracts for period-on-period comparison",
      "Service-owner confirmation that RDY service model excludes Type 1/2 ED activity"
    ))
  )

  after_key <- paste0(
    how_to_read,
    theme_commentary_section(commentary_cards, "Per-source commentary for A&E, DM01 and KH03 — source validation and cautious interpretation."),
    '<section class="nhs-section"><h2>A&amp;E and DM01 — trend status</h2>',
    ae_dm01_trend,
    '</section>',
    kh03_trend_html
  )

  verify_extra <- paste0(
    '<details class="nhs-verify-details"><summary>A&amp;E RDY row — full public data columns</summary>',
    ae_detail_html,
    '</details>',
    if (!is.null(kh03_mi)) paste0(
      '<details class="nhs-verify-details"><summary>KH03 mental illness beds (snapshots in extract)</summary>',
      html_table(kh03_mi),
      '</details>'
    ) else ""
  )

  config <- list(
    demonstrates = paste0(
      '<p>Checking RDY presence in public A&amp;E, DM01 and KH03 files with per-source commentary, ',
      'plain-English warnings for zero ED attendances, and descriptive KH03 snapshot history where multiple dates exist.</p>'
    ),
    question = paste(
      "Check whether RDY appears in public A&E, DM01 and KH03 files;",
      "explain what each source can safely support for a trust without an emergency department;",
      "and where trend analysis is or is not available from downloaded data."
    ),
    prompt_excerpt = paste(
      "For each source: confirm RDY row presence and draft commentary card.",
      "Report zero ED attendances explicitly. Summarise DM01 by test.",
      "KH03: trend only if multiple comparable snapshots — with heavy caveats.",
      "No ED performance claims. No causal language.",
      sep = "\n"
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>A&amp;E monthly provider CSV</li>',
      '<li>DM01 (<code>demo_dm01_diagnostics.csv</code> + full RDY extract)</li>',
      '<li>KH03 (<code>demo_kh03_beds.csv</code>)</li></ul>'
    ),
    period = "A&E May 2026; DM01 March 2026; KH03 snapshot dates vary in extract (verify latest quarter on NHS England site).",
    process_steps = c(
      "Download and inspect A&E, DM01 and KH03 public provider files",
      "Search each file for org code RDY; record presence in source check table",
      "Draft per-source commentary with agent flags",
      "For A&E: confirm zero Type 1/2 attendances — consistent with no ED at RDY",
      "Summarise DM01 diagnostic tests with numeric activity only",
      "For KH03: compute descriptive snapshot change for Mental Illness if ≥2 dates",
      "Link demo CSVs and filter notes for verification"
    ),
    first_draft_paragraphs = c(
      paste0(
        "RDY appears in all three public files checked. A&E shows zero Type 1/2 ED attendances",
        if (!is.na(ae_other_adm)) paste0(" and ", ae_other_adm, " other emergency admissions") else "",
        " — the agent treats this as source validation and service-model context, not ED performance."
      ),
      if (!is.null(dm01)) {
        paste0(
          "DM01 shows ", nrow(dm01), " diagnostic test rows for March 2026; ",
          dm01_top_test, " has the highest recorded activity in this extract — local diagnostics owner confirmation required."
        )
      } else {
        "DM01 extract was not available for summary."
      },
      if (isTRUE(kh03_trend$available)) {
        paste0(
          "KH03 mental illness snapshots span ", kh03_trend$n_periods,
          " dates in the extract — latest ", format(kh03_trend$latest_value, big.mark = ","),
          " beds (", kh03_trend$latest_period, ") vs ", format(kh03_trend$previous_value, big.mark = ","),
          " (", kh03_trend$previous_period, "). Irregular intervals — not current capacity without latest-quarter verification."
        )
      } else {
        "KH03 bed rows exist but trend analysis requires aligned latest-quarter snapshots confirmed with the bed management owner."
      }
    ),
    observations = c(
      "RDY presence confirmed in A&E and DM01 public files — useful for mandatory return mapping.",
      if (ae_ed_zero) "A&E: zero Type 1/2 attendances — consistent with no ED; do not overinterpret." else "A&E: confirm ED attendance columns locally.",
      if (!is.null(dm01)) paste0("DM01: ", nrow(dm01), " test rows; audiology/community diagnostics may dominate.") else "DM01 not summarised.",
      if (isTRUE(kh03_trend$available)) paste0("KH03: ", kh03_trend$n_periods, " mental illness snapshots — descriptive history only.") else "KH03: verify latest quarter before capacity discussions.",
      "A&E and DM01: single month — no month-on-month trend in current extract."
    ),
    cannot_conclude = c(
      "ED or urgent care performance from A&E statistics at RDY",
      "National urgent care position or comparator standing",
      "Current bed capacity from KH03 rows with mixed historical snapshot dates without latest-quarter check",
      "Diagnostic waiting performance without local service-owner validation",
      "Operational cause of any KH03 snapshot change without bed management context"
    ),
    bp_questions = c(standard_bp_questions(), list(
      list(
        q = "Which urgent care metrics apply locally without an ED?",
        expl = "Many national urgent care indicators assume Type 1/2 ED activity — confirm which apply to RDY's service model."
      ),
      list(
        q = "Who owns DM01 audiology/community diagnostics reporting?",
        expl = "DM01 activity may reflect community diagnostic pathways — confirm accountable service line."
      ),
      list(
        q = "Has the latest KH03 quarter been downloaded and aligned to board reporting?",
        expl = "Extract may include historical snapshots — bed management should confirm current published quarter."
      )
    ))
  )

  verify_body <- paste0(
    traceability_verify_body(
      "Presence checks and summary tables trace to demo CSVs and RDY-filtered processed extracts. No derived ranks or peer medians are computed in this brief.",
      c("demo_dm01_diagnostics.csv", "demo_kh03_beds.csv"),
      c("ae_monthly", "dm01_monthly", "kh03_quarterly")
    ),
    verify_extra
  )

  body <- agent_brief_sections(config, key_figures, verify_body, after_key)

  write_public_report("public-urgent-diagnostics-check.html",
    "Worked example: AI-assisted urgent care and diagnostics source check",
    "A&E, DM01 and KH03 — RDY presence and cautious interpretation", body)
}

# --- Run all reports ---------------------------------------------------------

build_performance_overview()
build_mh_profile()
build_csds_profile()
build_talking_therapies()
build_assurance_profile()
build_urgent_diagnostics()

cat("Public reports written to:", normalizePath(reports_dir), "\n")
