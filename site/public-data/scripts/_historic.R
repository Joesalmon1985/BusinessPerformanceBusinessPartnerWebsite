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
    if (nm %in% names(df)) {
      val <- fields[[nm]]
      if (length(val) == 0 || all(is.na(val))) val <- ""
      df[idx, nm] <- paste(as.character(val), collapse = "; ")
    }
  }
  write_historic_register(root, df)
  invisible(df[idx, , drop = FALSE])
}

read_tabular_historic <- function(path, n_max = NULL) {
  if (!file.exists(path)) return(NULL)
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    df <- tryCatch(
      if (is.null(n_max)) {
        utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
      } else {
        utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, nrows = n_max)
      },
      error = function(e) {
        utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "latin1")
      }
    )
    if (!is.data.frame(df)) return(NULL)
    return(df)
  }
  if (ext %in% c("xlsx", "xls") && requireNamespace("readxl", quietly = TRUE)) {
    return(as.data.frame(readxl::read_excel(path)))
  }
  NULL
}

extract_zip_csv <- function(zip_path, pattern = "core|csds|data|extract|MHSDS", prefer_largest = TRUE,
                            cache_root = NULL) {
  if (!file.exists(zip_path)) return(NULL)
  cache_dir <- if (!is.null(cache_root)) {
    file.path(cache_root, "metadata", "historic_extract", gsub("[^a-zA-Z0-9._-]+", "_", basename(zip_path)))
  } else {
    file.path(dirname(zip_path), ".extract", gsub("[^a-zA-Z0-9._-]+", "_", basename(zip_path)))
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  existing <- list.files(cache_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  if (length(existing) > 0) {
    if (nzchar(pattern)) {
      matched <- existing[grepl(pattern, basename(existing), ignore.case = TRUE)]
      if (length(matched) > 0) existing <- matched
    }
    if (prefer_largest && length(existing) > 1) {
      existing <- existing[which.max(file.info(existing)$size)]
    }
    return(existing[1])
  }
  tryCatch(utils::unzip(zip_path, exdir = cache_dir), error = function(e) NULL)
  files <- list.files(cache_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  if (length(files) == 0) return(NULL)
  if (nzchar(pattern)) {
    matched <- files[grepl(pattern, basename(files), ignore.case = TRUE)]
    if (length(matched) > 0) files <- matched
  }
  if (prefer_largest && length(files) > 1) {
    files <- files[which.max(file.info(files)$size)]
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
  "metric_value", "metric_value_raw", "value_status", "source_file", "caveats"
)

classify_value_status <- function(raw_val) {
  raw <- trimws(as.character(raw_val))
  if (length(raw) == 0 || is.na(raw) || !nzchar(raw)) return("missing")
  if (raw == "*") return("suppressed")
  num <- suppressWarnings(as.numeric(raw))
  if (!is.na(num)) return("numeric")
  "not_applicable"
}

normalize_trend_row <- function(source_id, publication_period, r_start, r_end,
                                org_code, org_name, measure_id, measure_name,
                                raw_val, source_file, caveats,
                                value_status = NULL) {
  if (is.null(value_status)) value_status <- classify_value_status(raw_val)
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
    value_status = value_status,
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
  if (!is.null(metadata_note) && length(metadata_note) > 0 && any(nzchar(metadata_note))) {
    note_path <- file.path(root, "metadata", sub("\\.csv$", ".txt", gsub("^trend_", "historic_note_", filename)))
    writeLines(metadata_note, note_path)
  }
  invisible(path)
}

count_distinct_periods <- function(df, col = "reporting_period_start") {
  if (is.null(df) || !is.data.frame(df) || nrow(df) == 0 || !col %in% names(df)) return(0L)
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

MHSDS_ACCESS_MEASURES <- c("MHS23", "MHS01", "MHS29", "MHS69")

stack_mhsds_measure_provider <- function(df, measure_id, publication_period, source_file) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  sub <- df[
    trimws(df$MEASURE_ID) == measure_id &
      trimws(df$BREAKDOWN) == "Provider" &
      trimws(df$PRIMARY_LEVEL) == "RDY",
    ,
    drop = FALSE
  ]
  if (nrow(sub) == 0) {
    return(normalize_trend_row(
      "mhsds_monthly", publication_period, NA_character_, NA_character_,
      "RDY", NA_character_, measure_id, NA_character_,
      NA_character_, source_file,
      "MHSDS Provider/RDY row absent for this measure in this publication.",
      value_status = "missing"
    ))
  }
  caveats <- paste0(
    "MHSDS ", measure_id, " at Provider/RDY breakdown; provisional monthly data."
  )
  normalize_trend_row(
    "mhsds_monthly", publication_period,
    sub$REPORTING_PERIOD_START[1], sub$REPORTING_PERIOD_END[1],
    "RDY", sub$PRIMARY_LEVEL_DESCRIPTION[1],
    measure_id, sub$MEASURE_NAME[1],
    sub$MEASURE_VALUE[1], source_file, caveats
  )
}

stack_mhsds_mhs23_provider <- function(df, publication_period, source_file) {
  stack_mhsds_measure_provider(df, "MHS23", publication_period, source_file)
}

stack_mhsds_access_measures <- function(df, publication_period, source_file,
                                        measures = MHSDS_ACCESS_MEASURES) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  rows <- lapply(measures, function(mid) {
    stack_mhsds_measure_provider(df, mid, publication_period, source_file)
  })
  do.call(rbind, rows)
}

parse_mhsds_slug_date <- function(slug) {
  slug <- tolower(trimws(as.character(slug)))
  m <- regmatches(slug, regexec("([a-z]+)-([0-9]{4})$", slug))[[1]]
  if (length(m) != 3) return(as.Date(NA))
  month_num <- match(tolower(m[2]), tolower(month.name))
  if (is.na(month_num)) return(as.Date(NA))
  as.Date(sprintf("%04d-%02d-01", as.integer(m[3]), month_num))
}

parse_trend_period_date <- function(x) {
  x <- trimws(as.character(x))
  d <- suppressWarnings(as.Date(x, format = "%d/%m/%Y"))
  if (length(d) == 0 || all(is.na(d))) {
    d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  }
  if (length(d) == 0 || all(is.na(d))) {
    d <- parse_mhsds_slug_date(x)
  }
  d
}

count_consecutive_months <- function(period_dates) {
  d <- sort(unique(na.omit(period_dates)))
  if (length(d) == 0) return(0L)
  if (length(d) == 1) return(1L)
  runs <- 1L
  best <- 1L
  for (i in seq_len(length(d) - 1L)) {
    gap <- as.integer(d[i + 1] - d[i])
    if (gap <= 31L && gap >= 27L) {
      runs <- runs + 1L
    } else {
      runs <- 1L
    }
    if (runs > best) best <- runs
  }
  best
}

validate_mhsds_measure_trend <- function(trend_df, measure_id, min_months = 6L) {
  if (is.null(trend_df) || nrow(trend_df) == 0) {
    return(list(
      measure_id = measure_id, n_periods = 0L, consecutive = 0L,
      n_numeric = 0L, n_suppressed = 0L, n_missing = 0L, ok = FALSE
    ))
  }
  sub <- trend_df[trimws(trend_df$measure_id) == measure_id, , drop = FALSE]
  if (nrow(sub) == 0) {
    return(list(
      measure_id = measure_id, n_periods = 0L, consecutive = 0L,
      n_numeric = 0L, n_suppressed = 0L, n_missing = 0L, ok = FALSE
    ))
  }
  sub$period_date <- parse_trend_period_date(sub$reporting_period_start)
  sub <- sub[!is.na(sub$period_date), , drop = FALSE]
  n_periods <- length(unique(sub$period_date))
  consecutive <- count_consecutive_months(sub$period_date)
  n_numeric <- sum(sub$value_status == "numeric", na.rm = TRUE)
  n_suppressed <- sum(sub$value_status == "suppressed", na.rm = TRUE)
  n_missing <- sum(sub$value_status == "missing", na.rm = TRUE)
  list(
    measure_id = measure_id,
    n_periods = n_periods,
    consecutive = consecutive,
    n_numeric = n_numeric,
    n_suppressed = n_suppressed,
    n_missing = n_missing,
    ok = consecutive >= min_months && n_numeric >= 2L
  )
}

print_mhsds_dry_run <- function(months) {
  if (is.null(months) || nrow(months) == 0) {
    cat("MHSDS dry run: no publication pages discovered.\n")
    return(invisible(NULL))
  }
  cat("MHSDS dry run — discovered publication pages (newest first):\n")
  for (i in seq_len(nrow(months))) {
    cat(sprintf(
      "  %2d. %s  (%s)  %s\n",
      i, months$slug[i],
      if (!is.na(months$pub_date[i])) format(months$pub_date[i], "%b %Y") else "?",
      months$href[i]
    ))
  }
  cat(sprintf("Total: %d publication(s)\n", nrow(months)))
  invisible(months)
}

stack_ae_rdy_row <- function(df, source_file) {
  if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  r <- rdy[1, , drop = FALSE]
  period <- if ("Period" %in% names(r)) as.character(r$Period[1]) else NA_character_
  get_col <- function(nm) {
    if (!nm %in% names(r)) return(NA_character_)
    as.character(r[[nm]][1])
  }
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
  period <- if ("Period" %in% names(rdy)) unique(trimws(rdy$Period))[1] else NA_character_
  if (is.na(period) || !nzchar(period)) {
    period <- sub(".*DM01-", "DM01-", basename(source_file))
    period <- sub("\\.zip$", "", period, ignore.case = TRUE)
  }
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
  if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(NULL)
  rdy <- filter_rdy_rows(df)
  if (nrow(rdy) == 0) return(NULL)
  org_col <- if ("Organisation_Code" %in% names(rdy)) "Organisation_Code" else names(rdy)[1]
  sector_col <- if ("Sector" %in% names(rdy)) "Sector" else NA_character_
  beds_col <- if ("Number_Of_Beds" %in% names(rdy)) "Number_Of_Beds" else NA_character_
  snap_col <- if ("Effective_Snapshot_Date" %in% names(rdy)) "Effective_Snapshot_Date" else NA_character_
  rows <- lapply(seq_len(nrow(rdy)), function(i) {
    r <- rdy[i, , drop = FALSE]
    snap <- if (!is.na(snap_col)) as.character(r[[snap_col]][1]) else NA_character_
    sector <- if (!is.na(sector_col)) as.character(r[[sector_col]][1]) else "Unknown"
    beds <- if (!is.na(beds_col)) r[[beds_col]][1] else NA
    org <- as.character(r[[org_col]][1])
    normalize_trend_row(
      "kh03_quarterly", snap, snap, snap,
      org, "DORSET HEALTHCARE UNIVERSITY NHS FOUNDATION TRUST",
      sector, paste0(sector, " beds"),
      beds, source_file, caveats
    )
  })
  do.call(rbind, rows)
}

filter_kh03_recent_snapshots <- function(df, max_snapshots = 6, min_year = 2020) {
  if (is.null(df) || nrow(df) == 0) return(df)
  if (!"snapshot_date" %in% names(df)) {
    df$snapshot_date <- parse_snapshot_date(df$reporting_period_start)
  }
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
  fy_links <- fy_links[!is.na(fy_links$href), , drop = FALSE]
  fy_links <- fy_links[grepl("2026-27|2025-26|2024-25", fy_links$href), , drop = FALSE]
  hrefs <- character()
  for (fy in fy_links$href) {
    zip_links <- scrape_links(fy)
    zip_links <- zip_links[!is.na(zip_links$href), , drop = FALSE]
    zip_links <- zip_links[grepl("\\.zip", zip_links$href, ignore.case = TRUE), , drop = FALSE]
    # Prefer monthly provider full-extract files (not aggregate REVISED bundles)
    full <- zip_links[
      grepl("full-extract|full_extract|DM01-[A-Z]+-[0-9]{4}-full", zip_links$href, ignore.case = TRUE) |
        grepl("full-extract|full extract", zip_links$text, ignore.case = TRUE),
      ,
      drop = FALSE
    ]
    if (nrow(full) > 0) {
      hrefs <- c(hrefs, full$href)
    } else {
      zip_links <- zip_links[grepl("DM01|extract|Extract", zip_links$href, ignore.case = TRUE) |
        grepl("DM01|extract|Extract", zip_links$text, ignore.case = TRUE), , drop = FALSE]
      bad <- grepl("REVISED|EXTRACTS-J|dh_[0-9]", zip_links$href, ignore.case = TRUE)
      bad[is.na(bad)] <- FALSE
      zip_links <- zip_links[!bad, , drop = FALSE]
      hrefs <- c(hrefs, zip_links$href)
    }
    if (length(unique(hrefs)) >= max_months) break
  }
  hrefs <- unique(hrefs[!is.na(hrefs)])
  if (length(hrefs) > max_months) hrefs <- hrefs[seq_len(max_months)]
  data.frame(href = hrefs, name = basename(hrefs), stringsAsFactors = FALSE)
}

discover_mhsds_from_raw_files <- function(root, max_months = 12) {
  raw_dir <- file.path(root, "raw")
  if (!dir.exists(raw_dir)) return(data.frame(href = character(), slug = character(), pub_date = as.Date(character())))
  files <- list.files(raw_dir, pattern = "^mhsds_monthly_historic_performance-[a-z]+-[0-9]{4}_main_data\\.zip$")
  if (length(files) == 0) {
    files <- list.files(raw_dir, pattern = "^mhsds_monthly_performance-[a-z]+-[0-9]{4}_main_data\\.zip$")
  }
  slugs <- sub("^mhsds_monthly_(?:historic_)?", "", files)
  slugs <- sub("_main_data\\.zip$", "", slugs)
  pub_dates <- as.Date(vapply(slugs, function(s) {
    d <- parse_mhsds_slug_date(s)
    if (is.na(d)) NA_character_ else format(d, "%Y-%m-%d")
  }, character(1)))
  hrefs <- paste0(
    "https://digital.nhs.uk/data-and-information/publications/statistical/",
    "mental-health-services-monthly-statistics/", slugs
  )
  out <- data.frame(href = hrefs, slug = slugs, pub_date = pub_dates, stringsAsFactors = FALSE)
  out <- out[!duplicated(out$slug), , drop = FALSE]
  out <- out[order(out$pub_date, decreasing = TRUE, na.last = TRUE), , drop = FALSE]
  if (nrow(out) > max_months) out <- out[seq_len(max_months), , drop = FALSE]
  out
}

discover_mhsds_month_pages <- function(index_url, max_months = 12, min_months = 6L, root = NULL) {
  collect_perf_links <- function(url) {
    links <- scrape_links(url)
    perf <- links[
      grepl("/mental-health-services-monthly-statistics/[a-z]+-[0-9]{4}$", links$href, ignore.case = TRUE),
      ,
      drop = FALSE
    ]
    if (nrow(perf) == 0) {
      perf <- links[grepl("performance-[a-z]+-[0-9]{4}", links$href, ignore.case = TRUE), , drop = FALSE]
    }
    perf
  }

  perf <- collect_perf_links(index_url)
  year_links <- scrape_links(index_url)
  year_hrefs <- year_links$href[
    grepl("/mental-health-services-monthly-statistics/20[0-9]{2}$", year_links$href, ignore.case = TRUE)
  ]
  for (yh in unique(year_hrefs)) {
    perf <- rbind(perf, collect_perf_links(yh))
  }

  if (nrow(perf) == 0 && !is.null(root)) {
    return(discover_mhsds_from_raw_files(root, max_months))
  }

  if (nrow(perf) == 0) {
    return(data.frame(href = character(), slug = character(), pub_date = as.Date(character())))
  }

  slugs <- gsub(".*/", "", perf$href)
  pub_dates <- as.Date(vapply(slugs, function(s) {
    d <- parse_mhsds_slug_date(s)
    if (is.na(d)) NA_character_ else format(d, "%Y-%m-%d")
  }, character(1)))
  out <- data.frame(href = perf$href, slug = slugs, pub_date = pub_dates, stringsAsFactors = FALSE)
  out <- out[!duplicated(out$slug), , drop = FALSE]
  out <- out[order(out$pub_date, decreasing = TRUE, na.last = TRUE), , drop = FALSE]
  if (nrow(out) > max_months) out <- out[seq_len(max_months), , drop = FALSE]

  if (nrow(out) < min_months && !is.null(root)) {
    raw_fallback <- discover_mhsds_from_raw_files(root, max_months)
    if (nrow(raw_fallback) > nrow(out)) out <- raw_fallback
  }

  if (nrow(out) < min_months && !is.null(getOption("historic.root"))) {
    append_log(getOption("historic.root"), paste(
      "mhsds_monthly: only", nrow(out), "publications discovered — need", min_months
    ))
  }
  out
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
      if (length(r$trend_caveats) > 0 && any(nzchar(as.character(r$trend_caveats)))) paste("- Caveats:", r$trend_caveats) else "",
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
  pub_summary <- file.path(root, "PUBLIC_DATA_RUN_SUMMARY.md")
  if (file.exists(pub_summary)) {
    append_line <- paste0(
      "\n## Historic trend pipeline (script 05)\n\n",
      "See [HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md](HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md) for latest historic download/stack results.\n"
    )
    existing <- readLines(pub_summary, warn = FALSE)
    if (!any(grepl("Historic trend pipeline \\(script 05\\)", existing))) {
      writeLines(c(existing, append_line), pub_summary)
    }
  }
}
