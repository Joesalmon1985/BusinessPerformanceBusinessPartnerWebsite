# Public Data Run Summary

**Generated:** 2026-06-21 18:46:36

> **DISCLAIMER:** These are public-data demonstration outputs. They are NOT official Dorset HealthCare reports.
> All figures require human review and local owner confirmation before operational use.
> Check publication dates, provisional data, suppression, rounding and revisions before interpretation.

## Download outcomes

- Successfully downloaded or checked: **11** sources
- Manual download needed: **0** sources
- Download failed: **0** sources
- Context only: **1** sources

| source_id | download_status | contains_dorset_healthcare_rows | publication_period |
|-----------|-----------------|--------------------------------|-------------------|
| nof_mh_community | downloaded | yes | Q4 2025/26 |
| mhsds_monthly | downloaded | yes | performance-april-2026 |
| csds_monthly | downloaded | yes | march-2026 |
| talking_therapies | downloaded | yes | performance-april-2026 |
| ae_monthly | downloaded | yes | May-2026-CSV-F4flrg.csv |
| dm01_monthly | downloaded | yes |  |
| kh03_quarterly | downloaded | yes | Latest quarter on overnight page |
| fft_monthly | checked_no_rdy_rows | no |  |
| ko41a_annual | downloaded | yes | 2024-25 |
| eric_annual | downloaded | yes | 2024/25 |
| dspt_rdy | downloaded | yes | Public assessment history |
| cqc_rdy | context_only | n/a | NA |

## Dorset HealthCare / RDY presence

Sources with confirmed RDY rows are prioritised for demo reports.
Sources marked `checked_no_rdy_rows` were inspected but contained no matching organisation rows.

- RDY rows found: **10** sources
- No RDY rows: **1** sources

## Best sources for first website reports

- **nof_mh_community** (NHS Oversight Framework MH/community trust CSVs): Public performance overview; assurance profile
- **mhsds_monthly** (MHSDS Monthly Statistics): Mental health access and activity public profile
- **csds_monthly** (Community Services Statistics (CSDS)): Community services public profile
- **talking_therapies** (NHS Talking Therapies Monthly Statistics): NHS Talking Therapies public profile
- **ae_monthly** (A&E Attendances and Emergency Admissions monthly provider files): Urgent care check (likely no RDY rows)
- **dm01_monthly** (DM01 Monthly Diagnostics provider files): Urgent care / diagnostics public data check
- **kh03_quarterly** (KH03 Bed Availability and Occupancy files): Bed capacity context
- **ko41a_annual** (KO41a / Data on Written Complaints CSV ZIP): Assurance / statutory reporting profile
- **eric_annual** (ERIC Estates Return dataset): Assurance / estates profile
- **dspt_rdy** (DSPT Dorset HealthCare public assessment history): Assurance / IG profile

## Manual download needed

- None in this run.

## Caveats observed

- Monthly MHSDS, CSDS and Talking Therapies data are typically **provisional** until end-of-year refresh.
- National publications may apply **suppression and rounding**; small numbers may be masked.
- A&E provider statistics may not include RDY (no emergency department).
- FFT uses organisation-level XLSX tables with variable response rates.
- ERIC and KO41a are **annual** snapshots; check amendments/revisions on publication pages.
- DSPT public page shows assessment status only — not operational IG detail.
- CQC provider page is **context only** — not statistical performance data.

## Demo extracts created

- demo_nof_overview.csv
- demo_mhsds_activity.csv
- demo_csds_activity.csv
- demo_talking_therapies.csv
- demo_kh03_beds.csv
- demo_dm01_diagnostics.csv
- demo_assurance_profile.csv

## Historic trend files (script 05)

See [HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md](HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md) and [HISTORIC_SOURCE_REGISTER.csv](HISTORIC_SOURCE_REGISTER.csv).

| Trend file | Used in report |
|------------|----------------|
| `trend_csds_activity_rdy.csv` | CSDS community services |
| `trend_mhs23_rdy.csv` | MHSDS (MHS23 open referrals) |
| `trend_ae_rdy.csv` | Urgent/diagnostics (source validation) |
| `trend_dm01_rdy.csv` | Urgent/diagnostics |
| `trend_kh03_beds_rdy.csv` | Urgent/diagnostics |

MHSDS MHS01/MHS29/MHS69 and Talking Therapies M001/M031/M053 use Provider time-series globs (not separate `trend_*.csv` files).

## HTML reports (built)

All six public briefs are rendered by `site/R/03_render_public_reports.R`. Each includes a **Key figures explained** section. See [FINAL_REPORT_QA_SUMMARY.md](FINAL_REPORT_QA_SUMMARY.md).

| Report | Demo CSV | HTML page |
|--------|----------|-----------|
| NHS Oversight Framework overview | demo_nof_overview.csv | reports/public-performance-overview.html |
| MHSDS access profile | demo_mhsds_activity.csv | reports/public-mh-access-profile.html |
| CSDS community services | demo_csds_activity.csv | reports/public-community-services-profile.html |
| Talking Therapies | demo_talking_therapies.csv | reports/public-talking-therapies-profile.html |
| Assurance profile | demo_assurance_profile.csv | reports/public-assurance-profile.html |
| Urgent/diagnostics check | demo_dm01_diagnostics.csv + demo_kh03_beds.csv | reports/public-urgent-diagnostics-check.html |

Each report states: *public-data demonstration report; not an official Trust report; requires human review and local owner confirmation.*

## Recommended next agent run — R report pages (NOT YET BUILT)

~~When instructed, create `site/R/03_render_public_reports.R` reading from `site/public-data/processed/demo_*.csv`:~~

**Completed.** Regenerate with:

```bash
Rscript site/R/03_render_public_reports.R
```

## Run commands

```bash
cd site/public-data
Rscript 01_download_public_data.R
Rscript 02_inspect_public_data.R
Rscript 03_filter_dorset_healthcare.R
Rscript 04_create_demo_extracts.R
```
