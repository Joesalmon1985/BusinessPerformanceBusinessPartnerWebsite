# Reporting pages checkpoint

**Date:** 2026-06-22  
**Status:** Reader-facing warehouse demo pages complete

## Files created

| File | Purpose |
|------|---------|
| [`../agentic-warehouse-build.html`](../agentic-warehouse-build.html) | Main explanatory hub for non-technical readers |
| [`../reports/synthetic-urgent-care-analysis.html`](../reports/synthetic-urgent-care-analysis.html) | Synthetic urgent-care movement analysis |
| [`../reports/synthetic-reporting-table-assurance.html`](../reports/synthetic-reporting-table-assurance.html) | Synthetic reporting-table assurance example |

## Files updated

| File | Change |
|------|--------|
| [`../../agent-operating-model.html`](../../agent-operating-model.html) | Added reader-facing examples card with hub + report links |
| [`../../draft-reports.html`](../../draft-reports.html) | Single reciprocal info-box linking to warehouse hub |
| [`demo_run_index.md`](demo_run_index.md) | Reader-facing pages section and site integration links |

## Public vs synthetic data separation

- **Public (RDY):** [`../../draft-reports.html`](../../draft-reports.html) — Dorset HealthCare public aggregate briefs
- **Synthetic (DRH):** All new pages use fictional Demo Rivers Health warehouse outputs only
- Every new page states DRH is not RDY; draft-reports info-box warns against blending providers
- No RDY public-data paths referenced in synthetic report conclusions

## Evidence sources used

- `profile-output/volume_trends.csv`
- `profile-output/dq_register.csv`
- `profile-output/linkage_analysis.csv`
- `profile-output/source_profiling_report.md`
- `marts/demo_provider_month_measures.csv`
- `sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md`
- `sql/views/05_qa_views.sql` (spec reference)
- `source-data/localops_extract_change_log.xlsx` (cited, not parsed in page build)
- `checkpoints/runs_2_5_internal_qa.md` (limitations)

**Not used:** `human_reviewer_answer_key.md`

## Checks performed

- [x] All new internal links resolve from hub and report pages
- [x] `site/reports/` not modified
- [x] `draft-reports.html` — only single info-box added
- [x] No answer-key leakage in page body (no planted-artefact phrasing from answer key)
- [x] Each synthetic finding includes figure, comparator, trend, judgement, evidence, human confirmation
- [x] Hub uses `../draft-reports.html`; reports use `../../draft-reports.html`

## Limitations

- SQL/ADF artefacts are demonstration specifications — not deployed to live Azure
- Mart built offline via `build_provider_month_measures.py`
- `qa.MonthlyContactCaseTrend` join is demo-simplified; profiler CSV authoritative for trends
- Pages are first-draft demonstrations requiring human sign-off

## Manual review still needed

- Human reviewer may complete `manual_answer_key_comparison_template.md` separately
- Operational sign-off before any use outside demonstration site
- CareCase data owner confirmation on March extract rule change
- Information lead confirmation on December export schedule change
