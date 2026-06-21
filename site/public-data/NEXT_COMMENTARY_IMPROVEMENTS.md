# Commentary improvements — status

Plain-English metric commentary, “how to read this report”, agent flags, improved first-draft analysis, Business & Performance Partner questions, and trend analysis (where public data supports it) are implemented for **all six** public reports in `site/R/03_render_public_reports.R`.

Reference: `build_commentary_card()`, `how_to_read_section()`, `measure_commentary_section()`, `trend_section()`, `trend_not_available_section()`, `load_trend_file()`, `extract_stacked_trend()`, `standard_bp_questions()`.

Historic trend pipeline: `site/public-data/05_download_historic_public_data.R` → `processed/trend_*_rdy.csv`. See `HISTORIC_PUBLIC_DATA_EXPANSION_PLAN.md`.

---

## Completed (2026-06-21)

| Report | Commentary | Trend analysis |
|--------|------------|----------------|
| `public-performance-overview.html` (NOF) | 11 metric cards | N/A (single quarter snapshot) |
| `public-mh-access-profile.html` | MHS23, MHS01, MHS29, MHS69, CYP32a, suppression | **Yes** — MHS01, MHS29, MHS69 (11 months, Provider time series); **MHS23** from `trend_mhs23_rdy.csv` when stacked |
| `public-community-services-profile.html` | Assessment, clinical intervention, age bands, aggregate limits | **Yes** — Assessment & Clinical Intervention from `trend_csds_activity_rdy.csv` (8 months) |
| `public-talking-therapies-profile.html` | M001, M031, M019–M022, M053, outcomes gap, suppression | **Yes** — M001, M031, M053 (13 months) |
| `public-assurance-profile.html` | KO41a, ERIC, DSPT, FFT gap, CQC | **Descriptive** — DSPT assessment history; FFT links to `metadata/fft_manual_download_needed.md` unless `trend_fft_rdy.csv` exists |
| `public-urgent-diagnostics-check.html` | A&E, DM01, KH03 per-source cards | **Yes** — A&E/DM01 from historic stack where available; KH03 from `trend_kh03_beds_rdy.csv` (recent snapshots); `latest_kh03_beds_rdy.csv` for demo snapshot |

---

## Historic expansion — done / remaining

| Item | Status |
|------|--------|
| CSDS monthly historic stack | **Done** — `trend_csds_activity_rdy.csv` |
| A&E monthly historic stack | **Done** — `trend_ae_rdy.csv` (source validation; zero ED) |
| DM01 monthly historic stack | **Partial** — depends on full-extract ZIP availability per month |
| KH03 latest + recent trend | **Done** — `latest_kh03_beds_rdy.csv`, `trend_kh03_beds_rdy.csv` |
| MHSDS MHS23 from main_data | **Done** — `trend_mhs23_rdy.csv` |
| FFT org-level trend | **Manual gap** — `metadata/fft_manual_download_needed.md` |
| Talking Therapies extra months | **Not needed** — existing 13-month series sufficient |

---

## Optional next steps

1. **FFT** — manual setting-level download; re-run script 05 after placing file in `raw/fft_monthly_*`
2. **DM01** — add more full-extract monthly ZIPs if FY pages expose additional months
3. **KH03** — re-scrape when NHS England publishes a newer overnight quarter
4. **Outcome measures** — optional Talking Therapies recovery card (M192, M186) for a separate outcome brief

Regenerate reports:

```bash
Rscript site/public-data/05_download_historic_public_data.R
Rscript site/public-data/04_create_demo_extracts.R
Rscript site/R/03_render_public_reports.R
```
