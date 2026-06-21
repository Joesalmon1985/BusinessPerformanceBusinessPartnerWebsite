# =============================================================================
# scripts/_common.R
# Shared helpers for NHS public aggregate data pipeline (Dorset HealthCare RDY).
# Public aggregate data only — no patient-identifiable information.
# =============================================================================

RDY_CODE <- "RDY"
RDY_NAME_PATTERNS <- c(
  "Dorset HealthCare University NHS Foundation Trust",
  "Dorset Healthcare University NHS Foundation Trust",
  "DORSET HEALTHCARE UNIVERSITY NHS FOUNDATION TRUST"
)

REGISTER_COLUMNS <- c(
  "source_id", "source_name", "publisher", "source_url", "file_type",
  "publication_period", "date_range", "update_frequency",
  "geographic_granularity", "organisation_granularity", "expected_filter_field",
  "can_filter_to_rdy", "contains_dorset_healthcare_rows", "download_status",
  "recommended_report_use", "caveats", "downloaded_file_path",
  "processed_file_path", "download_date", "source_access_notes"
)

get_public_data_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("--file=", "", args[grep("--file=", args)])
  if (length(script_path) > 0) {
    return(normalizePath(file.path(dirname(normalizePath(script_path)), "..")))
  }
  normalizePath(getwd())
}

ensure_dirs <- function(root) {
  for (d in c("raw", "processed", "metadata", "scripts")) {
    dir.create(file.path(root, d), recursive = TRUE, showWarnings = FALSE)
  }
}

ensure_packages <- function(packages = c("rvest", "readxl", "jsonlite"), root = NULL) {
  if (is.null(root)) {
    root <- tryCatch(get_public_data_root(), error = function(e) normalizePath(getwd()))
  }
  local_lib <- file.path(root, "R_libs")
  dir.create(local_lib, recursive = TRUE, showWarnings = FALSE)
  if (!local_lib %in% .libPaths()) {
    .libPaths(c(local_lib, .libPaths()))
  }
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    message("Installing missing CRAN packages to ", local_lib, ": ", paste(missing, collapse = ", "))
    install.packages(missing, repos = "https://cloud.r-project.org", lib = local_lib)
  }
  still_missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(still_missing) > 0) {
    stop("Required packages not available: ", paste(still_missing, collapse = ", "))
  }
  invisible(TRUE)
}

register_path <- function(root) {
  file.path(root, "DATA_SOURCE_REGISTER.csv")
}

read_register <- function(root) {
  path <- register_path(root)
  if (!file.exists(path)) return(NULL)
  df <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  for (col in REGISTER_COLUMNS) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }
  df[, REGISTER_COLUMNS, drop = FALSE]
}

write_register <- function(root, df) {
  for (col in REGISTER_COLUMNS) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }
  write.csv(df[, REGISTER_COLUMNS, drop = FALSE], register_path(root), row.names = FALSE)
}

update_register_row <- function(root, source_id, fields) {
  df <- read_register(root)
  if (is.null(df)) stop("Register not found. Run 01_download_public_data.R first.")
  idx <- which(df$source_id == source_id)
  if (length(idx) == 0) stop("Unknown source_id: ", source_id)
  for (nm in names(fields)) {
    if (nm %in% names(df)) df[idx, nm] <- as.character(fields[[nm]])
  }
  write_register(root, df)
  invisible(df[idx, , drop = FALSE])
}

get_register_row <- function(root, source_id) {
  df <- read_register(root)
  if (is.null(df)) return(NULL)
  row <- df[df$source_id == source_id, , drop = FALSE]
  if (nrow(row) == 0) NULL else row
}

candidate_org_columns <- function() {
  c(
    "org_code", "organisation code", "organization code", "organisation code \\(code of provider\\)",
    "provider code", "provider_code", "provder", "trust_code", "trust code",
    "organisation code", "organization code", "org code", "ods", "ods code",
    "trust_name", "trust name", "provider name", "provider_name",
    "organisation name", "organization name", "organisation name \\(name of provider\\)"
  )
}

