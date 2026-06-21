# Public Data Run Summary

**Generated:** 2026-06-21 17:02:47

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

## Public HTML briefs (agent-assisted template)

Reports are rendered by `site/R/03_render_public_reports.R` using the agent-assisted analytical brief template. See [AGENT_ANALYTICAL_BRIEF_REFRAME_PLAN.md](AGENT_ANALYTICAL_BRIEF_REFRAME_PLAN.md) and [PUBLIC_REPORTS_METHOD.md](PUBLIC_REPORTS_METHOD.md).

| Brief | Demo CSV | HTML page |
|-------|----------|-----------|
| AI-assisted NHS Oversight Framework analysis | demo_nof_overview.csv | reports/public-performance-overview.html |
| AI-assisted MHSDS public-data briefing | demo_mhsds_activity.csv | reports/public-mh-access-profile.html |
| AI-assisted CSDS community services briefing | demo_csds_activity.csv | reports/public-community-services-profile.html |
| AI-assisted Talking Therapies briefing | demo_talking_therapies.csv | reports/public-talking-therapies-profile.html |
| AI-assisted assurance and statutory reporting brief | demo_assurance_profile.csv | reports/public-assurance-profile.html |
| AI-assisted urgent care and diagnostics source check | demo_dm01_diagnostics.csv, demo_kh03_beds.csv | reports/public-urgent-diagnostics-check.html |

Each brief includes: *How to read this report*, *Agent commentary on selected measures*, trend analysis (where multi-period public data exists) or *Trend analysis not available from current extract*, plain-English Business & Performance Partner questions, and verification paths.

### Trend analysis in current extracts

| Brief | Trend available? | Source |
|-------|------------------|--------|
| MHSDS access | Yes (MHS01, MHS29, MHS69) | `rdy_mhsds_monthly_*time_series*Apr2025_Mar_Perf_2026_v2.csv` (11 months) |
| CSDS community | No | Single month (`demo_csds_activity.csv`) |
| Talking Therapies | Yes (M001, M031, M053) | `rdy_talking_therapies_*time_series.csv` (13 months) |
| Assurance | DSPT history only (descriptive) | `rdy_dspt_rdy_assessment_history.csv` |
| Urgent/diagnostics | KH03 mental illness snapshots only | `demo_kh03_beds.csv` (14 snapshot dates; A&E/DM01 single month) |

## Run commands

```bash
cd site/public-data
Rscript 01_download_public_data.R
Rscript 02_inspect_public_data.R
Rscript 03_filter_dorset_healthcare.R
Rscript 04_create_demo_extracts.R
```
