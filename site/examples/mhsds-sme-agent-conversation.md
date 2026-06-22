# Worked example: MHSDS Expert Agent conversation

**Demonstration only.** Synthetic aggregate data. Not an official Dorset HealthCare report or live Trust agent.

## What this example shows

This is an **illustrative worked example** — not a verbatim chat transcript. It demonstrates how the MHSDS Expert Agent would trace a local figure to source, separate data-quality from operational hypotheses, and refuse to approve publication without human sign-off.

This example uses **synthetic demonstration data only**. It is a different strand from the public RDY briefs — there is no June 2026 improvement pass or automated validation script for this SME demo.

<h2 id="evidence-chain">Evidence chain</h2>

### Agent rule

- [MHSDS Expert Agent rule](../agent-rules/mhsds-expert-agent.md)

### Evidence data

- [Synthetic aggregate data](../data/synthetic_mhsds_sme_demo.csv) — pre-aggregated demo figures cited in the dialogue
- [MHSDS source pack register](../public-data/mhsds-source-pack-register.csv) — approved national source references

### Definitions

- [Synthetic local dictionary](../docs/synthetic-mhsds-local-dictionary.md) — local metric lineage and calculation logic

### Related public brief (separate strand)

- [Public MHSDS access profile](../reports/public-mh-access-profile.html) — uses real public MHSDS aggregates for RDY; not connected to the synthetic SME demo above

### Checks and scripts

No automated validation script applies to this synthetic SME strand — figures are illustrative only.

---

## Turn 1 — Why has this gone up?

**User:**

I'm drafting the March directorate pack. Synthetic All Age MH access contacts have jumped from 1,240 to 1,610. Why has this gone up?

**MHSDS Expert Agent:**

The first thing I would check is whether this is a real activity increase or a recording / extraction change.

**What this figure is based on locally**

In the synthetic local dictionary (`docs/synthetic-mhsds-local-dictionary.md`), **Synthetic All Age Mental Health Access Contacts** is a local demo metric based on attended mental health contacts recorded in RiO for selected all-age mental health teams. It is **not** an official Trust definition or a direct MHSDS return output.

**Synthetic lineage (demonstration only)**

```
RiO contact / appointment record (DemoMHContactForm)
  → StgMHSDSContactExtractDemo
  → FactMHSDSContactDemo
  → join DimMHSDSServiceTeamDemo (AllAgeMHFlag = 1)
  → count where ContactStatusCode = 'ATT' and ContactMonth = reporting month
  → aggregate in synthetic_mhsds_sme_demo.csv
```

Key fields on the synthetic RiO form: `ContactStatusCode`, `ContactDate`, `AppointmentType`, `TeamCode`.

**What the data shows**

| Month | Attended contacts | Referrals received |
|-------|-------------------|--------------------|
| 2026-02 | 1,240 | 920 |
| 2026-03 | 1,610 | 985 |

Movement: **+370 contacts**, approximately **+29.8%** month-on-month.

March also includes **180 late-recorded contacts** in the synthetic data (`LateRecordedFlag = 1`), so I would not assume this is purely a demand increase.

**Data-quality issues that could cause the figure to rise**

1. RiO contact form or appointment recording process changed
2. Teams using `DemoMHContactForm` differently this month (e.g. recording contacts that were previously missed)
3. New team added to `DimMHSDSServiceTeamDemo` with `AllAgeMHFlag = 1`
4. Duplicate contacts appearing in `FactMHSDSContactDemo` (dedup rule not applied consistently)
5. Attended / DNA / cancelled status mapping changed in `ContactStatusCode`
6. Late-recorded contacts counted in March rather than the month they occurred
7. Extract logic change in `StgMHSDSContactExtractDemo` (nightly load, filter or join change)

**Operational changes that could cause the figure to rise**

- Backlog clearance clinic or additional capacity in March (noted in demo Crisis Resolution scenario)
- Higher referral demand (referrals rose ~7.1% in synthetic data — smaller than the contact increase)
- Staffing or session template changes increasing available appointments

**Checks I would run before using this in a pack**