is_org_code_column <- function(col_name) {
  cn <- tolower(trimws(safe_char(col_name)))
  cn %in% c(
    "org_code", "organisation code", "organization code", "provider code",
    "provider_code", "provder", "trust_code", "trust code", "org code",
    "ods", "ods code", "provider", "site code", "trust code"
  ) || grepl("org.*code|provider.*code|trust.*code|^ods$", cn)
}

is_org_name_column <- function(col_name) {
  cn <- tolower(trimws(safe_char(col_name)))
  cn %in% c(
    "trust_name", "trust name", "provider name", "provider_name",
    "organisation name", "organization name", "trust_name"
  ) || grepl("trust.*name|provider.*name|organisation.*name|organization.*name", cn)
}

normalise_colnames <- function(nms) {
  trimws(nms)
}

safe_download <- function(url, dest, timeout = 120) {
  result <- list(ok = FALSE, message = "", path = dest)
  if (is.na(url) || !nzchar(url)) {
    result$message <- "Empty URL"
    return(result)
  }
  if (file.exists(dest)) {
    result$ok <- TRUE
    result$message <- "File already exists (preserved, not overwritten)"
    return(result)
  }
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(fileext = ".download")
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  status <- tryCatch({
    utils::download.file(url, tmp, mode = "wb", quiet = TRUE, method = "libcurl")
    if (!file.exists(tmp) || file.info(tmp)$size == 0) {
      stop("Download produced empty file")
    }
    if (!file.copy(tmp, dest, overwrite = FALSE)) {
      stop("Could not copy to destination (file may already exist)")
    }
    TRUE
  }, error = function(e) {
    result$message <<- conditionMessage(e)
    FALSE
  })
  result$ok <- isTRUE(status)
  if (result$ok && !nzchar(result$message)) result$message <- "Downloaded successfully"
  result
}

fetch_html <- function(url) {
  if (!requireNamespace("rvest", quietly = TRUE)) stop("rvest required")
  rvest::read_html(url)
}

resolve_url <- function(base_url, href) {
  if (is.na(href) || !nzchar(href)) return(NA_character_)
  if (grepl("^https?://", href)) return(href)
  if (grepl("^//", href)) return(paste0("https:", href))
  origin <- regmatches(base_url, regexpr("^https?://[^/]+", base_url))
  if (grepl("^/", href)) return(paste0(origin, href))
  base_path <- gsub("[^/]+$", "", base_url)
  paste0(base_path, href)
}

scrape_links <- function(page_url, pattern = NULL, extensions = NULL) {
  if (!requireNamespace("rvest", quietly = TRUE)) {
    return(data.frame(href = character(), text = character()))
  }
  doc <- tryCatch(fetch_html(page_url), error = function(e) NULL)
  if (is.null(doc)) return(data.frame(href = character(), text = character()))
  links <- rvest::html_elements(doc, "a")
  raw_href <- rvest::html_attr(links, "href")
  text <- rvest::html_text2(links)
  abs_href <- vapply(raw_href, resolve_url, character(1), base_url = page_url)
  df <- data.frame(href = abs_href, text = text, stringsAsFactors = FALSE)
  df <- df[!is.na(df$href) & nzchar(df$href), , drop = FALSE]
  if (!is.null(pattern)) {
    pat <- paste(pattern, collapse = "|")
    df <- df[grepl(pat, df$href, ignore.case = TRUE) | grepl(pat, df$text, ignore.case = TRUE), , drop = FALSE]
  }
  if (!is.null(extensions)) {
    ext_pat <- paste0("\\.(", paste(extensions, collapse = "|"), ")(\\?|$)", collapse = "")
    df <- df[grepl(ext_pat, df$href, ignore.case = TRUE), , drop = FALSE]
  }
  df <- unique(df)
  row.names(df) <- NULL
  df
}

find_best_link <- function(page_url, patterns, extensions = c("csv", "zip", "xlsx", "xls")) {
  links <- scrape_links(page_url, pattern = patterns, extensions = extensions)
  if (nrow(links) == 0) {
    links <- scrape_links(page_url, pattern = patterns)
    if (nrow(links) > 0) {
      ext_pat <- paste0("\\.(", paste(extensions, collapse = "|"), ")", collapse = "")
      links <- links[grepl(ext_pat, links$href, ignore.case = TRUE), , drop = FALSE]
    }
  }
  if (nrow(links) == 0) return(NULL)
  links[1, , drop = FALSE]
}

