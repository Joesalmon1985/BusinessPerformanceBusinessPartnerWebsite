# Source profiling report (demonstration draft)

> **Synthetic demonstration only.** Profile of fictional Demo Rivers Health (DRH) source extracts. Pending human review before warehouse design.

**Prepared by:** Source Profiling Agent (worked example)  
**Inputs:** `source-data/*`, `source_manifest.csv`, profiler outputs (`file_grain_register.csv`, `volume_trends.csv`, `linkage_analysis.csv`, `dq_register.csv`), `localops_extract_change_log.xlsx`  
**Period:** September 2025 – May 2026

---

## 1. Inventory

All 19 files in `source_manifest.csv` are present under `source-data/`. Row counts match manifest for all CSV extracts (see `file_grain_register.csv`, `RowCountMatch=TRUE`).

| System | Files | Total rows (approx.) |
|--------|-------|----------------------|
| CareCall | 2 | 103,726 |
| CareCase | 3 | 28,744 |
| Legendary Care | 4 | 33,396 |
| RosterFlow | 3 | 41,176 |
| LedgerWise | 2 | 7,365 |
| LocalOps | 5 spreadsheets | 163 |

No unexpected gaps. XLSX extracts read successfully via profiler.

---

## 2. Grain and keys

See `file_grain_register.csv` for full register. Summary:

| File | Grain | Primary key | Key foreign keys |
|------|-------|-------------|------------------|
| `carecall_contacts.csv` | One row per contact | `ContactId` | `CareCaseCaseId`, `LegendaryCareReferralId`, `PatientPseudoId` |
| `carecase_cases.csv` | One row per case | `CaseId` | `SourceContactId`, `PatientPseudoId` |
| `legendary_care_referrals.csv` | One row per referral | `ReferralId` | `PatientPseudoId`, `SourceCareCallContactId` |
| `rosterflow_shifts.csv` | One row per shift | `ShiftId` | `SyntheticStaffId` |
| `ledgerwise_ledger.csv` | One row per posting | `LedgerLineId` | `CostCentreCode` |

`CareCaseCaseId` on contacts is not always a valid `CaseId` (47 orphan values per DQ003). Staging should not assume referential integrity without validation.

---

## 3. Date coverage

- CareCall contacts: 2025-09-01 to 2026-05-31  
- CareCase cases opened: 2025-09-01 to 2026-06-01 (small number in 2026-06)  
- Reporting focus: nine calendar months Sep 2025 – May 2026

**Date-boundary pattern (Dec 2025):** 46 IUCS contacts have `ContactDate` one calendar day earlier than `CreatedDateTime` (DQ001). `localops_extract_change_log.xlsx` records a CareCall export schedule change on 2025-12-04 (batch window moved to 02:00 UTC). Staging should flag `date_boundary_mismatch` rather than deduplicating blindly.

---

## 4. Linkage analysis

From `linkage_analysis.csv`:

| LinkageScenario | Contacts | Notes |
|-----------------|----------|-------|
| `NO_CASE` | 16,376 (63%) | Expected for non-IUCS and signposted contacts |
| `DIRECT_CARECASE` | 4,754 | `CareCaseCaseId` populated; most IDs valid in `carecase_cases` |
| `DIRECT_LEGENDARY` | 1,708 | Legendary referral/encounter IDs on contact |
| `INFERRED_MATCH` | 1,250 | No direct ID; requires patient + time-window inference |
| `AMBIGUOUS` | 1,016 | `AmbiguousMatchIds` lists multiple candidates |
| `CALLBACK_DUPLICATE` | 838 | `CallbackOfContactId` populated |

**Direct match quality:** Orphan `CareCaseCaseId` (47 rows) and cases with `SourceContactId` not in `carecall_contacts` require DQ gates before fact loading.

**Recommendation:** Land linkage scenario code in staging; use bridge table for `AMBIGUOUS` and `INFERRED_MATCH`; do not force single match in ETL.

---

## 5. Volume trends

From `volume_trends.csv`:

### CareCall IUCS (monthly)

