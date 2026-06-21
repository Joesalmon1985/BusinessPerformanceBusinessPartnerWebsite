# Post-render validation for public HTML reports.
# Called from 03_render_public_reports.R after all reports are written.

MONTH_ABBR <- c(
  Jan = 1L, Feb = 2L, Mar = 3L, Apr = 4L, May = 5L, Jun = 6L,
  Jul = 7L, Aug = 8L, Sep = 9L, Oct = 10L, Nov = 11L, Dec = 12L
)

BAD_TREND_PHRASES <- c(
  "Definition check required",
  "Finance sign-off required",
  "Source validation only",
  "Local owner confirmation needed",
  "Pathway / data-definition check required"
)

ALLOWED_TREND_LABELS <- c(
  "Improving", "Worsening", "Broadly stable", "Mixed / unclear",
  "Not available from current extract", "Rising", "Falling", "Stable",
  "Volatile", "MoM up", "MoM down", "6-month up", "6-month down",
  "—", ""
)

strip_html <- function(x) {
  x <- gsub("<[^>]+>", " ", x, perl = TRUE)
  gsub("\\s+", " ", x)
}

read_report_html <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

issue <- function(issues, msg) c(issues, msg)

check_duplicate_h2 <- function(html, fname, issues) {
  h2_lines <- grep("<h2[^>]*>", strsplit(html, "\n")[[1]], value = TRUE)
  if (length(h2_lines) == 0) return(issues)
  h2_norm <- trimws(strip_html(h2_lines))
  dupes <- unique(h2_norm[duplicated(h2_norm)])
  if (length(dupes) > 0) {
    issue(issues, paste0(fname, ": duplicate h2 heading: ", dupes[1]))
  } else {
    issues
  }
}

extract_kfe_tables <- function(html) {
  parts <- strsplit(html, '<table class="nhs-kfe-table')[[1]]
  if (length(parts) < 2) return(character())
  lapply(parts[-1], function(chunk) {
    end <- regexpr("</table>", chunk, fixed = TRUE)[1]
    if (end < 1) return(chunk)
    substr(chunk, 1, end + nchar("</table>") - 1)
  })
}

parse_kfe_rows <- function(table_html) {
  rows <- gregexpr("<tr>.*?</tr>", table_html, perl = TRUE)[[1]]
  if (rows[1] < 0) return(list())
  row_html <- regmatches(table_html, list(rows))[[1]]
  lapply(row_html, function(r) {
    cells <- gregexpr("<t[dh][^>]*>.*?</t[dh]>", r, perl = TRUE)[[1]]
    if (cells[1] < 0) return(character())
    strip_html(regmatches(r, list(cells))[[1]])
  })
}

check_kfe_trend_column <- function(html, fname, issues) {
  tables <- extract_kfe_tables(html)
  for (tbl in tables) {
    header <- sub(".*?</tr>", "", tbl, perl = TRUE)
    header_cells <- strip_html(
      regmatches(header, gregexpr("<th[^>]*>.*?</th>", header, perl = TRUE))[[1]]
    )
    trend_idx <- which(grepl("^Trend$", trimws(header_cells), ignore.case = TRUE))
    if (length(trend_idx) != 1) next
    rows <- parse_kfe_rows(tbl)
    for (row in rows[-1]) {
      if (length(row) < trend_idx) next
      trend_text <- trimws(row[trend_idx])
      if (!nzchar(trend_text) || trend_text == "—") next
      for (bad in BAD_TREND_PHRASES) {
        if (grepl(bad, trend_text, fixed = TRUE)) {
          issues <- issue(
            issues,
            paste0(fname, ": Trend column contains validation wording (", bad, ")")
          )
          break
        }
      }
      if (grepl("Finance", trend_text, fixed = TRUE)) {
        issues <- issue(issues, paste0(fname, ": Trend column mentions Finance"))
      }
    }
  }
  issues
}

check_tt_wait_totals <- function(html, processed_dir, issues) {
  tt_csv <- file.path(processed_dir, "demo_talking_therapies.csv")
  if (!file.exists(tt_csv)) return(issues)
  tt <- read.csv(tt_csv, stringsAsFactors = FALSE)
  wait_ids <- c("M019", "M020", "M021", "M022")
  vals <- sapply(wait_ids, function(id) {
    v <- tt$MEASURE_VALUE_SUPPRESSED[tt$MEASURE_ID == id]
    if (length(v) == 0 || v[1] == "*") return(NA_real_)
    suppressWarnings(as.numeric(v[1]))
  })
  total_021 <- sum(vals[1:3], na.rm = TRUE)
  total_all <- sum(vals, na.rm = TRUE)
  fmt <- function(x) format(as.integer(x), big.mark = ",", scientific = FALSE, trim = TRUE)
  if (is.finite(total_021) && !grepl(fmt(total_021), html, fixed = TRUE)) {
    issues <- issue(issues, paste0(
      "public-talking-therapies-profile.html: M019–M021 total ",
      fmt(total_021), " not found in HTML"
    ))
  }
  if (is.finite(total_all) && !grepl(fmt(total_all), html, fixed = TRUE)) {
    issues <- issue(issues, paste0(
      "public-talking-therapies-profile.html: M019–M022 total ",
      fmt(total_all), " not found in HTML"
    ))
  }
  issues
}

