# Warehouse report QA — agent addendum

Extends [report-analysis-agent.md](report-analysis-agent.md) for warehouse-demo urgent care briefs.

## Additional checks

1. **Extract vs operational** — If case counts rise without IUCS corroboration, check `localops_extract_change_log.xlsx` and `volume_trends.csv` `CasesWithoutSourceContactId`.
2. **Stock vs activity** — IUCS contacts are activity; open referrals are stock; do not conflate in narrative.
3. **Operational case filter** — Use `OperationalCaseOpenedCount` not raw `CaseOpenedCount` when `ExtractInclusionFlag` cases present.
4. **Synthetic caveat** — All DRH figures are `_synthetic=TRUE`; not RDY-calibrated.
5. **Evidence sources** — `profile-output/source_profiling_report.md`, `volume_trends.csv`, `demo_provider_month_measures.csv` only.

## Forbidden

- `human_reviewer_answer_key.md`

## Worked example

[warehouse-report-qa-conversation.md](../examples/warehouse-report-qa-conversation.md)
