# Conformed dimensions

## Staff (`DimStaff`)

**Source of truth for cross-system identity:** `stg.LocalOpsUserMapping` joined to `stg.RosterFlowStaff`.

| MappingConfidence | ETL behaviour |
|-------------------|---------------|
| High | Auto-conform usernames across systems |
| Medium | Conform with `mapping_review_required_flag` |
| Low | Conform for rostering only; nullable usernames elsewhere |
| Expired ValidToDate | Set `mapping_expired_flag`; still allow join with warning (DQ004) |

**Attributes:** `SyntheticStaffId`, `DisplayName`, `CareCallUsername`, `CareCaseUsername`, `LegendaryCareUsername`, `RosterFlowUsername`, `LedgerWiseUsername`, `PrimaryTeamKey`, `CostCentreKey`.

## Team (`DimTeam`)

**Sources:** `stg.LocalOpsTeamMapping` + RosterFlow team codes.

Handle name drift (`IUCS Hub` vs `Urgent Care Centre`) via:

- `team_code` as business key (stable)
- `local_team_name`, `rosterflow_team_name` as attributes
- Optional Type 2 when mapping notes indicate rename

## Patient (`DimPatient`)

**Source:** `stg.LegendaryPatient` enriched with CareCall `PatientPseudoId` / `NHSNumberDemo`.

`NHSNumberDemo` stored as label only — not validated as NHS number.

## Cost centre (`DimCostCentre`)

**Source:** `stg.LedgerCostCentre` + LocalOps team mapping `CostCentreCode`.

## Date (`DimDate`)

Generate calendar 2025-09-01 through 2026-06-30 for demo window.

Include `reporting_month_label` (YYYY-MM) for provider-month marts.

## Extract change dimension (optional)

`DimExtractChange` from `stg.LocalOpsExtractChangeLog` for QA joins — not slowly changing; insert new row per change event.