1. Has the RiO contact form or appointment recording process changed?
2. Are teams using the form differently this month?
3. Has a new team been added to the All Age MH mapping in `DimMHSDSServiceTeamDemo`?
4. Are duplicate contacts appearing in `FactMHSDSContactDemo`?
5. Has attended / DNA / cancelled status mapping changed?
6. Are late-recorded contacts being counted in March rather than the month they occurred?
7. Was there a backlog clearance clinic or additional capacity in March?

**National MHSDS context (background only)**

MHSDS is a person-based secondary uses data set for mental health services (`mhsds_standards_directory`). This local demo metric is **inspired by** contact-count reporting concepts but is not validated against a specific national published measure. I am not quoting ETOS derivations for this count.

**Draft directorate pack wording (pending human review)**

> All Age MH access contacts rose from 1,240 to 1,610 (+29.8%) in March 2026. This may reflect increased activity and/or recording effects, including 180 late-recorded contacts in the synthetic data. The metric counts attended RiO contacts for selected all-age MH teams per local warehouse logic. Definition and data quality checks are in progress — confirm with Information Lead before finalising.

---

## Turn 2 — Where does the figure come from?

**User:**

Where does this figure actually come from — is it straight from an MHSDS return?

**MHSDS Expert Agent:**

No — this is **not** a figure pulled directly from an MHSDS submission. It is a **local warehouse metric** built from RiO contact records through the synthetic demo ETL chain.

**Source to aggregate — step by step**

| Step | Synthetic object | What happens |
|------|------------------|--------------|
| 1 | `DemoMHContactForm` (RiO) | Clinician or admin records contact; sets `ContactStatusCode`, `ContactDate`, `TeamCode` |
| 2 | `StgMHSDSContactExtractDemo` | Nightly extract from RiO; one row per contact event with raw field values |
| 3 | `DimMHSDSServiceTeamDemo` | Maps `TeamCode` to service group and `AllAgeMHFlag`; excludes inpatient, LD/autism, IAPT teams |
| 4 | `FactMHSDSContactDemo` | ETL loads staged rows; applies dedup (`ROW_NUMBER()` on PersonID + ContactDate + TeamCode); sets `LateRecordedFlag` where applicable |
| 5 | Reporting query | Count attended contacts in reporting month for All Age MH teams |
| 6 | `synthetic_mhsds_sme_demo.csv` | Pre-aggregated demo output used in this worked example |

**Included teams (synthetic mapping)**

- Demo Community MH Access Team
- Demo All Age Crisis Resolution Team
- Demo Primary Care Liaison MH Service

**Relationship to MHSDS**

National MHSDS (`mhsds_data_model_v60`) includes person-level care contact tables that Trusts ultimately submit from PAS/EHR sources. This demo metric uses similar *concepts* (attended contacts by team and month) but has **not** been mapped to a specific MHSDS derivation or published measure code. Mapping validation would be an Information Lead task on real data.

---

## Turn 3 — How is it calculated?

**User:**

Walk me through how Synthetic All Age Mental Health Access Contacts is calculated.

**MHSDS Expert Agent:**

**Calculation logic (synthetic demo)**

From the local dictionary pseudologic:

```sql
SELECT COUNT(*)
FROM FactMHSDSContactDemo f
JOIN DimMHSDSServiceTeamDemo d ON f.TeamCode = d.TeamCode
WHERE f.ContactStatusCode = 'ATT'
  AND f.ContactMonth = @ReportingMonth
  AND d.AllAgeMHFlag = 1
```

**Filters applied**

| Filter | Value | Effect |
|--------|-------|--------|
| Contact status | `'ATT'` (attended) | Excludes DNA, cancelled, did not attend |
| Reporting month | `ContactMonth = @ReportingMonth` | Calendar month boundary |
| Team scope | `AllAgeMHFlag = 1` | Only mapped all-age MH access teams |
| Dedup | Earliest row per PersonID + ContactDate + TeamCode | Prevents double-counting same contact event |

**March 2026 breakdown (synthetic)**

