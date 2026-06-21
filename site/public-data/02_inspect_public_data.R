# =============================================================================
# 02_inspect_public_data.R
# Inspect downloaded public files; record structure and RDY presence.
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
ensure_packages(c("jsonlite", "readxl"), root = root)

register <- read_register(root)
if (is.null(register)) stop("Run 01_download_public_data.R first.")

inspect_csv <- function(path, max_rows = 50000) {
  info <- list(file = basename(path), type = "csv", size_bytes = file.info(path)$size)
  con <- file(path, "r")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1, warn = FALSE)
  cols <- strsplit(header, ",")[[1]]
  cols <- gsub('^"|"$', "", cols)
  info$columns <- cols
  # Count lines approximately
  n_lines <- length(readLines(path, warn = FALSE))
  info$row_count <- max(0L, n_lines - 1L)
  info$row_count_note <- if (info$row_count > max_rows) "full count; large file" else "full count"
  # Sample for RDY search
  if (info$size_bytes > 50e6) {
    sample_df <- utils::read.csv(path, nrows = 5000, stringsAsFactors = FALSE, check.names = FALSE)
    grep_res <- grep_rdy_in_file(path)
    rdy <- find_rdy_in_df(sample_df)
    rdy$search_method <- "sample_5000_rows_plus_grep"
    rdy$grep <- grep_res
  } else {
    df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, nrows = max_rows)
    rdy <- find_rdy_in_df(df)
    rdy$search_method <- if (info$row_count > max_rows) "first_n_rows" else "full_file"
    if (rdy$total_code_matches == 0 && rdy$total_name_matches == 0) {
      grep_res <- grep_rdy_in_file(path)
      rdy$grep <- grep_res
    }
  }
  info$rdy_search <- rdy
  info
}

inspect_xlsx <- function(path) {
  info <- list(file = basename(path), type = "xlsx", size_bytes = file.info(path)$size)
  sheets <- readxl::excel_sheets(path)
  info$sheets <- sheets
  sheet_info <- list()
  best_rdy <- list(total_code_matches = 0, total_name_matches = 0)
  for (sh in sheets) {
    df <- as.data.frame(readxl::read_excel(path, sheet = sh, n_max = 10000))
    rdy <- find_rdy_in_df(df)
    sheet_info[[sh]] <- list(
      row_count_sample = nrow(df),
      columns = names(df),
      rdy = rdy
    )
    if (rdy$total_code_matches + rdy$total_name_matches >
        best_rdy$total_code_matches + best_rdy$total_name_matches) {
      best_rdy <- rdy
    }
  }
  info$sheet_info <- sheet_info
  info$rdy_search <- best_rdy
  info
}

inspect_zip <- function(path) {
  info <- list(file = basename(path), type = "zip", size_bytes = file.info(path)$size, contents = list())
  tmp <- file.path(root, "metadata", paste0("tmp_", gsub("[^a-zA-Z0-9]", "_", basename(path))))
  extracted <- tryCatch(extract_zip_to_temp(path, tmp), error = function(e) character())
  for (f in extracted) {
    ext <- tolower(tools::file_ext(f))
    if (ext == "csv") {
      info$contents[[basename(f)]] <- inspect_csv(f)
    } else if (ext %in% c("xlsx", "xls")) {
      info$contents[[basename(f)]] <- inspect_xlsx(f)
    } else {
      info$contents[[basename(f)]] <- list(file = basename(f), type = ext, note = "not inspected")
    }
  }
  unlink(tmp, recursive = TRUE, force = TRUE)
  # Aggregate RDY signal
  any_rdy <- FALSE
  for (c in info$contents) {
    if (!is.null(c$rdy_search)) {
      if (c$rdy_search$total_code_matches + c$rdy_search$total_name_matches > 0) any_rdy <- TRUE
      if (!is.null(c$rdy_search$grep) && isTRUE(c$rdy_search$grep$found)) any_rdy <- TRUE
    }
  }
  info$any_rdy_signal <- any_rdy
  info
}

