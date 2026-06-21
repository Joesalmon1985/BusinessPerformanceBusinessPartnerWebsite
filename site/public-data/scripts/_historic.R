# =============================================================================
# scripts/_historic.R
# Helpers for historic public aggregate download and trend stacking (RDY only).
# Public aggregate data only — no patient-identifiable information.
# =============================================================================

HISTORIC_REGISTER_COLUMNS <- c(
  "source_id", "historic_download_attempted", "historic_periods_downloaded",
  "historic_raw_files", "historic_trend_file", "trend_available",
  "trend_periods_count", "rdy_rows_stacked", "trend_caveats",
  "manual_download_needed", "last_run_date"
)

historic_register_path <- function(root) {
  file.path(root, "HISTORIC_SOURCE_REGISTER.csv")
}

init_historic_register <- function(root) {
  df <- data.frame(
    source_id = c(
      "csds_monthly", "ae_monthly", "dm01_monthly", "kh03_quarterly",
      "fft_monthly", "mhsds_monthly"
    ),
    historic_download_attempted = "no",
    historic_periods_downloaded = "",
    historic_raw_files = "",
    historic_trend_file = "",
    trend_available = "no",
    trend_periods_count = "0",
    rdy_rows_stacked = "0",
    trend_caveats = "",
    manual_download_needed = "no",
    last_run_date = "",
    stringsAsFactors = FALSE
  )
  write.csv(df, historic_register_path(root), row.names = FALSE)
  df
}

read_historic_register <- function(root) {
  path <- historic_register_path(root)
  if (!file.exists(path)) return(init_historic_register(root))
  df <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  for (col in HISTORIC_REGISTER_COLUMNS) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }
  df[, HISTORIC_REGISTER_COLUMNS, drop = FALSE]
}

write_historic_register <- function(root, df) {
  for (col in HISTORIC_REGISTER_COLUMNS) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }
  write.csv(df[, HISTORIC_REGISTER_COLUMNS, drop = FALSE], historic_register_path(root), row.names = FALSE)
}

update_historic_row <- function(root, source_id, fields) {
  df <- read_historic_register(root)
  idx <- which(df$source_id == source_id)
  if (length(idx) == 0) {
    new_row <- as.list(setNames(rep("", length(HISTORIC_REGISTER_COLUMNS)), HISTORIC_REGISTER_COLUMNS))
    new_row$source_id <- source_id
    df <- rbind(df, as.data.frame(new_row, stringsAsFactors = FALSE))
    idx <- nrow(df)
  }
  for (nm in names(fields)) {
    if (nm %in% names(df)) df[idx, nm] <- as.character(fields[[nm]])
  }
  write_historic_register(root, df)
  invisible(df[idx, , drop = FALSE])
}

read_tabular_historic <- function(path) {
  if (!file.exists(path)) return(NULL)
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    df <- tryCatch(
      utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) {
        utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "latin1")
      }
    )
    return(df)
  }
  if (ext %in% c("xlsx", "xls") && requireNamespace("readxl", quietly = TRUE)) {
    return(as.data.frame(readxl::read_excel(path)))
  }
  NULL
}

extract_zip_csv <- function(zip_path, pattern = "core|csds|data|extract|MHSDS", prefer_largest = TRUE) {
  tmp <- tempfile("historic_zip_")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  utils::unzip(zip_path, exdir = tmp)
  files <- list.files(tmp, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  if (length(files) == 0) return(NULL)
  if (nzchar(pattern)) {
    matched <- files[grepl(pattern, basename(files), ignore.case = TRUE)]
    if (length(matched) > 0) files <- matched
  }
  if (prefer_largest && length(files) > 1) {
    sizes <- file.info(files)$size
    files <- files[which.max(sizes)]
  }
  files[1]
}

to_num_historic <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("", "*", "NA", "N/A")] <- NA
  suppressWarnings(as.numeric(x))
}

parse_snapshot_date <- function(x) {
  x <- trimws(as.character(x))
  d <- suppressWarnings(as.Date(x, format = "%d/%m/%Y"))
  if (all(is.na(d))) d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  d
}