| Month | IUCS | MoM % |
|-------|------|-------|
| 2025-09 – 11 (baseline) | ~1,263 avg | — |
| 2026-01 | 1,592 | +22.4% vs prior month |
| 2026-02 | 1,477 | -7.2% |
| 2026-03 | 1,272 | -13.9% |

Jan–Feb 2026 show elevated IUCS vs Sep–Nov baseline (DQ007, DQ008). Feb also shows higher urgent-care bank shifts (219 vs ~190 prior months) and agency nursing spend on `CC-URG-401` (~£61k in Feb).

### CareCase cases opened

| Month | Cases opened | Without SourceContactId |
|-------|--------------|-------------------------|
| 2026-02 | 525 | 123 |
| 2026-03 | **542** | **322** |
| 2026-04 | 362 | 151 |

**March 2026 pattern:** Case opens rise (+3% MoM) while IUCS contacts **fall** (-14% MoM). Cases without `SourceContactId` jump from 123 (Feb) to 322 (Mar) — majority of March increase.

`localops_extract_change_log.xlsx` (ChangeDate 2026-02-28, SystemName CareCase) records an inclusion rule change for `NightlyCaseExtract` effective from the March run. **Hypothesis:** March case increase may be extract-driven rather than front-door demand. Requires cross-source corroboration — CareCall IUCS does not support an operational surge in March.

### Jan–Feb operational pattern (alternative hypothesis)

January–February show coordinated signals:

- IUCS contacts elevated vs baseline  
- Case opens elevated (461 Jan, 525 Feb) with most retaining `SourceContactId`  
- Urgent-care bank shifts elevated in Feb  
- Agency nursing spend present on urgent-care cost centre  
- `localops_validation_notes.xlsx` references bank-holiday pressure and recovery plan (Feb 2026)

**Hypothesis:** Jan–Feb uplift may reflect genuine operational pressure, distinct from March pattern.

---

## 6. Extract vs reality

| Observation | CareCall IUCS | CareCase | RosterFlow | LedgerWise | Extract log |
|-------------|---------------|----------|------------|------------|-------------|
| Jan–Feb uplift | Up | Up (with source link) | Bank shifts up | Agency spend | No CareCase rule change |
| March case spike | **Down** | Up (many no source) | Flat/down | Flat | **CareCase inclusion change** |

Before attributing March cases to demand, rule out extract inclusion change.

---

## 7. Data quality register

See `dq_register.csv`. Priority items:

| ID | Severity | Issue |
|----|----------|-------|
| DQ001 | High | Dec 2025 date boundary mismatches (46) |
| DQ002 | High | Cases without SourceContactId (322 in Mar 2026) |
| DQ003 | Medium | Orphan CareCaseCaseId on contacts (47) |
| DQ004 | Medium | Expired LocalOps mappings still present (9) |
| DQ005 | Low | Ambiguous match rows (1,016) |

---

## 8. Staging recommendations

1. **Raw landing:** One table per source file; preserve all columns including `LinkageScenario`, `ExtractInclusionFlag`, `ExtractBatchDate`.
2. **DQ gates before facts:** Referential integrity (contact↔case), date-boundary flag, mapping confidence tier from LocalOps.
3. **Do not collapse ambiguous matches** in staging — route to bridge/link table.
4. **Month attribution:** Use `ContactDate` and `CreatedDateTime` separately; document which drives reporting month for contacts affected by DQ001.
5. **Extract metadata:** Join volume QA to `localops_extract_change_log` by month and system.

**Explicit non-goals for this pass:** No dimensional model, no fact tables, no ADF pipelines.

---

## Open questions for human reviewer

1. Which date column is authoritative for CareCall monthly reporting when DQ001 fires?  
2. Should `ExtractInclusionFlag=1` cases be excluded from operational IUCS conversion metrics?  
3. Confirm LocalOps mapping confidence rules for expired `ValidToDate` rows.  
4. Is the March CareCase increase accepted as extract-driven pending data owner confirmation?

**Status:** Draft — pending Information Lead / Performance & BI sign-off.
