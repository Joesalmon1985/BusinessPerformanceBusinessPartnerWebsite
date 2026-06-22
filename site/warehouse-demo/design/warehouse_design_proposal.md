# Warehouse design proposal (demonstration draft)

> **Synthetic demonstration only.** Conceptual design for Demo Rivers Health (DRH). Not approved for production.

## Executive summary

Profiling (Run 2) identified multi-system urgent-care sources with **imperfect linkage**, **extract-rule sensitivity** (CareCase March 2026) and **operational uplift** (Jan–Feb 2026). This proposal adopts a **medallion architecture** with explicit DQ gates and bridge tables for ambiguous matches.

**Scope:** IUCS front-door pathway slice across CareCall, CareCase, Legendary Care, RosterFlow, LedgerWise and LocalOps mappings.

## Design principles

1. **Land raw, validate in staging** — preserve source columns including `LinkageScenario`, `ExtractInclusionFlag`, export metadata.
2. **Do not force single match** — bridge table for `AMBIGUOUS` and optional inference table for `INFERRED_MATCH`.
3. **Separate extract artefacts from operations** — flag-driven exclusion or parallel reporting measures for `ExtractInclusionFlag` and admin-status cases.
4. **Conform via LocalOps with confidence tiers** — staff/team mappings respect `MappingConfidence` and `ValidToDate`.
5. **Provider-month marts last** — loose MHSDS-style stock/activity measures; not RDY-calibrated.

## Layer diagram

```
source-data (CSV/XLSX)
    → raw.*           (1:1 land)
    → stg.*           (typed, DQ flags)
    → dwh.Dim*        (conformed dimensions)
    → dwh.Fact*       (events and transactions)
    → dwh.Bridge*     (ambiguous / inferred linkage)
    → mart.ProviderMonth*  (aggregates for reporting)
```

## Key profiling inputs

| Finding | Design response |
|---------|-----------------|
| March cases without SourceContactId | Staging flag `is_extract_inclusion_case`; mart filter for operational cases |
| Dec date-boundary mismatches | Staging `date_boundary_mismatch_flag`; separate reporting date columns |
| Ambiguous Legendary matches | `BridgeCareCallReferralCandidate` |
| Expired LocalOps mappings | `DimStaff` mapping confidence attribute |
| Jan–Feb multi-source uplift | No special model — preserved in facts for trend analysis |

## Open decisions (see human_review_pack.md)

1. Operational case definition — exclude `ExtractInclusionFlag=1`?  
2. Primary contact reporting date when `date_boundary_mismatch_flag=1`.  
3. SCD type for `DimTeam` given name drift.  
4. Whether inferred matches enter facts automatically or via reviewer approval table.

## Related documents

- [`staging_model.md`](staging_model.md)
- [`dimensional_model.md`](dimensional_model.md)
- [`conformed_dimensions.md`](conformed_dimensions.md)
- [`linkage_resolution_strategy.md`](linkage_resolution_strategy.md)
- [`design_assumptions_and_risks.md`](design_assumptions_and_risks.md)

**Status:** Draft — pending human review.
