# =============================================================================
# 04_create_demo_extracts.R
# Create small report-ready demo CSV extracts and PUBLIC_DATA_RUN_SUMMARY.md
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

register <- read_register(root)
if (is.null(register)) stop("Run prior pipeline scripts first.")

processed_dir <- file.path(root, "processed")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

find_processed <- function(source_id, pattern = NULL) {
  files <- list.files(processed_dir, pattern = paste0("^rdy_", source_id), full.names = TRUE)
  if (!is.null(pattern)) {
    files <- files[grepl(pattern, basename(files), ignore.case = TRUE)]
  }
  files
}

read_proc <- function(path, n = 500) {
  if (!file.exists(path)) return(NULL)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, nrows = n)
  if (nrow(df) == 0) return(NULL)
  df
}

subset_cols <- function(df, max_cols = 15) {
  if (is.null(df)) return(NULL)
  if (ncol(df) <= max_cols) return(df)
  keep <- c(
    which(grepl("org|provider|trust|name|code|period|month|year|measure|value|count|rate", names(df), ignore.case = TRUE)),
    seq_len(min(max_cols, ncol(df)))
  )
  keep <- unique(head(keep, max_cols))
  df[, keep, drop = FALSE]
}

demo_written <- character()

write_demo <- function(name, df, source_label) {
  if (is.null(df) || nrow(df) == 0) return(invisible(FALSE))
  df$`_demo_source` <- source_label
  df$`_synthetic` <- FALSE
  path <- file.path(processed_dir, name)
  write.csv(df, path, row.names = FALSE)
  demo_written <<- c(demo_written, path)
  invisible(TRUE)
}

# demo_nof_overview — latest quarter only
nof_files <- find_processed("nof_mh_community", pattern = "-data\\.csv$")
if (length(nof_files) == 0) nof_files <- find_processed("nof_mh_community")
if (length(nof_files) > 0) {
  f <- pick_latest_processed(nof_files, prefer_pattern = "-data\\.csv$")
  df <- read_proc(f, 5000)
  if (!is.null(df)) {
    df <- nof_latest_quarter_rows(df)
    if (nrow(df) > 50) df <- df[seq_len(50), , drop = FALSE]
    write_demo("demo_nof_overview.csv", subset_cols(df, 20), "nof_mh_community")
  }
}

# demo_mhsds_activity — latest main data month (not oldest historic)
mhsds_files <- find_processed("mhsds_monthly")
if (length(mhsds_files) > 0) {
  pref <- mhsds_files[grepl("main_data|MHSDS Data", basename(mhsds_files), ignore.case = TRUE)]
  pref <- pref[!grepl("time_series|data_quality|out_of_area", basename(pref), ignore.case = TRUE)]
  f <- if (length(pref) > 0) pick_latest_processed(pref) else pick_latest_processed(mhsds_files)
  df <- read_proc(f, 200)
  write_demo("demo_mhsds_activity.csv", subset_cols(df, 15), "mhsds_monthly")
}

# demo_csds_activity — latest month core data
csds_files <- find_processed("csds_monthly")
if (length(csds_files) > 0) {
  pref <- csds_files[grepl("core-data|exp-core", basename(csds_files), ignore.case = TRUE)]
  pref <- pref[!grepl("data_quality", basename(pref), ignore.case = TRUE)]
  f <- if (length(pref) > 0) pick_latest_processed(pref) else pick_latest_processed(csds_files)
  df <- read_proc(f, 200)
  write_demo("demo_csds_activity.csv", subset_cols(df, 15), "csds_monthly")
}

# demo_talking_therapies — latest activity month (not time series)
tt_files <- find_processed("talking_therapies")
if (length(tt_files) > 0) {
  pref <- tt_files[grepl("activity", basename(tt_files), ignore.case = TRUE)]
  pref <- pref[!grepl("time_series|data_quality", basename(pref), ignore.case = TRUE)]
  f <- if (length(pref) > 0) pick_latest_processed(pref) else pick_latest_processed(tt_files)
  df <- read_proc(f, 200)
  write_demo("demo_talking_therapies.csv", subset_cols(df, 15), "talking_therapies")
}

