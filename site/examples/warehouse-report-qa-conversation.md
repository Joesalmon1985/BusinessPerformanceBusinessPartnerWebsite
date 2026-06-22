# Worked example: Warehouse report QA conversation

**Demonstration only.**

## What this example shows

This is a **curated worked example** from **Run 5** of the Demo Rivers Health warehouse demo — not a verbatim chat transcript. It follows the same flawed-draft → QA review → corrected brief chain as the [public Talking Therapies QA example](report-analysis-agent-conversation.md), but on synthetic DRH mart data.

<h2 id="evidence-chain">Evidence chain</h2>

### Agent rule and inputs / outputs

- [Report Analysis Agent rule](../agent-rules/report-analysis-agent.md) — QA framework applied to synthetic brief
- [Flawed draft](warehouse-draft-urgent-care-brief-flawed.md) — deliberate errors including "42% surge" claim (QA-11 in internal audit)
- [Corrected brief](../warehouse-demo/reports/urgent-care-provider-month-brief.html) — post-QA outcome

### Evidence data

- [Volume trends](../warehouse-demo/profile-output/volume_trends.csv) — IUCS contacts, cases opened, cases without SourceContactId
- [Provider-month measures mart](../warehouse-demo/marts/demo_provider_month_measures.csv) — corrected brief measure columns
- [Extract change log](../warehouse-demo/source-data/localops_extract_change_log.xlsx) — CareCase inclusion rule change (March 2026)

### Checks and scripts

- [Measure builder script](../warehouse-demo/generator/build_provider_month_measures.py) — generates mart CSV from synthetic sources

### Audit trail

- [Runs 2–5 internal QA](../warehouse-demo/checkpoints/runs_2_5_internal_qa.md) — QA-11 documents intentional "42% surge" error in flawed draft
- [Demo run index](../warehouse-demo/source-notes/demo_run_index.md) — Run 5 artefact register

---

## Turn 1 — Review the March headline

**User:**

The draft says March case surge proves the recovery plan worked. Is that supported?

**Report Analysis Agent:**

**No — blocking issue.**

Evidence from [volume_trends.csv](../warehouse-demo/profile-output/volume_trends.csv):

| Month | IUCS contacts | Cases opened | Cases without SourceContactId |
|-------|---------------|--------------|-------------------------------|
| 2026-02 | 1,477 | 525 | 123 |
| 2026-03 | 1,272 | 542 | 322 |

IUCS contacts **fell** 13.9% in March. Cases without `SourceContactId` rose from 123 to 322 — most of the March movement.

[localops_extract_change_log.xlsx](../warehouse-demo/source-data/localops_extract_change_log.xlsx) records a CareCase inclusion rule change effective March run. The draft did not reference this.

**Severity:** Critical — misattributes extract-driven movement as operational success.

---

## Turn 2 — Stock vs activity error

**User:**

The draft uses cases opened and IUCS contacts interchangeably. Flag it.

**Report Analysis Agent:**

**Major issue.** IUCS contacts are **activity** in-period. Open referrals are **stock** at a point in time. Case opens are flow, not stock.

Corrected brief must separate measures and cite [demo_provider_month_measures.csv](../warehouse-demo/marts/demo_provider_month_measures.csv) columns explicitly.

---

## Turn 3 — Can we publish?

**User:**

Board pack tomorrow — OK to publish?

**Report Analysis Agent:**

**No.**

Blocking: Critical March interpretation; Major stock/activity conflation; missing extract-change caveat; no human sign-off.

Required: Performance & BI lead, Urgent Care pathway lead, Information Lead (demo roles).

See corrected brief: [urgent-care-provider-month-brief.html](../warehouse-demo/reports/urgent-care-provider-month-brief.html)

---

## Closing summary

| Item | Detail |
|------|--------|
| Input | [Flawed draft](warehouse-draft-urgent-care-brief-flawed.md) — intentional "42% surge" and stock/activity errors |
| Critical finding | March case rise misattributed as operational success; IUCS contacts fell 13.9% |
| Evidence | [volume_trends.csv](../warehouse-demo/profile-output/volume_trends.csv), [extract change log](../warehouse-demo/source-data/localops_extract_change_log.xlsx) |
| After reference | [Corrected brief](../warehouse-demo/reports/urgent-care-provider-month-brief.html) |
| Audit note | QA-11 in [Runs 2–5 internal QA](../warehouse-demo/checkpoints/runs_2_5_internal_qa.md) |
| Publication | **Not approved** — human sign-off required |