TREND_STANDARD_COLS <- c(
  "source_id", "publication_period", "reporting_period_start", "reporting_period_end",
  "org_code", "org_name", "measure_id", "measure_name",
  "metric_value", "metric_value_raw", "source_file", "caveats"
)

normalize_trend_row <- function(source_id, publication_period, r_start, r_end,
                                org_code, org_name, measure_id, measure_name,
                                raw_val, source_file, caveats) {
  data.frame(
    source_id = source_id,
    publication_period = publication_period,
    reporting_period_start = r_start,
    reporting_period_end = r_end,
    org_code = org_code,
    org_name = org_name,
    measure_id = measure_id,
    measure_name = measure_name,
    metric_value = to_num_historic(raw_val),
    metric_value_raw = as.character(raw_val),
    source_file = basename(source_file),
    caveats = caveats,
    stringsAsFactors = FALSE
  )
}

write_trend_csv <- function(root, filename, df, metadata_note = NULL) {
  if (is.null(df) || nrow(df) == 0) return(invisible(NULL))
  for (col in TREND_STANDARD_COLS) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }
  df <- df[, TREND_STANDARD_COLS, drop = FALSE]
  path <- file.path(root, "processed", filename)
  write.csv(sanitize_df_for_export(df), path, row.names = FALSE)
  if (!is.null(metadata_note) && nzchar(metadata_note)) {
    note_path <- file.path(root, "metadata", sub("\\.csv$", ".txt", gsub("^trend_", "historic_note_", filename)))
    writeLines(metadata_note, note_path)
  }
  invisible(path)
}

count_distinct_periods <- function(df, col = "reporting_period_start") {
  if (is.null(df) || nrow(df) == 0 || !col %in% names(df)) return(0L)
  length(unique(na.omit(trimws(df[[col]]))))
}

stack_csds_careactivities <- function(df, publication_period, source_file) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  act <- rdy[
    rdy$COUNT_OF == "CareActivities" & rdy$DIMENSION == "ActivityType",
    ,
    drop = FALSE
  ]
  if (nrow(act) == 0) return(NULL)
  caveats <- "Provisional CSDS monthly data; ActivityType/CareActivities slice only."
  rows <- lapply(seq_len(nrow(act)), function(i) {
    r <- act[i, , drop = FALSE]
    normalize_trend_row(
      "csds_monthly", publication_period,
      r$REPORTING_PERIOD_START[1], r$REPORTING_PERIOD_END[1],
      r$ORG_CODE[1], r$ORG_NAME[1],
      r$MEASURE[1], r$MEASURE_DESC[1],
      r$MEASURE_VALUE[1], source_file, caveats
    )
  })
  do.call(rbind, rows)
}

stack_mhsds_mhs23_provider <- function(df, publication_period, source_file) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  sub <- df[
    trimws(df$MEASURE_ID) == "MHS23" &
      trimws(df$BREAKDOWN) == "Provider" &
      trimws(df$PRIMARY_LEVEL) == "RDY",
    ,
    drop = FALSE
  ]
  if (nrow(sub) == 0) return(NULL)
  caveats <- "MHSDS MHS23 open referrals at end of RP; Provider breakdown; provisional monthly data."
  normalize_trend_row(
    "mhsds_monthly", publication_period,
    sub$REPORTING_PERIOD_START[1], sub$REPORTING_PERIOD_END[1],
    "RDY", sub$PRIMARY_LEVEL_DESCRIPTION[1],
    "MHS23", sub$MEASURE_NAME[1],
    sub$MEASURE_VALUE[1], source_file, caveats
  )
}

