# Design assumptions and risks

## Assumptions

1. **Fictional systems** — table and column names are demo conventions, not supplier schemas.
2. **Single trust** — all data is DRH; no ICB-resident breakdown.
3. **Calendar reporting month** — primary grain for urgent-care marts unless D005 decides otherwise.
4. **Patient key** — `PatientPseudoId` conformed across CareCall, CareCase, Legendary.
5. **Profiling hypotheses accepted for design** — March case spike may be extract-driven; Jan–Feb may be operational (pending human confirmation).
6. **No real-time** — batch daily/weekly/monthly loads per source cadence in `source_system_overview.md`.
7. **Measures are illustrative** — not RDY-calibrated (per `target_public_measure_alignment.md`).

## Risks

| Risk | Source | Mitigation |
|------|--------|------------|
| Extract rule change inflates cases | Profiling + change log | `is_extract_inclusion_case` flag; separate mart measure |
| Date-boundary mis-reporting | DQ001 | Dual date keys; explicit mart filter |
| Forced match on ambiguous rows | DQ005 | Bridge table; no default in v1 |
| Expired LocalOps mappings | DQ004 | Confidence tier; QA view |
| Orphan FKs in facts | DQ003 | DQ gate; nullable FKs |
| Inferred match false positives | INFERRED_MATCH logic | Bridge only; label in mart |
| Team name drift | LocalOps vs RosterFlow | `team_code` as key; Type 2 names |

## Dependencies on Run 4

- DDL must implement flags and bridge tables before marts.
- QA views must expose monthly contact/case divergence for ongoing demo.

## Out of scope

- Real Azure deployment, ADF live orchestration, PHI handling, national submission compliance.