# demo_kh03_beds — prefer latest snapshot from historic pipeline
latest_kh03 <- file.path(processed_dir, "latest_kh03_beds_rdy.csv")
kh03_files <- find_processed("kh03_quarterly")
if (file.exists(latest_kh03)) {
  df <- read_proc(latest_kh03, 50)
  write_demo("demo_kh03_beds.csv", subset_cols(df, 20), "kh03_quarterly")
} else if (length(kh03_files) > 0) {
  f <- pick_latest_processed(kh03_files)
  df <- read_proc(f, 50)
  write_demo("demo_kh03_beds.csv", subset_cols(df, 20), "kh03_quarterly")
}

# demo_dm01_diagnostics — latest month full extract
dm01_files <- find_processed("dm01_monthly")
if (length(dm01_files) > 0) {
  pref <- dm01_files[grepl("full-extract|DM01-", basename(dm01_files), ignore.case = TRUE)]
  f <- if (length(pref) > 0) pick_latest_processed(pref) else pick_latest_processed(dm01_files)
  df <- read_proc(f, 200)
  write_demo("demo_dm01_diagnostics.csv", subset_cols(df, 15), "dm01_monthly")
}

# demo_assurance_profile — combine KO41a, ERIC, DSPT, FFT snippets
assurance_rows <- list()
add_assurance <- function(source_id, label, files) {
  if (length(files) == 0) return()
  f <- pick_latest_processed(files)
  df <- read_proc(f, 20)
  if (is.null(df) || nrow(df) == 0) return()
  assurance_rows[[length(assurance_rows) + 1]] <<- data.frame(
    source = source_id,
    label = label,
    rdy_rows = nrow(df),
    columns = paste(head(names(df), 8), collapse = "; "),
    stringsAsFactors = FALSE
  )
}
add_assurance("ko41a_annual", "Written complaints (KO41a)", find_processed("ko41a_annual"))
add_assurance("eric_annual", "ERIC estates", find_processed("eric_annual"))
add_assurance("dspt_rdy", "DSPT assessment history", find_processed("dspt_rdy"))
add_assurance("fft_monthly", "FFT mental health/community", find_processed("fft_monthly"))

if (length(assurance_rows) > 0) {
  assurance_df <- do.call(rbind, assurance_rows)
  assurance_df$`_demo_source` <- "assurance_combined"
  assurance_df$`_synthetic` <- FALSE
  write.csv(assurance_df, file.path(processed_dir, "demo_assurance_profile.csv"), row.names = FALSE)
  demo_written <- c(demo_written, file.path(processed_dir, "demo_assurance_profile.csv"))
}

# Synthetic placeholder for A&E where RDY unlikely
ae_has_rdy <- length(find_processed("ae_monthly")) > 0
if (!ae_has_rdy) {
  placeholder <- data.frame(
    source = "ae_monthly",
    note = "No RDY rows found in public A&E provider file (expected — Dorset HealthCare has no ED)",
    `_synthetic` = TRUE,
    `_demo_source` = "synthetic_placeholder",
    stringsAsFactors = FALSE
  )
  write.csv(placeholder, file.path(processed_dir, "synthetic_demo_ae_placeholder.csv"), row.names = FALSE)
  demo_written <- c(demo_written, file.path(processed_dir, "synthetic_demo_ae_placeholder.csv"))
}

# --- Generate PUBLIC_DATA_RUN_SUMMARY.md ---
register <- read_register(root)

downloaded <- register$download_status %in% c("downloaded", "checked_no_rdy_rows")
manual <- register$download_status == "manual_download_needed"
failed <- register$download_status == "download_failed"
context <- register$download_status == "context_only"

best_for_reports <- register[
  register$contains_dorset_healthcare_rows == "yes" &
    register$download_status %in% c("downloaded", "checked_no_rdy_rows"),
  c("source_id", "source_name", "recommended_report_use"),
  drop = FALSE
]