| Service group (`DimMHSDSServiceTeamDemo`) | Attended contacts |
|---------------------------------------------|-------------------|
| Demo Community MH Access Team | 720 |
| Demo All Age Crisis Resolution Team | 490 |
| Demo Primary Care Liaison MH Service | 400 |
| **Combined total** | **1,610** |

February combined total: 1,240. Movement: +370 (~29.8%).

**Late-recorded contacts**

180 contacts in March have `LateRecordedFlag = 1` — the contact occurred in an earlier month but was recorded or extracted into March. These inflate the March count unless you understand and caveat them.

**Dedup note**

If the `ROW_NUMBER()` dedup in `FactMHSDSContactDemo` changed between February and March (e.g. ETL release), the count could move without any change in clinical activity. Worth checking with the BI team.

---

## Turn 4 — Does this mean performance has deteriorated?

**User:**

Does this increase mean performance has deteriorated?

**MHSDS Expert Agent:**

Not necessarily — and I cannot give a performance verdict. An increase in attended contacts can mean different things depending on whether the driver is data quality or operations.

**If the rise is data-quality driven**

- Form usage or recording practice changed → more contacts captured, not more care delivered
- Status coding changed → contacts reclassified from DNA/cancelled to attended
- Team mapping expanded → more teams now counted in All Age MH scope
- Late recording or extract timing → contacts attributed to March that belong elsewhere
- Duplicate rows in `FactMHSDSContactDemo` → inflated count

**If the rise is operationally driven**

- More people seen (which could indicate **improved access**)
- Backlog clearance or additional clinic capacity
- Higher demand following referral increase (~7.1% in synthetic data)

**What the data shows (observation only)**

Contacts rose ~29.8% while referrals rose ~7.1%. The contact increase is disproportionate to referral growth, which points toward recording/extraction effects **or** a step-change in conversion from referral to attended contact — but I cannot determine which without the checks from Turn 1.

**Questions for service leads**

- Did March include a backlog clearance initiative or extra clinic sessions?
- Have any teams changed how they record contacts in RiO?
- Is the increase concentrated in one team (Community MH contributed 720 of 1,610)?

I can help you frame these as investigation questions for the directorate pack — I cannot conclude whether performance has improved or deteriorated.

---

## Turn 5 — Can I use this in the pack?

**User:**

Can I use this figure in the March directorate report?

**MHSDS Expert Agent:**

**Not yet as a final figure.** It can appear as **draft wording with caveats** only until the checks below are complete and a human owner signs off.

**Minimum checks still outstanding**

*Data quality (Information Lead):*

- Confirm `DimMHSDSServiceTeamDemo` mapping has not changed between February and March
- Validate dedup logic in `FactMHSDSContactDemo` is consistent across both months
- Review the 180 late-recorded contacts — decide whether to caveat or re-attribute
- Confirm `ContactStatusCode` mapping has not changed

*Operational context (Performance Manager):*

- Confirm with service leads whether backlog clearance or capacity changes explain part of the movement
- Agree proportionate caveats for the directorate narrative

**Sign-off required**

Information Lead (MHSDS accountability) and Performance Manager must review and sign off before this figure is treated as final in the directorate pack. I cannot sign off, submit an MHSDS return, or treat this demo as operationally validated against live Trust systems.

**Suggested status label for the pack**

> Draft — pending Information Lead and Performance Manager review.

---

## Closing summary

| Item | Detail |
|------|--------|
| Local lineage | RiO `DemoMHContactForm` → `StgMHSDSContactExtractDemo` → `FactMHSDSContactDemo` + `DimMHSDSServiceTeamDemo` |
| Calculation | Count attended contacts (`ContactStatusCode = 'ATT'`) in reporting month for All Age MH teams |
| Movement | +370 contacts (~29.8%) Feb→Mar 2026; 180 late-recorded in March |
| Likely drivers | Recording/extraction change and/or operational change — not confirmed |
| Draft wording | Offered in Turn 1 — pending human review |
| Report use (Turn 5) | Draft with caveats only until checks complete and sign-off obtained |
| National MHSDS | Background context only — no specific measure code claimed |
