# Worked example: Warehouse report QA conversation

**Demonstration only.**

## Supporting files

- [Flawed draft](warehouse-draft-urgent-care-brief-flawed.md)
- [Corrected brief](../warehouse-demo/reports/urgent-care-provider-month-brief.html)
- [Report Analysis Agent](../agent-rules/report-analysis-agent.md)
- [Volume trends](../warehouse-demo/profile-output/volume_trends.csv)

---

## Turn 1 — Review the March headline

**User:**

The draft says March case surge proves the recovery plan worked. Is that supported?

**Report Analysis Agent:**

**No — blocking issue.**

Evidence from `volume_trends.csv`:

| Month | IUCS contacts | Cases opened | Cases without SourceContactId |
|-------|---------------|--------------|-------------------------------|
| 2026-02 | 1,477 | 525 | 123 |
| 2026-03 | 1,272 | 542 | 322 |

IUCS contacts **fell** 13.9% in March. Cases without `SourceContactId` rose from 123 to 322 — most of the March movement.

`localops_extract_change_log.xlsx` records a CareCase inclusion rule change effective March run. The draft did not reference this.

**Severity:** Critical — misattributes extract-driven movement as operational success.

---

## Turn 2 — Stock vs activity error

**User:**

The draft uses cases opened and IUCS contacts interchangeably. Flag it.

**Report Analysis Agent:**

**Major issue.** IUCS contacts are **activity** in-period. Open referrals are **stock** at a point in time. Case opens are flow, not stock.

Corrected brief must separate measures and cite `demo_provider_month_measures.csv` columns explicitly.

---

## Turn 3 — Can we publish?

**User:**

Board pack tomorrow — OK to publish?

**Report Analysis Agent:**

**No.**

Blocking: Critical March interpretation; Major stock/activity conflation; missing extract-change caveat; no human sign-off.

Required: Performance & BI lead, Urgent Care pathway lead, Information Lead (demo roles).

See corrected brief: `warehouse-demo/reports/urgent-care-provider-month-brief.html`
