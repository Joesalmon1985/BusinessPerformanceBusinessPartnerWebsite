# Final Report QA Summary

**Generated:** 2026-06-21 (after final clarity, trend, explanation and simplification passes)

> Public-data demonstration only — not official Dorset HealthCare reporting. All figures require human review and local owner confirmation.

## Scope of this pass

- **Simplification pass (latest):** merged overlapping sections into Key findings explained, Agent summary, and What a human should check; demoted tables/commentary/trends to collapsible details. See [FINAL_SIMPLIFICATION_SUMMARY.md](FINAL_SIMPLIFICATION_SUMMARY.md).
- Added **Key findings explained** section to all six public HTML reports (formerly Key figures explained)
- Standardized **trend direction** labels and **comparator** wording
- Fixed narrative contradictions where historic trend files now exist (CSDS, MHSDS MHS23, urgent/diagnostics)
- Enhanced agent process and verification copy
- No new data downloads; uses existing `demo_*.csv`, time-series globs and `trend_*.csv` files

**Regenerate reports:**

```bash
Rscript site/R/03_render_public_reports.R
```

---

## Reports by trend data availability

| Report | Current data | Historic trend | Notes |
|--------|-------------|----------------|-------|
| `public-performance-overview.html` | Q4 2025/26 NOF snapshot | **None** (cross-sectional) | Peer median/rank from NHS England fields |
| `public-mh-access-profile.html` | Apr 2026 demo month | **Yes** — MHSDS time series (MHS01/29/69); `trend_mhs23_rdy.csv` (8 mo) | Heavy suppression in demo |
| `public-community-services-profile.html` | Mar 2026 demo month | **Yes** — `trend_csds_activity_rdy.csv` (8 mo) | Assessment & Clinical Intervention trended |
| `public-talking-therapies-profile.html` | Apr 2026 demo month | **Yes** — IAPT time series (13 mo) | M019–M022 waiting bands latest-only |
| `public-assurance-profile.html` | Annual snapshots | **Descriptive history only** — DSPT multi-year status | KO41a/ERIC annual; FFT gap; CQC context |
| `public-urgent-diagnostics-check.html` | May 2026 A&E; Mar 2026 DM01 | **Yes** — `trend_ae_rdy.csv`, `trend_dm01_rdy.csv`, `trend_kh03_beds_rdy.csv` | A&E = source validation; KH03 to Jun 2024 |

---

## Comparator types by report

| Report | Primary comparator | Secondary |
|--------|-------------------|-----------|
| NOF overview | **Peer median + published rank** (NHS England, not recalculated) | None for trend |
| MHSDS | **Previous comparable month** | None — no national target in extract |
| CSDS | **Previous comparable month** | No official standard stated |
| Talking Therapies | **Previous comparable month** | M053: no verified threshold in extract |
| Assurance | **Source validation / descriptive history** | No peer benchmarks |
| Urgent/diagnostics | **Previous period** (DM01, KH03); **validation only** (A&E) | No national comparators |

---

## Key figures explained — validation checklist

| Check | Result |
|-------|--------|
| All six reports contain "Key findings explained" | **Pass** |
| Each key figure has what / compare / trend / human-check columns | **Pass** |
| No trend inferred from single data point | **Pass** |
| No fabricated targets or peer medians (except NOF pass-through) | **Pass** |
| No causal claims introduced | **Pass** |
| Demonstration caveat intact on all reports | **Pass** |
| Links from `site/draft-reports.html` work | **Pass** (paths unchanged) |
| CSDS narrative consistent with 8-month trend | **Pass** |
| MHSDS MHS23 references `trend_mhs23_rdy.csv` when available | **Pass** |
| Urgent A&E/DM01 trend section renders when historic files present | **Pass** |
| Trend badges use allowed labels only | **Pass** |

---

## Figures where trend or comparator remains unavailable

| Figure | Limitation |
|--------|------------|
| All NOF metrics | Cross-sectional Q4 2025/26 only; median/rank often NA |
| MHSDS suppressed cells | `*` — trend N/A for those cells |
| MHSDS CYP32a | Not in Provider time-series bundle used here |
| CSDS age bands | No multi-period age-band trend in extract |
| IAPT M019–M022 waiting bands | Latest-period values only in Key figures explained |
| IAPT M192/M186 outcomes | Deferred — definition/suppression; not key figures |
| KO41a / ERIC | Single annual snapshot each |
| FFT | No org-level RDY rows in downloaded summary XLSX |
| CQC | Context note only — not numeric performance |
| A&E Type 1/2 attendances | Always zero — Source validation only |
| KH03 | Quarterly snapshots to Jun 2024; may lag NHS England latest page |

These gaps are stated explicitly in the reports.

---

## Files changed in this pass

| File | Change |
|------|--------|
| `site/R/03_render_public_reports.R` | Key figures explained helpers; all six `build_*()` functions; extended process steps |
| `site/assets/nhs-report.css` | `.key-figures-explained`, trend badges, comparator labels |
| `site/public-data/PUBLIC_REPORTS_METHOD.md` | Template, trend rules, historic file references |
| `site/public-data/PUBLIC_DATA_RUN_SUMMARY.md` | Historic trend cross-refs; reports marked built |
| `site/draft-reports.html` | Card copy updates for Key figures explained / trends |
| `site/public-data/FINAL_REPORT_QA_SUMMARY.md` | This document |
| `site/reports/public-*.html` | Regenerated (six files) |

---

## Remaining caveats before deployment

1. **FFT org-level gap** — manual download may still be needed (`metadata/fft_manual_download_needed.md`)
2. **KH03 snapshot lag** — trend file ends Jun 2024; verify latest quarter on NHS England site
3. **NOF demo CSV truncated** — full audit CSV/MD provided for verification
4. **Provisional monthly data** — MHSDS, CSDS, IAPT may revise on final refresh
5. **Period mismatch across sources** — urgent report documents A&E May 2026 vs KH03 Jun 2024 explicitly

---

## Ready for final site QA / deployment?

**Yes — ready for final human review and site QA.**

All six public reports now meet the clarity pass requirements: Key figures explained, honest comparators, standardized trend labels, enhanced agent process and verification sections. Operational use still requires local data owner confirmation and accountable sign-off.
