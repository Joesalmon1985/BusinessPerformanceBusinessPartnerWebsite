# Warehouse demo — run index

> Self-contained index for the agentic warehouse-design demonstration. Synthetic data only.

## Runs (complete)

| Run | Focus | Status |
|-----|-------|--------|
| 1 | Synthetic source-data pack | Complete |
| 2 | Agent definitions + source profiling | Complete |
| 3 | Warehouse design proposal | Complete |
| 4 | Azure SQL artefacts | Complete |
| 5 | ADF specs + reporting QA demo | Complete |

## Workflow

```
source-data → profile → design → SQL → ADF → mart → report QA → human review
```

## Run 1 — Source pack

| Artefact | Path |
|----------|------|
| Generator | [`generator/create_synthetic_source_data.py`](../generator/create_synthetic_source_data.py) |
| Source extracts | [`source-data/`](../source-data/) |
| Manifest | [`profile-output/source_manifest.csv`](../profile-output/source_manifest.csv) |
| Human answer key | [`source-notes/human_reviewer_answer_key.md`](human_reviewer_answer_key.md) — **reviewers only** |

## Run 2 — Profiling

| Artefact | Path |
|----------|------|
| Agent rule | [`../../agent-rules/source-profiling-agent.md`](../../agent-rules/source-profiling-agent.md) |
| Profiler | [`../profiler/profile_sources.py`](../profiler/profile_sources.py) |
| Profiling report | [`../profile-output/source_profiling_report.md`](../profile-output/source_profiling_report.md) |
| Conversation | [`../../examples/warehouse-source-profiling-conversation.md`](../../examples/warehouse-source-profiling-conversation.md) |
| Checkpoint | [`../checkpoints/run2_checkpoint.md`](../checkpoints/run2_checkpoint.md) |

## Run 3 — Design

| Artefact | Path |
|----------|------|
| Agent rule | [`../../agent-rules/warehouse-design-agent.md`](../../agent-rules/warehouse-design-agent.md) |
| Design proposal | [`../design/warehouse_design_proposal.md`](../design/warehouse_design_proposal.md) |
| Human review pack | [`../design/human_review_pack.md`](../design/human_review_pack.md) |
| Conversation | [`../../examples/warehouse-design-conversation.md`](../../examples/warehouse-design-conversation.md) |
| Checkpoint | [`../checkpoints/run3_checkpoint.md`](../checkpoints/run3_checkpoint.md) |

## Run 4 — SQL

| Artefact | Path |
|----------|------|
| SQL README | [`../sql/README.md`](../sql/README.md) |
| Expected load counts | [`../sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md`](../sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md) |
| Demo loader | [`../sql/load/load_from_csv.py`](../sql/load/load_from_csv.py) |
| Checkpoint | [`../checkpoints/run4_checkpoint.md`](../checkpoints/run4_checkpoint.md) |

## Run 5 — Pipelines + reporting

| Artefact | Path |
|----------|------|
| Pipeline overview | [`../pipelines/pipeline_overview.md`](../pipelines/pipeline_overview.md) |
| Measure builder | [`../generator/build_provider_month_measures.py`](../generator/build_provider_month_measures.py) |
| Mart CSV | [`../marts/demo_provider_month_measures.csv`](../marts/demo_provider_month_measures.csv) |
| Flawed draft | [`../../examples/warehouse-draft-urgent-care-brief-flawed.md`](../../examples/warehouse-draft-urgent-care-brief-flawed.md) |
| Corrected brief | [`../reports/urgent-care-provider-month-brief.html`](../reports/urgent-care-provider-month-brief.html) |
| QA conversation | [`../../examples/warehouse-report-qa-conversation.md`](../../examples/warehouse-report-qa-conversation.md) |
| QA agent addendum | [`../../agent-rules/warehouse-report-qa-agent.md`](../../agent-rules/warehouse-report-qa-agent.md) |
| Checkpoint | [`../checkpoints/run5_checkpoint.md`](../checkpoints/run5_checkpoint.md) |

## Reader-facing pages (post Runs 1–5)

| Page | Path |
|------|------|
| Explanatory hub | [`../../data-warehouse-agent-demo.html`](../../data-warehouse-agent-demo.html) |
| Legacy pointer | [`../agentic-warehouse-build.html`](../agentic-warehouse-build.html) — redirects to top-level page |
| Urgent-care analysis | [`../reports/synthetic-urgent-care-analysis.html`](../reports/synthetic-urgent-care-analysis.html) |
| Reporting-table assurance | [`../reports/synthetic-reporting-table-assurance.html`](../reports/synthetic-reporting-table-assurance.html) |
| Corrected brief | [`../reports/urgent-care-provider-month-brief.html`](../reports/urgent-care-provider-month-brief.html) |

## Checkpoints (audit trail)

| File | Do not rewrite after later runs |
|------|--------------------------------|
| [`run2_checkpoint.md`](../checkpoints/run2_checkpoint.md) | Preserves Run 2 state |
| [`run3_checkpoint.md`](../checkpoints/run3_checkpoint.md) | Preserves Run 3 state |
| [`run4_checkpoint.md`](../checkpoints/run4_checkpoint.md) | Preserves Run 4 state |
| [`run5_checkpoint.md`](../checkpoints/run5_checkpoint.md) | Session complete |
| [`runs_2_5_internal_qa.md`](../checkpoints/runs_2_5_internal_qa.md) | Internal consistency QA (Runs 2–5) |
| [`reporting_pages_checkpoint.md`](../checkpoints/reporting_pages_checkpoint.md) | Reader-facing pages created |
| [`dedicated_page_checkpoint.md`](../checkpoints/dedicated_page_checkpoint.md) | Top-level dedicated page |

## Human reviewer only

- [`human_reviewer_answer_key.md`](human_reviewer_answer_key.md)
- [`manual_answer_key_comparison_template.md`](../checkpoints/manual_answer_key_comparison_template.md) — fill in after session

## Site integration

- [Agent operating model](../../agent-operating-model.html#cat-e)
- [Warehouse demo hub](../../data-warehouse-agent-demo.html)
- [Public draft reports](../../draft-reports.html) (RDY — separate provider)
