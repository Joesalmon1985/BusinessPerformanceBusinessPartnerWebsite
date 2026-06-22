# Run 5 checkpoint — ADF + reporting demo (session complete)

**Completed:** 2026-06-22  
**Status:** Runs 2–5 complete

## Artefacts produced

- `site/warehouse-demo/pipelines/` — overview, 4 JSON specs, parameters
- `site/warehouse-demo/generator/build_provider_month_measures.py`
- `site/warehouse-demo/marts/demo_provider_month_measures.csv`
- `site/examples/warehouse-draft-urgent-care-brief-flawed.md`
- `site/examples/warehouse-report-qa-conversation.md`
- `site/agent-rules/warehouse-report-qa-agent.md`
- `site/warehouse-demo/reports/urgent-care-provider-month-brief.html`
- `site/warehouse-demo/checkpoints/manual_answer_key_comparison_template.md` (empty — human only)
- `site/warehouse-demo/source-notes/demo_run_index.md` (completed)
- `site/agent-operating-model.html` (full warehouse demo section)

## Verification summary

| Check | Result |
|-------|--------|
| Profiler reproducible | Yes |
| Answer key untouched | Yes |
| Earlier checkpoints not rewritten | Yes |
| `site/reports/` untouched | Yes |
| Flawed/corrected briefs use profiler evidence only | Yes |
| Comparison template empty | Yes |
| No live Azure used | Yes |

## End-to-end story

Synthetic sources → Source Profiling Agent → Warehouse Design Agent → SQL artefacts → ADF specs → Report QA → human review packs and checkpoints.

## Human follow-up

1. Complete `manual_answer_key_comparison_template.md` against answer key.  
2. Sign off `design/human_review_pack.md` decision log.  
3. Optional: execute SQL in Azure Data Studio demo environment.