summarise_rdy <- function(inspection) {
  if (!is.null(inspection$rdy_search)) {
    rs <- inspection$rdy_search
    if (rs$total_code_matches + rs$total_name_matches > 0) return("yes")
    if (!is.null(rs$grep) && isTRUE(rs$grep$found)) return("yes")
  }
  if (!is.null(inspection$any_rdy_signal) && inspection$any_rdy_signal) return("yes")
  if (!is.null(inspection$contents)) {
    for (c in inspection$contents) {
      s <- summarise_rdy(c)
      if (s == "yes") return("yes")
    }
  }
  "no"
}

write_inspection_txt <- function(path, source_id, inspections) {
  lines <- c(
    paste("Inspection report:", source_id),
    paste("Generated:", Sys.time()),
    paste("Files inspected:", length(inspections)),
    ""
  )
  for (nm in names(inspections)) {
    ins <- inspections[[nm]]
    lines <- c(lines, paste("---", nm, "---"), paste("Type:", ins$type %||% "?"))
    if (!is.null(ins$columns)) lines <- c(lines, paste("Columns:", paste(head(ins$columns, 20), collapse = "; ")))
    if (!is.null(ins$row_count)) lines <- c(lines, paste("Row count:", ins$row_count))
    if (!is.null(ins$sheets)) lines <- c(lines, paste("Sheets:", paste(ins$sheets, collapse = ", ")))
    rdy <- summarise_rdy(ins)
    lines <- c(lines, paste("RDY signal:", rdy), "")
  }
  writeLines(lines, path)
}

for (i in seq_len(nrow(register))) {
  sid <- register$source_id[i]
  if (sid == "cqc_rdy") {
    update_register_row(root, sid, list(contains_dorset_healthcare_rows = "n/a"))
    next
  }
  files <- list_raw_files(root, sid)
  if (length(files) == 0) {
    append_log(root, paste("inspect:", sid, "- no raw files"))
    next
  }
  inspections <- list()
  for (f in files) {
    ext <- tolower(tools::file_ext(f))
    key <- basename(f)
    inspections[[key]] <- tryCatch({
      if (ext == "csv") inspect_csv(f)
      else if (ext == "zip") inspect_zip(f)
      else if (ext %in% c("xlsx", "xls")) inspect_xlsx(f)
      else list(file = key, type = ext, note = "unsupported type")
    }, error = function(e) {
      list(file = key, error = conditionMessage(e))
    })
  }
  json_path <- file.path(root, "metadata", paste0("inspection_", sid, ".json"))
  txt_path <- file.path(root, "metadata", paste0("inspection_", sid, ".txt"))
  jsonlite::write_json(inspections, json_path, auto_unbox = TRUE, pretty = TRUE)
  write_inspection_txt(txt_path, sid, inspections)
  rdy_present <- "no"
  for (ins in inspections) {
    if (summarise_rdy(ins) == "yes") {
      rdy_present <- "yes"
      break
    }
  }
  observed_cols <- character()
  for (ins in inspections) {
    if (!is.null(ins$columns)) observed_cols <- c(observed_cols, ins$columns)
    if (!is.null(ins$contents)) {
      for (c in ins$contents) {
        if (!is.null(c$columns)) observed_cols <- c(observed_cols, c$columns)
      }
    }
  }
  org_cols <- observed_cols[grepl("org|provider|trust|ods", observed_cols, ignore.case = TRUE)]
  update_register_row(root, sid, list(
    contains_dorset_healthcare_rows = rdy_present,
    expected_filter_field = if (length(org_cols) > 0) paste(unique(head(org_cols, 5)), collapse = "; ") else register$expected_filter_field[i]
  ))
  cat("Inspected:", sid, "- RDY:", rdy_present, "\n")
}

cat("Inspection complete. Metadata in:", file.path(root, "metadata"), "\n")
