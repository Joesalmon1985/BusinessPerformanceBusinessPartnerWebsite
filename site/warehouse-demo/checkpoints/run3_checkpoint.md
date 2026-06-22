# Run 3 checkpoint — warehouse design proposal

**Completed:** 2026-06-22  
**Status:** Ready for Run 4 (SQL artefacts)

## Artefacts produced

- `site/agent-rules/warehouse-design-agent.md`
- `site/warehouse-demo/design/` (7 documents)
- `site/examples/warehouse-design-conversation.md`
- `site/warehouse-demo/source-notes/suggested_run4_agent_task.md`
- `site/agent-operating-model.html` (Warehouse Design Agent card added)

## Design decisions taken (demo assumptions)

- Medallion: raw → stg → dwh → mart
- Bridge tables for AMBIGUOUS and INFERRED_MATCH
- `is_extract_inclusion_case` flag for CareCase operational filtering
- `date_boundary_mismatch_flag` for CareCall Dec 2025 pattern
- LocalOps mapping confidence tiers in `DimStaff`
- Provider-month marts with loose MHSDS-style measures (not RDY-calibrated)

## Open questions deferred to human_review_pack.md

- D001–D005 decision log unfilled (intentional)
- Operational case definition for March admin-status rows

## Assumptions for Run 4

- Database name `DemoRiversDWH`; schemas `raw`, `stg`, `dwh`, `mart`, `qa`
- Azure SQL syntax (`DATETIME2`, `VARCHAR`)
- SQL not executed locally unless environment available — document in DEPLOYMENT_NOTES

## Verification

- No DDL or ADF JSON in design folder
- Answer key not read or modified
- `run2_checkpoint.md` not rewritten
