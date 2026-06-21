# Public Reports Method

How the six **agent-assisted analytical briefs** under `site/reports/public-*.html` were generated for the Dorset HealthCare (RDY) demonstration site.

> **Agentic AI was used to accelerate discovery, preparation, checking and drafting. The analysis remains bounded by the public aggregate data available, and any operational interpretation would require local subject matter review, data owner confirmation and accountable sign-off.**

## Overview

1. **Public-data pipeline** (`site/public-data/01–04_*.R`) downloads official NHS aggregate publications, filters RDY rows, and creates demo CSV extracts in `site/public-data/processed/`.
2. **Report render script** (`site/R/03_render_public_reports.R`) reads those demo CSVs (and selected full RDY extracts where demo files are column-limited), computes descriptive statistics, and writes static HTML using the **agent-assisted analytical brief template**.
3. **Styling** (`site/assets/nhs-report.css`) applies NHS-inspired colours without NHS logo or implied endorsement.

See also: [AGENT_ANALYTICAL_BRIEF_REFRAME_PLAN.md](AGENT_ANALYTICAL_BRIEF_REFRAME_PLAN.md) for the reframe specification.

## Agent-assisted analytical brief template

Each public report follows this workflow spine (rendered by `agent_brief_sections()`):

1. What this report demonstrates
2. The question given to the agent
3. Prompt excerpt
4. Data used (sources, period, RDY filter)
5. Agent process demonstrated (numbered steps)
6. Key figures from the agent’s first draft (tables, KPIs, charts)
7. **How to read this report** (plain-English field and period guidance)
8. **Agent commentary on selected measures** (metric/theme cards with agent flags)
9. **Trend analysis** or **Trend analysis not available from current extract** (where multi-period public data exists)
10. First-draft analysis (cautious narrative)
11. Agent-generated observations
12. What cannot be concluded from this data
13. Questions for a Business & Performance Partner (plain-English with short explanations)
14. How to verify the figures (traceability / audit appendix)
15. Human review required

The primary output is the **demonstrated workflow**, not the data table alone. Reports are indexed on `site/draft-reports.html` by question asked and workflow capability.

## Demo CSVs used

| Report | Primary demo CSV | Additional processed files |
|--------|------------------|----------------------------|
| `public-performance-overview.html` | `demo_nof_overview.csv` | `demo_assurance_profile.csv` |
| `public-mh-access-profile.html` | `demo_mhsds_activity.csv` | MHSDS time series (`rdy_mhsds_monthly_*time_series*Apr2025_Mar_Perf_2026_v2.csv`) |
| `public-community-services-profile.html` | `demo_csds_activity.csv` | — (single month only) |
| `public-talking-therapies-profile.html` | `demo_talking_therapies.csv` | `rdy_talking_therapies_*time_series.csv` |
| `public-assurance-profile.html` | `demo_assurance_profile.csv` | `rdy_dspt_rdy_assessment_history.csv`, CQC context note |
| `public-urgent-diagnostics-check.html` | `demo_dm01_diagnostics.csv`, `demo_kh03_beds.csv` | `rdy_ae_monthly_*.csv`, full `rdy_dm01_monthly_*.csv` |

If a demo CSV is missing, the render script writes a data-availability page rather than inventing figures.

## Statistical methods applied

All analysis is **descriptive** and bounded by published aggregates:

- **Latest-period values** from the demo extract reporting period columns
- **Peer comparison** (NOF): rank, median, lower/upper quartile where present — not significance testing
- **Counts and sums** where numeric; suppressed values (`*`) excluded from numeric calculations
- **Top-N tables** and **bar charts** (base R HTML) for largest numeric measures
- **Plain-English metric/theme commentary cards** with agent flags (Potential strength, Review locally, Watch / clarify, Definition check required, Source validation only, Trend not available)
- **Trend tables and charts** where downloaded time-series extracts contain ≥2 comparable periods for the same measure (latest vs previous month, absolute and percentage change; rolling mean only if ≥3 periods)
- **Source presence checks** (urgent/diagnostics report) for RDY row existence
- **Missingness / suppression counts** flagged explicitly

Not used: p-values, causal inference, forecasting, or blending with synthetic data.

## Why causal claims are avoided

Public aggregate data:

- May be **provisional** or revised (MHSDS, CSDS, Talking Therapies)
- Uses **suppression and rounding**
- Spans **different breakdowns** (ICB resident vs provider, referral source splits)
- Cannot explain **local operational context** (pathways, workforce, definitions)

The briefs describe *what a governed agent can produce from the public file* and *what a human must still check* — not *why performance changed*.

## Public aggregate vs local operational data

| Public aggregate | Local operational |
|------------------|-------------------|
| National publication schedules | Real-time warehouse / PAS extracts |
| RDY-filtered open data | Service-line validated KPIs |
| Peer medians from NOF | Internal targets and trajectories |
| Annual KO41a / ERIC snapshots | Live complaints / estates systems |

Business partners bridge these layers — public data informs questions; local data answers them.

## How the Cursor agent assisted

- Discovered and downloaded official publication files
- Documented sources in `DATA_SOURCE_REGISTER.csv`
- Filtered RDY rows with documented matching rules
- Created demo extracts and the agent brief render script
- Drafted per-report questions, prompt excerpts, process steps, first-draft narrative and reviewer questions

Human reviewers must still:

- Confirm metric definitions against NHS England / NHS Digital guidance
- Verify publication status (provisional vs final)
- Align periods with local reporting cycles
- Obtain named owner sign-off before operational or Board use

## Rerun instructions

