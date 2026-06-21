# NOF performance overview — audit and verification guide

Generated: 2026-06-21 19:45:24
Display quarter: Q4 2025/26

> Public-data demonstration only. Not an official Dorset HealthCare report.

## How to verify a figure manually

1. Open `site/public-data/metadata/public_report_audit_nof_overview.csv` or the HTML report audit section for the metric.
2. Note the `RDY_row_identifier` (Trust_code | Quarter | Metric_ID | Reporting_date).
3. Open the processed RDY extract (`Processed_extract_path` in the audit CSV) and locate that row.
4. Open the raw NOF data CSV (`Raw_source_file` in the audit CSV) and search for `Trust_code=RDY` and the same `Metric_ID`, `Quarter`, and `Reporting_date`.
5. Confirm `Value`, `Median_value`, and `Rank` match exactly — these are **NHS England published fields**, not recalculated by this demo.
6. Count comparator rows in the raw file for the same Quarter + Metric_ID + Reporting_date with a numeric Value — this should match `Comparator_rows_used`.
7. Check NHS England metric metadata for rank direction and clinical/operational meaning before any operational use.

## Median and rank

- **Median_value** and **Rank** come directly from the NHS England NOF data CSV.
- This demo does **not** recompute league tables, medians, or ranks.
- Rank 1 is published by NHS England as best in the MH/community trust peer group for that metric (per NOF methodology).
- **Polarity is not independently verified here** — confirm against NHS England definitions.

## Worked example: OF0005

- **Metric:** OF0005 — Percentage of patients waiting over 52 weeks for community services
- **RDY row:** RDY | Q4 2025/26 | OF0005 | Mar-26
- **Raw file:** site/public-data/raw/nof_mh_community_q4_2025_26_nhs-oversight-framework-mental-health-and-community-trust-data.csv
- **Comparator rows:** 42
- **Median/rank source:** NHS England published field in NOF data CSV — not recalculated by this demo

## Worked example: OF0079

- **Metric:** OF0079 — Planned surplus/deficit
- **RDY row:** RDY | Q4 2025/26 | OF0079 | 2025/26 plan
- **Raw file:** site/public-data/raw/nof_mh_community_q4_2025_26_nhs-oversight-framework-mental-health-and-community-trust-data.csv
- **Comparator rows:** 61
- **Caveat:** Finance metric rank direction requires NHS England definition check before operational interpretation.

## Human reviewer checklist

- Confirm publication quarter and whether a newer NOF release supersedes these figures.
- Check provisional/final status and any NHS England revisions.
- Verify RDY matching against local ODS register.
- Do not treat rank or median comparisons as significance tests.
- Obtain accountable sign-off before operational or Board use.

