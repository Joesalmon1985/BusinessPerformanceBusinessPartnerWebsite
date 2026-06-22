# Linkage resolution strategy

Based on `linkage_analysis.csv` and profiling report section 4.

## DIRECT_CARECASE

- Use `CareCaseCaseId` on contact when valid in `carecase_cases` (referential integrity pass).
- Populate `FactCareCase.SourceContactKey` from `SourceContactId` when present.
- Orphan IDs (47): load contact fact with `orphan_case_id_flag=1`; do not join to case.

## DIRECT_LEGENDARY

- Use `LegendaryCareReferralId` / `LegendaryCareEncounterId` on contact when populated.
- Facts load independently; optional link via `SourceCareCallContactId` on referral when present.

## INFERRED_MATCH

**Do not auto-promote to direct FK in facts.**

1. Staging identifies candidate pairs: same `PatientPseudoId`, case `OpenedDateTime` within ±24h of `ContactDateTime`, no direct IDs.
2. Insert into `BridgeCareCallInferredCase` with `inference_rule_id`, `confidence_score` (demo: fixed 0.75).
3. Mart measures: report **direct** and **inferred** linkage counts separately.

## AMBIGUOUS

1. Parse `AmbiguousMatchIds` (pipe-delimited) into `BridgeCareCallReferralCandidate` — one row per candidate.
2. No default winner; reporting uses primary candidate only after human mapping table (future) or highest `ReferralDateTime` proximity (documented assumption).

## CALLBACK_DUPLICATE

- Preserve `CallbackOfContactId` on `FactCareCallContact`.
- Dedup policy for marts: **count all contacts** vs **count distinct patient-day** — human decision (see review pack).

## NO_CASE

- No bridge rows; contact fact only.

## CareCase without SourceContactId

- Load `FactCareCase` with null contact key.
- Set `is_extract_inclusion_case` from staging.
- Operational IUCS conversion metrics exclude these unless reviewer approves inclusion rule.
