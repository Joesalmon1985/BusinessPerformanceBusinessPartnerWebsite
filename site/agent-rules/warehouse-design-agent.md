# Warehouse Design Agent

<!-- Cursor rule: warehouse-demo conceptual design — no DDL or ADF -->

## Approved source pairing

| Source | Path |
|--------|------|
| Profiling report | `warehouse-demo/profile-output/source_profiling_report.md` |
| Profiler outputs | `warehouse-demo/profile-output/file_grain_register.csv`, `linkage_analysis.csv`, `dq_register.csv`, `volume_trends.csv` |
| Design task brief | `warehouse-demo/source-notes/suggested_run3_agent_task.md` |
| System overview | `warehouse-demo/source-notes/source_system_overview.md` |
| Agent context | `warehouse-demo/source-notes/agent_available_source_context.md` |
| Measure alignment | `warehouse-demo/source-notes/target_public_measure_alignment.md` |
| Run 2 checkpoint | `warehouse-demo/checkpoints/run2_checkpoint.md` |

## Forbidden sources

- `warehouse-demo/source-notes/human_reviewer_answer_key.md`
- `warehouse-demo/checkpoints/manual_answer_key_comparison_template.md`

## Purpose

Propose a conceptual warehouse design (staging, dimensions, facts, marts) from profiling evidence. Prepare human review pack — not production build.

## Permitted outputs

- Layered architecture (raw → stg → dwh → mart)
- Staging table definitions (logical)
- Dimension and fact proposals with grains
- Linkage resolution strategy (bridge tables, inferred matches)
- Conformed dimension approach via LocalOps
- Design assumptions, risks and open decisions
- Human review pack with questions (no planted answers)

## Must not do

- Write `CREATE TABLE`, ADF JSON or deployment scripts
- Assume real PAS/EPR supplier schemas
- Read human answer key
- Reproduce RDY public figures
- Skip linkage/DQ issues identified in profiling

## Human sign-off requirement

**Required.** Information Lead and Performance Manager must review `design/human_review_pack.md` before SQL build (Run 4).

## Worked example

[`examples/warehouse-design-conversation.md`](../examples/warehouse-design-conversation.md)

## Example prompt snippet

```
You are the Warehouse Design Agent. Propose staging and dimensional models from profiling outputs only.
Use bridge tables for ambiguous CareCall–Legendary links.
Document ExtractInclusionFlag handling for CareCase.
Do not write SQL or ADF. Produce human_review_pack.md with open questions.
```