find_publication_page <- function(index_url, slug_pattern = "performance|datasets|publication") {
  links <- scrape_links(index_url)
  if (nrow(links) == 0) return(NULL)
  cand <- links[grepl(slug_pattern, links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(cand) == 0) return(NULL)
  cand[1, "href"]
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x

raw_dest_path <- function(root, source_id, publication_slug, original_name) {
  slug <- gsub("[^a-zA-Z0-9._-]+", "_", publication_slug)
  orig <- gsub("[^a-zA-Z0-9._-]+", "_", original_name)
  file.path(root, "raw", paste0(source_id, "_", slug, "_", orig))
}

append_log <- function(root, message) {
  log_path <- file.path(root, "metadata", "download_log.txt")
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", message, "\n")
  cat(line, file = log_path, append = file.exists(log_path))
}

safe_char <- function(x) {
  x <- as.character(x)
  iconv(x, from = "", to = "UTF-8", sub = "byte")
}

matches_rdy_code <- function(x) {
  toupper(trimws(safe_char(x))) == RDY_CODE
}

matches_rdy_name <- function(x) {
  xv <- safe_char(x)
  if (length(xv) == 0) return(logical(0))
  res <- rep(FALSE, length(xv))
  for (pat in RDY_NAME_PATTERNS) {
    res <- res | grepl(pat, xv, ignore.case = TRUE, fixed = TRUE)
  }
  res
}

find_rdy_in_df <- function(df, max_rows_report = NA) {
  cols <- names(df)
  code_matches <- list()
  name_matches <- list()
  total_code <- 0
  total_name <- 0
  for (col in cols) {
    col_safe <- safe_char(col)
    vals <- safe_char(df[[col]])
    if (is_org_code_column(col_safe)) {
      m <- matches_rdy_code(vals)
      n <- sum(m, na.rm = TRUE)
      if (n > 0) {
        code_matches[[col]] <- n
        total_code <- total_code + n
      }
    }
    if (is_org_name_column(col_safe) || grepl("name|trust|provider|organisation|organization", tolower(col_safe))) {
      m <- matches_rdy_name(vals)
      n <- sum(m, na.rm = TRUE)
      if (n > 0) {
        name_matches[[col]] <- n
        total_name <- total_name + n
      }
    }
  }
  rdy_any <- list()
  for (col in cols) {
    vals <- safe_char(df[[col]])
    m <- grepl("\\bRDY\\b", vals, ignore.case = TRUE)
    n <- sum(m, na.rm = TRUE)
    if (n > 0) rdy_any[[col]] <- n
  }
  list(
    code_matches = code_matches,
    name_matches = name_matches,
    rdy_any = rdy_any,
    total_code_matches = total_code,
    total_name_matches = total_name,
    row_count = nrow(df)
  )
}

sanitize_df_for_export <- function(df) {
  names(df) <- safe_char(names(df))
  df
}

filter_rdy_rows <- function(df) {
  if (nrow(df) == 0) return(df)
  mask <- rep(FALSE, nrow(df))
  cols <- names(df)
  coalesce_mask <- function(m) {
    m[is.na(m)] <- FALSE
    m
  }
  for (col in cols) {
    col_safe <- safe_char(col)
    vals <- safe_char(df[[col]])
    if (is_org_code_column(col_safe)) {
      mask <- mask | coalesce_mask(matches_rdy_code(vals))
    }
    if (is_org_name_column(col_safe) || grepl("name|trust|provider|organisation|organization", tolower(col_safe))) {
      mask <- mask | coalesce_mask(matches_rdy_name(vals))
    }
  }
  if (!any(mask, na.rm = TRUE)) {
    for (col in cols) {
      vals <- safe_char(df[[col]])
      mask <- mask | coalesce_mask(grepl("\\bRDY\\b", vals, ignore.case = TRUE))
    }
  }
  mask[is.na(mask)] <- FALSE
  df[mask, , drop = FALSE]
}

grep_rdy_in_file <- function(file_path, max_bytes = 5e8) {
  if (!file.exists(file_path)) return(list(found = FALSE, count = 0L, method = "file_missing"))
  size <- file.info(file_path)$size
  if (size > max_bytes) {
    # Sample first 50MB
    con <- file(file_path, "r")
    on.exit(close(con), add = TRUE)
    lines <- readLines(con, n = 50000, warn = FALSE)
    txt <- paste(lines, collapse = "\n")
  } else {
    txt <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
  }
  rdy_hits <- gregexpr("\\bRDY\\b", txt, ignore.case = TRUE)[[1]]
  name_hits <- sum(vapply(RDY_NAME_PATTERNS, function(p) {
    length(gregexpr(p, txt, ignore.case = TRUE, fixed = TRUE)[[1]] > 0)
  }, integer(1)))
  count <- if (rdy_hits[1] == -1) 0L else length(rdy_hits)
  list(
    found = count > 0 || name_hits > 0,
    rdy_count = count,
    name_pattern_found = name_hits > 0,
    method = if (size > max_bytes) "sampled_grep" else "full_grep"
  )
}

list_raw_files <- function(root, source_id = NULL) {
  raw_dir <- file.path(root, "raw")
  if (!dir.exists(raw_dir)) return(character())
  files <- list.files(raw_dir, full.names = TRUE, recursive = FALSE)
  files <- files[!grepl("^\\.", basename(files))]
  if (!is.null(source_id)) {
    prefix <- paste0(source_id, "_")
    files <- files[grepl(paste0("^", prefix), basename(files))]
  }
  sort(files)
}

extract_zip_to_temp <- function(zip_path, temp_dir) {
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(zip_path, exdir = temp_dir)
  list.files(temp_dir, full.names = TRUE, recursive = TRUE)
}

write_json_metadata <- function(path, obj) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    writeLines(as.character(jsonlite::toJSON(obj, auto_unbox = TRUE, pretty = TRUE)), path)
  } else {
    jsonlite::write_json(obj, path, auto_unbox = TRUE, pretty = TRUE)
  }
}