```bash
# 1. Refresh public data (requires network)
cd site/public-data
Rscript 01_download_public_data.R
Rscript 02_inspect_public_data.R
Rscript 03_filter_dorset_healthcare.R
Rscript 04_create_demo_extracts.R

# 1b. Historic trend stack (optional — requires network; does not overwrite existing raw files)
Rscript 05_download_historic_public_data.R
```

Historic pipeline outputs (when stacking succeeds):

| Trend file | Source |
|------------|--------|
| `processed/trend_csds_activity_rdy.csv` | CSDS CareActivities / ActivityType |
| `processed/trend_ae_rdy.csv` | A&E provider monthly (source validation) |
| `processed/trend_dm01_rdy.csv` | DM01 full-extract monthly |
| `processed/trend_kh03_beds_rdy.csv` | KH03 recent snapshots (≤6 quarters, post-2020) |
| `processed/latest_kh03_beds_rdy.csv` | KH03 latest snapshot only |
| `processed/trend_mhs23_rdy.csv` | MHSDS MHS23 Provider from main_data monthly |
| `processed/trend_fft_rdy.csv` | FFT org-level (if found) |

Register and run summary: `HISTORIC_SOURCE_REGISTER.csv`, `HISTORIC_PUBLIC_DATA_RUN_SUMMARY.md`.

```bash
# 2. Render public HTML reports (offline OK if CSVs exist)
Rscript site/R/03_render_public_reports.R
```

## Known limitations in this run

- **FFT**: org-level RDY rows not found in downloaded summary XLSX — see `metadata/fft_manual_download_needed.md`
- **KH03**: latest snapshot in public file may lag NHS England “latest quarter” — verify on source site; trend uses recent snapshots only (not full 2007–2024 history)
- **A&E**: RDY row reflects other emergency admissions, not ED attendances (no ED at RDY); historic stack is source validation only
- **DM01**: audiology may dominate activity; historic trend requires full-extract monthly ZIPs (not aggregate REVISED bundles)
- **MHS23**: stacked from MHSDS main_data monthly files — not the Provider time-series bundle
- **CSDS / MHSDS / A&E trends**: provisional monthly data; descriptive period-on-period only — not causal performance claims

## Recommended next improvement

- Obtain **FFT org-level** or setting-level rows to fill the assurance gap (manual download steps in metadata)
- Align **KH03** to the latest NHS England publication quarter when the overnight page updates
- Add more **DM01 full-extract** months if FY scrape misses older months
- Optional Talking Therapies outcome measures (M192, M186) for a separate outcome brief

See [NEXT_COMMENTARY_IMPROVEMENTS.md](NEXT_COMMENTARY_IMPROVEMENTS.md) and [HISTORIC_PUBLIC_DATA_EXPANSION_PLAN.md](HISTORIC_PUBLIC_DATA_EXPANSION_PLAN.md).

## Traceability and verification

Every public brief figure should be traceable back through the pipeline:

1. **Report HTML table or KPI** → demo CSV in `site/public-data/processed/demo_*.csv`
2. **Demo CSV** → full RDY processed extract (`site/public-data/processed/rdy_*.csv`)
3. **Processed extract** → raw public file in `site/public-data/raw/` (filtered to RDY only)
4. **Raw file** → NHS England / NHS Digital source URL in `DATA_SOURCE_REGISTER.csv`

All reports include a **How to verify these figures** section at the bottom of the narrative (before the final human-review warning in the template flow, with human review as the closing gate).

### NOF performance overview (full audit)

The NOF brief includes **plain-English agent commentary** for each displayed metric (see “Agent commentary on selected metrics”), a **How to read this table** guide, and machine-readable audit outputs:

- `site/public-data/metadata/public_report_audit_nof_overview.csv` — one row per displayed metric
- `site/public-data/metadata/public_report_audit_nof_overview.md` — plain-English verification guide

Metric polarity and definitions should be confirmed against the [official NHS England NOF technical metric specification](https://www.england.nhs.uk/long-read/nhs-oversight-framework-csv-metadata-file/) — this long-read was not bulk-downloaded in the public-data pipeline.

Audit summary and per-metric detail appear in collapsible blocks under **How to verify these figures**.

**Important:** `Value`, `Median_value`, and `Rank` in the NOF brief are **NHS England published fields** from the official NOF data CSV. This demo does **not** recalculate medians, ranks, or league tables.

To verify a figure manually:

1. Open the audit CSV or HTML verification section for the metric.
2. Use `RDY_row_identifier` to find the row in the processed and raw NOF files.
3. Confirm `Value`, `Median_value`, and `Rank` match exactly.
4. Check `Comparator_rows_used` against the count of numeric trust rows in the raw file for the same Quarter + Metric_ID + Reporting_date.
5. Confirm rank direction and metric definition against NHS England metadata before operational use.

Regenerating reports also regenerates the audit CSV and MD:

```bash
Rscript site/R/03_render_public_reports.R
```

### Other public briefs (verification appendix)

Briefs for MHSDS, CSDS, Talking Therapies, assurance, and urgent/diagnostics include **How to verify these figures** linking to demo CSVs, filter notes, and governance documentation. Technical detail (full A&E columns, assurance index with all columns, CQC context note) is in collapsible verification blocks where appropriate.

### Human reviewer checklist

Before relying on any public report figure operationally:

- Confirm publication quarter and whether a newer release supersedes the extract
- Check provisional vs final status and suppression rules
- Verify RDY matching against local ODS register
- Do not treat published rank or median as a significance test
- Confirm metric polarity (higher/lower better) against NHS England definitions
- Obtain accountable sign-off from the relevant data owner
