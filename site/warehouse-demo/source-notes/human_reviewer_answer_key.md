# Human reviewer answer key

> **Human reviewers only.** Profiling agents must **not** read this file. Compare agent findings against this key after the agent has completed source profiling.

## Linkage scenario targets (IUCS contacts)

Approximate expected mix across IUCS contacts:

| Scenario | ~% | Reviewer check |
|----------|-----|----------------|
| `DIRECT_CARECASE` | 38% | `CareCaseCaseId` populated; `SourceContactId` on case matches |
| `DIRECT_LEGENDARY` | 14% | Legendary IDs on contact; often no CareCase |
| `INFERRED_MATCH` | 11% | Null direct IDs; same `PatientPseudoId` and case open within ~24h |
| `NO_CASE` | 22% | No downstream case expected |
| `AMBIGUOUS` | 8% | Two plausible referral IDs in `AmbiguousMatchIds` |
| `CALLBACK_DUPLICATE` | 7% | `CallbackOfContactId` populated |

Additional noise: ~3% `DIRECT_CARECASE` rows with mismatched `CareCaseCaseId`; ~1–2% orphan Legendary referral IDs on contacts.

## Planted artefact 1 — CareCase March 2026 extract-rule change

**Expected agent finding:**

- CareCase cases opened jump in **2026-03** (~+40–50% vs prior months) without a matching IUCS uplift in CareCall
- ~180 additional cases with `CaseStatus` in (`PendingAdminClosure`, `AwaitingSignoff`), `ExtractInclusionFlag=1`, often **empty `SourceContactId`**
- `localops_extract_change_log.xlsx` records CareCase `NightlyCaseExtract` inclusion rule change effective March run
- `localops_validation_notes.xlsx` mentions 2026-03-01 deployment

**Interpretation:** Apparent activity increase is **extract-driven**, not a genuine front-door surge. Do not attribute to operational demand without cross-source corroboration.

## Planted artefact 2 — CareCall December 2025 timezone export shift

**Expected agent finding:**

- ~47 IUCS contacts in **2025-12** where `ContactDate` is one calendar day earlier than `CreatedDateTime` implies
- `localops_validation_notes.xlsx` (2025-12-05) and extract change log (2025-12-04 CareCall schedule change) provide context

**Interpretation:** Date-boundary artefact from export window move to 02:00 UTC — not duplicate patients.

## Genuine operational change — Jan–Feb 2026 winter pressure

**Expected agent finding (multi-source corroboration):**

| Source | Signal |
|--------|--------|
| CareCall | IUCS contacts +14% Jan, +11% Feb vs Sep–Nov baseline |
| CareCase | Genuine new IUCS-linked cases elevated in Jan–Feb (exclude March admin-status artefact rows) |
| RosterFlow | Additional urgent-care bank shifts in Feb (~22 above typical bank rate) |
| LedgerWise | Agency nursing (`6100`) on `CC-URG-401` ~+18% spend in Feb |
| LocalOps | Validation notes on bank-holiday pressure, recovery plan, temp escalation roster |

**Interpretation:** Coordinated **real** operational pressure in Jan–Feb, distinct from March extract artefact.

## Distinguishing the two March vs February stories

| Question | Feb escalation | March spike |
|----------|----------------|-------------|
| CareCall IUCS up? | Yes | No |
| RosterFlow bank shifts up? | Yes | No |
| Ledger agency spend up? | Yes | No |
| Cases without `SourceContactId`? | Rare | Common (artefact) |
| Extract change log? | No CareCase rule change | CareCase inclusion change |

## Background noise (not primary findings)

Agents may also report:

- Expired LocalOps mappings still in use
- Team name drift across systems
- Low-rate orphan foreign keys
- Benign `cc.test.account` contacts
- Minor month-on-month jitter without narrative

These are intentional — real profiling is rarely one clean mystery.

## Minimum acceptable agent output (profiling phase)

1. Per-file grain, row counts and date ranges (may use `source_manifest.csv`)
2. CareCall → CareCase → Legendary linkage quality assessment
3. Month-on-month volume tables for contacts, cases, shifts and spend
4. Hypothesis for any large month-on-month case increase **with evidence**
5. Explicit list of data quality issues and recommended staging checks
6. **No** warehouse star-schema proposal in the profiling pass
