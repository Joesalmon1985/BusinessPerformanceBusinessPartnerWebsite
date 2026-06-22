# Dedicated page checkpoint

**Date:** 2026-06-22  
**Status:** Top-level warehouse demonstration page complete

## Files created

| File | Purpose |
|------|---------|
| [`../../data-warehouse-agent-demo.html`](../../data-warehouse-agent-demo.html) | Canonical public-facing warehouse agent demonstration |

## Files updated

| File | Change |
|------|--------|
| [`../agentic-warehouse-build.html`](../agentic-warehouse-build.html) | Replaced with short pointer to top-level page |
| [`../../index.html`](../../index.html) | Three-demo sentence + warehouse card; nav item |
| [`../../draft-reports.html`](../../draft-reports.html) | Info-box link to dedicated page; nav item |
| [`../../agent-operating-model.html`](../../agent-operating-model.html) | §E signpost only; removed reader-examples card; nav item |
| [`../../mandatory-reporting-map.html`](../../mandatory-reporting-map.html) | Nav item |
| [`../../governance-and-benefits.html`](../../governance-and-benefits.html) | Nav item |
| [`../reports/synthetic-urgent-care-analysis.html`](../reports/synthetic-urgent-care-analysis.html) | Nav/back links → `../../data-warehouse-agent-demo.html` |
| [`../reports/synthetic-reporting-table-assurance.html`](../reports/synthetic-reporting-table-assurance.html) | Nav/back links → `../../data-warehouse-agent-demo.html` |
| [`demo_run_index.md`](demo_run_index.md) | Primary hub → top-level page; legacy pointer noted |

## Content moved / linked

- Full narrative migrated from `agentic-warehouse-build.html` to `data-warehouse-agent-demo.html` (expanded with sections 3, 12–14 labels, extended workflow, artefact grid).
- Old hub URL preserved as pointer only — no duplicate narrative.
- `agent-operating-model.html` §E retains agent rule cards and workflow diagram only (technical reference).

## Public vs synthetic separation

- Dedicated page and draft-reports info-box state DRH ≠ RDY.
- No RDY public-data paths used in warehouse conclusions.
- Homepage card states synthetic Demo Rivers Health only.

## Verification checks performed

- [x] All hrefs from `data-warehouse-agent-demo.html` resolve
- [x] Relative paths: top-level → `data-warehouse-agent-demo.html`; reports → `../../data-warehouse-agent-demo.html`; pointer → `../data-warehouse-agent-demo.html`; artefacts → `warehouse-demo/...`
- [x] `site/reports/` not modified
- [x] Draft report cards unchanged (info-box + nav only on draft-reports)
- [x] No answer-key leakage in new page
- [x] `agent-operating-model.html` and `agentic-warehouse-build.html` do not duplicate full dedicated-page narrative
- [x] `agent-operating-model.html#cat-e` anchor confirmed (existing `id="cat-e"`)

## Limitations

- SQL/ADF are specification artefacts — not live Azure
- Mart built offline
- Human sign-off required before operational use

## Manual review still needed

- Optional comparison against human reviewer answer key (separate from agent outputs)
- Operational sign-off if ever used outside demonstration context
