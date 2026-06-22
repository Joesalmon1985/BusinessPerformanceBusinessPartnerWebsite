# Staging model (logical)

One staging table per source extract. All tables include `load_batch_id`, `source_file_name`, `loaded_at_utc`.

## CareCall

### stg.CareCallContact
Source: `carecall_contacts.csv`

| Column group | Treatment |
|--------------|-----------|
| All source columns | Land as-is |
| `ContactDate`, `CreatedDateTime` | `DATETIME2`; compute `date_boundary_mismatch_flag` (DQ001) |
| `LinkageScenario` | Preserve enum |
| DQ | Orphan `CareCaseCaseId` → `orphan_case_id_flag` |

### stg.CareCallEvent
Source: `carecall_call_events.csv` — FK `ContactId` → stg.CareCallContact

## CareCase

### stg.CareCase
Source: `carecase_cases.csv`

| Derived column | Logic |
|----------------|-------|
| `is_extract_inclusion_case` | `ExtractInclusionFlag = 1` OR empty `SourceContactId` with admin status |
| `is_operational_case` | Inverse filter for IUCS ops metrics (TBD — human decision) |
| `opened_reporting_month` | From `OpenedDateTime` |

### stg.CareCaseEvent / stg.CareCaseClinicianContact
Source: case events and clinician contacts — FK `CaseId`

## Legendary Care

### stg.LegendaryPatient, stg.LegendaryReferral, stg.LegendaryAppointment, stg.LegendaryEncounter
Land all columns. `SourceCareCallContactId` nullable — do not inner-join to contacts in staging.

## RosterFlow / LedgerWise

### stg.RosterFlowStaff, stg.RosterFlowShift, stg.RosterFlowAbsence
### stg.LedgerCostCentre, stg.LedgerPosting

## LocalOps (spreadsheet land)

### stg.LocalOpsUserMapping, stg.LocalOpsTeamMapping, stg.LocalOpsValidationNote, stg.LocalOpsExtractChangeLog, stg.LocalOpsWaitingListAdjustment

## DQ gates (from dq_register.csv)

| Gate ID | Staging action |
|---------|----------------|
| DQ001 | Set `date_boundary_mismatch_flag` |
| DQ002 | Set `missing_source_contact_flag` on cases |
| DQ003 | Set `orphan_case_id_flag` on contacts |
| DQ004 | Set `mapping_expired_flag` on staff joins |
| DQ005 | Route rows to bridge load queue |
| DQ006 | Join extract change log to monthly QA summary |

## Load order

1. LocalOps dimensions (mapping)  
2. CareCall contacts → events  
3. CareCase cases → events → clinician contacts  
4. Legendary patients → referrals → appointments → encounters  
5. RosterFlow → LedgerWise
