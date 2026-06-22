# Expected synthetic load counts

> **Run 4 SQL verification aid.** Separate from Run 1 `human_reviewer_answer_key.md`.  
> Counts match `source_manifest.csv` from synthetic source pack (seed 42).

## raw / stg row counts (post full load)

| Table | Expected rows | Source file |
|-------|---------------|-------------|
| raw.CareCallContact | 25,942 | carecall_contacts.csv |
| raw.CareCase | 3,631 | carecase_cases.csv |
| raw.LegendaryReferral | 7,928 | legendary_care_referrals.csv |
| raw.RosterFlowShift | 40,926 | rosterflow_shifts.csv |
| raw.LedgerPosting | 7,360 | ledgerwise_ledger.csv |

## QA view expectations

### qa.MonthlyContactCaseTrend

| ReportingMonth | IUCSContactCount (approx) | CaseOpenedCount (approx) | CasesWithoutSourceContact (approx) |
|----------------|---------------------------|--------------------------|-------------------------------------|
| 2026-02 | 1,477 | 525 | 123 |
| 2026-03 | 1,272 | 542 | 322 |

March: cases up, IUCS down, cases without source contact sharply up.

### qa.OrphanCareCaseSourceContact

Non-zero orphan `SourceContactId` rows possible (background noise).

### qa.ExpiredLocalOpsMappingInUse

~9 rows with expired `ValidToDate` per profiling DQ004.

## mart.ProviderMonthUrgentCare

Populated by Run 5 measure builder or ADF mart refresh spec — 9 months × 1 provider (DRH).
