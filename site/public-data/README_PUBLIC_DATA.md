# Public NHS Aggregate Data — Dorset HealthCare (RDY) Demo

> **IMPORTANT DISCLAIMER**
>
> - All data in this folder is **public aggregate data** from official publishers (NHS England, NHS England Digital, DSPT, CQC, GOV.UK).
> - **No patient-identifiable information** is used or intended.
> - These outputs are **public-data demonstration reports** — they are **NOT official Dorset HealthCare University NHS Foundation Trust reports**.
> - Operational interpretation requires **human review and local owner confirmation** before any use in performance management, assurance or submission workflows.
> - Check **publication dates, provisional vs final data, suppression, rounding, experimental statistics and revisions** on the original publication pages before interpreting any figure.

## Purpose

This workspace supports a safe, reproducible, agent-assisted workflow for:

1. Discovering official public NHS aggregate datasets
2. Documenting sources in `DATA_SOURCE_REGISTER.csv`
3. Downloading and preserving raw files
4. Inspecting structure and searching for Dorset HealthCare (**ODS code `RDY`**)
5. Creating lightweight RDY-only processed extracts and demo CSVs for static R reports

**Target organisation:** Dorset HealthCare University NHS Foundation Trust (ODS **RDY**)

## Folder structure

```
site/public-data/
├── raw/                    # Original downloads — never overwritten
├── processed/              # RDY-filtered extracts and demo CSVs
├── metadata/               # Inspection JSON/txt, filter notes, download log
├── scripts/                  # Shared R helpers (_common.R)
├── 01_download_public_data.R
├── 02_inspect_public_data.R
├── 03_filter_dorset_healthcare.R
├── 04_create_demo_extracts.R
├── DATA_SOURCE_REGISTER.csv
├── README_PUBLIC_DATA.md
└── PUBLIC_DATA_RUN_SUMMARY.md
```

## How to run

Requires R and network access for downloads. Install CRAN packages on first run:

- `rvest` — scrape publication pages for file links
- `readxl` — read FFT and other XLSX sources
- `jsonlite` — write inspection metadata

```bash
cd site/public-data
Rscript 01_download_public_data.R
Rscript 02_inspect_public_data.R
Rscript 03_filter_dorset_healthcare.R
Rscript 04_create_demo_extracts.R
```

Script 01 installs missing packages automatically if needed into `site/public-data/R_libs/`.

## Data sources investigated

| ID | Source | Typical RDY content |
|----|--------|---------------------|
| `nof_mh_community` | NHS Oversight Framework MH/community CSVs | Yes — trust league table |
| `mhsds_monthly` | MHSDS Monthly Statistics | Yes — provider aggregates |
| `csds_monthly` | Community Services Statistics | Yes — provider aggregates |
| `talking_therapies` | NHS Talking Therapies Monthly Statistics | Yes — provider aggregates |
| `ae_monthly` | A&E Attendances (provider) | Unlikely — no ED at RDY |
| `dm01_monthly` | DM01 Monthly Diagnostics | Yes — community diagnostics |
| `kh03_quarterly` | KH03 Bed Availability | Yes — MH/day beds |
| `fft_monthly` | Friends and Family Test | Yes — MH/community XLSX |
| `ko41a_annual` | Written Complaints (KO41a) | Yes — trust-level |
| `eric_annual` | ERIC Estates Return | Yes — trust-level |
| `dspt_rdy` | DSPT public assessment history | Yes — org page |
| `cqc_rdy` | CQC provider page | Context only — not statistical data |

See `DATA_SOURCE_REGISTER.csv` for URLs, download status, caveats and file paths.

## Limitations

- **Not all relevant collections contain Dorset HealthCare rows** in every file (e.g. A&E provider statistics).
- **Some sources require manual download** when website structure prevents reliable automation — status recorded in the register.
- **Provisional monthly data** (MHSDS, CSDS, Talking Therapies) may be revised in later publications.
- **Suppression and rounding** may apply in national publications; do not infer suppressed values.
- **Large files** (MHSDS main data) may be sampled during inspection and filtering; check source files for full context.
- **Synthetic placeholders** (e.g. `synthetic_demo_ae_placeholder.csv`) are clearly labelled and never mixed silently with real public data.
- **CQC** is recorded for regulatory context only — not for performance benchmarking.

## Relationship to the demo website

The main site ([site/README.md](../README.md)) currently uses **synthetic data** in `site/data/`. This public-data pipeline is a **parallel track**. Future R report pages should read from `site/public-data/processed/demo_*.csv` with updated disclaimer text — see `PUBLIC_DATA_RUN_SUMMARY.md` for proposed report candidates.

## Information governance

- Aggregate public data only — no patient-level records
- No confidential, unpublished, internal or service-sensitive data
- No scraping behind login or authenticated endpoints
- Do not imply outputs are official Trust reports
- Agent-assisted workflows must pass human IG review before operational use

## Register columns

`DATA_SOURCE_REGISTER.csv` contains one row per source with: `source_id`, `source_name`, `publisher`, `source_url`, `file_type`, `publication_period`, `date_range`, `update_frequency`, `geographic_granularity`, `organisation_granularity`, `expected_filter_field`, `can_filter_to_rdy`, `contains_dorset_healthcare_rows`, `download_status`, `recommended_report_use`, `caveats`, `downloaded_file_path`, `processed_file_path`, `download_date`, `source_access_notes`.

**Download status values:** `downloaded`, `manual_download_needed`, `checked_no_rdy_rows`, `download_failed`, `context_only`, `not_attempted_in_this_run`.
