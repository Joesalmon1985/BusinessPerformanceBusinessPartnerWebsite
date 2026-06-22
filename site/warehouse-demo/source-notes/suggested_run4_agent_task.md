# Suggested next agent task — Azure SQL artefacts (Run 4)

## Objective

Implement **Azure SQL demonstration artefacts** from the approved design in `warehouse-demo/design/`. No live Azure deployment.

## Approved sources

- All `warehouse-demo/design/*.md`
- `warehouse-demo/checkpoints/run3_checkpoint.md`
- Profiling outputs (for QA view logic)
- `source-data/*` (for load script targets)

## Forbidden

- `human_reviewer_answer_key.md`
- Do not update answer key — use `sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md` instead

## Required outputs

See plan: `sql/` folder with DDL, QA views, optional `load/load_from_csv.py`, `DEPLOYMENT_NOTES.md`, `EXPECTED_SYNTHETIC_LOAD_COUNTS.md`, `run4_checkpoint.md`

## Non-goals

- Live Azure connection required
- Production ETL