summary_lines <- c(
  "# Public Data Run Summary",
  "",
  paste("**Generated:**", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "> **DISCLAIMER:** These are public-data demonstration outputs. They are NOT official Dorset HealthCare reports.",
  "> All figures require human review and local owner confirmation before operational use.",
  "> Check publication dates, provisional data, suppression, rounding and revisions before interpretation.",
  "",
  "## Download outcomes",
  "",
  sprintf("- Successfully downloaded or checked: **%d** sources", sum(downloaded, na.rm = TRUE)),
  sprintf("- Manual download needed: **%d** sources", sum(manual, na.rm = TRUE)),
  sprintf("- Download failed: **%d** sources", sum(failed, na.rm = TRUE)),
  sprintf("- Context only: **%d** sources", sum(context, na.rm = TRUE)),
  "",
  "| source_id | download_status | contains_dorset_healthcare_rows | publication_period |",
  "|-----------|-----------------|--------------------------------|-------------------|"
)

for (i in seq_len(nrow(register))) {
  summary_lines <- c(summary_lines, sprintf(
    "| %s | %s | %s | %s |",
    register$source_id[i],
    register$download_status[i],
    register$contains_dorset_healthcare_rows[i],
    register$publication_period[i]
  ))
}

summary_lines <- c(summary_lines,
  "",
  "## Dorset HealthCare / RDY presence",
  "",
  "Sources with confirmed RDY rows are prioritised for demo reports.",
  "Sources marked `checked_no_rdy_rows` were inspected but contained no matching organisation rows.",
  "",
  paste0("- RDY rows found: **", sum(register$contains_dorset_healthcare_rows == "yes", na.rm = TRUE), "** sources"),
  paste0("- No RDY rows: **", sum(register$contains_dorset_healthcare_rows == "no", na.rm = TRUE), "** sources"),
  "",
  "## Best sources for first website reports",
  ""
)

if (nrow(best_for_reports) > 0) {
  for (i in seq_len(nrow(best_for_reports))) {
    summary_lines <- c(summary_lines, sprintf(
      "- **%s** (%s): %s",
      best_for_reports$source_id[i],
      best_for_reports$source_name[i],
      best_for_reports$recommended_report_use[i]
    ))
  }
} else {
  summary_lines <- c(summary_lines, "- No RDY-containing sources available in this run — review download log.")
}

manual_sources <- register[manual, , drop = FALSE]
summary_lines <- c(summary_lines,
  "",
  "## Manual download needed",
  ""
)
if (nrow(manual_sources) > 0) {
  for (i in seq_len(nrow(manual_sources))) {
    summary_lines <- c(summary_lines, sprintf(
      "- **%s**: %s — %s",
      manual_sources$source_id[i],
      manual_sources$source_url[i],
      manual_sources$source_access_notes[i]
    ))
  }
} else {
  summary_lines <- c(summary_lines, "- None in this run.")
}

summary_lines <- c(summary_lines,
  "",
  "## Caveats observed",
  "",
  "- Monthly MHSDS, CSDS and Talking Therapies data are typically **provisional** until end-of-year refresh.",
  "- National publications may apply **suppression and rounding**; small numbers may be masked.",
  "- A&E provider statistics may not include RDY (no emergency department).",
  "- FFT uses organisation-level XLSX tables with variable response rates.",
  "- ERIC and KO41a are **annual** snapshots; check amendments/revisions on publication pages.",
  "- DSPT public page shows assessment status only — not operational IG detail.",
  "- CQC provider page is **context only** — not statistical performance data.",
  "",
  "## Demo extracts created",
  ""
)

if (length(demo_written) > 0) {
  for (f in demo_written) {
    summary_lines <- c(summary_lines, paste("-", basename(f)))
  }
} else {
  summary_lines <- c(summary_lines, "- No demo extracts created (no RDY processed files).")
}

summary_lines <- c(summary_lines,
  "",
  "## Run commands",
  "",
  "```bash",
  "cd site/public-data",
  "Rscript 01_download_public_data.R",
  "Rscript 02_inspect_public_data.R",
  "Rscript 03_filter_dorset_healthcare.R",
  "Rscript 05_download_historic_public_data.R",
  "Rscript 04_create_demo_extracts.R",
  "Rscript ../R/03_render_public_reports.R",
  "```"
)

writeLines(summary_lines, file.path(root, "PUBLIC_DATA_RUN_SUMMARY.md"))
cat("Demo extracts:", length(demo_written), "\n")
cat("Summary written to PUBLIC_DATA_RUN_SUMMARY.md\n")
