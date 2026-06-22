# Dimensional model (logical)

Database: `DemoRiversDWH` (fictional). Schema: `dwh` for dimensions/facts; `mart` for aggregates.

## Dimensions

| Table | Grain | SCD | Key attributes |
|-------|-------|-----|----------------|
| `DimDate` | Calendar day | n/a | fiscal month, NHS reporting month |
| `DimPatient` | PatientPseudoId | Type 1 | NHSNumberDemo (label only), DOB, sex, postcode sector |
| `DimStaff` | SyntheticStaffId | Type 2 optional | usernames per system, mapping confidence, team |
| `DimTeam` | Team code | Type 2 | local vs rosterflow name, cost centre |
| `DimCostCentre` | CostCentreCode | Type 1 | name, department |
| `DimReferralSource` | Source code | Type 1 | MHSDS-style source analogue |
| `DimCaseStatus` | Status | Type 1 | includes admin statuses |

## Facts

| Table | Grain | Measures / degenerate dims |
|-------|-------|---------------------------|
| `FactCareCallContact` | One row per contact | ContactType, Pathway, Outcome, LinkageScenario, queue, abandoned flag |
| `FactCareCallEvent` | One row per event | DurationSeconds, EventType |
| `FactCareCase` | One row per case | Priority, closure reason, extract flags, days to close |
| `FactCareCaseEvent` | One row per case event | EventType |
| `FactClinicianContact` | One row per clinician contact | ContactMode, DurationMinutes, OutcomeCode |
| `FactReferral` | One row per referral | ServiceCode, Urgency, Status |
| `FactAppointment` | One row per appointment | DNAFlag, Status |
| `FactEncounter` | One row per encounter | EncounterType, LocationCode |
| `FactShift` | One row per shift | IsBankShift, UrgentCareFlag, hours |
| `FactAbsence` | One row per absence episode | HoursLost, AbsenceType |
| `FactLedgerPosting` | One row per posting | AmountGBP, SpendType, AccountCode |

## Bridge / factless

| Table | Purpose |
|-------|---------|
| `BridgeCareCallReferralCandidate` | `ContactId` ↔ candidate `ReferralId` from `AmbiguousMatchIds` |
| `BridgeCareCallInferredCase` | `ContactId` ↔ `CaseId` where inference rules met (±24h, same patient) |
| `FactMonthlyProviderMeasure` | Optional snapshot fact for mart feeds |

## Mart (provider-month)

| Table | Grain |
|-------|-------|
| `mart.ProviderMonthUrgentCare` | DRH × reporting month |
| `mart.ProviderMonthFinance` | DRH × financial month × cost centre |

Measures (loose analogues): IUCS contacts, cases opened (operational filter), open referrals stock, agency spend, median days to first clinician contact.

## FK conventions

- Facts reference `DimDate` on event dates (role-playing: contact date vs created date).  
- `FactCareCase` optional FK to `FactCareCallContact` via `SourceContactId` — nullable.  
- Do not require Legendary `SourceCareCallContactId` for fact inclusion.
