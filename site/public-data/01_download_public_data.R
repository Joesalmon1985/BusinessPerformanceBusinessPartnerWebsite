# =============================================================================
# 01_download_public_data.R
# Download public NHS aggregate datasets for Dorset HealthCare (RDY) demo.
# Public aggregate data only — no patient-identifiable information.
# Does not hard-fail if individual sources cannot be downloaded.
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

ensure_dirs(root)
ensure_packages(c("rvest", "readxl", "jsonlite"), root = root)

if (!file.exists(register_path(root))) {
  init_source_register(root)
}
append_log(root, "=== Download run started ===")

download_date <- format(Sys.Date(), "%Y-%m-%d")

download_source_files <- function(source_id, slug, urls_and_names, page_url = NA) {
  paths <- character()
  ok_count <- 0
  fail_msgs <- character()
  for (item in urls_and_names) {
    url <- item$url
    name <- item$name
    dest <- raw_dest_path(root, source_id, slug, name)
    res <- safe_download(url, dest)
    if (res$ok) {
      paths <- c(paths, dest)
      ok_count <- ok_count + 1
      append_log(root, paste(source_id, "OK:", basename(dest), "-", res$message))
    } else {
      fail_msgs <- c(fail_msgs, paste(name, ":", res$message))
      append_log(root, paste(source_id, "FAIL:", name, "-", res$message))
    }
  }
  list(paths = paths, ok = ok_count, fails = fail_msgs)
}

update_after_download <- function(source_id, status, paths = character(), period = NA,
                                  access_note = NA, url = NA) {
  fields <- list(
    download_status = status,
    download_date = download_date,
    downloaded_file_path = if (length(paths) > 0) paste(paths, collapse = "; ") else NA_character_
  )
  if (!is.na(period)) fields$publication_period <- period
  if (!is.na(access_note)) fields$source_access_notes <- access_note
  if (!is.na(url)) fields$source_url <- url
  update_register_row(root, source_id, fields)
}

