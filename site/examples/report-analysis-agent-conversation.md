# Worked example: Report Analysis Agent conversation

**Demonstration only.** Synthetic flawed draft v0.3. Not an official Dorset HealthCare report or live Trust agent.

## Supporting files

- [Report Analysis and Improvement Agent rule](../agent-rules/report-analysis-agent.md)
- [Flawed draft input](synthetic-draft-talking-therapies-flawed.md)
- [Corrected Talking Therapies brief (after improvement pass)](../reports/public-talking-therapies-profile.html)
- [Demo CSV](../public-data/processed/demo_talking_therapies.csv)
- [Final report QA summary](../public-data/FINAL_REPORT_QA_SUMMARY.md)
- [Post-render validation script](../R/04_validate_public_reports.R)

---

## Turn 1 — Please review this draft

**User:**

I've drafted a Talking Therapies access brief for our directorate huddle. Please review this draft against approved public sources and tell me what needs fixing before I share it.

Attached: `synthetic-draft-talking-therapies-flawed.md`

**Report Analysis Agent:**

## Review summary

- **Report:** IAPT six-month access brief — author draft v0.3
- **Classification:** public aggregate (Provider / RDY demo extract)
- **Reviewed against:** report-analysis-agent.md v1.0
- **Demonstration only** — not a live Trust agent

I reviewed the draft against `demo_talking_therapies.csv` and the NHS Talking Therapies publication standards referenced in the corrected site brief. Below are numbered findings with evidence. I have **not** approved this draft for publication.

## Findings

| # | Severity | Step | Finding | Evidence | Type | Confidence |
|---|----------|------|---------|----------|------|------------|
| 1 | Critical | 4 | KFE row labels **M019–M022 total: 5,870** but four-band sum is **6,780** | Draft KFE vs CSV: M019=4705, M020=705, M021=460, M022=910 → 5870+910=6780. Would fail `check_tt_wait_totals`. | Fact | confirmed |
| 2 | Major | 3 | **“Six-month trend”** for Aug 2025–Apr 2026 uses **six non-consecutive** data points (gaps: no Sep, Dec, Mar) | Draft trend note lists Aug, Oct, Nov, Jan, Feb, Apr only | Fact | confirmed |
| 3 | Major | 5 | M053 says **no verified national threshold** — **75% six-week** and **95% eighteen-week** standards exist in NHS Digital publication | Standard not in extract row alone; documented in national Talking Therapies statistics | Interpretation | confirmed |
| 4 | Major | 7–8 | **Trend column mixes** “Falling” with “Finance sign-off required” | Violates KFE model; would fail `check_kfe_trend_column` | Fact | confirmed |
| 5 | Major | 9 | Judgement **“Performance is strong”** misses **above 75% standard but falling** (95→88 in window) | Draft trend note + M053=88% vs 75% standard | Interpretation | confirmed |
| 6 | Major | 2, 8 | **Finance check** on M053 access metric — wrong owner; should be **pathway / data-definition** | Generic finance wording copied from finance reports | Recommendation | confirmed |
| 7 | Major | 1 | Title uses legacy **“IAPT”** and **“six-month”** — national name is **NHS Talking Therapies**; period is six data points not six consecutive months | Draft title vs Apr 2026 publication naming | Recommendation | confirmed |
| 8 | Minor | 9 | **Self-referrals (M002=1,370, ~76% of M001=1,815)** buried in audit — material demand-route insight | `demo_talking_therapies.csv` M001, M002 rows | Interpretation | confirmed |
| 9 | Minor | 5, 9 | No **18-week access (M055=99%)** or signpost that complete access view needs both standards | CSV M055 row present; draft omits | Recommendation | confirmed |
| 10 | Minor | 9 | No **bottom-line** paragraph for non-technical reader; no **Provider/RDY scope** badge | Would fail `check_required_sections` on rendered briefs | Recommendation | confirmed |

---

## Turn 2 — Revised wording (excerpt)

**Report Analysis Agent:**

### M053 — Six-week access (draft KFE row)

> **M053 — Six-week access (finished course):** 88% (Apr 2026).  
> **Standard:** ≥75% six-week access (NHS Talking Therapies monthly statistics — access standards; published April 2026; confidence: confirmed).  
> **Trend:** Falling.  
> **Validation:** Pathway / data-definition check required.  
> **Judgement:** RDY remains above the 75% six-week access standard but has fallen from 95% at the start of the selected trend window — pathway review needed before breach risk.  
> **Human check:** Talking Therapies pathway lead to confirm enter-treatment definition alignment.

`DRAFT — REQUIRES HUMAN REVIEW`

### M019–M022 waiting bands (draft KFE row)

> **Latest:** M019–M021: **5,870**; M019–M022: **6,780** (Apr 2026).  
> **Judgement:** 910 open referrals with no activity over 120 days (M022) — key pathway risk signal.  
> **Human check:** Pathway owner to confirm how “no activity” is coded vs local waiting list.

### Suggested headline (draft)

> Six-week access remains above the 75% national standard at 88%, but the selected trend window shows a falling pattern. Self-referrals account for most referrals (M002: 1,370 of 1,815). Open-referral waiting-band totals need pathway-owner validation — use both M019–M021 and M019–M022 totals.

### Suggested period caption

> **Period:** Six available monthly data points: Aug 2025 – Apr 2026 (non-consecutive months in extract).

---

## Turn 3 — Human validation register

| Item | Owner | Status |
|------|-------|--------|
| Correct M019–M022 totals and band labels | Report author | pending |
| Confirm M053 / M055 denominators and local enter-treatment tracking | Talking Therapies pathway lead | needs owner confirmation |
| Confirm suppression handling (36/200 rows) | Information Lead | conditional |
| Apply period caption and NHS Talking Therapies naming | Report author | pending |

## IG / Safety handoff

**Recommendation: PASS** (for this public aggregate demo — no PID detected, no unpublished internal documents cited).

Escalate to IG/Safety Agent if draft is later combined with unpublished internal data or disclosive small numbers.

---

## Turn 4 — Can I publish this now?

**User:**

Can I publish this to the directorate huddle now?

**Report Analysis Agent:**

**No.** I cannot approve publication.

**Blocking items:**

1. **Critical #1** — waiting-band total error must be corrected and verified against `demo_talking_therapies.csv` (M019–M021 = 5,870; M019–M022 = 6,780).
2. **Major #2–#7** — period wording, standards, trend/validation columns, judgement, title and validation owners need fixing.
3. **Human validation register** — all items remain open.

**Required sign-off before any share:**

- Report author (apply corrections)
- Performance Manager or Business & Performance Business Partner (review findings)
- Talking Therapies pathway lead (M053/M055 definition confirmation)
- IG / Safety Agent PASS if workflow includes unpublished material (not required for this public demo only)

**Status label:** Draft — pending named human sign-off.

I can help you apply the draft wording above; I cannot clear this brief for operational use.

---

## Closing summary

| Item | Detail |
|------|--------|
| Input | Flawed draft v0.3 (`synthetic-draft-talking-therapies-flawed.md`) |
| Critical finding | M019–M022 total mislabelled (5,870 vs 6,780) |
| Script checks | Would fail `check_tt_wait_totals`, `check_kfe_trend_column`, `check_required_sections` |
| After reference | [Corrected brief](../reports/public-talking-therapies-profile.html) from June 2026 improvement pass |
| Publication | **Not approved** — human sign-off required |
