# Runs 2–5 internal QA findings

**Date:** 2026-06-22  
**Scope:** Internal consistency only (no new features).  
**Answer key:** Not read during this QA pass.

## Summary

| Area | Result |
|------|--------|
| Missing deliverable files | Pass — all planned artefacts present |
| Markdown / repo links | Pass — no broken relative links in warehouse-demo or examples |
| HTML hrefs (agent-operating-model) | Pass — 15 warehouse-related targets exist |
| JSON pipeline specs | Pass — 4/4 valid JSON |
| `site/reports/` modified | Pass — not modified |
| `draft-reports.html` modified | Pass — not modified |
| Answer-key leakage (agent outputs) | Pass — no planted counts in profiling report; forbidden lists only elsewhere |

## Issues found and disposition

### Fixed (low-risk)

| ID | Issue | Fix applied |
|----|-------|-------------|
| QA-01 | Corrected HTML brief showed Mar operational cases **220** but `demo_provider_month_measures.csv` has **197** for same filter | Updated [`reports/urgent-care-provider-month-brief.html`](../reports/urgent-care-provider-month-brief.html) |
| QA-02 | Jan operational cases showed em dash; mart CSV has **274** | Same HTML table row updated |
| QA-03 | `qa.ExpiredLocalOpsMappingInUse` references `stg.LocalOpsUserMapping` — table missing from DDL | Added to [`sql/staging/01_stg_tables.sql`](../sql/staging/01_stg_tables.sql) |
| QA-04 | Loader/ADF/EXPECTED counts reference `raw.CareCase`, `raw.LegendaryReferral`, etc. — only `raw.CareCallContact` had DDL | Added [`sql/staging/02_raw_other_sources.sql`](../sql/staging/02_raw_other_sources.sql); README run order updated |
| QA-05 | HTML caveat cited `linkage_resolution_strategy.md` without working relative path | Linked to `../design/linkage_resolution_strategy.md` |
| QA-06 | Agent operating model section still titled "in progress" after Run 5 | Title updated to "Warehouse design demo" |

### Documented — no fix (by design or out of scope)

| ID | Issue | Notes |
|----|-------|-------|
| QA-07 | [`qa.MonthlyContactCaseTrend`](../sql/views/05_qa_views.sql) uses `FULL OUTER JOIN` on month only — can mis-aggregate cases vs contacts | Demo QA view; profiling uses Python `volume_trends.csv` instead |
| QA-08 | SQL DDL incomplete vs design (`staging_model.md` lists many stg/raw tables) | Artefact spec only; not all sources have CREATE TABLE scripts |
| QA-09 | ADF JSON references stored procedures (`stg.usp_*`, `mart.usp_*`) not defined in SQL folder | Expected for pipeline specs; procedures not in demo scope |
| QA-10 | Flawed brief uses invented open-referral figures (4,200 / 4,350) | Intentional QA trap — not sourced from mart |
| QA-11 | Flawed brief claims "42% surge" for March | Intentional error for Report QA demo |
| QA-12 | `suggested_next_agent_task.md` still describes Run 2 profiling | Superseded by `suggested_run3_agent_task.md`; retained as historical Run 1 handoff |
| QA-13 | `2026-06` partial month in volume/mart outputs | Source data edge rows; profiling includes with caveat |

### Answer-key references (expected)

References to `human_reviewer_answer_key.md` appear only in: forbidden-source lists, human-only checkpoints, comparison template, README reviewer note. **No leakage into** `source_profiling_report.md` or agent conversations (except intentional flawed draft errors).

## Cross-artifact consistency checks

| Check | Status |
|-------|--------|
| Mar 2026 cases opened 542 | Consistent: volume_trends, mart, profiling report, HTML |
| Mar IUCS 1,272 | Consistent across profiler and mart |
| Mar cases without SourceContactId 322 | Consistent: volume_trends, DQ002, profiling report |
| Feb operational cases 402 | Consistent: mart CSV and corrected HTML (after QA-01/02) |
| Agency spend Feb ~£61,356 | Consistent: volume_trends, mart, HTML |
| Table names SQL ↔ ADF ↔ design | Core names align (`raw.CareCallContact`, `stg.CareCase`, `mart.ProviderMonthUrgentCare`) |
| Checkpoint immutability | `run2`–`run4` checkpoints not rewritten during this QA |

## Re-verification commands

```bash
python3 -m json.tool site/warehouse-demo/pipelines/pl_ingest_source_csv.json > /dev/null
cd site/warehouse-demo/profiler && .venv/bin/python profile_sources.py
cd site/warehouse-demo/sql/load && python3 load_from_csv.py --dry-run
```

**QA status:** Pass with documented limitations. Low-risk fixes applied.
