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

load_trend_file <- function(filename) {
  path <- file.path(processed_dir, filename)
  if (!file.exists(path)) return(NULL)
  tryCatch(read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
           error = function(e) NULL)
}

parse_stacked_period <- function(x) {
  x <- trimws(as.character(x))
  d <- parse_period_start(x)
  if (length(d) > 0 && !all(is.na(d))) return(d)
  m <- regmatches(x, regexec("MSitAE-([A-Za-z]+)-([0-9]{4})", x, ignore.case = TRUE))[[1]]
  if (length(m) == 3) {
    month_num <- match(tolower(m[2]), tolower(month.name))
    if (!is.na(month_num)) {
      return(as.Date(sprintf("%04d-%02d-01", as.integer(m[3]), month_num)))
    }
  }
  m2 <- regmatches(x, regexec("DM01-([A-Za-z]+)-([0-9]{4})", x, ignore.case = TRUE))[[1]]
  if (length(m2) == 3) {
    month_num <- match(tolower(m2[2]), tolower(month.name))
    if (!is.na(month_num)) {
      return(as.Date(sprintf("%04d-%02d-01", as.integer(m2[3]), month_num)))
    }
  }
  m3 <- regmatches(x, regexec("([a-z]+)-([0-9]{4})$", x, ignore.case = TRUE))[[1]]
  if (length(m3) == 3) {
    month_num <- match(tolower(m3[2]), tolower(month.name))
    if (!is.na(month_num)) {
      return(as.Date(sprintf("%04d-%02d-01", as.integer(m3[3]), month_num)))
    }
  }
  as.Date(NA)
}

extract_stacked_trend <- function(df, measure_id = NULL, measure_name = NULL, label = NULL) {
  if (is.null(df) || nrow(df) == 0) return(list(available = FALSE, n_periods = 0L))
  sub <- df
  if (!is.null(measure_id) && "measure_id" %in% names(sub)) {
    sub <- sub[trimws(sub$measure_id) == measure_id, , drop = FALSE]
  }
  if (!is.null(measure_name) && "measure_name" %in% names(sub)) {
    sub <- sub[trimws(sub$measure_name) == measure_name, , drop = FALSE]
  }
  if (nrow(sub) == 0) {
    return(list(available = FALSE, n_periods = 0L, measure_label = label %||% ""))
  }
  sub$period <- parse_stacked_period(sub$reporting_period_start)
  if (all(is.na(sub$period)) && "publication_period" %in% names(sub)) {
    sub$period <- parse_stacked_period(sub$publication_period)
  }
  sub$value <- to_num(sub$metric_value)
  sub <- sub[!is.na(sub$value), , drop = FALSE]
  if (nrow(sub) == 0) return(list(available = FALSE, n_periods = 0L))
  if (!all(is.na(sub$period))) {
    sub <- sub[!is.na(sub$period), , drop = FALSE]
    agg <- stats::aggregate(value ~ period, data = sub, FUN = function(v) v[1])
    ts_sub <- agg[order(agg$period), , drop = FALSE]
  } else {
    sub <- sub[order(sub$publication_period), , drop = FALSE]
    ts_sub <- data.frame(
      period = seq_len(nrow(sub)),
      value = sub$value,
      stringsAsFactors = FALSE
    )
  }
  measure_label <- if (!is.null(label) && nzchar(label)) {
    label
  } else if ("measure_name" %in% names(sub) && nzchar(sub$measure_name[1])) {
    sub$measure_name[1]
  } else {
    as.character(measure_id)
  }
  compute_period_trend(ts_sub, measure_label)
}

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !all(is.na(a)) && nzchar(as.character(a)[1])) a else b

