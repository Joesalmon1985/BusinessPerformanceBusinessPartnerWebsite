# =============================================================================
# 03_filter_dorset_healthcare.R
# Create Dorset HealthCare (RDY) extracts from inspected public data.
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
ensure_packages(c("readxl"), root = root)

register <- read_register(root)
if (is.null(register)) stop("Run 01_download_public_data.R first.")

read_tabular <- function(path, max_rows = Inf) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    if (nrow(df) == 0) {
      df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "latin1")
    }
    if (is.finite(max_rows) && nrow(df) > max_rows) {
      df <- df[seq_len(max_rows), , drop = FALSE]
    }
    df
  } else if (ext %in% c("xlsx", "xls")) {
    n_max <- if (is.finite(max_rows)) as.integer(max_rows) else NULL
    as.data.frame(readxl::read_excel(path, n_max = n_max))
  } else {
    NULL
  }
}

filter_and_save <- function(df, source_id, file_stub, register_row) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  filtered <- filter_rdy_rows(df)
  note_lines <- c(
    paste("Filter note:", source_id, "-", file_stub),
    paste("Generated:", Sys.time()),
    paste("Publication period:", register_row$publication_period),
    "",
    paste("Input rows:", nrow(df)),
    paste("RDY matching rows:", nrow(filtered)),
    ""
  )
  if (nrow(filtered) == 0) {
    note_lines <- c(note_lines,
      "No Dorset HealthCare / RDY rows found in this file.",
      "The source was checked using case-insensitive RDY code and trust name variants.",
      "",
      paste("Caveats:", register_row$caveats),
      "",
      "DISCLAIMER: Public-data demonstration output. Not an official Dorset HealthCare report.",
      "Requires human review and local owner confirmation."
    )
    writeLines(note_lines, file.path(root, "metadata", paste0("filter_note_", source_id, ".txt")))
    return(NULL)
  }
  dest <- file.path(root, "processed", paste0("rdy_", source_id, "_", file_stub, ".csv"))
  write.csv(sanitize_df_for_export(filtered), dest, row.names = FALSE)
  note_lines <- c(note_lines,
    paste("Output:", dest),
    paste("Columns:", paste(names(filtered), collapse = "; ")),
    "",
    paste("Caveats:", register_row$caveats),
    "",
    "DISCLAIMER: Public-data demonstration output. Not an official Dorset HealthCare report.",
    "Requires human review and local owner confirmation."
  )
  writeLines(note_lines, file.path(root, "metadata", paste0("filter_note_", source_id, ".txt")))
  dest
}

process_file <- function(path, source_id, register_row) {
  stub <- gsub("[^a-zA-Z0-9._-]+", "_", tools::file_path_sans_ext(basename(path)))
  ext <- tolower(tools::file_ext(path))
  outputs <- character()

  # DSPT org page is RDY-specific — preserve entire public assessment table
  if (source_id == "dspt_rdy") {
    df <- read_tabular(path)
    if (!is.null(df) && nrow(df) > 0) {
      dest <- file.path(root, "processed", paste0("rdy_", source_id, "_assessment_history.csv"))
      write.csv(sanitize_df_for_export(df), dest, row.names = FALSE)
      note_lines <- c(
        paste("Filter note:", source_id),
        "DSPT public org page is RDY-specific; all rows retained.",
        paste("Rows:", nrow(df)),
        paste("Output:", dest),
        "",
        "DISCLAIMER: Public-data demonstration output. Not an official Dorset HealthCare report."
      )
      writeLines(note_lines, file.path(root, "metadata", paste0("filter_note_", source_id, ".txt")))
      return(dest)
    }
    return(character())
  }

  if (ext == "zip") {
    tmp <- file.path(root, "metadata", paste0("filter_tmp_", source_id))
    extracted <- tryCatch(extract_zip_to_temp(path, tmp), error = function(e) character())
    if (source_id == "ko41a_annual") {
      extracted <- extracted[grepl("KO41a.*Org Level|Secondary Care KO41a", extracted, ignore.case = TRUE)]
    }
    for (f in extracted) {
      fext <- tolower(tools::file_ext(f))
      if (!fext %in% c("csv", "xlsx", "xls")) next
      if (source_id == "ko41a_annual" && grepl("metadata|Meta data", basename(f), ignore.case = TRUE)) next
      df <- read_tabular(f)
      out <- filter_and_save(df, source_id, paste0(stub, "_", tools::file_path_sans_ext(basename(f))), register_row)
      if (!is.null(out)) outputs <- c(outputs, out)
    }
    unlink(tmp, recursive = TRUE, force = TRUE)
  } else {
    size <- file.info(path)$size
    max_rows <- if (size > 100e6) 200000 else Inf
    df <- read_tabular(path, max_rows = max_rows)
    out <- filter_and_save(df, source_id, stub, register_row)
    if (!is.null(out)) outputs <- c(outputs, out)
  }
  outputs
}

for (i in seq_len(nrow(register))) {
  sid <- register$source_id[i]
  row <- register[i, , drop = FALSE]
  if (sid == "cqc_rdy") {
    writeLines(c(
      "Filter note: cqc_rdy",
      "Context only — no tabular data to filter.",
      "See metadata/cqc_rdy_context_note.txt",
      "",
      "DISCLAIMER: Not an official Dorset HealthCare report."
    ), file.path(root, "metadata", "filter_note_cqc_rdy.txt"))
    next
  }
  files <- list_raw_files(root, sid)
  if (length(files) == 0) {
    writeLines(c(
      paste("Filter note:", sid),
      "No raw files available to filter.",
      paste("Download status:", row$download_status)
    ), file.path(root, "metadata", paste0("filter_note_", sid, ".txt")))
    next
  }
  all_outputs <- character()
  for (f in files) {
    outs <- tryCatch(process_file(f, sid, row), error = function(e) {
      append_log(root, paste("filter error", sid, conditionMessage(e)))
      character()
    })
    all_outputs <- c(all_outputs, outs)
  }
  if (length(all_outputs) == 0) {
    status <- if (row$contains_dorset_healthcare_rows == "no") "checked_no_rdy_rows" else row$download_status
    update_register_row(root, sid, list(
      download_status = status,
      processed_file_path = NA_character_
    ))
    cat("Filter:", sid, "- no RDY rows extracted\n")
  } else {
    update_register_row(root, sid, list(
      download_status = "downloaded",
      processed_file_path = paste(all_outputs, collapse = "; ")
    ))
    cat("Filter:", sid, "-", length(all_outputs), "extract(s)\n")
  }
}

cat("Filter complete. Processed files in:", file.path(root, "processed"), "\n")
