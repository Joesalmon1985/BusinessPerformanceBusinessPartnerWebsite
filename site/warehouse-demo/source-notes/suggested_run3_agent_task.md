# Suggested next agent task — warehouse design (Run 3)

## Objective

Using Run 2 profiling outputs, produce a **warehouse design proposal** (staging + dimensional model). Do **not** write SQL DDL or ADF JSON in this pass.

## Approved sources — may read

- All Run 2 `profile-output/*` files including `source_profiling_report.md`
- `source-data/*` (if needed to validate grains)
- `source-notes/source_system_overview.md`
- `source-notes/agent_available_source_context.md`
- `source-notes/target_public_measure_alignment.md`
- `source-notes/suggested_run3_agent_task.md` (this file)

## Forbidden sources

- `source-notes/human_reviewer_answer_key.md`
- `checkpoints/manual_answer_key_comparison_template.md`

## Required outputs

Write to `warehouse-demo/design/`:

- `warehouse_design_proposal.md`
- `staging_model.md`
- `dimensional_model.md`
- `conformed_dimensions.md`
- `linkage_resolution_strategy.md`
- `human_review_pack.md` (questions only — no planted answers)
- `design_assumptions_and_risks.md`

## Explicit non-goals

- No `CREATE TABLE` statements
- No ADF pipeline JSON
- No assumption of real PAS supplier schemas

## Human sign-off

Design proposal remains draft until reviewed via `human_review_pack.md`.
