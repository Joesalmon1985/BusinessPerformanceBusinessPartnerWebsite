# =============================================================================
# 03_sync_mandatory_register_html.R
# Reads mandatory_returns_register.csv and syncs table rows into
# mandatory-reporting-map.html between TABLE_BODY markers.
# =============================================================================

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

truncate_text <- function(x, max_len = 90) {
  if (nchar(x) <= max_len) return(x)
  paste0(substr(x, 1, max_len - 1), "…")
}

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
} else {
  script_dir <- getwd()
}
data_dir <- file.path(script_dir, "..", "data")
html_path <- file.path(script_dir, "..", "mandatory-reporting-map.html")

returns <- read.csv(file.path(data_dir, "mandatory_returns_register.csv"), stringsAsFactors = FALSE)

badge_risk <- function(r) {
  cls <- switch(r, Low = "badge-low", Medium = "badge-medium", High = "badge-high", "badge-medium")
  paste0('<span class="badge ', cls, '">', r, '</span>')
}

badge_assurance <- function(s) {
  cls <- if (grepl("production", s, ignore.case = TRUE)) "badge-production"
    else if (grepl("validation", s, ignore.case = TRUE)) "badge-validation"
    else if (grepl("manual", s, ignore.case = TRUE)) "badge-manual"
    else if (grepl("review", s, ignore.case = TRUE)) "badge-review"
    else if (grepl("not applicable", s, ignore.case = TRUE)) "badge-na"
    else "badge-manual"
  paste0('<span class="badge ', cls, '">', s, '</span>')
}

conf_key <- function(c) {
  if (c == "Needs owner confirmation") "needs-owner" else tolower(c)
}

assurance_key <- function(s) {
  if (grepl("production", s, ignore.case = TRUE)) "production"
  else if (grepl("validation", s, ignore.case = TRUE)) "validation"
  else if (grepl("manual", s, ignore.case = TRUE)) "manual"
  else if (grepl("review", s, ignore.case = TRUE)) "review"
  else "other"
}

rows <- character(nrow(returns))
for (i in seq_len(nrow(returns))) {
  r <- returns[i, ]
  ref_cell <- if (nzchar(r$reference_url)) {
    sprintf(
      '<a href="%s" rel="noopener noreferrer" target="_blank">Public reference</a>',
      html_escape(r$reference_url)
    )
  } else {
    "—"
  }
  rows[i] <- sprintf(
    paste0(
      '<tr data-owner="%s" data-risk="%s" data-confidence="%s" data-assurance="%s">',
      '<td>%s</td><td>%s</td><td>%s</td><td>%s</td>',
      '<td>%s</td><td>%s</td><td class="col-notes">%s</td><td>%s</td></tr>'
    ),
    html_escape(r$owner_team), r$risk, conf_key(r$confidence), assurance_key(r$assurance_status),
    html_escape(r$return_name), html_escape(r$owner_team),
    html_escape(r$reporting_frequency), html_escape(r$next_due_date),
    badge_assurance(r$assurance_status), badge_risk(r$risk),
    html_escape(truncate_text(r$issues)), ref_cell
  )
}

body <- paste(rows, collapse = "\n")

html <- readLines(html_path, warn = FALSE, encoding = "UTF-8")
start_marker <- "<!-- TABLE_BODY_START -->"
end_marker <- "<!-- TABLE_BODY_END -->"
start_idx <- which(grepl(start_marker, html, fixed = TRUE))
end_idx <- which(grepl(end_marker, html, fixed = TRUE))

if (length(start_idx) != 1 || length(end_idx) != 1 || end_idx <= start_idx) {
  stop("TABLE_BODY markers not found or invalid in mandatory-reporting-map.html")
}

new_html <- c(html[1:start_idx], body, html[end_idx:length(html)])
writeLines(new_html, html_path, useBytes = TRUE)
cat("Synced", nrow(returns), "rows into", normalizePath(html_path), "\n")