# --- 1. NHS Oversight Framework ---
tryCatch({
  page <- "https://www.england.nhs.uk/long-read/nhs-oversight-framework-csv-metadata-file/"
  links <- scrape_links(page, pattern = "mental-health-and-community-trust")
  links <- links[grepl("\\.csv", links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(links) == 0) stop("No NOF CSV links found on metadata page")
  items <- lapply(seq_len(nrow(links)), function(i) {
    list(url = links$href[i], name = basename(links$href[i]))
  })
  res <- download_source_files("nof_mh_community", "q4_2025_26", items, page)
  status <- if (res$ok > 0) "downloaded" else "download_failed"
  if (res$ok == 0) status <- "manual_download_needed"
  update_after_download("nof_mh_community", status, res$paths, "Q4 2025/26", page)
}, error = function(e) {
  append_log(root, paste("nof_mh_community ERROR:", conditionMessage(e)))
  update_after_download("nof_mh_community", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 2. MHSDS Monthly ---
tryCatch({
  index <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"
  pub_page <- find_publication_page(index, "performance-[a-z]+-[0-9]{4}|/[a-z]+-[0-9]{4}$")
  if (is.null(pub_page)) {
    links <- scrape_links(index, pattern = "performance")
    pub_page <- links$href[1]
  }
  if (is.na(pub_page) || !nzchar(pub_page)) stop("Could not find latest MHSDS publication page")
  slug <- gsub(".*/", "", pub_page)
  all_links <- scrape_links(pub_page)
  patterns <- list(
    list(pat = "MHSDS Data File|Main.*Data.*File|Data File.*ZIP", name = "main_data.zip"),
    list(pat = "Time Series|time-series|timeseries", name = "time_series.zip"),
    list(pat = "Data Coverage|coverage", name = "data_coverage.csv"),
    list(pat = "VODIM|Integrity|integrity|Data Quality", name = "data_quality.csv"),
    list(pat = "Out of Area|out-of-area|OAP", name = "out_of_area.zip")
  )
  items <- list()
  for (p in patterns) {
    m <- all_links[grepl(p$pat, all_links$text, ignore.case = TRUE) |
      grepl(p$pat, all_links$href, ignore.case = TRUE), , drop = FALSE]
    m <- m[grepl("\\.(csv|zip|xlsx)", m$href, ignore.case = TRUE), , drop = FALSE]
    if (nrow(m) > 0) items[[length(items) + 1]] <- list(url = m$href[1], name = p$name)
  }
  if (length(items) == 0) stop("No MHSDS resource links found")
  res <- download_source_files("mhsds_monthly", slug, items, pub_page)
  status <- if (res$ok >= 1) "downloaded" else "download_failed"
  if (res$ok == 0) status <- "manual_download_needed"
  update_after_download("mhsds_monthly", status, res$paths, slug, pub_page)
}, error = function(e) {
  append_log(root, paste("mhsds_monthly ERROR:", conditionMessage(e)))
  update_after_download("mhsds_monthly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 3. CSDS ---
tryCatch({
  index <- "https://digital.nhs.uk/data-and-information/publications/statistical/community-services-statistics-for-children-young-people-and-adults"
  links <- scrape_links(index)
  month_links <- links[grepl("/community-services-statistics-for-children-young-people-and-adults/[a-z]+-[0-9]{4}$",
    links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(month_links) == 0) stop("Could not find CSDS month publication links")
  pub_page <- paste0(month_links$href[1], "/datasets")
  slug <- gsub(".*/", "", month_links$href[1])
  all_links <- scrape_links(pub_page)
  items <- list()
  for (p in list(
    list(pat = "core-data|csds.*\\.zip|CSV Data", name = "csds_data.zip"),
    list(pat = "dq\\.csv|Data Quality|exp-dq", name = "data_quality.csv"),
    list(pat = "metadata|exp-metadata", name = "metadata.xlsx")
  )) {
    m <- all_links[grepl(p$pat, all_links$text, ignore.case = TRUE) |
      grepl(p$pat, all_links$href, ignore.case = TRUE), , drop = FALSE]
    m <- m[grepl("\\.(csv|zip|xls|xlsx)", m$href, ignore.case = TRUE), , drop = FALSE]
    if (nrow(m) > 0) items[[length(items) + 1]] <- list(url = m$href[1], name = p$name)
  }
  if (length(items) == 0) stop("No CSDS resource links found")
  res <- download_source_files("csds_monthly", slug, items, pub_page)
  status <- if (res$ok >= 1) "downloaded" else "manual_download_needed"
  update_after_download("csds_monthly", status, res$paths, slug, pub_page)
}, error = function(e) {
  append_log(root, paste("csds_monthly ERROR:", conditionMessage(e)))
  update_after_download("csds_monthly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 4. Talking Therapies ---
tryCatch({
  index <- "https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors"
  pub_page <- find_publication_page(index, "performance")
  if (is.null(pub_page)) {
    links <- scrape_links(index, pattern = "performance")
    pub_page <- links$href[1]
  }
  slug <- gsub(".*/", "", pub_page)
  all_links <- scrape_links(pub_page)
  items <- list()
  for (p in list(
    list(pat = "Activity Data|Monthly Activity", name = "activity.csv"),
    list(pat = "Data Quality|DQR|Quality Report", name = "data_quality.csv"),
    list(pat = "Time Series|time series", name = "time_series.csv")
  )) {
    m <- all_links[grepl(p$pat, all_links$text, ignore.case = TRUE), , drop = FALSE]
    m <- m[grepl("\\.csv", m$href, ignore.case = TRUE), , drop = FALSE]
    if (nrow(m) > 0) items[[length(items) + 1]] <- list(url = m$href[1], name = p$name)
  }
  if (length(items) == 0) stop("No Talking Therapies links found")
  res <- download_source_files("talking_therapies", slug, items, pub_page)
  status <- if (res$ok >= 1) "downloaded" else "manual_download_needed"
  update_after_download("talking_therapies", status, res$paths, slug, pub_page)
}, error = function(e) {
  append_log(root, paste("talking_therapies ERROR:", conditionMessage(e)))
  update_after_download("talking_therapies", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 5. A&E ---
tryCatch({
  index <- "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/"
  fy_links <- scrape_links(index, pattern = "ae-attendances-and-emergency-admissions-20")
  if (nrow(fy_links) == 0) stop("No A&E FY page found")
  fy_page <- fy_links$href[1]
  csv_links <- scrape_links(fy_page, extensions = c("csv"))
  csv_links <- csv_links[grepl("Monthly A|E|attendance", csv_links$text, ignore.case = TRUE) |
    grepl("Monthly.*\\.csv", csv_links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(csv_links) == 0) {
    csv_links <- scrape_links(fy_page, extensions = c("csv"))
  }
  if (nrow(csv_links) == 0) stop("No A&E CSV found")
  slug <- gsub(".*/", "", fy_page)
  items <- list(list(url = csv_links$href[1], name = basename(csv_links$href[1])))
  res <- download_source_files("ae_monthly", slug, items, fy_page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("ae_monthly", status, res$paths, basename(csv_links$href[1]), fy_page)
}, error = function(e) {
  append_log(root, paste("ae_monthly ERROR:", conditionMessage(e)))
  update_after_download("ae_monthly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 6. DM01 ---
tryCatch({
  index <- "https://www.england.nhs.uk/statistics/statistical-work-areas/diagnostics-waiting-times-and-activity/monthly-diagnostics-waiting-times-and-activity/"
  fy_links <- scrape_links(index, pattern = "monthly-diagnostics-data-20")
  fy_links <- fy_links[grepl("2026-27|2025-26", fy_links$href), , drop = FALSE]
  if (nrow(fy_links) == 0) stop("No DM01 FY page found")
  fy_page <- fy_links$href[1]
  zip_links <- scrape_links(fy_page)
  zip_links <- zip_links[grepl("\\.zip", zip_links$href, ignore.case = TRUE), , drop = FALSE]
  zip_links <- zip_links[grepl("DM01|extract|Extract|CSV", zip_links$href, ignore.case = TRUE) |
    grepl("DM01|extract|Extract|CSV", zip_links$text, ignore.case = TRUE), , drop = FALSE]
  if (nrow(zip_links) == 0) stop("No DM01 ZIP found")
  slug <- gsub(".*/", "", fy_page)
  items <- list(list(url = zip_links$href[1], name = basename(zip_links$href[1])))
  res <- download_source_files("dm01_monthly", slug, items, fy_page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("dm01_monthly", status, res$paths, slug, fy_page)
}, error = function(e) {
  append_log(root, paste("dm01_monthly ERROR:", conditionMessage(e)))
  update_after_download("dm01_monthly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 7. KH03 ---
tryCatch({
  page <- "https://www.england.nhs.uk/statistics/statistical-work-areas/bed-availability-and-occupancy/bed-data-overnight/"
  csv_links <- scrape_links(page, extensions = c("csv"))
  csv_links <- csv_links[grepl("Available|Occupied|KH03|bed", csv_links$text, ignore.case = TRUE) |
    grepl("bed|available|occupied", csv_links$href, ignore.case = TRUE), , drop = FALSE]
  if (nrow(csv_links) == 0) {
    csv_links <- scrape_links(page, extensions = c("csv"))
  }
  if (nrow(csv_links) == 0) stop("No KH03 CSV links found")
  slug <- "latest_quarter"
  items <- lapply(seq_len(min(3, nrow(csv_links))), function(i) {
    list(url = csv_links$href[i], name = basename(csv_links$href[i]))
  })
  res <- download_source_files("kh03_quarterly", slug, items, page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("kh03_quarterly", status, res$paths, "Latest quarter on overnight page", page)
}, error = function(e) {
  append_log(root, paste("kh03_quarterly ERROR:", conditionMessage(e)))
  update_after_download("kh03_quarterly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 8. FFT ---
tryCatch({
  index <- "https://www.england.nhs.uk/fft/friends-and-family-test-data/"
  pub_links <- scrape_links(index, pattern = "friends-and-family-test-data-[a-z]+-[0-9]{4}")
  if (nrow(pub_links) == 0) {
    pub_links <- scrape_links(index, pattern = "publication/friends-and-family")
  }
  if (nrow(pub_links) == 0) stop("No FFT publication page found")
  pub_page <- pub_links$href[1]
  slug <- gsub(".*/", "", pub_page)
  all_links <- scrape_links(pub_page)
  xlsx_links <- all_links[grepl("\\.xlsx", all_links$href, ignore.case = TRUE), , drop = FALSE]
  xlsx_links <- unique(xlsx_links$href)
  if (length(xlsx_links) == 0) stop("No FFT XLSX links found")
  items <- lapply(seq_along(xlsx_links), function(i) {
    list(url = xlsx_links[i], name = basename(xlsx_links[i]))
  })
  res <- download_source_files("fft_monthly", slug, items, pub_page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("fft_monthly", status, res$paths, slug, pub_page)
}, error = function(e) {
  append_log(root, paste("fft_monthly ERROR:", conditionMessage(e)))
  update_after_download("fft_monthly", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 9. KO41a ---
tryCatch({
  page <- "https://digital.nhs.uk/data-and-information/publications/statistical/data-on-written-complaints-in-the-nhs/2024-25"
  zip_link <- find_best_link(page, c("CSV zip|CSV ZIP|Written Complaints.*zip|KO41"))
  if (is.null(zip_link)) stop("No KO41a ZIP link found")
  items <- list(list(url = zip_link$href, name = "ko41a_2024_25.zip"))
  res <- download_source_files("ko41a_annual", "2024_25", items, page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("ko41a_annual", status, res$paths, "2024-25", page)
}, error = function(e) {
  append_log(root, paste("ko41a_annual ERROR:", conditionMessage(e)))
  update_after_download("ko41a_annual", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 10. ERIC ---
tryCatch({
  page <- "https://digital.nhs.uk/data-and-information/publications/statistical/estates-returns-information-collection/summary-page-and-dataset-for-eric-2024-25"
  trust_link <- find_best_link(page, c("Trust.*CSV|ERIC.*Trust|Trust level"))
  if (is.null(trust_link)) {
    links <- scrape_links(page, extensions = c("csv"))
    trust_link <- links[grepl("trust", links$text, ignore.case = TRUE) |
      grepl("trust", links$href, ignore.case = TRUE), , drop = FALSE]
    if (nrow(trust_link) > 0) trust_link <- trust_link[1, , drop = FALSE]
  }
  if (is.null(trust_link) || nrow(trust_link) == 0) stop("No ERIC Trust CSV found")
  items <- list(list(url = trust_link$href, name = basename(trust_link$href)))
  res <- download_source_files("eric_annual", "2024_25", items, page)
  status <- if (res$ok > 0) "downloaded" else "manual_download_needed"
  update_after_download("eric_annual", status, res$paths, "2024/25", page)
}, error = function(e) {
  append_log(root, paste("eric_annual ERROR:", conditionMessage(e)))
  update_after_download("eric_annual", "manual_download_needed",
    access_note = paste("Scrape failed:", conditionMessage(e)))
})

# --- 11. DSPT ---
tryCatch({
  page <- "https://www.dsptoolkit.nhs.uk/OrganisationSearch/RDY"
  dest <- raw_dest_path(root, "dspt_rdy", "public", "dspt_rdy_assessment_history.csv")
  html <- tryCatch(fetch_html(page), error = function(e) NULL)
  if (is.null(html)) stop("Could not fetch DSPT org page")
  tables <- rvest::html_table(html, fill = TRUE)
  if (length(tables) == 0) stop("No tables on DSPT page")
  # Use largest table with assessment-like columns
  best <- tables[[1]]
  for (tb in tables) {
    if (nrow(tb) > nrow(best)) best <- tb
  }
  if (!file.exists(dest)) {
    write.csv(best, dest, row.names = FALSE)
    append_log(root, paste("dspt_rdy OK: parsed HTML table to", basename(dest)))
  }
  update_after_download("dspt_rdy", "downloaded", dest, "Public assessment history", page)
}, error = function(e) {
  append_log(root, paste("dspt_rdy ERROR:", conditionMessage(e)))
  update_after_download("dspt_rdy", "manual_download_needed",
    access_note = paste("HTML parse failed:", conditionMessage(e)))
})

# --- 12. CQC context only ---
tryCatch({
  page <- "https://www.cqc.org.uk/provider/RDY"
  note_path <- file.path(root, "metadata", "cqc_rdy_context_note.txt")
  html <- tryCatch(fetch_html(page), error = function(e) NULL)
  title <- if (!is.null(html)) rvest::html_text2(rvest::html_element(html, "h1")) else "Dorset HealthCare (RDY)"
  note <- c(
    "CQC Dorset HealthCare provider page — CONTEXT ONLY",
    "================================================",
    "",
    "DISCLAIMER: This is a public-data demonstration note. It is NOT an official Dorset HealthCare report.",
    "Outputs require human review and local owner confirmation before operational use.",
    "",
    paste("URL:", page),
    paste("Page title:", title),
    paste("Captured:", download_date),
    "",
    "This source provides regulatory context (ratings, regulated activities, inspection links).",
    "It is not a statistical aggregate dataset and was not bulk-downloaded.",
    "Do not scrape or infer confidential service-sensitive information.",
    "",
    "Provider ID: RDY",
    "Organisation: Dorset HealthCare University NHS Foundation Trust"
  )
  writeLines(note, note_path)
  update_register_row(root, "cqc_rdy", list(
    download_status = "context_only",
    download_date = download_date,
    downloaded_file_path = note_path,
    contains_dorset_healthcare_rows = "n/a",
    source_access_notes = "Context note written to metadata/cqc_rdy_context_note.txt"
  ))
  append_log(root, "cqc_rdy: context note written")
}, error = function(e) {
  append_log(root, paste("cqc_rdy ERROR:", conditionMessage(e)))
  update_after_download("cqc_rdy", "context_only",
    access_note = paste("Context note failed:", conditionMessage(e)))
})

append_log(root, "=== Download run completed ===")
cat("Download run completed. See metadata/download_log.txt and DATA_SOURCE_REGISTER.csv\n")
cat("Raw files in:", file.path(root, "raw"), "\n")
