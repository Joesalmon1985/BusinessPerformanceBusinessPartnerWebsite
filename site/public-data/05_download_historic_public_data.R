# =============================================================================
# 05_download_historic_public_data.R
# Download and stack historic public aggregate data for RDY trend analysis.
# Public aggregate data only — no patient-identifiable information.
# Does not overwrite existing raw files. Each source runs independently.
# =============================================================================

root <- local({
  args <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("--file=", "", args[grep("--file=", args)])
  if (length(script_path) > 0) {
    normalizePath(file.path(dirname(normalizePath(script_path)), "."))
  } else {
    normalizePath(getwd())
  }
})

source(file.path(root, "scripts", "_common.R"))
source(file.path(root, "scripts", "_historic.R"))

ensure_dirs(root)
ensure_packages(c("rvest", "readxl", "jsonlite"), root = root)

run_date <- format(Sys.Date(), "%Y-%m-%d")
MAX_MONTHS <- 12L
MIN_MONTHS <- 6L
cli_args <- commandArgs(trailingOnly = TRUE)
DRY_RUN <- "--dry-run" %in% cli_args || "--dry-run-mhsds" %in% cli_args
MHSDS_ONLY <- "--mhsds-only" %in% cli_args || "--dry-run-mhsds" %in% cli_args
options(historic.root = root)

append_log(root, paste("=== Historic public data run started", if (DRY_RUN) "(dry-run)" else "", "==="))
invisible(read_historic_register(root))

historic_results <- list()

skip_non_mhsds <- function() MHSDS_ONLY

# --- 1. CSDS monthly history -------------------------------------------------

