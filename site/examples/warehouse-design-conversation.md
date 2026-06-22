# Worked example: Warehouse Design Agent conversation

**Demonstration only.**

## What this example shows

This is a **curated worked example** from **Run 3** of the Demo Rivers Health warehouse demo — not a verbatim chat transcript. The dialogue shows how the Warehouse Design Agent translates profiling evidence into staging and dimensional design decisions. Key numbers (322 of 542 March cases without `SourceContactId`, 47 orphan IDs) trace directly to [profiler outputs](../warehouse-demo/profile-output/volume_trends.csv).

<h2 id="evidence-chain">Evidence chain</h2>

### Agent rule

- [Warehouse Design Agent rule](../agent-rules/warehouse-design-agent.md)

### Evidence data

- [Volume trends](../warehouse-demo/profile-output/volume_trends.csv) — March case / IUCS divergence cited in Turn 2
- [Linkage analysis](../warehouse-demo/profile-output/linkage_analysis.csv) — DIRECT, INFERRED, AMBIGUOUS match counts
- [DQ register](../warehouse-demo/profile-output/dq_register.csv) — DQ003 orphan case IDs (47)

### Design outputs

- [Source profiling report](../warehouse-demo/profile-output/source_profiling_report.md) — input from Run 2
- [Linkage resolution strategy](../warehouse-demo/design/linkage_resolution_strategy.md) — layered linkage approach cited in Turn 1
- [Warehouse design proposal](../warehouse-demo/design/warehouse_design_proposal.md) — full dimensional model
- [Human review pack](../warehouse-demo/design/human_review_pack.md) — open decisions D001–D005

### Audit trail

- [Demo run index](../warehouse-demo/source-notes/demo_run_index.md) — Run 3 artefact register

---

## Turn 1 — How should we model IUCS to case linkage?

**User:**

Profiling found ambiguous and inferred matches. How should the warehouse handle CareCall to CareCase linkage?

**Warehouse Design Agent:**

Do not force a single foreign key in the fact load. Use a layered approach from [linkage_resolution_strategy.md](../warehouse-demo/design/linkage_resolution_strategy.md):

**1. DIRECT_CARECASE** — When `CareCaseCaseId` validates against `carecase_cases`, populate `FactCareCase` with `SourceContactKey`. Orphan IDs (47 per DQ003) load with `orphan_case_id_flag` — no case join.

**2. INFERRED_MATCH** — Do not auto-promote. Insert candidates into `BridgeCareCallInferredCase` (same patient, case open within ±24h of contact). Report direct vs inferred counts separately in marts.

**3. AMBIGUOUS** — Parse `AmbiguousMatchIds` into `BridgeCareCallReferralCandidate` (one row per pipe-delimited referral). No default winner without human decision D003.

**4. CALLBACK_DUPLICATE** — Keep `CallbackOfContactKey` on `FactCareCallContact`. Mart dedup policy is an open decision (D004).

**Staging prerequisite:** Preserve `LinkageScenario` column in `stg.CareCallContact`.

---

## Turn 2 — What about March cases without a CareCall contact?

**User:**

Should we load cases that have no SourceContactId?

**Warehouse Design Agent:**

Yes — land all cases in `stg.CareCase` and `FactCareCase`. Add derived flags:

- `missing_source_contact_flag` (empty SourceContactId)
- `is_extract_inclusion_case` (from `ExtractInclusionFlag` and admin statuses)

Profiling showed 322 of 542 March opens lack `SourceContactId` while IUCS contacts fell ([volume_trends.csv](../warehouse-demo/profile-output/volume_trends.csv)). Operational IUCS metrics should **exclude** `is_extract_inclusion_case=1` until decision D001 is signed off.

See [human_review_pack.md](../warehouse-demo/design/human_review_pack.md) question 1.

---

## Turn 3 — Can you write the CREATE TABLE scripts?

**User:**

Generate the SQL please.

**Warehouse Design Agent:**

Outside this agent's scope. Design proposal is complete in `warehouse-demo/design/`.

**Next step:** Run 4 SQL build per `suggested_run4_agent_task.md` after human review pack sign-off.