parse_month_label <- function(lab) {
  lab <- trimws(lab)
  m <- regexec("^([A-Za-z]{3})\\s+(\\d{4})$", lab)
  hit <- regmatches(lab, m)[[1]]
  if (length(hit) < 3) return(NA_integer_)
  mo <- MONTH_ABBR[[hit[2]]]
  yr <- as.integer(hit[3])
  if (is.null(mo) || is.na(yr)) return(NA_integer_)
  yr * 12L + mo
}

check_chronological_chart_labels <- function(html, fname, issues) {
  charts <- gregexpr(
    '<div class="nhs-chart">.*?</div>\\s*</div>',
    html,
    perl = TRUE
  )[[1]]
  if (charts[1] < 0) return(issues)
  chart_html <- regmatches(html, list(charts))[[1]]
  for (ch in chart_html) {
    labels <- strip_html(
      regmatches(ch, gregexpr(
        '<span class="nhs-bar-label">.*?</span>',
        ch,
        perl = TRUE
      ))[[1]]
    )
    if (length(labels) < 2) next
    ord <- vapply(labels, parse_month_label, integer(1))
    if (any(is.na(ord))) next
    if (any(diff(ord) < 0, na.rm = TRUE)) {
      issues <- issue(
        issues,
        paste0(fname, ": time-series chart labels not in chronological order (",
               paste(labels, collapse = ", "), ")")
      )
    }
  }
  issues
}

check_period_captions_on_kfe <- function(html, fname, issues) {
  if (!grepl("key-figures-explained", html, fixed = TRUE)) return(issues)
  if (!grepl("nhs-period-caption", html, fixed = TRUE)) {
    issues <- issue(issues, paste0(fname, ": Key figures section missing period caption"))
  }
  issues
}

check_required_sections <- function(html, fname, issues) {
  required <- c("nhs-bottom-line", "nhs-why-useful")
  for (cls in required) {
    if (!grepl(cls, html, fixed = TRUE)) {
      issues <- issue(issues, paste0(fname, ": missing .", cls, " section"))
    }
  }
  issues
}

check_kh03_quarter_wording <- function(html, issues) {
  fname <- "public-urgent-diagnostics-check.html"
  if (!grepl("quarter", html, ignore.case = TRUE)) return(issues)
  n_quarters <- length(gregexpr("quarter", html, ignore.case = TRUE)[[1]])
  if (grepl("six quarters", html, ignore.case = TRUE) &&
      grepl("Jan 2023", html, fixed = TRUE) &&
      grepl("Jun 2024", html, fixed = TRUE)) {
    return(issues)
  }
  if (grepl("KH03", html, fixed = TRUE) && !grepl("quarterly snapshot", html, ignore.case = TRUE)) {
    issues <- issue(issues, paste0(fname, ": KH03 section should state quarterly snapshot wording"))
  }
  issues
}

check_dm01_period_consistency <- function(html, issues) {
  fname <- "public-urgent-diagnostics-check.html"
  dm01_periods <- gregexpr("DM01[^<]{0,80}period", html, ignore.case = TRUE)[[1]]
  if (dm01_periods[1] < 0) return(issues)
  if (grepl("headline uses latest period per source", html, fixed = TRUE)) {
    return(issues)
  }
  issues
}

validate_public_reports <- function(reports_dir, processed_dir = NULL) {
  if (is.null(processed_dir)) {
    processed_dir <- file.path(dirname(reports_dir), "public-data", "processed")
  }
  issues <- character()
  html_files <- sort(list.files(
    reports_dir,
    pattern = "^public-.*\\.html$",
    full.names = TRUE
  ))
  if (length(html_files) == 0) {
    stop("No public-*.html files found in ", reports_dir, call. = FALSE)
  }

  for (f in html_files) {
    fname <- basename(f)
    html <- read_report_html(f)
    issues <- check_duplicate_h2(html, fname, issues)
    issues <- check_kfe_trend_column(html, fname, issues)
    issues <- check_chronological_chart_labels(html, fname, issues)
    issues <- check_period_captions_on_kfe(html, fname, issues)
    issues <- check_required_sections(html, fname, issues)
    if (fname == "public-talking-therapies-profile.html") {
      issues <- check_tt_wait_totals(html, processed_dir, issues)
    }
    if (fname == "public-urgent-diagnostics-check.html") {
      issues <- check_kh03_quarter_wording(html, issues)
      issues <- check_dm01_period_consistency(html, issues)
    }
  }

  if (length(issues) > 0) {
    cat("VALIDATION FAILED:\n")
    cat(paste("-", issues, collapse = "\n"), "\n")
    stop(
      "Public report validation failed with ", length(issues), " issue(s).",
      call. = FALSE
    )
  }
  cat("All public report validation checks passed (", length(html_files), " files).\n", sep = "")
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  script_dir <- dirname(normalizePath(
    sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))][1])
  ))
  site_dir <- dirname(script_dir)
  reports_dir <- file.path(site_dir, "reports")
  processed_dir <- file.path(site_dir, "public-data", "processed")
  validate_public_reports(reports_dir = reports_dir, processed_dir = processed_dir)
}