stack_ae_rdy_row <- function(df, source_file) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  r <- rdy[1, , drop = FALSE]
  period <- if ("Period" %in% names(r)) r$Period[1] else NA_character_
  get_col <- function(nm) if (nm %in% names(r)) r[[nm]][1] else NA
  caveats <- paste(
    "A&E source validation only — RDY has no Type 1/2 ED;",
    "do not interpret as urgent care performance."
  )
  rows <- list(
    normalize_trend_row(
      "ae_monthly", period, period, period,
      get_col("Org Code"), get_col("Org name"),
      "AE_TYPE1", "A&E attendances Type 1",
      get_col("A&E attendances Type 1"), source_file, caveats
    ),
    normalize_trend_row(
      "ae_monthly", period, period, period,
      get_col("Org Code"), get_col("Org name"),
      "AE_TYPE2", "A&E attendances Type 2",
      get_col("A&E attendances Type 2"), source_file, caveats
    ),
    normalize_trend_row(
      "ae_monthly", period, period, period,
      get_col("Org Code"), get_col("Org name"),
      "OTHER_EM_ADM", "Other emergency admissions",
      get_col("Other emergency admissions"), source_file, caveats
    )
  )
  do.call(rbind, rows)
}

stack_dm01_rdy <- function(df, source_file) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  period <- if ("Period" %in% names(rdy)) unique(rdy$Period)[1] else NA_character_
  caveats <- "Provisional DM01 monthly diagnostics; validate with local service owner."
  tests <- unique(rdy$`Diagnostic Tests`)
  rows <- lapply(tests, function(tst) {
    row <- rdy[rdy$`Diagnostic Tests` == tst, , drop = FALSE][1, , drop = FALSE]
    normalize_trend_row(
      "dm01_monthly", period, period, period,
      row$`Provider Org Code`, row$`Provider Org Name`,
      row$`Diagnostic Tests Sort Order`, tst,
      row$`Total Activity`, source_file, caveats
    )
  })
  do.call(rbind, rows)
}

stack_kh03_rdy_long <- function(df, source_file, caveats) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  rows <- lapply(seq_len(nrow(rdy)), function(i) {
    r <- rdy[i, , drop = FALSE]
    snap <- r$Effective_Snapshot_Date[1]
    normalize_trend_row(
      "kh03_quarterly", snap, snap, snap,
      r$Organisation_Code[1], "DORSET HEALTHCARE UNIVERSITY NHS FOUNDATION TRUST",
      r$Sector[1], paste0(r$Sector[1], " beds"),
      r$Number_Of_Beds[1], source_file, caveats
    )
  })
  do.call(rbind, rows)
}

filter_kh03_recent_snapshots <- function(df, max_snapshots = 6, min_year = 2020) {
  if (is.null(df) || nrow(df) == 0) return(df)
  df$snapshot_date <- parse_snapshot_date(df$reporting_period_start)
  df <- df[!is.na(df$snapshot_date) & as.integer(format(df$snapshot_date, "%Y")) >= min_year, , drop = FALSE]
  if (nrow(df) == 0) return(df)
  snaps <- sort(unique(df$snapshot_date), decreasing = TRUE)
  keep <- snaps[seq_len(min(max_snapshots, length(snaps)))]
  df <- df[df$snapshot_date %in% keep, , drop = FALSE]
  df$snapshot_date <- NULL
  df
}

discover_csds_month_pages <- function(index_url, max_months = 12) {
  links <- scrape_links(index_url)
  month_links <- links[grepl(
    "/community-services-statistics-for-children-young-people-and-adults/[a-z]+-[0-9]{4}$",
    links$href, ignore.case = TRUE
  ), , drop = FALSE]
  if (nrow(month_links) == 0) return(data.frame(href = character(), slug = character()))
  slugs <- gsub(".*/", "", month_links$href)
  data.frame(href = month_links$href, slug = slugs, stringsAsFactors = FALSE)
}

