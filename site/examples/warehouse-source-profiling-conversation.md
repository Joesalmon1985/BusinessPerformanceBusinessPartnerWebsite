# Worked example: Source Profiling Agent conversation

**Demonstration only.** Synthetic DRH source extracts. Not a live Trust agent.

## Supporting files

- [Source Profiling Agent rule](../agent-rules/source-profiling-agent.md)
- [Source profiling report](../warehouse-demo/profile-output/source_profiling_report.md)
- [Volume trends](../warehouse-demo/profile-output/volume_trends.csv)
- [DQ register](../warehouse-demo/profile-output/dq_register.csv)
- [Extract change log](../warehouse-demo/source-data/localops_extract_change_log.xlsx)

---

## Turn 1 — Why did CareCase cases jump in March?

**User:**

CareCase cases opened went from 525 in February to 542 in March. Is urgent care demand increasing?

**Source Profiling Agent:**

I would not assume operational demand from the case count alone. Cross-source evidence does not support a front-door surge in March.

**Volume evidence** (`volume_trends.csv`):

| Month | IUCS contacts | Cases opened | Cases without SourceContactId |
|-------|---------------|--------------|-------------------------------|
| 2026-02 | 1,477 | 525 | 123 |
| 2026-03 | 1,272 | 542 | 322 |

IUCS contacts **fell** 13.9% month-on-month in March while cases opened rose slightly. The increase in cases without `SourceContactId` (123 → 322) accounts for most of the March movement.

**Extract change evidence** (`localops_extract_change_log.xlsx`):

- ChangeDate 2026-02-28, SystemName CareCase, ExtractName NightlyCaseExtract  
- ChangeType: Inclusion rule change — PendingAdminClosure and AwaitingSignoff included from March run  
- ExpectedImpact field notes higher case counts from March; not activity-led

**Hypothesis (draft):** March case increase may be **extract-driven**. CareCall IUCS does not corroborate operational demand.

**Checks before using March cases in a pack:**

1. Filter cases with empty `SourceContactId` and review `CaseStatus` / `ExtractInclusionFlag`.  
2. Compare to CareCall IUCS trend for same month.  
3. Confirm with data owner whether inclusion rule changed.

**Status:** Draft finding — pending human review.

---

## Turn 2 — What about January and February?

**User:**

January and February also look busy. Is that the same issue?

**Source Profiling Agent:**

January–February look different from March — multiple sources move together.

**CareCall** (`volume_trends.csv`): IUCS 1,592 in Jan (+22% vs Dec), 1,477 in Feb — both above Sep–Nov baseline (~1,263).

**CareCase:** Cases opened 461 (Jan) and 525 (Feb); most rows retain `SourceContactId` (only 123 without in Feb vs 322 in Mar).

**RosterFlow:** Urgent-care bank shifts 219 in Feb vs ~190 in prior months.

**LedgerWise:** Agency nursing spend on `CC-URG-401` ~£61k in Feb (`volume_trends.csv`, AgencyNursingSpendGBP).

**LocalOps** (`localops_validation_notes.xlsx`): Notes dated Feb 2026 reference bank-holiday pressure and recovery plan.

**Hypothesis (draft):** Jan–Feb pattern is **multi-source operational uplift**, not the same mechanism as March.

---

## Turn 3 — Can we start building the warehouse?

**User:**

OK — propose the fact tables.

**Source Profiling Agent:**

That is outside this agent's brief. Profiling is complete; staging recommendations are in `source_profiling_report.md` section 8.

**Next step:** Hand off to Warehouse Design Agent with `suggested_run3_agent_task.md`. Do not skip design review.

**Required sign-off before build:** Information Lead / Performance & BI (demo roles).