trends_from_stacked <- function(df, measures) {
  if (is.null(df) || nrow(df) == 0) return(list())
  lapply(measures, function(m) {
    extract_stacked_trend(
      df,
      measure_id = m$id,
      measure_name = m$name,
      label = m$label
    )
  })
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
    esc(trimws(as.character(row$Metric_description))), '</summary>',
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
    '<details class="nhs-verify-details"><summary>Technical audit detail</summary>',
    '<div class="nhs-audit-summary">', html_table(summary_df, max_rows = 50), '</div>',
    '</details>',
    '<details class="nhs-verify-details"><summary>Per-metric source trace</summary>',
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
  '<strong>Public-data demonstration report:</strong> ',
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

short_human_check <- function(text) {
  text <- trimws(as.character(text))
  if (!nzchar(text)) return("")
  parts <- strsplit(text, "\\. ", perl = TRUE)[[1]]
  result <- if (length(parts) >= 1 && nzchar(parts[1])) parts[1] else text
  result <- trimws(result)
  if (!grepl("\\.$", result)) paste0(result, ".") else result
}

format_peer_position_short <- function(median, rank) {
  median <- trimws(as.character(median))
  rank <- trimws(as.character(rank))
  if (is.na(to_num(median)) && is.na(to_num(rank))) {
    return("Median and rank not published for this metric in the extract.")
  }
  paste0("Peer median: ", median, ". Published rank: ", rank, ". Not a local target.")
}

format_initial_reading <- function(flag_class, position_text, extra = NULL) {
  flag_read <- switch(
    flag_class %||% "review",
    strength = "Confirm locally before describing as positive performance.",
    definition = "Finance or definition check required.",
    review = "Local review needed.",
    watch = "Interpret cautiously — confirm cohort and scope.",
    validation = "Source validation only — not a performance standing.",
    "Local review needed."
  )
  paste0(trimws(position_text), " ", flag_read, if (!is.null(extra) && nzchar(extra)) paste0(" ", extra) else "")
}

scope_section <- function(can_items = list(), cannot_items = list()) {
  if (length(can_items) == 0 && length(cannot_items) == 0) return("")
  can_html <- if (length(can_items) > 0) {
    paste0("<p><strong>This report can:</strong></p>", bullet_list(can_items))
  } else {
    ""
  }
  cannot_html <- if (length(cannot_items) > 0) {
    paste0("<p><strong>This report cannot:</strong></p>", bullet_list(cannot_items))
  } else {
    ""
  }
  paste0(
    '<section class="nhs-section">',
    '<h2>What this report can and cannot tell us</h2>',
    can_html,
    cannot_html,
    '<p><em>For that reason, this should be treated as a first-draft prompt for review, not a final performance judgement.</em></p>',
    "</section>"
  )
}

headline_reading_section <- function(bullets) {
  if (length(bullets) == 0) return("")
  paste0(
    '<section class="nhs-section">',
    "<h2>Headline reading</h2>",
    '<div class="nhs-headline-reading">',
    bullet_list(bullets),
    "</div></section>"
  )
}

findings_group_section <- function(groups) {
  if (is.null(groups) || length(groups) == 0) return("")
  groups_html <- paste(vapply(groups, function(g) {
    items_html <- paste(vapply(g$items, function(item) {
      owner <- if (!is.null(item$owner) && nzchar(item$owner)) {
        paste0('<p class="nhs-finding-owner"><strong>Human check:</strong> ', esc(item$owner), "</p>")
      } else {
        ""
      }
      paste0(
        '<article class="nhs-finding-item">',
        "<h4>", esc(item$title), "</h4>",
        "<p>", esc(item$body), "</p>",
        owner,
        "</article>"
      )
    }, character(1)), collapse = "")
    paste0('<div class="nhs-findings-group"><h3>', esc(g$title), "</h3>", items_html, "</div>")
  }, character(1)), collapse = "")
  paste0(
    '<section class="nhs-section">',
    "<h2>Key findings by review area</h2>",
    groups_html,
    "</section>"
  )
}

first_draft_analysis <- function(paragraphs) {
  paras <- paste0("<p>", esc(paragraphs), "</p>", collapse = "")
  paste0('<section class="nhs-section"><h2>First-draft analysis</h2>', paras, '</section>')
}

human_review_warning <- function() {
  paste0(
    '<div class="nhs-warning" role="note"><strong>Human review required:</strong> ',
    'Confirm definitions, publication status and local owner sign-off before any operational use.</div>'
  )
}

verify_section <- function(intro_html, body_html) {
  paste0(
    '<section class="nhs-section nhs-verify-block"><h2>Audit trail and source checks</h2>',
    '<div class="nhs-verify-intro">', intro_html, '</div>',
    body_html,
    '</section>'
  )
}

verify_intro_short <- function(demo_link_html = "", trace_sentence = NULL) {
  trace <- trace_sentence %||%
    "Open the linked demo CSV or audit file, locate the RDY row, and confirm the value matches the published source."
  paste0(
    '<p>', trace, '</p>',
    '<ul class="nhs-list-compact">',
    if (nzchar(demo_link_html)) demo_link_html else "",
    '<li><a href="../public-data/DATA_SOURCE_REGISTER.csv">Source register</a></li>',
    '<li><a href="../public-data/PUBLIC_REPORTS_METHOD.md">Method document</a></li>',
    '</ul>'
  )
}

collapsible_details <- function(summary, content_html, extra_class = "") {
  if (!nzchar(content_html)) return("")
  paste0(
    '<details class="nhs-support-details ', extra_class, '">',
    '<summary>', esc(summary), '</summary>',
    '<div class="nhs-support-details-body">', content_html, '</div>',
    '</details>'
  )
}

commentary_cards_block <- function(cards) {
  if (length(cards) == 0) return("")
  paste0('<div class="nhs-metric-commentary">', paste(cards, collapse = "\n"), '</div>')
}

wrap_trend_collapsible <- function(trend_html, summary = "Trend detail (charts and tables)") {
  if (!nzchar(trend_html)) return("")
  collapsible_details(summary, trend_html)
}

what_agent_asked_section <- function(question, dataset_line = NULL) {
  dataset_html <- if (!is.null(dataset_line) && nzchar(dataset_line)) {
    paste0("<p><strong>Dataset:</strong> ", esc(dataset_line), "</p>")
  } else {
    ""
  }
  paste0(
    '<section class="nhs-section"><h2>What the agent was asked to do</h2>',
    '<div class="nhs-agent-box">',
    "<p><strong>Business question:</strong> ", esc(question), "</p>",
    dataset_html,
    "<p>This is a <strong>first-draft analytical brief</strong> for human review — not an approved performance report.</p>",
    "</div>",
    "</section>"
  )
}

data_used_section <- function(config) {
  trend_line <- config$trend_available %||% ""
  trend_html <- if (nzchar(trend_line)) {
    paste0("<li><strong>Historic trend data:</strong> ", esc(trend_line), "</li>")
  } else {
    ""
  }
  paste0(
    '<section class="nhs-section"><h2>Data used</h2>',
    config$data_used_html,
    '<ul class="nhs-list-compact nhs-data-meta">',
    "<li><strong>Period covered:</strong> ", esc(config$period), "</li>",
    "<li><strong>RDY filter:</strong> ODS code <strong>RDY</strong>; Dorset HealthCare trust name variants (see filter notes)</li>",
    trend_html,
    "</ul></section>"
  )
}

agent_summary_section <- function(bullets) {
  if (length(bullets) == 0) return("")
  paste0(
    '<section class="nhs-section"><h2>Draft interpretation</h2>',
    bullet_list(bullets),
    "</section>"
  )
}

human_checks_section <- function(items) {
  if (is.null(items) || length(items) == 0) return("")
  if (is.list(items[[1]]) && !is.null(items[[1]]$q)) {
    bullets <- vapply(items, function(x) {
      paste0(x$q, " — ", x$expl)
    }, character(1))
  } else {
    bullets <- unlist(items)
  }
  paste0(
    '<section class="nhs-section"><h2>Human validation checklist</h2>',
    bullet_list(bullets),
    "</section>"
  )
}

standard_human_checks <- function(extra = list()) {
  base <- list(
    list(
      q = "Is this the same definition used locally?",
      expl = "Public datasets may use national definitions. Local dashboards may use different filters, denominators or reporting dates."
    ),
    list(
      q = "Is this still the latest position?",
      expl = "Public data may be delayed. Local operational data may have moved on since the reporting period shown."
    ),
    list(
      q = "Is the figure affected by data quality, suppression, coding or service model?",
      expl = "A public figure can be affected by small numbers, exclusions, coding rules or how services are configured."
    ),
    list(
      q = "Who owns the local narrative?",
      expl = "The accountable service, finance, workforce, quality or BI owner should confirm the explanation before use."
    ),
    list(
      q = "Is this suitable for board/service reporting, or only a prompt for further review?",
      expl = "These briefs are first drafts — confirm whether the figure is ready for formal reporting or needs more local work."
    )
  )
  c(base, extra)
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
  commentary_cards_block(cards)
}

nof_agent_reading <- function(entry, row) {
  if (is.null(entry)) return("Definition check and local review needed.")
  val_n <- to_num(row$Value)
  med_n <- to_num(row$Median_value)
  pos <- if (!is.na(val_n) && !is.na(med_n)) {
    if (val_n > med_n) "RDY is above the peer median." else if (val_n < med_n) "RDY is below the peer median." else "RDY matches the peer median."
  } else {
    ""
  }
  extra <- if (trimws(as.character(row$Metric_ID)) == "OF0086") {
    "For this metric, a value of 100 is approximately expected cost."
  } else {
    NULL
  }
  format_initial_reading(entry$flag_class, pos, extra)
}

nof_position_phrase <- function(row) {
  val_n <- to_num(row$Value)
  med_n <- to_num(row$Median_value)
  val <- trimws(as.character(row$Value))
  med <- trimws(as.character(row$Median_value))
  rank <- trimws(as.character(row$Rank))
  if (!is.na(val_n) && !is.na(med_n)) {
    if (val_n > med_n) pos <- "above"
    else if (val_n < med_n) pos <- "below"
    else pos <- "in line with"
    paste0(
      "RDY is shown as ", val, " against a peer median of ", med,
      ", with a published rank of ", rank, ". RDY is ", pos, " the peer median."
    )
  } else {
    paste0("RDY is shown as ", val, " with published rank ", rank, ".")
  }
}

nof_group_item <- function(row, entry) {
  id <- trimws(as.character(row$Metric_ID))
  title <- if (!is.null(entry)) entry$plain_meaning else trimws(as.character(row$Metric_description))
  body <- paste0(
    nof_position_phrase(row), " ",
    switch(
      id,
      OF0005 = "This may be a positive position, but the local owner should confirm the cohort, denominator, reporting period and whether the national definition matches local waiting list reporting.",
      OF0079 = "This needs finance review before interpretation. The owner should confirm the sign convention, plan version and whether the public figure matches internal board reporting.",
      OF0081 = "Finance owner should confirm Month 12 YTD basis, plan assumptions and whether amendments have been published.",
      OF0082 = "The workforce lead should confirm the reporting period, inclusion rules and whether local sickness dashboards use the same definition.",
      OF0041 = "The CYP mental health lead should confirm numerator, ICB/resident vs provider scope and whether local access data supports the direction of change.",
      OF0061 = "The OD or workforce lead should confirm survey methodology, response rate, cohort and whether the difference is meaningful for local workforce planning.",
      OF0084 = "The OD or workforce lead should confirm survey methodology, response rate, cohort and whether the difference is meaningful for local workforce planning.",
      OF0057 = "The community urgent care owner should confirm the UCR definition, reporting period and current operational position.",
      OF0016 = "The crisis pathway owner should confirm the cohort, face-to-face definition and alignment with local crisis standards.",
      OF0086 = "For this metric, a value of 100 is approximately expected cost. Finance or productivity leads should confirm the cost index basis, peer group and local productivity narrative.",
      OF0063 = "The inpatient mental health lead should confirm the definition, cohort and whether the public figure matches local bed management data.",
      "Confirm metric definition and local owner review before operational use."
    )
  )
  owner <- if (!is.null(entry)) entry$human_check else "Confirm metric definition against NHS England NOF specification."
  list(title = title, body = body, owner = owner)
}

nof_build_grouped_findings <- function(audit_source, lookup) {
  ids_for <- function(metric_ids) {
    lapply(metric_ids, function(id) {
      idx <- which(trimws(audit_source$Metric_ID) == id)
      if (length(idx) == 0) return(NULL)
      row <- audit_source[idx[1], , drop = FALSE]
      entry <- lookup[[id]]
      nof_group_item(row, entry)
    })
  }
  compact_items <- function(items) {
    items <- items[!vapply(items, is.null, logical(1))]
    if (length(items) == 0) NULL else items
  }
  groups <- list(
    list(
      title = "Potential strengths, subject to validation",
      items = compact_items(ids_for(c("OF0005", "OF0079")))
    ),
    list(
      title = "Areas for local review",
      items = compact_items(ids_for(c("OF0057", "OF0016", "OF0063", "OF0086")))
    ),
    list(
      title = "Finance / definition checks",
      items = compact_items(ids_for(c("OF0079", "OF0081", "OF0086")))
    ),
    list(
      title = "Workforce indicators",
      items = compact_items(ids_for(c("OF0082", "OF0061", "OF0084")))
    ),
    list(
      title = "Metrics needing cautious interpretation",
      items = compact_items(ids_for(c("OF0041")))
    )
  )
  groups[vapply(groups, function(g) length(g$items %||% list()) > 0, logical(1))]
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

STANDARD_PROCESS_SUFFIX <- c(
  "Filter to RDY using ODS code and Dorset HealthCare trust name variants (see filter notes)",
  "Detect current vs historic periods from reporting columns or stacked trend files",
  "Select key figures from named measures, top-N tables or source-presence checks — not exhaustive lists",
  "Decide trend analysis only when ≥2 comparable periods exist and values are not suppressed",
  "Avoid overclaiming — no causal language, no fabricated targets, no recalculated peer comparators",
  "Document verification paths and what a human reviewer must still confirm"
)

format_comparator <- function(comparator_type, details = "") {
  if (nzchar(details)) {
    return(details)
  }
  switch(
    comparator_type,
    official_standard = "Official standard or target from the published source (if present in extract).",
    peer_median = "Peer median and published rank from NHS England source file — not a local target.",
    previous_period = "Latest period compared with the previous comparable period in the downloaded public extract.",
    descriptive_history = "Descriptive history across multiple published rows — not a numeric performance trend.",
    none = "No verified target or comparator in the current public extract.",
    validation_only = "Source validation only — confirms RDY presence or participation, not performance standing.",
    "No comparator in the current public extract."
  )
}

trend_badge_css <- function(label) {
  switch(
    label,
    "Improving" = "improving",
    "Worsening" = "worsening",
    "Broadly stable" = "stable",
    "Mixed / unclear" = "unclear",
    "Definition check required" = "unclear",
    "Not available from current extract" = "na",
    "Source validation only" = "validation",
    "na"
  )
}

classify_trend_direction <- function(trend_obj = NULL, polarity = "unknown",
                                     override_label = NULL, override_note = NULL,
                                     stable_pct_threshold = 2) {
  if (!is.null(override_label) && nzchar(as.character(override_label)[1])) {
    return(list(
      label = override_label,
      note = override_note %||% "",
      css = trend_badge_css(override_label)
    ))
  }
  if (identical(polarity, "validation_only")) {
    return(list(
      label = "Source validation only",
      note = "Trend direction is not meaningful for this source-validation figure.",
      css = "validation"
    ))
  }
  if (identical(polarity, "definition")) {
    return(list(
      label = "Definition check required",
      note = "Metric polarity or meaning must be confirmed before interpreting direction.",
      css = "unclear"
    ))
  }
  if (is.null(trend_obj) || !isTRUE(trend_obj$available) || trend_obj$n_periods < 2) {
    n <- if (is.null(trend_obj)) 0L else trend_obj$n_periods %||% 0L
    note <- if (n <= 1) {
      "Trend direction is marked as unavailable because the current extract contains fewer than two comparable periods."
    } else {
      "Trend could not be computed from the available rows."
    }
    return(list(label = "Not available from current extract", note = note, css = "na"))
  }
  if (identical(polarity, "unknown") || identical(polarity, "none")) {
    chg <- trend_obj$absolute_change
    pct <- trend_obj$percent_change
    note <- paste0(
      "Latest ", format(trend_obj$latest_value, big.mark = ","), " (", trend_obj$latest_period, ") vs ",
      format(trend_obj$previous_value, big.mark = ","), " (", trend_obj$previous_period, "). ",
      "Direction is descriptive only — metric polarity is not verified in this demo."
    )
    return(list(label = "Mixed / unclear", note = note, css = "unclear"))
  }
  chg <- trend_obj$absolute_change
  pct <- trend_obj$percent_change
  stable <- (!is.na(pct) && abs(pct) <= stable_pct_threshold) ||
    (is.na(pct) && abs(chg) < max(1, abs(trend_obj$previous_value) * 0.02))
  if (stable) {
    return(list(
      label = "Broadly stable",
      note = paste0(
        "Change between ", trend_obj$previous_period, " and ", trend_obj$latest_period,
        " is small (", if (!is.na(pct)) paste0(if (pct >= 0) "+" else "", pct, "%") else paste0(if (chg >= 0) "+" else "", format(chg, big.mark = ",")),
        ") — descriptive only."
      ),
      css = "stable"
    ))
  }
  higher_better <- identical(polarity, "higher_better")
  lower_better <- identical(polarity, "lower_better")
  improving <- if (higher_better) chg > 0 else if (lower_better) chg < 0 else NA
  label <- if (isTRUE(improving)) "Improving" else if (isFALSE(improving)) "Worsening" else "Mixed / unclear"
  list(
    label = label,
    note = paste0(
      format(trend_obj$latest_value, big.mark = ","), " (", trend_obj$latest_period, ") vs ",
      format(trend_obj$previous_value, big.mark = ","), " (", trend_obj$previous_period, "). ",
      "Descriptive period-on-period change only — not causal."
    ),
    css = trend_badge_css(label)
  )
}

trend_badge_html <- function(trend_info) {
  paste0(
    '<span class="nhs-trend-badge nhs-trend-badge--', esc(trend_info$css), '" title="',
    esc(trend_info$note), '">', esc(trend_info$label), '</span>'
  )
}

comparator_label_html <- function(comparator_type) {
  tag <- switch(
    comparator_type,
    official_standard = "Official standard",
    peer_median = "Peer median",
    previous_period = "Previous period",
    descriptive_history = "Descriptive history",
    validation_only = "Source validation",
    "No comparator"
  )
  paste0('<span class="nhs-comparator-label">', esc(tag), '</span> ')
}

format_kfe_latest <- function(value_text, period_text = NULL, suppressed = FALSE) {
  if (suppressed) return("* (suppressed in public extract)")
  if (is.null(value_text) || (length(value_text) == 1 && (is.na(value_text) || trimws(as.character(value_text)) == ""))) {
    return("—")
  }
  v <- as.character(value_text)
  if (!is.null(period_text) && nzchar(period_text)) paste0(v, " (", period_text, ")") else v
}

kfe_from_trend <- function(trend_obj, value_text = NULL, period_text = NULL) {
  if (!is.null(value_text)) {
    format_kfe_latest(value_text, period_text)
  } else if (isTRUE(trend_obj$available)) {
    format_kfe_latest(format(trend_obj$latest_value, big.mark = ","), trend_obj$latest_period)
  } else {
    "—"
  }
}

key_figures_explained_section <- function(specs, intro = NULL, supporting_html = "",
                                        title = "Main metric table", show_trend = TRUE,
                                        show_what = FALSE, trend_note = NULL,
                                        comparator_header = "Peer position / comparator") {
  if (length(specs) == 0) return("")
  intro_text <- intro %||%
    paste(
      "Plain-English explanation of the most useful measures in this brief.",
      "Trend direction uses downloaded public historic data only where at least two comparable periods exist."
    )
  trend_note_html <- if (!show_trend && !is.null(trend_note) && nzchar(trend_note)) {
    paste0("<p><em>", esc(trend_note), "</em></p>")
  } else {
    ""
  }
  rows_html <- vapply(specs, function(spec) {
    cmp_text <- if (nzchar(spec$comparator_detail %||% "")) {
      spec$comparator_detail
    } else {
      format_comparator(spec$comparator_type %||% "none", "")
    }
    row_parts <- c(
      paste0("<th scope=\"row\">", esc(spec$figure), "</th>"),
      if (show_what) paste0("<td>", esc(spec$what), "</td>") else character(),
      paste0("<td>", esc(spec$latest), "</td>"),
      paste0("<td>", esc(cmp_text), "</td>"),
      if (show_trend) {
        trend_info <- classify_trend_direction(
          trend_obj = spec$trend,
          polarity = spec$polarity %||% "unknown",
          override_label = spec$trend_override,
          override_note = spec$trend_note
        )
        paste0("<td>", trend_badge_html(trend_info), "</td>")
      } else {
        character()
      },
      paste0("<td>", esc(spec$interpretation), "</td>"),
      paste0("<td class=\"nhs-human-check\">", esc(spec$human_check), "</td>")
    )
    paste0("<tr>", paste(row_parts, collapse = ""), "</tr>")
  }, character(1))
  header_parts <- c(
    '<th scope="col">Figure / measure</th>',
    if (show_what) '<th scope="col">What it means</th>' else character(),
    '<th scope="col">Latest value</th>',
    paste0('<th scope="col">', esc(comparator_header), '</th>'),
    if (show_trend) '<th scope="col">Trend</th>' else character(),
    '<th scope="col">Initial reading</th>',
    '<th scope="col">Human check</th>'
  )
  table_class <- if (show_what || show_trend) "nhs-kfe-table" else "nhs-kfe-table nhs-kfe-table--brief"
  paste0(
    '<section class="nhs-section key-figures-explained">',
    '<h2>', esc(title), '</h2>',
    '<p>', intro_text, '</p>',
    trend_note_html,
    '<div class="nhs-table-wrap"><table class="', table_class, '">',
    '<thead><tr>',
    paste(header_parts, collapse = ""),
    '</tr></thead><tbody>',
    paste(rows_html, collapse = "\n"),
    '</tbody></table></div>',
    supporting_html,
    '</section>'
  )
}

extend_process_steps <- function(steps) {
  c(steps, STANDARD_PROCESS_SUFFIX)
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
  commentary_cards_block(cards)
}

theme_commentary_section <- function(cards, intro = NULL) {
  commentary_cards_block(cards)
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

agent_brief_sections <- function(config, key_findings_html, verify_body_html,
                               supporting_html = "") {
  audit_trail_extra <- paste0(
    if (!is.null(config$prompt_excerpt) && nzchar(config$prompt_excerpt)) {
      collapsible_details("Prompt excerpt", agent_prompt_box(config$prompt_excerpt))
    } else {
      ""
    },
    supporting_html
  )
  scope <- config$scope %||% list()
  paste0(
    what_agent_asked_section(config$question, config$dataset_line),
    data_used_section(config),
    scope_section(scope$can %||% list(), scope$cannot %||% list()),
    headline_reading_section(config$headline %||% list()),
    if (!is.null(config$grouped_findings) && length(config$grouped_findings) > 0) {
      findings_group_section(config$grouped_findings)
    } else {
      ""
    },
    key_findings_html,
    agent_summary_section(config$agent_summary),
    human_checks_section(config$human_checks),
    verify_section(
      config$verify_intro %||% verify_intro_short(),
      paste0(verify_body_html, audit_trail_extra)
    ),
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

  nof_lookup <- nof_commentary_lookup()
  nof_kfe_specs <- lapply(seq_len(nrow(audit_source)), function(i) {
    row <- audit_source[i, , drop = FALSE]
    id <- trimws(as.character(row$Metric_ID))
    entry <- nof_lookup[[id]]
    plain <- if (!is.null(entry)) entry$plain_meaning else trimws(as.character(row$Metric_description))
    human <- if (!is.null(entry)) entry$human_check else "Confirm metric definition and rank polarity against NHS England NOF specification."
    rank_txt <- trimws(as.character(row$Rank))
    median_txt <- trimws(as.character(row$Median_value))
    val_txt <- trimws(as.character(row$Value))
    peer_pos <- if (is.na(to_num(median_txt)) && is.na(to_num(rank_txt))) {
      "Median and rank not published for this metric in the extract."
    } else {
      base <- format_peer_position_short(median_txt, rank_txt)
      if (id == "OF0086") {
        paste0(base, " A value of 100 is approximately expected cost for this metric.")
      } else {
        base
      }
    }
    list(
      figure = paste0(id, " — ", plain),
      what = plain,
      latest = paste0(val_txt, " (", latest_q, ")"),
      comparator_type = if (is.na(to_num(median_txt)) && is.na(to_num(rank_txt))) "none" else "peer_median",
      comparator_detail = peer_pos,
      trend = NULL,
      polarity = "definition",
      trend_override = "Not available from current NOF extract",
      trend_note = paste0("Cross-sectional snapshot for ", latest_q, " — no historic NOF trend in this brief."),
      interpretation = nof_agent_reading(entry, row),
      human_check = short_human_check(human)
    )
  })

  kfe_supporting <- paste0(
    collapsible_details("Full metric table and domain summary", key_figures),
    collapsible_details("Additional metric commentary cards", commentary_html)
  )

  nof_trend_note <- paste(
    "There is no historic trend in this NOF extract, so the report cannot say whether performance is improving or worsening.",
    "Peer median and published rank are NHS England fields — not recalculated.",
    "The peer median is a comparator, not a local target.",
    "Metric polarity varies — check the official specification before drawing conclusions."
  )

  kfe_html <- key_figures_explained_section(
    nof_kfe_specs,
    paste(
      "The detailed table below gives the full metric list.",
      "For each metric, the peer median and published rank are taken from NHS England's source file.",
      "They are not recalculated in this demonstration."
    ),
    supporting_html = "",
    show_trend = FALSE,
    trend_note = nof_trend_note,
    comparator_header = "Peer position"
  )

  config <- list(
    question = paste(
      "Using the latest public NHS Oversight Framework file for mental health and community trusts,",
      "prepare a first-draft RDY performance brief: which raw metrics exist,",
      "what do published median/rank fields show, and what must a human verify?"
    ),
    dataset_line = "NHS Oversight Framework MH/community CSV (RDY)",
    prompt_excerpt = paste(
      "Locate NHS England NOF MH/community trust CSV. Filter Trust_code=RDY.",
      "Use latest quarter raw metrics (OF0xxx) only. Do not recalculate median or rank.",
      "Summarise domains and ranked metrics descriptively. Flag rank-direction uncertainty.",
      "No causal claims. Include verification paths to raw rows.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Show where RDY appears to sit against published peer median and rank fields.",
        "Help identify areas that may need local review."
      ),
      cannot = c(
        "Explain why a metric is high or low.",
        "Confirm whether the public figure matches the latest internal position, local definitions or operational context."
      )
    ),
    headline = c(
      paste0("The public NOF snapshot includes ", n_metrics, " raw RDY metrics across ", n_domains, " domains."),
      "The strongest-looking published ranks are for community waits over 52 weeks and planned surplus/deficit — both still need definition checks before being described as positive performance.",
      "The main areas flagged for local review are urgent community response 2-hour performance, mental health crisis face-to-face contact within 24 hours, adult mental health inpatients with length of stay over 60 days, and relative difference in costs.",
      "Finance metrics need specific finance-owner interpretation because the public fields do not explain the local plan, sign convention or internal reporting context.",
      "There is no historic trend in this NOF extract, so the report cannot say whether performance is improving or worsening."
    ),
    grouped_findings = nof_build_grouped_findings(audit_source, nof_lookup),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>NHS Oversight Framework (<code>demo_nof_overview.csv</code> + full RDY processed extract)</li>',
      '<li>Assurance index (<code>demo_assurance_profile.csv</code>) where available</li>',
      '</ul>'
    ),
    period = period_text,
    trend_available = "Not available — cross-sectional NOF snapshot only",
    agent_summary = c(
      paste0("Across ", latest_q, ", ", n_metrics, " raw NOF metrics span ", n_domains, " domains — several show strong published ranks (e.g. OF0005, OF0079) but need definition checks."),
      "The agent flags OF0063, OF0057, OF0016 and OF0086 for local review where RDY sits below peer median on access/long-stay or above on cost index.",
      "Finance metrics (OF0079, OF0081, OF0086) need finance-owner interpretation — the agent does not assume surplus/deficit meaning.",
      "This snapshot cannot explain why performance changed or what action is needed without local validation."
    ),
    human_checks = standard_human_checks(),
    verify_intro = verify_intro_short(
      paste0(
        '<li><a href="../public-data/processed/demo_nof_overview.csv">demo_nof_overview.csv</a></li>',
        '<li><a href="../public-data/metadata/public_report_audit_nof_overview.csv">Audit CSV</a></li>',
        '<li><a href="../public-data/metadata/public_report_audit_nof_overview.md">Audit MD</a></li>'
      ),
      "Each ranked metric traces to the NHS England NOF file via the audit CSV — median and rank are pass-through fields, not recalculated."
    )
  )

  verify_body <- nof_audit_verify_body(audit_df, raw_display, raw_url)

  body <- paste0(
    agent_brief_sections(config, kfe_html, verify_body, kfe_supporting),
    collapsible_details("Related assurance sources index", assurance_html)
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
    list(value = "See note", label = "Referral sum (not a valid headline KPI)")
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

  mhs23_trend_df <- load_trend_file("trend_mhs23_rdy.csv")
  trend_mhs23 <- extract_stacked_trend(mhs23_trend_df, measure_id = "MHS23", label = "MHS23 — open referrals at end of RP")
  mhs23_gap_note <- file.path(metadata_dir, "mhs23_trend_not_available.md")

  fmt_val <- function(v) {
    if (is.na(v$num)) if (is_suppressed(v$raw)) "*" else "—" else format(v$num, big.mark = ",")
  }

  trend_note_mhs23 <- if (isTRUE(trend_mhs23$available)) {
    paste0(
      "Stacked from MHSDS main data monthly files (not time-series bundle): ",
      format(trend_mhs23$latest_value, big.mark = ","), " (", trend_mhs23$latest_period, ") vs ",
      format(trend_mhs23$previous_value, big.mark = ","), " (", trend_mhs23$previous_period, ")."
    )
  } else if (file.exists(mhs23_gap_note)) {
    "MHS23 not in Provider time-series extract — see metadata/mhs23_trend_not_available.md for historic stack status."
  } else {
    "MHS23 (open referrals) is not present in the Provider time-series extract — trend not shown for this measure."
  }
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

  mhs23_latest_text <- if (isTRUE(trend_mhs23$available)) {
    kfe_from_trend(trend_mhs23)
  } else if (is_suppressed(mhs23$raw)) {
    format_kfe_latest("*", period, suppressed = TRUE)
  } else {
    format_kfe_latest(fmt_val(mhs23), period)
  }

  commentary_cards <- c(
    build_commentary_card(
      "MHS23 — Open referrals at end of reporting period",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Count of people with an open referral to mental health services at the last day of the month.",
        "Latest value (provider row)" = paste0(fmt_val(mhs23), " for ", period),
        "Comparator / trend" = paste0(trend_note_mhs23, if (!isTRUE(trend_mhs23$available)) " Demo table shows a single month only for this measure." else ""),
        "Agent flag" = "Review locally",
        "Cautious interpretation" = paste0(
          "Open referrals are a caseload-style stock measure, not new demand. ",
          "The agent would not treat ", fmt_val(mhs23), " as a headline access KPI without confirming scope."
        ),
        "Human check required" = "MHSDS/data owner to confirm open-referral definition and alignment with local caseload reporting."
      )
    ),
    build_commentary_card(
      "MHS01 — People in contact with services at end of reporting period",
      if (isTRUE(trend_mhs01$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(trend_mhs01$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "People actively in contact with MH services at month end.",
        "Latest value (provider row)" = paste0(fmt_val(mhs01), " (demo month)"),
        "Comparator / trend" = trend_line(trend_mhs01),
        "Agent flag" = if (isTRUE(trend_mhs01$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = "Month-on-month movement may reflect activity, discharge or coding — descriptive only.",
        "Human check required" = "Confirm whether local in-contact definition matches MHSDS."
      )
    ),
    build_commentary_card(
      "MHS29 — Contacts in reporting period",
      if (isTRUE(trend_mhs29$available)) "Watch / clarify" else "Trend not available",
      if (isTRUE(trend_mhs29$available)) "watch" else "definition",
      list(
        "Plain-English meaning" = "Total care contacts recorded in the month.",
        "Latest value (provider row)" = if (is.na(mhs29$num)) "See time series" else fmt_val(mhs29),
        "Comparator / trend" = trend_line(trend_mhs29),
        "Agent flag" = if (isTRUE(trend_mhs29$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = "Contacts can rise with intensity of support or data quality.",
        "Human check required" = "Service/BI owner to confirm contact counting rules."
      )
    ),
    build_commentary_card(
      "Suppression and breakdown mixing",
      "Watch / clarify", "watch",
      list(
        "Plain-English meaning" = paste0(n_supp, " of ", nrow(prov), " RDY rows show '*'."),
        "Latest value" = paste0(n_numeric, " numeric values published"),
        "Comparator / trend" = "Suppression may differ by month.",
        "Agent flag" = "Watch / clarify",
        "Cautious interpretation" = "Provider and ICB-resident breakdowns must not be summed into one headline.",
        "Human check required" = "Identify which suppressed measures matter for Dorset ICB (11J)."
      )
    )
  )

  ref_obs <- if (!is.na(ref_total)) {
    paste0("Referral-related numeric rows sum to ", format(ref_total, big.mark = ","), " across breakdowns — not a single headline referral count.")
  } else {
    "Referral-related totals were not computed as a single headline figure."
  }

  mh_kfe_specs <- list(
    list(
      figure = "MHS23 — Open referrals at end of reporting period",
      what = "Count of people with an open referral to mental health services at the last day of the month.",
      latest = mhs23_latest_text,
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_mhs23$available)) {
        paste0(
          "Previous period: ", format(trend_mhs23$previous_value, big.mark = ","),
          " (", trend_mhs23$previous_period, "). ",
          trend_mhs23$n_periods, " months in trend_mhs23_rdy.csv."
        )
      } else {
        "Latest-period value only — MHS23 not in Provider time-series extract."
      },
      trend = trend_mhs23,
      polarity = "unknown",
      interpretation = "Open referrals are a stock measure — higher counts are not automatically worse. Local review needed.",
      human_check = short_human_check("MHSDS/data owner to confirm open-referral definition and alignment with local caseload reporting.")
    ),
    list(
      figure = "MHS01 — People in contact at end of reporting period",
      what = "People actively in contact with mental health services at month end.",
      latest = if (isTRUE(trend_mhs01$available)) kfe_from_trend(trend_mhs01) else format_kfe_latest(fmt_val(mhs01), period),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_mhs01$available)) {
        paste0(
          "Previous period: ", format(trend_mhs01$previous_value, big.mark = ","),
          " (", trend_mhs01$previous_period, "). ",
          trend_mhs01$n_periods, " months in Provider time series."
        )
      } else {
        "Insufficient periods in Provider time-series extract."
      },
      trend = trend_mhs01,
      polarity = "unknown",
      interpretation = "Month-on-month movement may reflect activity, discharge or coding — descriptive only, not cause.",
      human_check = short_human_check("Confirm whether local in-contact definition matches MHSDS and whether the provisional month has refreshed.")
    ),
    list(
      figure = "MHS29 — Contacts in reporting period",
      what = "Total care contacts recorded in the month — activity volume, not unique patients.",
      latest = if (isTRUE(trend_mhs29$available)) kfe_from_trend(trend_mhs29) else format_kfe_latest(fmt_val(mhs29), period),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_mhs29$available)) {
        paste0(
          "Previous period: ", format(trend_mhs29$previous_value, big.mark = ","),
          " (", trend_mhs29$previous_period, "). Provider RDY rows from MHSDS time series."
        )
      } else {
        "Provider RDY rows from MHSDS time-series extract."
      },
      trend = trend_mhs29,
      polarity = "unknown",
      interpretation = "Contacts can rise with intensity of support or data quality — not automatically good or bad access.",
      human_check = short_human_check("Service/BI owner to confirm contact counting rules and operational narrative.")
    ),
    list(
      figure = "MHS69 — CYP with at least two contacts",
      what = "Children and young people receiving at least two contacts where first contact was before 18th birthday.",
      latest = if (isTRUE(trend_mhs69$available)) kfe_from_trend(trend_mhs69) else "See demo table — ICB-resident rows may be suppressed",
      comparator_type = "previous_period",
      comparator_detail = paste0(n_supp, " suppressed cells in demo extract — do not infer from missing values."),
      trend = trend_mhs69,
      polarity = "unknown",
      interpretation = "Do not infer CYP access from suppressed ICB-resident rows alone. Interpret cautiously — confirm cohort and scope.",
      human_check = short_human_check("CYP mental health lead to confirm resident vs provider scope.")
    ),
    list(
      figure = "Suppression in RDY extract",
      what = paste0("Measure rows where MEASURE_VALUE is '*' (withheld under disclosure rules)."),
      latest = paste0(n_supp, " of ", nrow(prov), " rows suppressed"),
      comparator_type = "none",
      comparator_detail = "Suppression may differ by month.",
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Not available from current extract",
      interpretation = "Summing referral-related rows across breakdowns is not a valid trust-wide headline.",
      human_check = short_human_check("Identify which suppressed measures matter for Dorset ICB (11J).")
    )
  )

  mh_trends <- list(trend_mhs01, trend_mhs29, trend_mhs69)
  if (isTRUE(trend_mhs23$available)) mh_trends <- c(mh_trends, list(trend_mhs23))

  supporting_html <- paste0(
    collapsible_details("Supporting tables and charts", key_figures),
    collapsible_details("Additional measure commentary", measure_commentary_section(commentary_cards)),
    wrap_trend_collapsible(
      trend_section(
        mh_trends,
        paste0(ts_file_note, if (!is.null(mhs23_trend_df)) "; MHS23 from trend_mhs23_rdy.csv" else ""),
        c(
          "MHSDS monthly data are provisional; months may revise on final refresh.",
          "Trend labels describe direction of change only — not operational cause."
        )
      )
    )
  )

  mh_kfe_html <- key_figures_explained_section(
    mh_kfe_specs,
    paste(
      "Key MHSDS access and activity measures for RDY as provider.",
      "MHS23 open referrals uses trend_mhs23_rdy.csv where available — it is not in the Provider time-series bundle.",
      paste0(n_supp, " suppressed cells in this extract — check before using any figure operationally.")
    ),
    comparator_header = "Previous period / comparator"
  )

  config <- list(
    question = paste(
      "From public MHSDS data for RDY, explain key access and activity measures,",
      "where month-on-month trends are supported, and what a mental health data owner must confirm."
    ),
    dataset_line = "MHSDS Monthly Statistics (RDY provider rows)",
    prompt_excerpt = paste(
      "Filter provider RDY from MHSDS monthly CSV.",
      "Compute trends from downloaded time-series file (Provider breakdown).",
      "Do not sum incompatible breakdowns. No causal claims.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Describe key MHSDS access and activity measures for RDY as provider.",
        "Show descriptive month-on-month trends where the public time-series or trend files support them.",
        "Flag suppression and breakdown mixing that affects interpretation."
      ),
      cannot = c(
        "Support operational access conclusions or pathway performance without local MHSDS validation.",
        "Combine provider and ICB-resident breakdowns into a single trust-wide headline.",
        "Explain why month-on-month movement occurred."
      )
    ),
    headline = c(
      paste0("For ", period, ", ", nrow(prov), " RDY measure rows (", n_numeric, " numeric, ", n_supp, " suppressed)."),
      if (isTRUE(trend_mhs01$available)) {
        paste0(
          "MHS01 in-contact counts show descriptive month-on-month movement (",
          format(trend_mhs01$previous_value, big.mark = ","), " to ",
          format(trend_mhs01$latest_value, big.mark = ","), ") — not cause."
        )
      } else {
        "Multi-period Provider time series not available for all key measures."
      },
      paste0(ref_obs, " Provider and ICB-resident breakdowns must not be summed into one headline."),
      "Open referrals (MHS23) are a stock measure — higher counts are not automatically worse without local definition checks."
    ),
    grouped_findings = list(
      list(
        title = "Access and stock measures",
        items = list(
          list(
            title = "MHS23 — Open referrals at end of reporting period",
            body = paste0(
              "Open referrals are a caseload-style stock measure, not new demand. Latest value: ",
              fmt_val(mhs23), ". ", trend_note_mhs23
            ),
            owner = "MHSDS/data owner to confirm open-referral definition and alignment with local caseload reporting."
          ),
          list(
            title = "MHS01 — People in contact at end of reporting period",
            body = paste0(
              "People actively in contact with MH services at month end. Latest: ", fmt_val(mhs01), ". ",
              trend_line(trend_mhs01), " Month-on-month movement may reflect activity, discharge or coding — descriptive only."
            ),
            owner = "Confirm whether local in-contact definition matches MHSDS."
          )
        )
      ),
      list(
        title = "Activity measures",
        items = list(
          list(
            title = "MHS29 — Contacts in reporting period",
            body = paste0(
              "Total care contacts recorded in the month. ",
              trend_line(trend_mhs29), " Contacts can rise with intensity of support or data quality."
            ),
            owner = "Service/BI owner to confirm contact counting rules."
          ),
          list(
            title = "MHS69 — CYP with at least two contacts",
            body = "Children and young people receiving at least two contacts where first contact was before 18th birthday. Do not infer CYP access from suppressed ICB-resident rows alone.",
            owner = "CYP mental health lead to confirm resident vs provider scope."
          )
        )
      ),
      list(
        title = "Data quality and suppression",
        items = list(
          list(
            title = "Suppression and breakdown mixing",
            body = paste0(
              n_supp, " of ", nrow(prov), " RDY rows show '*'. Provider and ICB-resident breakdowns must not be summed into one headline."
            ),
            owner = "Identify which suppressed measures matter for Dorset ICB (11J)."
          )
        )
      )
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>MHSDS (<code>demo_mhsds_activity.csv</code> — latest month slice)</li>',
      if (!is.null(mhsds_ts)) paste0('<li>MHSDS time series (<code>', esc(ts_file_note), '</code>)</li>') else "",
      if (!is.null(mhs23_trend_df)) '<li><code>trend_mhs23_rdy.csv</code> — MHS23 historic stack</li>' else "",
      '</ul>'
    ),
    period = period,
    trend_available = if (isTRUE(trend_mhs01$available)) {
      paste0("Yes — MHSDS Provider time series (", trend_mhs01$n_periods, "+ months); MHS23 via trend file where stacked")
    } else {
      "Limited — single month in demo extract for some measures"
    },
    agent_summary = c(
      paste0("For ", period, ", ", nrow(prov), " RDY measure rows (", n_numeric, " numeric, ", n_supp, " suppressed)."),
      if (isTRUE(trend_mhs01$available)) {
        paste0(
          "MHS01 in-contact counts show descriptive month-on-month movement (",
          format(trend_mhs01$previous_value, big.mark = ","), " to ",
          format(trend_mhs01$latest_value, big.mark = ","), ") — not cause."
        )
      } else {
        "Multi-period Provider time series not available for all key measures."
      },
      paste0(ref_obs, " Provider and ICB-resident breakdowns must not be summed into one headline."),
      "This brief cannot support operational access conclusions without local MHSDS validation."
    ),
    human_checks = standard_human_checks(list(
      list(
        q = "Are suppressed cells material for Dorset ICB (11J) residents?",
        expl = paste0(n_supp, " suppressed values — check whether key access measures are affected.")
      )
    )),
    verify_intro = verify_intro_short(
      '<li><a href="../public-data/processed/demo_mhsds_activity.csv">demo_mhsds_activity.csv</a></li>',
      "Figures trace to demo_mhsds_activity.csv and MHSDS time-series files — no derived ranks or peer medians."
    )
  )

  verify_body <- traceability_verify_body(
    "See linked demo CSV and filter notes. Trend deltas from time-series and trend_mhs23_rdy.csv where cited.",
    c("demo_mhsds_activity.csv", if (!is.null(mhsds_ts)) ts_file_note else NULL, if (!is.null(mhs23_trend_df)) "trend_mhs23_rdy.csv" else NULL),
    "mhsds_monthly",
    "mhsds_monthly"
  )

  body <- agent_brief_sections(config, mh_kfe_html, verify_body, supporting_html)

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

  csds_trend <- load_trend_file("trend_csds_activity_rdy.csv")
  trend_assess <- extract_stacked_trend(csds_trend, measure_name = "Assessment", label = "CSDS — Assessment (CareActivities)")
  trend_clin <- extract_stacked_trend(csds_trend, measure_name = "Clinical Intervention", label = "CSDS — Clinical Intervention (CareActivities)")
  csds_trend_note <- if (!is.null(csds_trend)) {
    "trend_csds_activity_rdy.csv (historic stack from script 05)"
  } else {
    "Historic CSDS trend file not found — run site/public-data/05_download_historic_public_data.R"
  }
  csds_trend_line <- function(t) {
    if (isTRUE(t$available)) {
      paste0(
        "Latest vs previous month: ",
        format(t$latest_value, big.mark = ","), " (", t$latest_period, ") vs ",
        format(t$previous_value, big.mark = ","), " (", t$previous_period, ")"
      )
    } else if (!is.null(csds_trend)) {
      "Historic trend file present but fewer than two comparable periods for this measure."
    } else {
      "Trend not available — historic stack not yet generated."
    }
  }

  csds_has_trend <- isTRUE(trend_assess$available) || isTRUE(trend_clin$available)

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
        "Comparator / trend" = csds_trend_line(trend_assess),
        "Agent flag" = if (is.na(assess_n) || assess_n == 0) "Watch / clarify" else "Review locally",
        "Cautious interpretation" = "Activity counts reflect coded CSDS submissions — not unique patients.",
        "Human check required" = "Community services/BI owner to confirm activity coding."
      )
    ),
    build_commentary_card(
      "Care activities — Clinical Intervention",
      "Review locally", "review",
      list(
        "Plain-English meaning" = "Direct clinical intervention activities in community services for the month.",
        "Latest value" = if (is.na(clin_n)) "—" else format(clin_n, big.mark = ","),
        "Comparator / trend" = csds_trend_line(trend_clin),
        "Agent flag" = "Review locally",
        "Cautious interpretation" = "Largest activity type where numeric — confirm service scope locally.",
        "Human check required" = "Directorate lead to confirm which services feed this measure."
      )
    )
  )

  csds_kfe_specs <- list(
    list(
      figure = "Care activities — Assessment",
      what = "Count of assessment-type care activities recorded in CSDS for the month (CareActivities / ActivityType).",
      latest = if (is.na(assess_n)) "—" else format_kfe_latest(format(assess_n, big.mark = ","), "March 2026"),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_assess$available)) {
        paste0(
          "Previous period: ", format(trend_assess$previous_value, big.mark = ","),
          " (", trend_assess$previous_period, "). No official standard in public CSDS extract."
        )
      } else {
        "Latest month only — no multi-period trend for Assessment."
      },
      trend = trend_assess,
      polarity = "unknown",
      interpretation = "Activity counts reflect coded CSDS submissions — not unique patients or completed care pathways.",
      human_check = short_human_check("Community services/BI owner to confirm activity coding and whether this matches local community dashboards.")
    ),
    list(
      figure = "Care activities — Clinical Intervention",
      what = "Direct clinical intervention activities in community services for the month.",
      latest = if (is.na(clin_n)) "—" else format_kfe_latest(format(clin_n, big.mark = ","), "March 2026"),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_clin$available)) {
        paste0(
          "Previous period: ", format(trend_clin$previous_value, big.mark = ","),
          " (", trend_clin$previous_period, "). Historic stack: trend_csds_activity_rdy.csv."
        )
      } else {
        csds_trend_note
      },
      trend = trend_clin,
      polarity = "unknown",
      interpretation = "Largest activity type where numeric — confirm service scope locally before review use.",
      human_check = short_human_check("Directorate lead to confirm which services feed this measure and coding QA for March 2026.")
    ),
    list(
      figure = "Total care activities (ActivityType slice)",
      what = "Sum of numeric CareActivities rows in the ActivityType dimension for March 2026 demo month.",
      latest = format_kfe_latest(format(total_contacts, big.mark = ","), "March 2026"),
      comparator_type = "none",
      comparator_detail = "Aggregate sum for one month — not trended as a single total in historic stack.",
      trend = NULL,
      polarity = "unknown",
      trend_override = if (csds_has_trend) "Mixed / unclear" else "Not available from current extract",
      trend_note = if (csds_has_trend) "Total not trended — see Assessment and Clinical Intervention rows for month-on-month change." else "Historic stack missing or insufficient periods.",
      interpretation = "Public CSDS aggregates cannot support team-level or pathway conclusions without local drill-down.",
      human_check = short_human_check("Confirm full RDY processed extract contains all measures needed — demo slice may not surface every row.")
    ),
    list(
      figure = "Age-band columns (0–18, 19–64, 65+)",
      what = "Published splits of the same activity count by broad age band where supplied.",
      latest = "See activity table — splits vary by activity type",
      comparator_type = "none",
      comparator_detail = "Age-band time series not available in current historic CSDS stack.",
      trend = NULL,
      polarity = "definition",
      trend_override = "Not available from current extract",
      interpretation = "Age splits help directorate review but may not match local age definitions or service lines.",
      human_check = short_human_check("Validate CYP vs adult splits with the CSDS return owner before directorate use.")
    )
  )

  csds_kfe_html <- key_figures_explained_section(
    csds_kfe_specs,
    paste(
      "March 2026 community activity for RDY.",
      if (csds_has_trend) paste0("Assessment and Clinical Intervention trends use ", trend_assess$n_periods %||% trend_clin$n_periods, "-month historic stack.") else "Historic trend limited or not available — latest month only for some measures.",
      "Public aggregate CSDS cannot support team-level or pathway conclusions."
    ),
    comparator_header = "Previous period / comparator"
  )

  csds_trend_html <- if (isTRUE(trend_assess$available) || isTRUE(trend_clin$available)) {
    trend_section(
      list(trend_assess, trend_clin),
      csds_trend_note,
      c(
        "Provisional CSDS monthly data; ActivityType/CareActivities slice only.",
        "Trend describes direction of change only — not operational cause."
      )
    )
  } else {
    trend_not_available_section(c(
      "Additional monthly CSDS public files for consecutive months",
      "Consistent measure and ActivityType filters across periods"
    ))
  }

  supporting_html <- paste0(
    collapsible_details("Supporting tables and charts", key_figures),
    collapsible_details("Additional measure commentary", measure_commentary_section(commentary_cards)),
    wrap_trend_collapsible(csds_trend_html)
  )

  config <- list(
    question = paste(
      "Using public CSDS for March 2026, explain community activity measures,",
      "show descriptive trends where the historic stack supports them,",
      "and what a business partner should validate locally."
    ),
    dataset_line = "CSDS Monthly Statistics (RDY provider rows)",
    prompt_excerpt = paste(
      "Filter CSDS monthly CSV to RDY. Inspect CareActivities by ActivityType.",
      "Use trend_csds_activity_rdy.csv for month-on-month trends where ≥2 periods exist.",
      "No causal language.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Describe March 2026 community activity totals and key activity types for RDY.",
        "Show descriptive month-on-month trends for Assessment and Clinical Intervention where the historic stack supports them."
      ),
      cannot = c(
        "Prove referral demand, waiting times or team performance from public aggregate CSDS.",
        "Support pathway or team-level conclusions without local drill-down."
      )
    ),
    headline = c(
      paste0("For ", period, ", care activity totals sum to ", format(total_contacts, big.mark = ","), " in the ActivityType slice."),
      if (csds_has_trend) "Historic CSDS stack supports descriptive month-on-month comparison for Assessment and Clinical Intervention — not causal conclusions." else "Trend analysis not available from current extract.",
      "Public aggregate CSDS cannot prove referral demand, waiting times or team performance.",
      "Sparse or zero activity in the demo slice needs local coding confirmation."
    ),
    grouped_findings = list(
      list(
        title = "Activity with trend support",
        items = list(
          list(
            title = "Care activities — Assessment",
            body = paste0(
              "Assessment-type care activities for March 2026: ",
              if (is.na(assess_n)) "—" else format(assess_n, big.mark = ","), ". ",
              csds_trend_line(trend_assess)
            ),
            owner = "Community services/BI owner to confirm activity coding."
          ),
          list(
            title = "Care activities — Clinical Intervention",
            body = paste0(
              "Direct clinical intervention activities: ",
              if (is.na(clin_n)) "—" else format(clin_n, big.mark = ","), ". ",
              csds_trend_line(trend_clin)
            ),
            owner = "Directorate lead to confirm which services feed this measure."
          )
        )
      ),
      list(
        title = "Aggregate limits",
        items = list(
          list(
            title = "Total care activities and age bands",
            body = paste0(
              "Total ActivityType slice sums to ", format(total_contacts, big.mark = ","),
              ". Age-band splits vary by activity type and are not trended in the current stack."
            ),
            owner = "Validate CYP vs adult splits with the CSDS return owner before directorate use."
          )
        )
      )
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>CSDS (<code>demo_csds_activity.csv</code> — March 2026)</li>',
      if (!is.null(csds_trend)) '<li><code>trend_csds_activity_rdy.csv</code> — historic CareActivities stack</li>' else "",
      '</ul>'
    ),
    period = period,
    trend_available = if (csds_has_trend) {
      paste0("Yes — ", trend_assess$n_periods %||% trend_clin$n_periods, "-month historic stack for key activity types")
    } else {
      "Limited — latest month only or insufficient comparable periods"
    },
    agent_summary = c(
      paste0("For ", period, ", care activity totals sum to ", format(total_contacts, big.mark = ","), " in the ActivityType slice."),
      if (csds_has_trend) "Historic CSDS stack supports descriptive month-on-month comparison for Assessment and Clinical Intervention — not causal conclusions." else "Trend analysis not available from current extract.",
      "Public aggregate CSDS cannot prove referral demand, waiting times or team performance.",
      "Sparse or zero activity in the demo slice needs local coding confirmation."
    ),
    human_checks = standard_human_checks(),
    verify_intro = verify_intro_short(
      '<li><a href="../public-data/processed/demo_csds_activity.csv">demo_csds_activity.csv</a></li>',
      "March 2026 values from demo CSV; trend deltas from trend_csds_activity_rdy.csv where cited."
    )
  )

  verify_body <- traceability_verify_body(
    "See linked demo CSV and filter notes.",
    c("demo_csds_activity.csv", if (!is.null(csds_trend)) "trend_csds_activity_rdy.csv" else NULL),
    "csds_monthly"
  )

  body <- agent_brief_sections(config, csds_kfe_html, verify_body, supporting_html)

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

  m053_val <- to_num(prov[prov$MEASURE_ID == "M053", "MEASURE_VALUE_SUPPRESSED"][1])

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
    list(value = if (is.na(wait_total)) "—" else format(wait_total, big.mark = ","), label = "Open referrals no activity (M019–M021 only)"),
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
        "Plain-English meaning" = "Count of new referrals received in the month.",
        "Latest value" = if (is.na(refs_n)) "—" else format(refs_n, big.mark = ","),
        "Comparator / trend" = trend_line(trend_m001),
        "Agent flag" = if (isTRUE(trend_m001$available)) "Watch / clarify" else "Trend not available",
        "Cautious interpretation" = "Referral counts move with demand and recording — descriptive only.",
        "Human check required" = "IAPT/data owner to confirm M001 matches local reporting."
      )
    ),
    build_commentary_card(
      "M053 — Six-week access (finished course)",
      "Definition check required", "definition",
      list(
        "Plain-English meaning" = "Percentage accessing within 6 weeks among those finishing treatment.",
        "Latest value" = if (is.na(m053_val)) "—" else paste0(m053_val, "%"),
        "Comparator / trend" = trend_line(trend_m053),
        "Agent flag" = "Definition check required",
        "Cautious interpretation" = "Not clinical quality without outcome definitions.",
        "Human check required" = "Confirm national IAPT access definition locally."
      )
    )
  )

  tt_kfe_specs <- list(
    list(
      figure = "M001 — Referrals received",
      what = "Count of new referrals received in the month — inflow measure, not caseload.",
      latest = if (isTRUE(trend_m001$available)) kfe_from_trend(trend_m001) else format_kfe_latest(if (is.na(refs_n)) "—" else format(refs_n, big.mark = ","), period),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_m001$available)) {
        paste0(
          "Previous period: ", format(trend_m001$previous_value, big.mark = ","),
          " (", trend_m001$previous_period, "). ",
          trend_m001$n_periods, " months in Provider time series."
        )
      } else {
        "Insufficient periods in Provider time-series extract."
      },
      trend = trend_m001,
      polarity = "unknown",
      interpretation = "Referral counts move with demand, pathways and recording — month-on-month change is descriptive only.",
      human_check = short_human_check("IAPT/data owner to confirm M001 matches local referrals reporting for the same period.")
    ),
    list(
      figure = "M031 — People accessing services",
      what = "People who accessed talking therapies services during the month.",
      latest = if (isTRUE(trend_m031$available)) kfe_from_trend(trend_m031) else format_kfe_latest(if (is.na(accessing_n)) "—" else format(accessing_n, big.mark = ","), period),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_m031$available)) {
        paste0(
          "Previous period: ", format(trend_m031$previous_value, big.mark = ","),
          " (", trend_m031$previous_period, "). No verified access standard in extract."
        )
      } else {
        "No verified access standard in downloaded extract."
      },
      trend = trend_m031,
      polarity = "unknown",
      interpretation = "Access counts differ from referrals received and from people finishing treatment — do not conflate.",
      human_check = short_human_check("Confirm access definition and whether self-referral surge affects month-on-month movement.")
    ),
    list(
      figure = "M053 — Six-week access (finished course)",
      what = "Percentage accessing services within 6 weeks among those finishing a course of treatment.",
      latest = if (isTRUE(trend_m053$available)) {
        paste0(trend_m053$latest_value, "% (", trend_m053$latest_period, ")")
      } else if (is.na(m053_val)) "—" else paste0(m053_val, "% (", period, ")"),
      comparator_type = "none",
      comparator_detail = "No verified national threshold present in the downloaded public extract for this demo.",
      trend = trend_m053,
      polarity = "higher_better",
      interpretation = "Percentage measures need denominator checks — high values may still mask subgroup gaps. Finance or definition check required.",
      human_check = short_human_check("Confirm national IAPT access definition and whether local enter-treatment waits use the same cohort.")
    ),
    list(
      figure = "M019–M022 — Open referrals with no activity (waiting bands)",
      what = "Open referrals with no recorded activity for 60, 61–90, 91–120 or 120+ days — waiting-style stock measures.",
      latest = paste0("M019–M021 sum: ", if (is.na(wait_total)) "—" else format(wait_total, big.mark = ","), " (", period, ")"),
      comparator_type = "none",
      comparator_detail = "Waiting bands not consistently trended in this brief.",
      trend = NULL,
      polarity = "lower_better",
      trend_override = "Not available from current extract",
      trend_note = "Waiting-band measures shown as latest-period values only.",
      interpretation = "Large 'no activity' counts may reflect pathway recording, not necessarily clinical risk — local validation required.",
      human_check = short_human_check("Pathway owner to confirm how 'no activity' is coded vs local waiting list and enter-treatment tracking.")
    ),
    list(
      figure = "Suppression (Provider RDY rows)",
      what = paste0("Measures withheld as '*' under disclosure rules in the demo extract."),
      latest = paste0(n_supp, " of ", nrow(prov), " provider rows suppressed"),
      comparator_type = "none",
      comparator_detail = "Suppression may vary by month.",
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Not available from current extract",
      interpretation = "Do not infer from missing cells; small-number referral sources are often suppressed.",
      human_check = short_human_check("Review monthly IAPT DQ report and whether suppressed measures matter for your question.")
    )
  )

  tt_kfe_html <- key_figures_explained_section(
    tt_kfe_specs,
    paste(
      "Access and waiting measures for RDY as provider.",
      paste0(n_supp, " suppressed cells — do not infer from missing values."),
      "Recovery/outcome measures (e.g. M192, M186) exist in the full CSV but are not inferred in this access brief."
    ),
    comparator_header = "Previous period / comparator"
  )

  supporting_html <- paste0(
    collapsible_details("Supporting tables and charts", key_figures),
    collapsible_details("Additional measure commentary", measure_commentary_section(commentary_cards)),
    wrap_trend_collapsible(
      trend_section(
        list(trend_m001, trend_m031, trend_m053),
        ts_file_note,
        c(
          "IAPT monthly statistics are provisional and may revise.",
          "Trend descriptions are not causal — pathway and recording changes may explain movement."
        )
      )
    )
  )

  config <- list(
    question = paste(
      "From public NHS Talking Therapies data for RDY, explain referrals, access and waiting measures,",
      "show trends where the time-series extract supports them, and list what outcome analysis would require."
    ),
    dataset_line = "NHS Talking Therapies Monthly Statistics (RDY provider rows)",
    prompt_excerpt = paste(
      "Filter IAPT monthly CSV to ORG_CODE2=RDY, Provider group.",
      "Trend from downloaded time-series file only. No recovery inference. No causal claims.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Describe referrals, access and waiting measures for RDY as provider.",
        "Show descriptive month-on-month trends where the Provider time series supports them."
      ),
      cannot = c(
        "Infer recovery or clinical outcomes from access measures alone.",
        "Draw conclusions from suppressed cells or missing values."
      )
    ),
    headline = c(
      if (!is.na(refs_n)) paste0(format(refs_n, big.mark = ","), " referrals received (M001) for ", period, " — local validation required.") else "M001 referrals not numeric in extract.",
      if (!is.na(wait_total)) paste0("Open referral 'no activity' bands total ", format(wait_total, big.mark = ","), " — pathway owner confirmation needed.") else "Waiting bands need local pathway definitions.",
      paste0(n_supp, " suppressed measures — do not infer from missing cells."),
      "Recovery/outcome analysis requires separate definition checks — not included in this access brief."
    ),
    grouped_findings = list(
      list(
        title = "Access and waiting",
        items = list(
          list(
            title = "M001 — Referrals received",
            body = paste0(
              "New referrals received in the month. Latest: ",
              if (is.na(refs_n)) "—" else format(refs_n, big.mark = ","), ". ",
              trend_line(trend_m001)
            ),
            owner = "IAPT/data owner to confirm M001 matches local reporting."
          ),
          list(
            title = "M031 — People accessing services",
            body = paste0(
              "People who accessed talking therapies during the month. ",
              trend_line(trend_m031), " Access counts differ from referrals received — do not conflate."
            ),
            owner = "Confirm access definition and whether self-referral surge affects month-on-month movement."
          ),
          list(
            title = "M053 — Six-week access (finished course)",
            body = paste0(
              "Percentage accessing within 6 weeks among those finishing treatment. Latest: ",
              if (is.na(m053_val)) "—" else paste0(m053_val, "%"), ". Denominator checks required."
            ),
            owner = "Confirm national IAPT access definition locally."
          )
        )
      ),
      list(
        title = "Suppression and outcomes gap",
        items = list(
          list(
            title = "Waiting bands and suppression",
            body = paste0(
              "M019–M021 sum: ", if (is.na(wait_total)) "—" else format(wait_total, big.mark = ","),
              ". ", n_supp, " suppressed provider rows — do not infer from missing cells."
            ),
            owner = "Pathway owner to confirm 'no activity' coding vs local waiting lists."
          ),
          list(
            title = "Recovery/outcome measures not inferred",
            body = "Recovery/outcome measures (e.g. M192, M186) exist in the full CSV but are not inferred in this access brief.",
            owner = "Separate outcome analysis requires definition checks with the IAPT lead."
          )
        )
      )
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>NHS Talking Therapies (<code>demo_talking_therapies.csv</code>)</li>',
      if (!is.null(tt_ts)) paste0('<li>Time series (<code>', esc(ts_file_note), '</code>)</li>') else "",
      '</ul>'
    ),
    period = period,
    trend_available = if (isTRUE(trend_m001$available)) {
      paste0("Yes — ", trend_m001$n_periods, "+ months in Provider time series")
    } else {
      "Limited — insufficient periods in extract"
    },
    agent_summary = c(
      if (!is.na(refs_n)) paste0(format(refs_n, big.mark = ","), " referrals received (M001) for ", period, " — local validation required.") else "M001 referrals not numeric in extract.",
      if (!is.na(wait_total)) paste0("Open referral 'no activity' bands total ", format(wait_total, big.mark = ","), " — pathway owner confirmation needed.") else "Waiting bands need local pathway definitions.",
      paste0(n_supp, " suppressed measures — do not infer from missing cells."),
      "Recovery/outcome analysis requires separate definition checks — not included in this access brief."
    ),
    human_checks = standard_human_checks(),
    verify_intro = verify_intro_short(
      '<li><a href="../public-data/processed/demo_talking_therapies.csv">demo_talking_therapies.csv</a></li>',
      "Figures trace to demo CSV and time-series file — no derived ranks or peer medians."
    )
  )

  verify_body <- traceability_verify_body(
    "See linked demo CSV and filter notes.",
    c("demo_talking_therapies.csv", if (!is.null(tt_ts)) ts_file_note else NULL),
    "talking_therapies"
  )

  body <- agent_brief_sections(config, tt_kfe_html, verify_body, supporting_html)

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

  fft_manual <- file.path(metadata_dir, "fft_manual_download_needed.md")
  fft_trend <- load_trend_file("trend_fft_rdy.csv")
  fft_trend_obj <- if (!is.null(fft_trend) && nrow(fft_trend) > 0) {
    extract_stacked_trend(fft_trend, label = "FFT — org-level aggregate")
  } else {
    list(available = FALSE)
  }

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

  assurance_kfe_specs <- list(
    list(
      figure = "KO41a — Written complaints (annual)",
      what = "Annual statutory return confirming RDY submitted written complaints data for 2024-25.",
      latest = "RDY org-level row present (2024-25 extract)",
      comparator_type = "validation_only",
      comparator_detail = "Source validation — presence confirms participation, not complaints performance standing.",
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Not available from current extract",
      trend_note = "Single annual snapshot — complaints trends need multiple years or local data.",
      interpretation = "The agent confirms source presence, not complaints performance standing.",
      human_check = short_human_check("Complaints team to confirm 2024-25 figures, PALS themes and whether public row matches internal reporting.")
    ),
    list(
      figure = "ERIC — Estates returns (annual)",
      what = "Annual estates and facilities cost/activity return — benchmarking and assurance context.",
      latest = "RDY trust row in 2024/25 ERIC extract",
      comparator_type = "none",
      comparator_detail = "Annual cadence — no peer benchmark computed in this brief.",
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Not available from current extract",
      trend_note = "Latest annual only — trend requires multiple ERIC years or local estates dashboards.",
      interpretation = "ERIC supports facilities benchmarking conversations — not a simple good/bad performance score.",
      human_check = short_human_check("Estates/facilities owner to confirm amendments file and whether board reporting uses the same year.")
    ),
    list(
      figure = "DSPT — Data Security and Protection Toolkit",
      what = "Annual IG assurance assessment status published on the DSPT organisation page.",
      latest = dspt_latest,
      comparator_type = "descriptive_history",
      comparator_detail = if (dspt_n >= 2) {
        paste0("Latest: ", dspt$Status[1], " (", dspt$`Date Published`[1], "). ", dspt_n, " published assessment rows — descriptive history only.")
      } else {
        dspt_history_note
      },
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Source validation only",
      trend_note = "Multi-year status history is descriptive assurance context — not Improving/Worsening performance trend.",
      interpretation = "'Standards met' is an annual assurance label — it does not prove day-to-day operational IG compliance.",
      human_check = short_human_check("IG/calendar owner to confirm current-year submission status and internal IG audit programme.")
    ),
    list(
      figure = "FFT — Friends and Family Test (org-level gap)",
      what = "Patient experience survey aggregate — org-level FFT rows expected in summary downloads.",
      latest = "No org-level RDY rows in downloaded FFT summary XLSX",
      comparator_type = "none",
      comparator_detail = if (file.exists(fft_manual)) "See metadata/fft_manual_download_needed.md for manual download steps." else "Org-level data not in current extract.",
      trend = fft_trend_obj,
      polarity = "validation_only",
      trend_override = "Not available from current extract",
      trend_note = "Missing org-level FFT is a workflow gap for analysts — not evidence of poor experience.",
      interpretation = "The agent documents the gap for patient experience lead follow-up.",
      human_check = short_human_check("Patient experience lead to confirm whether setting-level XLSX download fills the gap.")
    ),
    list(
      figure = "CQC — Regulatory context",
      what = "Care Quality Commission provider page captured as context note — inspection and regulatory background.",
      latest = "Context note in metadata — not a performance metric",
      comparator_type = "validation_only",
      comparator_detail = "Qualitative regulatory context only.",
      trend = NULL,
      polarity = "validation_only",
      trend_override = "Source validation only",
      interpretation = "CQC information supports assurance conversations — it must not be treated as a league table or performance proxy.",
      human_check = short_human_check("Quality/governance lead to confirm latest inspection status and internal action plans.")
    )
  )

  assurance_kfe_html <- key_figures_explained_section(
    assurance_kfe_specs,
    "Assurance sources are indexed for appropriate use — not combined into a performance score.",
    show_trend = FALSE,
    trend_note = "Assurance sources are mostly annual snapshots or descriptive history — not numeric performance trends.",
    comparator_header = "Source position / comparator"
  )

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
        "Comparator / trend" = if (isTRUE(fft_trend_obj$available)) {
          paste0(
            "Historic FFT stack: ", format(fft_trend_obj$latest_value, big.mark = ","),
            " (", fft_trend_obj$latest_period, ") vs ",
            format(fft_trend_obj$previous_value, big.mark = ","), " (", fft_trend_obj$previous_period, ")."
          )
        } else if (file.exists(fft_manual)) {
          "Org-level trend not available — see metadata/fft_manual_download_needed.md for manual download steps."
        } else {
          "Trend not available until org-level or setting-level data is obtained."
        },
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

  fft_trend_section <- if (isTRUE(fft_trend_obj$available)) {
    trend_section(
      list(fft_trend_obj),
      "trend_fft_rdy.csv",
      c(
        "FFT response rates vary; small number suppression may apply.",
        "Confirm measure definition and setting scope with patient experience lead."
      )
    )
  } else if (file.exists(fft_manual)) {
    paste0(
      '<section class="nhs-section nhs-trend-section">',
      '<h2>FFT trend not available from current extract</h2>',
      '<p>Public FFT summary XLSX files did not yield org-level RDY rows suitable for trend analysis.</p>',
      '<p>See <code>site/public-data/metadata/fft_manual_download_needed.md</code> for URLs tried and recommended manual steps.</p>',
      '</section>'
    )
  } else {
    trend_not_available_section(c(
      "Setting-level or trust-level FFT XLSX with RDY org code",
      "At least two comparable publication months",
      "Patient experience lead confirmation of response rates and suppression"
    ))
  }

  supporting_html <- paste0(
    collapsible_details("Assurance source tables and DSPT history", key_figures),
    collapsible_details("Additional source commentary", theme_commentary_section(commentary_cards)),
    wrap_trend_collapsible(dspt_trend_section, "DSPT assessment history (descriptive)"),
    if (nzchar(fft_trend_section)) wrap_trend_collapsible(fft_trend_section, "FFT trend detail") else ""
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
    question = paste(
      "Which public assurance artefacts contain RDY rows, what is each useful for,",
      "what are the gaps (FFT org-level, CQC non-statistical context),",
      "and how should a Business & Performance Partner use this as a conversation starter?"
    ),
    dataset_line = "KO41a, ERIC, DSPT, FFT and CQC public sources (assurance index)",
    prompt_excerpt = paste(
      "Index public assurance sources for RDY: KO41a, ERIC, DSPT, FFT, CQC.",
      "Appropriate-use language only — no operational IG or complaints performance conclusions.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Confirm which public assurance sources contain RDY rows and what each is useful for.",
        "Document gaps such as missing org-level FFT rows or non-statistical CQC context."
      ),
      cannot = c(
        "Combine assurance sources into a performance score or league table.",
        "Draw operational IG, complaints or patient experience conclusions without local owner validation."
      )
    ),
    headline = c(
      "Public data confirms RDY participation in KO41a complaints and ERIC estates returns.",
      paste0("Latest DSPT public assessment: ", dspt_latest, " — annual assurance label, not operational IG detail."),
      "FFT org-level rows were absent in the downloaded summary file — patient experience lead follow-up needed.",
      "CQC provides regulatory context only — not a performance score or league table."
    ),
    grouped_findings = list(
      list(
        title = "Statutory participation confirmed",
        items = list(
          list(
            title = "KO41a — Written complaints (annual)",
            body = "RDY org-level row present in 2024-25 extract. Presence confirms participation — volume and themes need the complaints team.",
            owner = "Complaints team to confirm 2024-25 figures and whether public row matches internal reporting."
          ),
          list(
            title = "ERIC — Estates returns (annual)",
            body = "RDY trust row in 2024/25 ERIC extract. Supports facilities benchmarking — not a simple good/bad score.",
            owner = "Estates/facilities owner to confirm amendments file and board reporting year."
          )
        )
      ),
      list(
        title = "IG and patient experience",
        items = list(
          list(
            title = "DSPT — Data Security and Protection Toolkit",
            body = paste0("Latest public assessment: ", dspt_latest, ". ", dspt_history_note),
            owner = "IG/calendar owner to confirm current-year submission status."
          ),
          list(
            title = "FFT — Friends and Family Test (org-level gap)",
            body = "No org-level RDY rows in downloaded FFT summary XLSX — workflow gap for analysts, not evidence of poor experience.",
            owner = "Patient experience lead to confirm whether setting-level XLSX download fills the gap."
          )
        )
      ),
      list(
        title = "Regulatory context",
        items = list(
          list(
            title = "CQC — Regulatory context",
            body = "Care Quality Commission provider page captured as context note — inspection and regulatory background only.",
            owner = "Quality/governance lead to confirm latest inspection status and internal action plans."
          )
        )
      )
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li><code>demo_assurance_profile.csv</code></li>',
      '<li>KO41a, ERIC, DSPT processed extracts</li>',
      '<li>CQC context note (regulatory background only)</li></ul>'
    ),
    period = "KO41a 2024-25; ERIC 2024/25; DSPT public history; FFT/CQC as noted.",
    trend_available = if (dspt_n >= 2) "Descriptive DSPT history only — not numeric performance trend" else "Annual snapshots only",
    agent_summary = c(
      "Public data confirms RDY participation in KO41a complaints and ERIC estates returns.",
      paste0("Latest DSPT public assessment: ", dspt_latest, " — annual assurance label, not operational IG detail."),
      "FFT org-level rows were absent in the downloaded summary file — patient experience lead follow-up needed.",
      "CQC provides regulatory context only — not a performance score or league table."
    ),
    human_checks = standard_human_checks(list(
      list(
        q = "Who is the named owner for each return this cycle?",
        expl = "KO41a, ERIC, DSPT and FFT each have accountable teams — confirm before citing in assurance packs."
      )
    )),
    verify_intro = verify_intro_short(
      '<li><a href="../public-data/processed/demo_assurance_profile.csv">demo_assurance_profile.csv</a></li>',
      "Assurance index figures trace to demo and processed extracts — no derived ranks or peer medians."
    )
  )

  verify_body <- paste0(
    traceability_verify_body(
      "See linked demo CSV and filter notes.",
      "demo_assurance_profile.csv",
      c("ko41a_annual", "eric_annual", "dspt_rdy")
    ),
    verify_extra
  )

  body <- agent_brief_sections(config, assurance_kfe_html, verify_body, supporting_html)

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
  if (is.null(kh03)) kh03 <- load_trend_file("latest_kh03_beds_rdy.csv")

  ae_trend <- load_trend_file("trend_ae_rdy.csv")
  dm01_trend <- load_trend_file("trend_dm01_rdy.csv")
  kh03_trend_df <- load_trend_file("trend_kh03_beds_rdy.csv")

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
      if (!is.null(kh03)) paste0(nrow(kh03), " bed rows — latest snapshot from historic pipeline") else "Extract not found"
    ),
    stringsAsFactors = FALSE
  )
  source_check$RDY_present <- ifelse(source_check$RDY_present, "Yes", "No")

  dm01_summary <- NULL
  dm01_top_test <- "n/a"
  trend_dm01_activity <- list(available = FALSE, n_periods = 0L)
  if (!is.null(dm01_trend) && nrow(dm01_trend) > 0) {
    aud <- dm01_trend[grepl("Audiology", dm01_trend$measure_name, ignore.case = TRUE), , drop = FALSE]
    if (nrow(aud) > 0) {
      dm01_top_test <- aud$measure_name[1]
      trend_dm01_activity <- extract_stacked_trend(aud, measure_name = aud$measure_name[1], label = "DM01 — Audiology total activity")
    } else {
      top_test <- dm01_trend$measure_name[which.max(to_num(dm01_trend$metric_value))]
      dm01_top_test <- top_test
      trend_dm01_activity <- extract_stacked_trend(dm01_trend, measure_name = top_test, label = paste0("DM01 — ", top_test, " total activity"))
    }
  }

  trend_ae_other <- extract_stacked_trend(
    ae_trend, measure_id = "OTHER_EM_ADM",
    label = "A&E — other emergency admissions (source validation)"
  )
  trend_ae_type12 <- extract_stacked_trend(
    ae_trend, measure_id = "AE_TYPE1",
    label = "A&E — Type 1 attendances (expected zero at RDY)"
  )

  if (!is.null(dm01) && "Diagnostic Tests" %in% names(dm01)) {
    dm01$Total_WL <- to_num(dm01$`Total WL`)
    dm01$Total_Activity <- to_num(dm01$`Total Activity`)
    dm01_summary <- dm01[, c("Diagnostic Tests", "Total WL", "Total Activity", "13+ Weeks")]
    dm01_summary <- dm01_summary[order(-dm01$Total_Activity), ]
    if (nrow(dm01_summary) > 0) {
      non_total <- dm01_summary[!grepl("^TOTAL$", trimws(dm01_summary$`Diagnostic Tests`), ignore.case = TRUE), , drop = FALSE]
      if (nrow(non_total) > 0) dm01_top_test <- non_total$`Diagnostic Tests`[1]
    }
  }

  ae_file_note <- basename(list.files(processed_dir, pattern = "^rdy_ae_monthly.*\\.csv$")[1])
  if (length(ae_file_note) == 0 || is.na(ae_file_note)) ae_file_note <- "rdy_ae_monthly_*.csv"
  dm01_mar_activity <- NA
  if (!is.null(dm01) && "Diagnostic Tests" %in% names(dm01)) {
    row <- dm01[trimws(dm01$`Diagnostic Tests`) == dm01_top_test, , drop = FALSE]
    if (nrow(row) > 0) dm01_mar_activity <- to_num(row$`Total Activity`[1])
  }

  kh03_trend <- extract_stacked_trend(
    kh03_trend_df,
    measure_id = "Mental Illness",
    label = "KH03 — Mental illness overnight beds (recent snapshots)"
  )

  urgent_has_ae_dm01_trend <- isTRUE(trend_ae_other$available) || isTRUE(trend_dm01_activity$available)

  urgent_kfe_specs <- list(
    list(
      figure = "A&E — RDY row and Type 1/2 attendances",
      what = "Monthly A&E provider statistics confirming RDY appears in the public file; Type 1 and Type 2 attendance columns.",
      latest = paste0("RDY present; Type 1/2 A&E attendances = 0 (May 2026 extract)"),
      comparator_type = "validation_only",
      comparator_detail = "Source validation — RDY does not operate a Type 1/2 emergency department.",
      trend = trend_ae_type12,
      polarity = "validation_only",
      trend_override = "Source validation only",
      trend_note = "Type 1/2 attendances remain zero across historic stack — expected for RDY service model.",
      interpretation = "Zero ED attendances reflect coding/service-model context — do not overinterpret as urgent care performance.",
      human_check = short_human_check("Urgent/emergency care lead to confirm service model and what is coded in A&E returns.")
    ),
    list(
      figure = "A&E — Other emergency admissions",
      what = "Count of other emergency admissions recorded in the monthly A&E provider file for RDY.",
      latest = if (!is.na(ae_other_adm)) paste0(ae_other_adm, " (May 2026)") else "See A&E extract",
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_ae_other$available)) {
        paste0(
          "Previous period: ", format(trend_ae_other$previous_value, big.mark = ","),
          " (", trend_ae_other$previous_period, "). Historic stack: trend_ae_rdy.csv."
        )
      } else if (!is.null(ae_trend)) {
        "Historic stack in trend_ae_rdy.csv — source validation context only."
      } else {
        "Single month only."
      },
      trend = trend_ae_other,
      polarity = "validation_only",
      trend_override = "Source validation only",
      trend_note = "Small counts (0–4/month) need service-owner confirmation of what is included.",
      interpretation = "The public figure needs local explanation — source validation only, not proof of a problem.",
      human_check = short_human_check("Confirm what 'other emergency admissions' represents for RDY in the national return.")
    ),
    list(
      figure = paste0("DM01 — ", dm01_top_test, " total activity"),
      what = "Monthly diagnostic waiting list and activity by test type/modality for RDY as provider.",
      latest = if (!is.na(dm01_mar_activity)) paste0(format(dm01_mar_activity, big.mark = ","), " (Mar 2026)") else paste0("See DM01 extract — top test: ", dm01_top_test),
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(trend_dm01_activity$available)) {
        paste0(
          "Previous period: ", format(trend_dm01_activity$previous_value, big.mark = ","),
          " (", trend_dm01_activity$previous_period, "). trend_dm01_rdy.csv."
        )
      } else {
        "No multi-month trend for top test."
      },
      trend = trend_dm01_activity,
      polarity = "unknown",
      interpretation = "Audiology/community diagnostics may dominate activity — do not infer national waiting position without local validation.",
      human_check = short_human_check("Diagnostics service owner to confirm DM01 mapping to local community diagnostic pathways.")
    ),
    list(
      figure = "KH03 — Mental illness overnight beds",
      what = "Quarterly overnight bed stock for Mental Illness sector — relevant to RDY as mental health provider.",
      latest = if (isTRUE(kh03_trend$available)) {
        paste0(format(kh03_trend$latest_value, big.mark = ","), " beds (", kh03_trend$latest_period, " snapshot)")
      } else {
        "See KH03 extract — verify latest quarter on NHS England site"
      },
      comparator_type = "previous_period",
      comparator_detail = if (isTRUE(kh03_trend$available)) {
        paste0(
          "Previous snapshot: ", format(kh03_trend$previous_value, big.mark = ","),
          " (", kh03_trend$previous_period, "). trend_kh03_beds_rdy.csv."
        )
      } else {
        "trend_kh03_beds_rdy.csv — recent quarterly stack only; may lag A&E/DM01 publication dates."
      },
      trend = kh03_trend,
      polarity = "unknown",
      interpretation = "KH03 trend uses recent quarterly snapshots only — not mixed with pre-2023 raw history unless clearly labelled.",
      human_check = short_human_check("Bed management/estates lead to confirm latest KH03 quarter and alignment with internal bed state.")
    )
  )

  urgent_kfe_html <- key_figures_explained_section(
    urgent_kfe_specs,
    "Source validation and descriptive trends from downloaded public files — RDY rows confirmed where stated.",
    comparator_header = "Previous period / comparator"
  )

  kh03_mi <- NULL
  if (!is.null(kh03) && "Sector" %in% names(kh03)) {
    mi <- kh03[kh03$Sector == "Mental Illness", , drop = FALSE]
    if (nrow(mi) > 0) {
      mi$Beds <- to_num(if ("Number_Of_Beds" %in% names(mi)) mi$Number_Of_Beds else mi$metric_value)
      snap_col <- if ("Effective_Snapshot_Date" %in% names(mi)) "Effective_Snapshot_Date" else "reporting_period_start"
      kh03_mi <- mi[, intersect(c(snap_col, "Number_Of_Beds", "metric_value"), names(mi)), drop = FALSE]
    }
  } else if (!is.null(kh03) && "measure_id" %in% names(kh03)) {
    mi <- kh03[kh03$measure_id == "Mental Illness", , drop = FALSE]
    if (nrow(mi) > 0) {
      kh03_mi <- mi[, c("reporting_period_start", "metric_value"), drop = FALSE]
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
        "Comparator / trend" = if (!is.null(ae_trend)) {
          n_ae <- length(unique(na.omit(trimws(ae_trend$reporting_period_start))))
          paste0(
            "Historic A&E stack (", n_ae, " months) — ",
            "Type 1/2 attendances remain zero; source validation only."
          )
        } else {
          "Single month A&E extract — run script 05 for historic stack."
        },
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
        "Comparator / trend" = if (isTRUE(trend_dm01_activity$available)) {
          paste0(
            "Historic DM01 stack: latest vs previous month for ", dm01_top_test, " — ",
            format(trend_dm01_activity$latest_value, big.mark = ","), " vs ",
            format(trend_dm01_activity$previous_value, big.mark = ","), "."
          )
        } else if (!is.null(dm01_trend)) {
          "Historic DM01 file present but fewer than two comparable months for top test."
        } else {
          "Single month in current extract — run script 05 for DM01 historic stack."
        },
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
        "Cautious interpretation" = "KH03 trend uses recent quarterly snapshots only (script 05) — not the full 2007–2024 raw history mixed in older demo files.",
        "Human check required" = "Bed management/ estates lead to confirm latest KH03 quarter and alignment with internal bed state."
      )
    )
  )

  kh03_trend_html <- if (isTRUE(kh03_trend$available)) {
    trend_section(
      list(kh03_trend),
      "trend_kh03_beds_rdy.csv — Mental Illness sector, recent snapshots only",
      c(
        "Snapshot dates are irregular (quarterly, not monthly) — descriptive only.",
        "Latest snapshot may lag NHS England publication — verify on source site."
      )
    )
  } else {
    trend_not_available_section(c(
      "Latest KH03 quarterly snapshot aligned to board reporting date",
      "Consistent sector filter (Mental Illness) across consecutive quarters"
    ))
  }

  ae_dm01_trends <- list()
  if (isTRUE(trend_ae_other$available)) ae_dm01_trends <- c(ae_dm01_trends, list(trend_ae_other))
  if (isTRUE(trend_dm01_activity$available)) ae_dm01_trends <- c(ae_dm01_trends, list(trend_dm01_activity))

  ae_dm01_trend <- if (length(ae_dm01_trends) > 0) {
    trend_section(
      ae_dm01_trends,
      "trend_ae_rdy.csv / trend_dm01_rdy.csv (historic stack from script 05)",
      c(
        "A&E trends are source validation only — zero Type 1/2 ED attendances expected at RDY.",
        "Descriptive period-on-period change only — not operational cause."
      )
    )
  } else {
    trend_not_available_section(c(
      "Run site/public-data/05_download_historic_public_data.R for trend_ae_rdy.csv and trend_dm01_rdy.csv",
      "Service-owner confirmation that RDY service model excludes Type 1/2 ED activity"
    ))
  }

  supporting_html <- paste0(
    collapsible_details("Source presence tables and charts", key_figures),
    collapsible_details("Additional source commentary", theme_commentary_section(commentary_cards)),
    wrap_trend_collapsible(ae_dm01_trend, "A&E and DM01 trend detail"),
    wrap_trend_collapsible(kh03_trend_html, "KH03 bed snapshot trend detail")
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
    question = paste(
      "Check whether RDY appears in public A&E, DM01 and KH03 files;",
      "explain what each source can safely support for a trust without an emergency department;",
      "and where trend analysis is or is not available."
    ),
    dataset_line = "A&E, DM01 and KH03 public provider files (RDY)",
    prompt_excerpt = paste(
      "Confirm RDY row presence per source. Report zero ED attendances explicitly.",
      "No ED performance claims. No causal language.",
      sep = "\n"
    ),
    scope = list(
      can = c(
        "Confirm RDY row presence in public A&E, DM01 and KH03 files.",
        "Show descriptive trends where stacked historic files support them.",
        "Explain what each source can safely support for a trust without a Type 1/2 emergency department."
      ),
      cannot = c(
        "Prove urgent care or diagnostic performance standing from source validation alone.",
        "Make ED performance claims — RDY shows zero Type 1/2 A&E attendances by service model."
      )
    ),
    headline = c(
      paste0(
        "RDY appears in public A&E, DM01 and KH03 files — interpretation needs service-owner confirmation.",
        if (ae_ed_zero) " A&E shows zero Type 1/2 ED attendances (expected for RDY service model)." else ""
      ),
      if (!is.null(dm01)) paste0("DM01: ", nrow(dm01), " test rows for March 2026 — ", dm01_top_test, " has highest activity in extract.") else "DM01 extract not summarised.",
      if (isTRUE(kh03_trend$available)) paste0("KH03: ", kh03_trend$n_periods, " mental illness snapshots — verify latest quarter on NHS England site.") else "KH03: confirm latest quarter before capacity discussions.",
      "This brief validates source presence — it does not prove urgent care or diagnostic performance standing."
    ),
    grouped_findings = list(
      list(
        title = "A&E source validation",
        items = list(
          list(
            title = "A&E — RDY row and zero Type 1/2 attendances",
            body = paste0(
              "RDY row present in May 2026 A&E extract. Type 1/2 attendances = 0 — expected for RDY service model.",
              if (!is.na(ae_other_adm)) paste0(" Other emergency admissions: ", ae_other_adm, ".") else ""
            ),
            owner = "Urgent/emergency care lead to confirm service model and A&E return coding."
          )
        )
      ),
      list(
        title = "DM01 diagnostics",
        items = list(
          list(
            title = paste0("DM01 — ", dm01_top_test),
            body = paste0(
              if (!is.null(dm01)) paste0(nrow(dm01), " diagnostic test rows for March 2026. ") else "",
              if (!is.na(dm01_mar_activity)) paste0("Top test activity: ", format(dm01_mar_activity, big.mark = ","), ". ") else "",
              "Audiology/community diagnostics may dominate — local validation required."
            ),
            owner = "Diagnostics service owner to confirm DM01 mapping to local pathways."
          )
        )
      ),
      list(
        title = "KH03 bed snapshots",
        items = list(
          list(
            title = "KH03 — Mental illness overnight beds",
            body = if (isTRUE(kh03_trend$available)) {
              paste0(
                "Latest snapshot: ", format(kh03_trend$latest_value, big.mark = ","), " beds (",
                kh03_trend$latest_period, "). Quarterly stack only — verify latest quarter on NHS England site."
              )
            } else {
              "KH03 extract present — confirm latest quarter before capacity discussions."
            },
            owner = "Bed management/estates lead to confirm alignment with internal bed state."
          )
        )
      )
    ),
    data_used_html = paste0(
      '<ul class="nhs-list-compact">',
      '<li>A&amp;E monthly provider CSV (<code>', esc(ae_file_note), '</code>)</li>',
      '<li>DM01 (<code>demo_dm01_diagnostics.csv</code> + full RDY extract)</li>',
      '<li>KH03 (<code>demo_kh03_beds.csv</code> + trend file where used)</li>',
      if (!is.null(ae_trend)) '<li><code>trend_ae_rdy.csv</code></li>' else "",
      if (!is.null(dm01_trend)) '<li><code>trend_dm01_rdy.csv</code></li>' else "",
      '</ul>'
    ),
    period = "A&E May 2026; DM01 March 2026; KH03 quarterly snapshots to Jun 2024 in trend file.",
    trend_available = if (urgent_has_ae_dm01_trend || isTRUE(kh03_trend$available)) {
      "Yes — descriptive A&E/DM01 and/or KH03 snapshot trends where stacked files exist"
    } else {
      "Limited — source validation only for some sources"
    },
    agent_summary = c(
      paste0(
        "RDY appears in public A&E, DM01 and KH03 files — interpretation needs service-owner confirmation.",
        if (ae_ed_zero) " A&E shows zero Type 1/2 ED attendances (expected for RDY service model)." else ""
      ),
      if (!is.null(dm01)) paste0("DM01: ", nrow(dm01), " test rows for March 2026 — ", dm01_top_test, " has highest activity in extract.") else "DM01 extract not summarised.",
      if (isTRUE(kh03_trend$available)) paste0("KH03: ", kh03_trend$n_periods, " mental illness snapshots — verify latest quarter on NHS England site.") else "KH03: confirm latest quarter before capacity discussions.",
      "This brief validates source presence — it does not prove urgent care or diagnostic performance standing."
    ),
    human_checks = standard_human_checks(list(
      list(
        q = "Which urgent care metrics apply locally without an ED?",
        expl = "Many national urgent care indicators assume Type 1/2 ED activity — confirm which apply to RDY."
      )
    )),
    verify_intro = verify_intro_short(
      paste0(
        '<li><a href="../public-data/processed/demo_dm01_diagnostics.csv">demo_dm01_diagnostics.csv</a></li>',
        '<li><a href="../public-data/processed/demo_kh03_beds.csv">demo_kh03_beds.csv</a></li>'
      ),
      "Figures trace to processed RDY extracts and trend_*.csv files — filter to Organisation_Code or Org Code = RDY."
    )
  )

  verify_body <- paste0(
    traceability_verify_body(
      "See linked demo CSV and filter notes.",
      c("demo_dm01_diagnostics.csv", "demo_kh03_beds.csv", ae_file_note,
        if (!is.null(ae_trend)) "trend_ae_rdy.csv" else NULL,
        if (!is.null(dm01_trend)) "trend_dm01_rdy.csv" else NULL,
        if (!is.null(kh03_trend_df)) "trend_kh03_beds_rdy.csv" else NULL),
      c("ae_monthly", "dm01_monthly", "kh03_quarterly")
    ),
    verify_extra
  )

  body <- agent_brief_sections(config, urgent_kfe_html, verify_body, supporting_html)

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