find_csds_core_zip <- function(pub_datasets_url) {
  all_links <- scrape_links(pub_datasets_url)
  m <- all_links[grepl("core-data|csds.*\\.zip|CSV Data", all_links$text, ignore.case = TRUE) |
    grepl("core-data|csds.*\\.zip", all_links$href, ignore.case = TRUE), , drop = FALSE]
  m <- m[grepl("\\.zip", m$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(m) == 0) return(NULL)
  m$href[1]
}

discover_ae_monthly_csvs <- function(max_months = 12) {
  index <- "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/"
  fy_links <- scrape_links(index, pattern = "ae-attendances-and-emergency-admissions-20")
  hrefs <- character()
  for (fy in fy_links$href) {
    csv_links <- scrape_links(fy, extensions = c("csv"))
    csv_links <- csv_links[grepl("Monthly|monthly|\\.csv", csv_links$href, ignore.case = TRUE), , drop = FALSE]
    hrefs <- c(hrefs, csv_links$href)
    if (length(unique(hrefs)) >= max_months) break
  }
  hrefs <- unique(hrefs)
  if (length(hrefs) > max_months) hrefs <- hrefs[seq_len(max_months)]
  data.frame(href = hrefs, name = basename(hrefs), stringsAsFactors = FALSE)
}

discover_dm01_monthly_zips <- function(max_months = 12) {
  index <- paste0(
    "https://www.england.nhs.uk/statistics/statistical-work-areas/",
    "diagnostics-waiting-times-and-activity/monthly-diagnostics-waiting-times-and-activity/"
  )
  fy_links <- scrape_links(index, pattern = "monthly-diagnostics-data-20")
  hrefs <- character()
  for (fy in fy_links$href) {
    zip_links <- scrape_links(fy)
    zip_links <- zip_links[grepl("\\.zip", zip_links$href, ignore.case = TRUE), , drop = FALSE]
    zip_links <- zip_links[grepl("DM01|extract|Extract", zip_links$href, ignore.case = TRUE) |
      grepl("DM01|extract|Extract", zip_links$text, ignore.case = TRUE), , drop = FALSE]
    hrefs <- c(hrefs, zip_links$href)
    if (length(unique(hrefs)) >= max_months) break
  }
  hrefs <- unique(hrefs)
  if (length(hrefs) > max_months) hrefs <- hrefs[seq_len(max_months)]
  data.frame(href = hrefs, name = basename(hrefs), stringsAsFactors = FALSE)
}

discover_mhsds_month_pages <- function(index_url, max_months = 12) {
  links <- scrape_links(index_url)
  perf <- links[grepl("/mental-health-services-monthly-statistics/[a-z]+-[0-9]{4}$", links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(perf) == 0) {
    perf <- links[grepl("performance-[a-z]+-[0-9]{4}", links$href, ignore.case = TRUE), , drop = FALSE]
  }
  slugs <- gsub(".*/", "", perf$href)
  data.frame(href = perf$href, slug = slugs, stringsAsFactors = FALSE)
}

find_mhsds_main_zip <- function(pub_page) {
  all_links <- scrape_links(pub_page)
  m <- all_links[grepl("MHSDS Data File|Main.*Data|Data File.*ZIP|main_data", all_links$text, ignore.case = TRUE) |
    grepl("main.*data|data.*file", all_links$href, ignore.case = TRUE), , drop = FALSE]
  m <- m[grepl("\\.zip", m$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(m) == 0) return(NULL)
  m$href[1]
}

write_historic_run_summary <- function(root, register_df) {
  lines <- c(
    "# Historic public data run summary",
    "",
    paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "",
    "> Public aggregate data only. Not official Dorset HealthCare reporting.",
    "> Human review and local owner confirmation required.",
    "",
    "## Sources",
    ""
  )
  for (i in seq_len(nrow(register_df))) {
    r <- register_df[i, , drop = FALSE]
    lines <- c(lines,
      paste0("### ", r$source_id),
      paste("- Historic download attempted:", r$historic_download_attempted),
      paste("- Periods downloaded:", r$historic_periods_downloaded),
      paste("- Trend file:", if (nzchar(r$historic_trend_file)) r$historic_trend_file else "none"),
      paste("- Trend available:", r$trend_available),
      paste("- Trend periods (distinct):", r$trend_periods_count),
      paste("- RDY rows stacked:", r$rdy_rows_stacked),
      paste("- Manual download needed:", r$manual_download_needed),
      if (nzchar(r$trend_caveats)) paste("- Caveats:", r$trend_caveats) else "",
      ""
    )
  }
  lines <- c(lines,
    "## Rerun",
    "",
    "```bash",
    "Rscript site/public-data/05_download_historic_public_data.R",
    "Rscript site/R/03_render_public_reports.R",
    "```",
    ""
  )
  writeLines(lines, file.path(root, "HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md"))
}