init_source_register <- function(root) {
  sources <- data.frame(
    source_id = c(
      "nof_mh_community", "mhsds_monthly", "csds_monthly", "talking_therapies",
      "ae_monthly", "dm01_monthly", "kh03_quarterly", "fft_monthly",
      "ko41a_annual", "eric_annual", "dspt_rdy", "cqc_rdy"
    ),
    source_name = c(
      "NHS Oversight Framework MH/community trust CSVs",
      "MHSDS Monthly Statistics",
      "Community Services Statistics (CSDS)",
      "NHS Talking Therapies Monthly Statistics",
      "A&E Attendances and Emergency Admissions monthly provider files",
      "DM01 Monthly Diagnostics provider files",
      "KH03 Bed Availability and Occupancy files",
      "Friends and Family Test organisation-level tables",
      "KO41a / Data on Written Complaints CSV ZIP",
      "ERIC Estates Return dataset",
      "DSPT Dorset HealthCare public assessment history",
      "CQC Dorset HealthCare provider page (context only)"
    ),
    publisher = c(
      "NHS England", "NHS England Digital", "NHS England Digital",
      "NHS England Digital", "NHS England", "NHS England", "NHS England",
      "NHS England", "NHS England Digital", "NHS England Digital",
      "NHS Digital / DSPT", "CQC"
    ),
    source_url = c(
      "https://www.england.nhs.uk/publication/nhs-oversight-framework-nhs-trust-performance-league-tables-process-and-results/",
      "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics",
      "https://digital.nhs.uk/data-and-information/publications/statistical/community-services-statistics-for-children-young-people-and-adults",
      "https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors",
      "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/",
      "https://www.england.nhs.uk/statistics/statistical-work-areas/diagnostics-waiting-times-and-activity/monthly-diagnostics-waiting-times-and-activity/",
      "https://www.england.nhs.uk/statistics/statistical-work-areas/bed-availability-and-occupancy/bed-data-overnight/",
      "https://www.england.nhs.uk/fft/friends-and-family-test-data/",
      "https://digital.nhs.uk/data-and-information/publications/statistical/data-on-written-complaints-in-the-nhs/2024-25",
      "https://digital.nhs.uk/data-and-information/publications/statistical/estates-returns-information-collection/summary-page-and-dataset-for-eric-2024-25",
      "https://www.dsptoolkit.nhs.uk/OrganisationSearch/RDY",
      "https://www.cqc.org.uk/provider/RDY"
    ),
    file_type = c(
      "CSV", "ZIP/CSV", "ZIP/CSV", "CSV", "CSV/XLS", "ZIP/CSV", "CSV/XLS",
      "XLSX", "ZIP/CSV", "CSV/XLSX", "HTML/CSV", "HTML"
    ),
    publication_period = rep(NA_character_, 12),
    date_range = rep(NA_character_, 12),
    update_frequency = c(
      "Quarterly", "Monthly", "Monthly", "Monthly", "Monthly", "Monthly",
      "Quarterly", "Monthly", "Annual", "Annual", "Annual", "Ad hoc"
    ),
    geographic_granularity = rep("England / NHS regions", 12),
    organisation_granularity = c(
      "Trust", "Provider trust", "Provider trust", "Provider trust",
      "Provider trust", "Provider trust", "Provider trust", "Organisation",
      "Trust", "Trust / site", "Organisation", "Provider"
    ),
    expected_filter_field = c(
      "Trust_code; Trust_name", "ORG_CODE; provider name", "ORG_CODE; PROVIDER",
      "ORG_CODE", "org_code", "Provider Code; ORG_CODE", "ORG_CODE",
      "Organisation Code", "ORG_CODE", "Trust Code; Trust Name", "ODS", "Provider ID RDY"
    ),
    can_filter_to_rdy = c(
      "yes", "yes", "yes", "yes", "unlikely", "yes", "yes", "yes",
      "yes", "yes", "yes", "n/a"
    ),
    contains_dorset_healthcare_rows = rep("unknown", 12),
    download_status = rep("not_attempted_in_this_run", 12),
    recommended_report_use = c(
      "Public performance overview; assurance profile",
      "Mental health access and activity public profile",
      "Community services public profile",
      "NHS Talking Therapies public profile",
      "Urgent care check (likely no RDY rows)",
      "Urgent care / diagnostics public data check",
      "Bed capacity context",
      "Assurance / patient experience profile",
      "Assurance / statutory reporting profile",
      "Assurance / estates profile",
      "Assurance / IG profile",
      "Context only — regulatory background"
    ),
    caveats = c(
      "Quarterly league table metrics; check metric definitions and revisions",
      "Provisional monthly data; large files; VODIM/DQM caveats; possible suppression",
      "Provisional monthly data; data quality file should be reviewed",
      "Provisional monthly IAPT data; employment advisor subset separate",
      "RDY has no ED; may have zero or minimal rows; revised data possible",
      "Provisional monthly; 15 test types; commissioner splits",
      "Quarterly snapshot; specialty coding; wide format",
      "XLSX by setting; response rates vary; small number suppression",
      "Annual HCHS complaints; KO41a only for secondary/community",
      "Annual estates; check amendments file for revisions",
      "Public assessment status only; not operational IG detail",
      "Not statistical data; inspection context only; not an official Trust report"
    ),
    downloaded_file_path = rep(NA_character_, 12),
    processed_file_path = rep(NA_character_, 12),
    download_date = rep(NA_character_, 12),
    source_access_notes = c(
      "Scrape quarterly publication page for MH/community CSV links",
      "Scrape latest performance month page for ZIP/CSV resources",
      "Scrape latest month datasets page",
      "Scrape latest performance month page",
      "Scrape current FY statistics page for monthly CSV",
      "Scrape current FY diagnostics page for provider ZIP",
      "Scrape overnight bed data page for latest quarter CSV",
      "Scrape monthly FFT publication for mental health and community XLSX",
      "Scrape annual 2024-25 page for CSV ZIP",
      "Scrape ERIC 2024-25 summary page for Trust CSV",
      "Parse public org page HTML table",
      "Context note only — no bulk download"
    ),
    stringsAsFactors = FALSE
  )
  write_register(root, sources)
  sources
}
