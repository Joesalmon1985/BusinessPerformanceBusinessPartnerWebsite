# Deployment notes (demonstration only)

## Scope

These scripts are **specification artefacts** for the warehouse-demo worked example. They are syntactically plausible Azure SQL but:

- **Not executed** against a live Azure SQL database in the generation session unless a local SQL Server instance is available
- **No Azure subscription**, credentials, Key Vault secrets or ADF workspace required
- **Not for production** use

## What was not executed locally

If no SQL Server / Azure SQL endpoint was available during generation:

- `CREATE DATABASE` and table DDL were not validated by execution
- `load/load_from_csv.py` was run in `--dry-run` mode only (row counts printed, no INSERT)
- QA views were not materialised

Re-validate in Azure Data Studio or `sqlcmd` before citing in live environments.

## IG

- Source data is synthetic (`DEMO-NHS-*` identifiers)
- Do not load real patient or staff data into these objects

## Post-load verification

Compare row counts to [`EXPECTED_SYNTHETIC_LOAD_COUNTS.md`](EXPECTED_SYNTHETIC_LOAD_COUNTS.md).

Query `qa.MonthlyContactCaseTrend` — expect March 2026 case opens elevated vs IUCS contacts (profiling pattern).
