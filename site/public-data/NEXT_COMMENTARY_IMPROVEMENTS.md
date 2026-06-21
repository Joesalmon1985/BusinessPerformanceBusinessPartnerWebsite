# Commentary improvements — status

Plain-English metric commentary, “how to read this report”, agent flags, improved first-draft analysis, Business & Performance Partner questions, and trend analysis (where public data supports it) are implemented for **all six** public reports in `site/R/03_render_public_reports.R`.

Reference: `build_commentary_card()`, `how_to_read_section()`, `measure_commentary_section()`, `trend_section()`, `trend_not_available_section()`, `standard_bp_questions()`.

---

## Completed (2026-06-21)

| Report | Commentary | Trend analysis |
|--------|------------|----------------|
| `public-performance-overview.html` (NOF) | 11 metric cards | N/A (single quarter snapshot) |
| `public-mh-access-profile.html` | MHS23, MHS01, MHS29, MHS69, CYP32a, suppression | **Yes** — MHS01, MHS29, MHS69 (11 months, Provider time series) |
| `public-community-services-profile.html` | Assessment, clinical intervention, age bands, aggregate limits | **No** — single month (March 2026) |
| `public-talking-therapies-profile.html` | M001, M031, M019–M022, M053, outcomes gap, suppression | **Yes** — M001, M031, M053 (13 months) |
| `public-assurance-profile.html` | KO41a, ERIC, DSPT, FFT gap, CQC | **Descriptive** — DSPT assessment history (multi-row, not numeric trend) |
| `public-urgent-diagnostics-check.html` | A&E, DM01, KH03 per-source cards | **Partial** — KH03 mental illness snapshots (14 dates); A&E/DM01 single month |

---

## Remaining gaps / suggested next steps

1. **CSDS** — download consecutive monthly files; enable CareActivities trend by activity type
2. **MHSDS MHS23** — not in Provider time-series extract; add when publication includes comparable rows
3. **FFT** — manual setting-level download to fill org-level gap in assurance brief
4. **KH03** — filter extract to latest published quarter only; avoid mixing 2007–2024 snapshots in one “current capacity” read
5. **A&E / DM01** — stack monthly provider files for month-on-month source validation trends
6. **Outcome measures** — optional Talking Therapies recovery card (M192, M186) with explicit definition checks if requested for a separate outcome brief

Regenerate reports: `Rscript site/R/03_render_public_reports.R`
