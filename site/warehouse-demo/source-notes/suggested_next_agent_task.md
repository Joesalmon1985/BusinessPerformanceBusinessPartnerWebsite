# Suggested next agent task — source profiling

## Objective

Profile the synthetic source-data pack in `site/warehouse-demo/` and produce a **source profiling report**. Do **not** design the warehouse, fact tables or ADF pipelines in this pass.

## Approved sources — may read first

- `source-data/*` — all CSV and XLSX extracts
- `profile-output/source_manifest.csv`
- `profile-output/source_summary.md`
- `source-notes/source_system_overview.md`
- `source-notes/synthetic_data_safety_statement.md`
- `source-notes/agent_available_source_context.md`
- `source-notes/target_public_measure_alignment.md`
- `source-notes/suggested_next_agent_task.md`

## Forbidden sources — human reviewer only

- **`source-notes/human_reviewer_answer_key.md`** — do not read, search or cite

If you believe you have found a planted issue, document your evidence from the approved sources only. A human reviewer will compare your findings to the answer key separately.

## Required outputs (profiling pass)

1. **Inventory** — confirm files against `source_manifest.csv`; note any unexpected gaps
2. **Grain and keys** — per file: grain, primary identifiers, foreign-key candidates
3. **Date coverage** — reporting period, min/max dates, late-arriving patterns
4. **Linkage analysis** — CareCall → CareCase → Legendary Care match rates; ambiguous and inferred matches
5. **Volume trends** — monthly contacts, cases, shifts, spend; flag large month-on-month moves with hypotheses
6. **Extract vs reality** — where counts may be driven by extract rule changes (use LocalOps change log and cross-source checks)
7. **Data quality register** — nulls, orphans, duplicates, mapping confidence issues
8. **Staging recommendations** — what to land raw, what to validate before modelling — **not** final dimensional models

## Explicit non-goals

- Do not propose `DimPatient`, `FactContact` or other star-schema tables yet
- Do not write ADF pipeline JSON or SQL DDL
- Do not assume Legendary Care schema matches any real PAS supplier
- Do not reproduce RDY public figures for validation

## Suggested workflow

```
1. Read manifest + safety statement + agent context
2. Profile each source file (schema, counts, dates)
3. Cross-link CareCall, CareCase, Legendary, RosterFlow, LedgerWise, LocalOps
4. Document findings and open questions
5. Stop — hand off to human reviewer before warehouse design
```

## Human sign-off

All profiling conclusions remain draft until reviewed by an accountable human. This is a demonstration site, not a live Trust process.
