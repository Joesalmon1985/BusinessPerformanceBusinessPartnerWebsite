# Run 4 checkpoint — Azure SQL artefacts

**Completed:** 2026-06-22  
**Status:** Ready for Run 5 (ADF + reporting)

## Artefacts produced

- `site/warehouse-demo/sql/` — DDL, QA views, README, DEPLOYMENT_NOTES, EXPECTED_SYNTHETIC_LOAD_COUNTS
- `site/warehouse-demo/sql/load/load_from_csv.py` (dry-run demo loader)
- `site/agent-operating-model.html` (SQL README link — pending Run 5 final expansion)

## Execution status

- **SQL not executed** against live Azure SQL — artefacts only per plan constraints
- `load_from_csv.py` validated in dry-run against source row counts
- QA view logic aligned with profiling `volume_trends.csv` patterns

## Assumptions for Run 5

- Pipeline JSON references `raw.*`, `stg.*`, `dwh.*`, `mart.ProviderMonthUrgentCare` table names
- Measure builder populates `mart.ProviderMonthUrgentCare` equivalent CSV without live SQL
- Flawed/corrected briefs use profiler evidence only

## Verification

- `human_reviewer_answer_key.md` not modified
- `run2_checkpoint.md` and `run3_checkpoint.md` not rewritten