if (!skip_non_mhsds()) historic_results$csds_monthly <- tryCatch({
  append_log(root, "csds_monthly: starting historic download")
  index <- paste0(
    "https://digital.nhs.uk/data-and-information/publications/statistical/",
    "community-services-statistics-for-children-young-people-and-adults"
  )
  months <- discover_csds_month_pages(index, MAX_MONTHS)
  if (nrow(months) == 0) stop("No CSDS month publication links found")
  if (nrow(months) > MAX_MONTHS) months <- months[seq_len(MAX_MONTHS), , drop = FALSE]

  raw_paths <- character()
  stacked <- list()
  periods_ok <- character()

  for (i in seq_len(nrow(months))) {
    slug <- months$slug[i]
    pub_datasets <- paste0(months$href[i], "/datasets")
    zip_url <- find_csds_core_zip(pub_datasets)
    if (is.null(zip_url)) {
      append_log(root, paste("csds_monthly: no zip for", slug))
      next
    }
    dest <- raw_dest_path(root, "csds_monthly", slug, "csds_data.zip")
    res <- safe_download(zip_url, dest)
    if (res$ok) raw_paths <- c(raw_paths, dest)
    csv_path <- extract_zip_csv(dest, pattern = "core|csds|exp", cache_root = root)
    if (is.null(csv_path)) {
      append_log(root, paste("csds_monthly: no CSV in zip for", slug))
      next
    }
    df <- read_tabular_historic(csv_path)
    part <- stack_csds_careactivities(df, slug, dest)
    if (!is.null(part) && nrow(part) > 0) {
      stacked[[length(stacked) + 1]] <- part
      periods_ok <- c(periods_ok, slug)
    }
  }

  trend_df <- if (length(stacked) > 0) do.call(rbind, stacked) else NULL
  trend_file <- ""
  trend_avail <- "no"
  n_periods <- 0L

  if (!is.null(trend_df) && nrow(trend_df) > 0) {
    write_trend_csv(
      root, "trend_csds_activity_rdy.csv", trend_df,
      metadata_note = c(
        paste("Historic CSDS CareActivities trend for RDY — generated", Sys.time()),
        paste("Periods:", paste(unique(periods_ok), collapse = ", ")),
        "Provisional monthly CSDS; ActivityType/CareActivities only.",
        "DISCLAIMER: Public-data demonstration. Not official Dorset HealthCare reporting."
      )
    )
    trend_file <- "trend_csds_activity_rdy.csv"
    n_periods <- count_distinct_periods(trend_df)
    trend_avail <- if (n_periods >= 2) "yes" else "no"
  }

  update_historic_row(root, "csds_monthly", list(
    historic_download_attempted = "yes",
    historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
    historic_raw_files = paste(raw_paths, collapse = "; "),
    historic_trend_file = trend_file,
    trend_available = trend_avail,
    trend_periods_count = as.character(n_periods),
    rdy_rows_stacked = as.character(if (is.null(trend_df)) 0 else nrow(trend_df)),
    trend_caveats = "Provisional CSDS; single ActivityType slice; definition changes possible between months.",
    manual_download_needed = if (n_periods < 2) "yes" else "no",
    last_run_date = run_date
  ))
  append_log(root, paste("csds_monthly: done — periods", n_periods, "rows", if (is.null(trend_df)) 0 else nrow(trend_df)))
  list(ok = TRUE, periods = n_periods)
}, error = function(e) {
  append_log(root, paste("csds_monthly ERROR:", conditionMessage(e)))
  update_historic_row(root, "csds_monthly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- 2. A&E monthly history ----------------------------------------------------

if (!skip_non_mhsds()) historic_results$ae_monthly <- tryCatch({
  append_log(root, "ae_monthly: starting historic download")
  csvs <- discover_ae_monthly_csvs(MAX_MONTHS)
  if (nrow(csvs) == 0) stop("No A&E monthly CSV links found")

  raw_paths <- character()
  stacked <- list()
  periods_ok <- character()

  for (i in seq_len(nrow(csvs))) {
    slug <- gsub("[^a-zA-Z0-9._-]+", "_", csvs$name[i])
    dest <- raw_dest_path(root, "ae_monthly", slug, csvs$name[i])
    res <- safe_download(csvs$href[i], dest)
    if (res$ok) raw_paths <- c(raw_paths, dest)
    df <- read_tabular_historic(dest)
    part <- stack_ae_rdy_row(df, dest)
    if (!is.null(part) && nrow(part) > 0) {
      stacked[[length(stacked) + 1]] <- part
      periods_ok <- c(periods_ok, unique(part$reporting_period_start)[1])
    }
  }

  trend_df <- if (length(stacked) > 0) do.call(rbind, stacked) else NULL
  trend_file <- ""
  n_periods <- count_distinct_periods(trend_df)
  trend_avail <- if (n_periods >= 2) "yes" else "no"

  if (!is.null(trend_df) && nrow(trend_df) > 0) {
    write_trend_csv(
      root, "trend_ae_rdy.csv", trend_df,
      metadata_note = c(
        paste("A&E RDY trend — source validation only — generated", Sys.time()),
        "RDY has no Type 1/2 ED; zero attendances expected.",
        "Do not interpret as urgent care performance."
      )
    )
    trend_file <- "trend_ae_rdy.csv"
  }

  update_historic_row(root, "ae_monthly", list(
    historic_download_attempted = "yes",
    historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
    historic_raw_files = paste(raw_paths, collapse = "; "),
    historic_trend_file = trend_file,
    trend_available = trend_avail,
    trend_periods_count = as.character(n_periods),
    rdy_rows_stacked = as.character(if (is.null(trend_df)) 0 else nrow(trend_df)),
    trend_caveats = "Source validation only; zero ED attendances at RDY expected.",
    manual_download_needed = if (n_periods < 2) "yes" else "no",
    last_run_date = run_date
  ))
  append_log(root, paste("ae_monthly: done — periods", n_periods))
  list(ok = TRUE, periods = n_periods)
}, error = function(e) {
  append_log(root, paste("ae_monthly ERROR:", conditionMessage(e)))
  update_historic_row(root, "ae_monthly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- 3. DM01 monthly history ---------------------------------------------------

if (!skip_non_mhsds()) historic_results$dm01_monthly <- tryCatch({
  append_log(root, "dm01_monthly: starting historic download")
  zips <- discover_dm01_monthly_zips(MAX_MONTHS)
  existing_full <- list.files(
    file.path(root, "raw"),
    pattern = "dm01.*full-extract.*\\.zip$",
    full.names = TRUE,
    ignore.case = TRUE
  )
  if (nrow(zips) == 0 && length(existing_full) == 0) stop("No DM01 ZIP links or local full-extract files found")

  raw_paths <- character()
  stacked <- list()
  periods_ok <- character()

  process_dm01_zip <- function(dest) {
    csv_path <- extract_zip_csv(dest, pattern = "DM01|extract|full", cache_root = root)
    if (is.null(csv_path)) return(invisible(NULL))
    df <- tryCatch(
      read_tabular_historic(csv_path),
      error = function(e) {
        append_log(root, paste("dm01_monthly: read failed for", basename(dest), "—", conditionMessage(e)))
        NULL
      }
    )
    if (is.null(df)) return(invisible(NULL))
    stack_dm01_rdy(df, dest)
  }

  for (i in seq_len(max(0L, nrow(zips)))) {
    slug <- gsub("[^a-zA-Z0-9._-]+", "_", zips$name[i])
    dest <- raw_dest_path(root, "dm01_monthly", slug, zips$name[i])
    res <- safe_download(zips$href[i], dest)
    if (res$ok) raw_paths <- c(raw_paths, dest)
  }

  for (dest in unique(c(existing_full, raw_paths))) {
    if (!dest %in% raw_paths) raw_paths <- c(raw_paths, dest)
    part <- process_dm01_zip(dest)
    if (!is.null(part) && nrow(part) > 0) {
      stacked[[length(stacked) + 1]] <- part
      periods_ok <- c(periods_ok, unique(part$reporting_period_start)[1])
    }
  }

  trend_df <- if (length(stacked) > 0) do.call(rbind, stacked) else NULL
  trend_file <- ""
  n_periods <- count_distinct_periods(trend_df)
  trend_avail <- if (n_periods >= 2) "yes" else "no"

  if (!is.null(trend_df) && nrow(trend_df) > 0) {
    write_trend_csv(
      root, "trend_dm01_rdy.csv", trend_df,
      metadata_note = c(
        paste("DM01 RDY diagnostics trend — generated", Sys.time()),
        "Provisional monthly data; validate with diagnostics service owner."
      )
    )
    trend_file <- "trend_dm01_rdy.csv"
  }

  update_historic_row(root, "dm01_monthly", list(
    historic_download_attempted = "yes",
    historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
    historic_raw_files = paste(raw_paths, collapse = "; "),
    historic_trend_file = trend_file,
    trend_available = trend_avail,
    trend_periods_count = as.character(n_periods),
    rdy_rows_stacked = as.character(if (is.null(trend_df)) 0 else nrow(trend_df)),
    trend_caveats = "Provisional DM01; audiology may dominate activity counts.",
    manual_download_needed = if (n_periods < 2) "yes" else "no",
    last_run_date = run_date
  ))
  append_log(root, paste("dm01_monthly: done — periods", n_periods))
  list(ok = TRUE, periods = n_periods)
}, error = function(e) {
  append_log(root, paste("dm01_monthly ERROR:", conditionMessage(e)))
  update_historic_row(root, "dm01_monthly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- 4. KH03 cleanup -----------------------------------------------------------

if (!skip_non_mhsds()) historic_results$kh03_quarterly <- tryCatch({
  append_log(root, "kh03_quarterly: starting historic processing")
  page <- paste0(
    "https://www.england.nhs.uk/statistics/statistical-work-areas/",
    "bed-availability-and-occupancy/bed-data-overnight/"
  )
  csv_links <- scrape_links(page, extensions = c("csv"))
  csv_links <- csv_links[grepl("Available|available|KH03", csv_links$href, ignore.case = TRUE) |
    grepl("Available|KH03", csv_links$text, ignore.case = TRUE), , drop = FALSE]
  if (nrow(csv_links) == 0) csv_links <- scrape_links(page, extensions = c("csv"))

  raw_paths <- character()
  for (i in seq_len(min(3, nrow(csv_links)))) {
    dest <- raw_dest_path(root, "kh03_quarterly", "historic", basename(csv_links$href[i]))
    res <- safe_download(csv_links$href[i], dest)
    if (res$ok) raw_paths <- c(raw_paths, dest)
  }

  # Also use existing raw/processed KH03 files
  existing <- c(
    list_raw_files(root, "kh03_quarterly"),
    list.files(file.path(root, "processed"), pattern = "^rdy_kh03.*Available.*\\.csv$", full.names = TRUE)
  )
  existing <- unique(existing[file.exists(existing)])

  all_long <- list()
  for (f in unique(c(raw_paths, existing))) {
    df <- read_tabular_historic(f)
    part <- stack_kh03_rdy_long(
      df, f,
      "KH03 quarterly snapshot; verify latest quarter on NHS England publication page."
    )
    if (!is.null(part)) all_long[[length(all_long) + 1]] <- part
  }

  long_df <- if (length(all_long) > 0) do.call(rbind, all_long) else NULL
  trend_file <- ""
  latest_file <- ""
  n_periods <- 0L
  trend_avail <- "no"
  recent_df <- NULL
  latest_date <- as.Date(NA)

  if (!is.null(long_df) && nrow(long_df) > 0) {
    long_df$snapshot_date <- parse_snapshot_date(long_df$reporting_period_start)
    valid <- long_df[!is.na(long_df$snapshot_date), , drop = FALSE]
    if (nrow(valid) > 0) {
      latest_date <- max(valid$snapshot_date, na.rm = TRUE)
      latest_df <- valid[valid$snapshot_date == latest_date, , drop = FALSE]
      latest_df$snapshot_date <- NULL

      write_trend_csv(
        root, "latest_kh03_beds_rdy.csv", latest_df[, TREND_STANDARD_COLS, drop = FALSE],
        metadata_note = c(
          paste("KH03 latest snapshot for RDY — generated", Sys.time()),
          paste("Latest snapshot date:", format(latest_date, "%d/%m/%Y")),
          "Single snapshot only — use trend_kh03_beds_rdy.csv for recent quarter comparison.",
          "Not current operational capacity without local bed management confirmation."
        )
      )
      latest_file <- "latest_kh03_beds_rdy.csv"

      recent_df <- filter_kh03_recent_snapshots(valid, max_snapshots = 6, min_year = 2020)
      n_periods <- count_distinct_periods(recent_df)

      if (n_periods >= 2) {
        write_trend_csv(
          root, "trend_kh03_beds_rdy.csv", recent_df[, TREND_STANDARD_COLS, drop = FALSE],
          metadata_note = c(
            paste("KH03 recent snapshots for RDY — generated", Sys.time()),
            "Excludes pre-2020 rows from trend; full raw NHS file may contain older dates.",
            paste("Latest snapshot date:", format(latest_date, "%d/%m/%Y")),
            "Not current operational capacity without local bed management confirmation."
          )
        )
        trend_file <- "trend_kh03_beds_rdy.csv"
        trend_avail <- "yes"
      }
    }
  }

  kh03_periods_label <- ""
  if (!is.null(long_df) && "snapshot_date" %in% names(long_df)) {
    snaps <- sort(unique(long_df$snapshot_date[!is.na(long_df$snapshot_date)]), decreasing = TRUE)
    kh03_periods_label <- paste(format(head(snaps, 6), "%Y-%m"), collapse = "; ")
  } else if (!is.null(recent_df) && nrow(recent_df) > 0) {
    kh03_periods_label <- paste(unique(recent_df$reporting_period_start), collapse = "; ")
  }

  update_historic_row(root, "kh03_quarterly", list(
    historic_download_attempted = "yes",
    historic_periods_downloaded = kh03_periods_label,
    historic_raw_files = paste(raw_paths, collapse = "; "),
    historic_trend_file = paste(c(trend_file, latest_file), collapse = "; "),
    trend_available = trend_avail,
    trend_periods_count = as.character(n_periods),
    rdy_rows_stacked = as.character(if (is.null(long_df)) 0 else nrow(long_df)),
    trend_caveats = "Quarterly snapshots; raw file mixes historic dates — trend uses recent quarters only.",
    manual_download_needed = if (n_periods < 2) "partial" else "no",
    last_run_date = run_date
  ))
  append_log(root, paste("kh03_quarterly: done — trend periods", n_periods))
  list(ok = TRUE, periods = n_periods)
}, error = function(e) {
  append_log(root, paste("kh03_quarterly ERROR:", conditionMessage(e)))
  update_historic_row(root, "kh03_quarterly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- 5. FFT organisation-level attempt -----------------------------------------

if (!skip_non_mhsds()) historic_results$fft_monthly <- tryCatch({
  append_log(root, "fft_monthly: starting FFT org-level search")
  index <- "https://www.england.nhs.uk/fft/friends-and-family-test-data/"
  pub_links <- scrape_links(index, pattern = "friends-and-family-test-data-[a-z]+-[0-9]{4}")
  if (nrow(pub_links) == 0) {
    pub_links <- scrape_links(index, pattern = "publication/friends-and-family")
  }

  raw_paths <- character()
  stacked <- list()
  periods_ok <- character()
  urls_tried <- character()

  pages <- if (nrow(pub_links) > 0) head(unique(pub_links$href), MAX_MONTHS) else character()
  seen_dest <- character()
  for (pub_page in pages) {
    urls_tried <- c(urls_tried, pub_page)
    slug <- gsub(".*/", "", pub_page)
    all_links <- scrape_links(pub_page)
    xlsx <- all_links[grepl("\\.xlsx", all_links$href, ignore.case = TRUE), , drop = FALSE]
    setting <- xlsx[grepl("setting|trust|organisation|org|provider|mental|community", xlsx$text, ignore.case = TRUE) |
      grepl("setting|trust|organisation|org|provider", xlsx$href, ignore.case = TRUE), , drop = FALSE]
    if (nrow(setting) == 0) setting <- xlsx
    for (j in seq_len(min(3, nrow(setting)))) {
      dest <- raw_dest_path(root, "fft_monthly", slug, basename(setting$href[j]))
      if (dest %in% seen_dest) next
      seen_dest <- c(seen_dest, dest)
      res <- safe_download(setting$href[j], dest)
      if (!res$ok) next
      raw_paths <- c(raw_paths, dest)
      if (!requireNamespace("readxl", quietly = TRUE)) next
      sheets <- readxl::excel_sheets(dest)
      for (sh in sheets) {
        df <- as.data.frame(readxl::read_excel(dest, sheet = sh, n_max = 50000))
        rdy <- find_rdy_in_df(df)
        if (rdy$total_code_matches + rdy$total_name_matches == 0) next
        rdy_rows <- filter_rdy_rows(df)
        if (nrow(rdy_rows) == 0) next
        for (k in seq_len(nrow(rdy_rows))) {
          row <- rdy_rows[k, , drop = FALSE]
          num_cols <- names(row)[vapply(row, function(x) {
            v <- to_num_historic(x[1])
            !is.na(v)
          }, logical(1))]
          val_col <- if (length(num_cols) > 0) num_cols[1] else names(row)[1]
          stacked[[length(stacked) + 1]] <- normalize_trend_row(
            "fft_monthly", slug, slug, slug,
            "RDY", "DORSET HEALTHCARE UNIVERSITY NHS FOUNDATION TRUST",
            sh, paste(sh, "-", val_col),
            row[[val_col]][1], dest,
            "FFT public aggregate; check response rates and suppression."
          )
        }
        periods_ok <- c(periods_ok, slug)
      }
    }
  }

  trend_df <- if (length(stacked) > 0) do.call(rbind, stacked) else NULL
  trend_file <- ""
  n_periods <- count_distinct_periods(trend_df, "publication_period")
  trend_avail <- if (n_periods >= 2 && !is.null(trend_df) && nrow(trend_df) > 0) "yes" else "no"

  manual_path <- file.path(root, "metadata", "fft_manual_download_needed.md")
  if (trend_avail != "yes") {
    writeLines(c(
      "# FFT manual download needed",
      "",
      paste("Generated:", Sys.time()),
      "",
      "Public FFT summary XLSX files inspected did not yield org-level RDY rows suitable for trend analysis.",
      "",
      "## URLs tried",
      "",
      paste0("- ", urls_tried),
      "",
      "## Recommended next steps",
      "",
      "1. Open [NHS England FFT data](https://www.england.nhs.uk/fft/friends-and-family-test-data/)",
      "2. Download setting-level or trust-level XLSX if available (not headline summary only)",
      "3. Search for ODS code **RDY** or Dorset HealthCare trust name",
      "4. Place file in `site/public-data/raw/` with prefix `fft_monthly_` and re-run script 05",
      "",
      "> Do not scrape behind login. Do not guess values.",
      "> Not official Dorset HealthCare reporting."
    ), manual_path)
    update_historic_row(root, "fft_monthly", list(
      historic_download_attempted = "yes",
      historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
      historic_raw_files = paste(raw_paths, collapse = "; "),
      historic_trend_file = "",
      trend_available = "no",
      trend_periods_count = as.character(n_periods),
      rdy_rows_stacked = "0",
      trend_caveats = "No org-level RDY rows in downloaded FFT summary files.",
      manual_download_needed = "yes",
      last_run_date = run_date
    ))
  } else {
    write_trend_csv(root, "trend_fft_rdy.csv", trend_df)
    trend_file <- "trend_fft_rdy.csv"
    update_historic_row(root, "fft_monthly", list(
      historic_download_attempted = "yes",
      historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
      historic_raw_files = paste(raw_paths, collapse = "; "),
      historic_trend_file = trend_file,
      trend_available = "yes",
      trend_periods_count = as.character(n_periods),
      rdy_rows_stacked = as.character(nrow(trend_df)),
      trend_caveats = "FFT response rates vary; small number suppression may apply.",
      manual_download_needed = "no",
      last_run_date = run_date
    ))
  }
  append_log(root, paste("fft_monthly: done — trend", trend_avail))
  list(ok = TRUE, trend = trend_avail)
}, error = function(e) {
  append_log(root, paste("fft_monthly ERROR:", conditionMessage(e)))
  writeLines(c(
    "# FFT manual download needed",
    "", paste("Error during automated attempt:", conditionMessage(e)),
    "", "See HISTORIC_PUBLIC_DATA_EXPANSION_PLAN.md for manual steps."
  ), file.path(root, "metadata", "fft_manual_download_needed.md"))
  update_historic_row(root, "fft_monthly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- 6. MHSDS access measures from main data monthly files ---------------------

historic_results$mhsds_monthly <- tryCatch({
  append_log(root, "mhsds_monthly: stacking MHS23/MHS01/MHS29/MHS69 from main data")

  index <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"
  months <- discover_mhsds_month_pages(index, MAX_MONTHS, MIN_MONTHS, root = root)
  print_mhsds_dry_run(months)

  if (DRY_RUN) {
    append_log(root, "mhsds_monthly: dry-run complete — no downloads performed")
    list(ok = TRUE, dry_run = TRUE, periods = nrow(months))
  } else {

  raw_paths <- character()
  stacked <- list()
  periods_ok <- character()

  for (i in seq_len(nrow(months))) {
    slug <- months$slug[i]
    dest <- raw_dest_path(root, "mhsds_monthly", paste0("historic_", slug), "main_data.zip")
    if (!file.exists(dest)) {
      zip_url <- find_mhsds_main_zip(months$href[i])
      if (is.null(zip_url)) {
        append_log(root, paste("mhsds_monthly: no main zip for", slug))
        next
      }
      res <- safe_download(zip_url, dest)
      if (res$ok) raw_paths <- c(raw_paths, dest)
    } else {
      raw_paths <- c(raw_paths, dest)
    }
    if (!file.exists(dest)) next
    csv_path <- extract_zip_csv(dest, pattern = "MHSDS|Data", cache_root = root)
    if (is.null(csv_path)) next
    df <- read_tabular_historic(csv_path)
    part <- stack_mhsds_access_measures(df, slug, dest)
    if (!is.null(part) && nrow(part) > 0) {
      stacked[[length(stacked) + 1]] <- part
      periods_ok <- c(periods_ok, slug)
    }
  }

  trend_df <- if (length(stacked) > 0) do.call(rbind, stacked) else NULL
  trend_file <- ""
  trend_avail <- "no"
  manual_note <- file.path(root, "metadata", "mhsds_trend_gap_note.md")

  measure_checks <- lapply(MHSDS_ACCESS_MEASURES, function(mid) {
    validate_mhsds_measure_trend(trend_df, mid, MIN_MONTHS)
  })
  names(measure_checks) <- MHSDS_ACCESS_MEASURES
  all_ok <- all(vapply(measure_checks, function(x) isTRUE(x$ok), logical(1)))
  min_consecutive <- if (length(measure_checks) > 0) {
    min(vapply(measure_checks, function(x) x$consecutive, integer(1)))
  } else {
    0L
  }

  check_lines <- vapply(measure_checks, function(x) {
    paste0(
      x$measure_id, ": ", x$consecutive, " consecutive month(s), ",
      x$n_numeric, " numeric, ", x$n_suppressed, " suppressed, ",
      x$n_missing, " missing — ", if (isTRUE(x$ok)) "PASS" else "FAIL"
    )
  }, character(1))

  if (!is.null(trend_df) && nrow(trend_df) > 0 && all_ok) {
    write_trend_csv(
      root, "trend_mhsds_access_rdy.csv", trend_df,
      metadata_note = c(
        paste("MHSDS access measures Provider RDY trend — generated", Sys.time()),
        paste("Measures:", paste(MHSDS_ACCESS_MEASURES, collapse = ", ")),
        paste("Periods:", paste(unique(periods_ok), collapse = ", ")),
        check_lines,
        "Provisional monthly MHSDS; Provider breakdown only."
      )
    )
    mhs23_slice <- trend_df[trimws(trend_df$measure_id) == "MHS23", , drop = FALSE]
    if (nrow(mhs23_slice) > 0) {
      write_trend_csv(
        root, "trend_mhs23_rdy.csv", mhs23_slice,
        metadata_note = c(
          paste("MHSDS MHS23 compatibility slice — generated", Sys.time()),
          "Primary source: trend_mhsds_access_rdy.csv"
        )
      )
    }
    trend_file <- "trend_mhsds_access_rdy.csv; trend_mhs23_rdy.csv"
    trend_avail <- "yes"
    if (file.exists(manual_note)) unlink(manual_note)
  } else {
    writeLines(c(
      "# MHSDS access trend gap",
      "",
      paste("Generated:", Sys.time()),
      "",
      paste("Publications processed:", length(periods_ok)),
      paste("Minimum consecutive months required:", MIN_MONTHS),
      "",
      "## Per-measure validation",
      "",
      paste0("- ", check_lines),
      "",
      "## What would be needed",
      "",
      "- Additional MHSDS monthly main data publications with consistent Provider/RDY rows",
      "- Confirmation that measure IDs are unchanged between months",
      "- Local MHSDS owner validation before any operational use",
      "",
      "> Do not fabricate trends. Not official Dorset HealthCare reporting."
    ), manual_note)
  }

  update_historic_row(root, "mhsds_monthly", list(
    historic_download_attempted = "yes",
    historic_periods_downloaded = paste(unique(periods_ok), collapse = "; "),
    historic_raw_files = paste(raw_paths, collapse = "; "),
    historic_trend_file = trend_file,
    trend_available = trend_avail,
    trend_periods_count = as.character(min_consecutive),
    rdy_rows_stacked = as.character(if (is.null(trend_df)) 0 else nrow(trend_df)),
    trend_caveats = paste(
      "Primary: trend_mhsds_access_rdy.csv (MHS23/MHS01/MHS29/MHS69).",
      paste(check_lines, collapse = " | ")
    ),
    manual_download_needed = if (all_ok) "no" else "yes",
    last_run_date = run_date
  ))
  append_log(root, paste("mhsds_monthly access measures:", paste(check_lines, collapse = "; ")))
  list(ok = TRUE, periods = min_consecutive, all_ok = all_ok)
  }

}, error = function(e) {
  append_log(root, paste("mhsds_monthly ERROR:", conditionMessage(e)))
  writeLines(c(
    "# MHSDS access trend not available",
    "", paste("Error:", conditionMessage(e))
  ), file.path(root, "metadata", "mhsds_trend_gap_note.md"))
  update_historic_row(root, "mhsds_monthly", list(
    historic_download_attempted = "yes", trend_available = "no",
    manual_download_needed = "yes", last_run_date = run_date,
    trend_caveats = conditionMessage(e)
  ))
  list(ok = FALSE, error = conditionMessage(e))
})

# --- Summary -------------------------------------------------------------------

reg <- read_historic_register(root)
write_historic_run_summary(root, reg)
append_log(root, "=== Historic public data run completed ===")

cat("Historic run complete.\n")
cat("Summary written to:", file.path(root, "HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md"), "\n")
for (sid in names(historic_results)) {
  r <- historic_results[[sid]]
  cat(sid, ":", if (isTRUE(r$ok)) "OK" else "FAILED", "\n")
}
