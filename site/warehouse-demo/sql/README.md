# SQL artefacts — Demo Rivers Health warehouse

Demonstration-only Azure SQL DDL. **Not deployed to live Azure.**

## Run order

1. `00_create_schema.sql` — database and schemas (`raw`, `stg`, `dwh`, `mart`, `qa`)
2. `staging/01_raw_carecall.sql` — example raw land pattern
3. `staging/02_raw_other_sources.sql` — additional raw tables for loader/ADF targets
4. `staging/01_stg_tables.sql` — staging with DQ flags
5. `dimensions/02_dim_tables.sql`
6. `facts/03_fact_tables.sql`
7. `marts/04_mart_tables.sql`
8. `views/05_qa_views.sql`

## Optional local load

```bash
cd site/warehouse-demo/sql/load
pip install pandas pyodbc  # pyodbc only if SQL Server available
python load_from_csv.py --dry-run
```

See [`DEPLOYMENT_NOTES.md`](DEPLOYMENT_NOTES.md) for execution limits.

## Related

- Design: [`../design/`](../design/)
- Expected counts: [`EXPECTED_SYNTHETIC_LOAD_COUNTS.md`](EXPECTED_SYNTHETIC_LOAD_COUNTS.md)
