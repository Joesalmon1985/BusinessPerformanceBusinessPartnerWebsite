# =============================================================================
# 01_generate_synthetic_data.R
# Generates synthetic aggregate data for demonstration purposes ONLY.
# Does NOT connect to any live system. Does NOT use real Trust data.
# No patient-identifiable or confidential service-level figures.
# =============================================================================

set.seed(42)

# Resolve paths relative to this script
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
} else {
  script_dir <- getwd()
}
data_dir <- file.path(script_dir, "..", "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

months <- c("2025-04", "2025-05", "2025-06", "2025-07", "2025-08", "2025-09",
            "2025-10", "2025-11", "2025-12", "2026-01", "2026-02", "2026-03")

# --- CYP Waiting List ---
cyp <- data.frame(
  month = months,
  referrals = c(142, 156, 148, 163, 171, 159, 168, 174, 180, 165, 158, 152),
  waiting_list = c(198, 205, 212, 218, 225, 230, 228, 222, 215, 208, 200, 195),
  waits_over_18w = c(28, 32, 35, 38, 42, 45, 44, 40, 36, 32, 28, 25),
  median_wait_weeks = c(11.2, 11.8, 12.1, 12.5, 13.0, 13.4, 13.1, 12.6, 12.0, 11.5, 11.0, 10.8),
  appointments = c(420, 435, 428, 445, 450, 442, 455, 460, 448, 440, 432, 425),
  discharges = c(118, 125, 122, 130, 128, 135, 132, 138, 140, 133, 128, 122)
)
write.csv(cyp, file.path(data_dir, "synthetic_cyp_waiting_list.csv"), row.names = FALSE)

# --- All Age Mental Health Access ---
mh <- data.frame(
  month = months,
  referrals = c(890, 920, 905, 940, 955, 930, 960, 975, 950, 935, 910, 895),
  caseload = c(3200, 3250, 3280, 3310, 3340, 3360, 3350, 3320, 3290, 3260, 3230, 3200),
  contacts = c(4100, 4180, 4150, 4220, 4280, 4250, 4300, 4320, 4280, 4200, 4150, 4100),
  median_wait_weeks = c(6.2, 6.5, 6.8, 7.0, 7.2, 7.1, 6.9, 6.7, 6.5, 6.3, 6.1, 6.0),
  dna_rate_pct = c(8.2, 8.5, 8.1, 8.8, 9.0, 8.6, 8.4, 8.3, 8.0, 7.8, 7.6, 7.5),
  capacity_pressure_index = c(72, 74, 76, 78, 80, 79, 77, 75, 73, 71, 70, 68)
)
write.csv(mh, file.path(data_dir, "synthetic_mental_health_access.csv"), row.names = FALSE)

# --- Learning Disability Performance ---
ld <- data.frame(
  month = months,
  open_caseload = c(480, 485, 490, 492, 495, 498, 500, 498, 495, 492, 488, 485),
  health_checks_due = c(45, 48, 50, 52, 55, 58, 60, 58, 55, 52, 48, 45),
  health_checks_completed = c(38, 40, 42, 44, 46, 48, 50, 49, 47, 45, 42, 40),
  contacts = c(820, 835, 840, 850, 855, 860, 858, 850, 845, 838, 830, 825),
  long_waits = c(12, 14, 15, 16, 18, 17, 16, 15, 14, 13, 12, 11),
  safeguarding_flags = c(2, 1, 3, 2, 2, 1, 2, 3, 2, 1, 2, 1)
)
write.csv(ld, file.path(data_dir, "synthetic_learning_disability.csv"), row.names = FALSE)

# --- Demand and Capacity (weekly, last 12 weeks) ---
weeks <- paste0("2026-W", sprintf("%02d", 10:21))
demand <- c(185, 190, 188, 195, 200, 198, 205, 210, 208, 215, 212, 218)
capacity <- c(180, 182, 185, 185, 188, 190, 190, 192, 195, 195, 198, 200)
dc <- data.frame(
  week = weeks,
  demand = demand,
  capacity = capacity,
  backlog = cumsum(demand - capacity) + 120,
  forecast_clearance_weeks = round(c(14, 15, 14, 16, 17, 16, 18, 19, 17, 18, 16, 15), 1)
)
write.csv(dc, file.path(data_dir, "synthetic_demand_capacity.csv"), row.names = FALSE)

# --- Mandatory Returns Register (verified public reference URLs only; demo metadata) ---
# Returns without a working public reference URL are omitted from this demo register.
returns <- data.frame(
  return_name = c(
    "MHSDS", "CSDS", "NHS Talking Therapies", "ECDS / urgent care",
    "KH03 bed occupancy", "RTT", "DM01 audiology/diagnostics",
    "CYP eating disorder waits", "KO41a complaints",
    "FFT", "ERIC", "DSPT", "CQC notifications", "WRES / WDES / EDS"
  ),
  recipient = c(
    rep("NHS England", 12), "CQC", "NHS England"
  ),
  mandate_source = c(
    "Statutory", "Statutory", "Contractual", "Statutory",
    "Statutory", "Statutory", "Statutory", "National standard",
    "Statutory", "Statutory", "Statutory", "Statutory",
    "Regulatory", "Statutory"
  ),
  service_trigger = c(
    "All age MH services", "Community services", "IAPT / Talking Therapies",
    "Urgent care / ED", "Inpatient beds", "Elective / diagnostics",
    "Audiology / diagnostics", "CYP ED pathway", "All services",
    "All services", "Estates / facilities", "All Trust",
    "Regulated activities", "Workforce / EDI"
  ),
  owner_team = c(
    "Performance & BI", "Performance & BI", "MH Performance Team",
    "Urgent Care BI", "Bed Management / BI", "Performance & BI",
    "Diagnostics PMO", "CYP Performance", "Complaints Team",
    "Patient Experience", "Estates & Facilities", "IG / IT Security",
    "Quality & Governance", "Workforce / OD"
  ),
  reporting_frequency = c(
    "Monthly", "Monthly", "Monthly", "Monthly", "Quarterly", "Monthly",
    "Monthly", "Monthly", "Quarterly", "Monthly", "Annual", "Annual",
    "Ad hoc", "Annual"
  ),
  next_due_date = c(
    "2026-04-15", "2026-04-15", "2026-04-10", "2026-04-20", "2026-04-30",
    "2026-04-15", "2026-04-12", "2026-04-08", "2026-04-30",
    "2026-04-05", "2026-05-31", "2026-05-31", "Ad hoc", "2026-05-31"
  ),
  source_system = c(
    "Data warehouse (demo)", "Data warehouse (demo)", "Manual + DWH (demo)",
    "ED system extract (demo)", "Bed management system (demo)",
    "Data warehouse (demo)", "DM01 portal + manual (demo)",
    "CYP pathway system (demo)", "Complaints system (demo)",
    "FFT platform (demo)", "Estates system (demo)", "Corporate IG system (demo)",
    "Manual notification (demo)", "ESR + manual (demo)"
  ),
  assurance_status = c(
    "In production", "In production", "In production", "Needs validation",
    "In production", "Needs validation", "Manual process", "In production",
    "In production", "In production", "Under review",
    "In production", "Manual process", "In production"
  ),
  risk = c(
    "Medium", "Medium", "Low", "High", "Low", "High", "Medium", "High",
    "Low", "Low", "Low", "Medium", "High", "Low"
  ),
  issues = c(
    "Validate against MHSDS guidance; coding QA pending",
    "Community metrics require coding QA each month",
    "Recovery target tracking in place",
    "ECDS scope needs local confirmation",
    "KH03 reconciled with bed state each quarter",
    "RTT incomplete for some pathways",
    "Audiology DM01 partially manual",
    "National ED access standard — high scrutiny",
    "KO41a aligned with complaints policy",
    "FFT response rates monitored",
    "ERIC annual cycle — estates data lag possible",
    "DSPT annual assessment",
    "CQC notifications require clinical sign-off",
    "Workforce data from ESR — extract delay possible"
  ),
  confidence = c(
    "Confirmed", "Confirmed", "Likely", "Conditional", "Confirmed",
    "Conditional", "Likely", "Confirmed", "Confirmed",
    "Confirmed", "Likely", "Confirmed", "Confirmed", "Confirmed"
  ),
  reference_url = c(
    "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics",
    "https://digital.nhs.uk/data-and-information/publications/statistical/community-services-statistics-for-children-young-people-and-adults",
    "https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors",
    "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/",
    "https://www.england.nhs.uk/statistics/statistical-work-areas/bed-availability-and-occupancy/bed-data-overnight/",
    "https://www.england.nhs.uk/statistics/statistical-work-areas/rtt-waiting-times/",
    "https://www.england.nhs.uk/statistics/statistical-work-areas/diagnostics-waiting-times-and-activity/",
    "https://www.england.nhs.uk/mental-health/cyp/trailblazers/ed/",
    "https://digital.nhs.uk/data-and-information/publications/statistical/data-on-written-complaints-in-the-nhs/2024-25",
    "https://www.england.nhs.uk/fft/",
    "https://digital.nhs.uk/data-and-information/publications/statistical/estates-returns-information-collection/summary-page-and-dataset-for-eric-2024-25",
    "https://www.dsptoolkit.nhs.uk/",
    "https://www.cqc.org.uk/guidance-regulation/providers/notifications",
    "https://www.england.nhs.uk/publication/nhs-workforce-race-equality-standard/"
  ),
  reference_type = rep("Public reference", 14),
  escalation_route = c(
    "Performance Manager", "Information Lead", "MH Performance Manager",
    "Urgent Care Director", "Bed Management Lead", "Performance Manager",
    "Diagnostics PMO", "CYP Director", "Complaints Manager",
    "Patient Experience Lead", "Estates Director", "IG Lead",
    "Medical Director", "Workforce Director"
  ),
  stringsAsFactors = FALSE
)
write.csv(returns, file.path(data_dir, "mandatory_returns_register.csv"), row.names = FALSE)

cat("Synthetic data written to:", normalizePath(data_dir), "\n")
cat("Files:", paste(list.files(data_dir), collapse = ", "), "\n")
