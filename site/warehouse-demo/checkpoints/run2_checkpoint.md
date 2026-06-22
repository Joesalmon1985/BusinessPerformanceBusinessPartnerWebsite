# Run 2 checkpoint — source profiling

**Completed:** 2026-06-22  
**Status:** Ready for Run 3 (warehouse design proposal)

## Artefacts produced

- `site/agent-rules/source-profiling-agent.md`
- `site/warehouse-demo/profiler/profile_sources.py` (+ requirements.txt)
- `site/warehouse-demo/profile-output/source_profiling_report.md`
- `site/warehouse-demo/profile-output/file_grain_register.csv`
- `site/warehouse-demo/profile-output/linkage_analysis.csv`
- `site/warehouse-demo/profile-output/dq_register.csv`
- `site/warehouse-demo/profile-output/volume_trends.csv`
- `site/examples/warehouse-source-profiling-conversation.md`
- `site/warehouse-demo/source-notes/suggested_run3_agent_task.md`
- `site/warehouse-demo/source-notes/demo_run_index.md` (started)
- `site/agent-operating-model.html` (warehouse demo stub)
- `.gitignore` updated for profiler venv

## Assumptions taken

- Profiling report narrative derived from profiler CSV outputs and `localops_extract_change_log.xlsx` only (answer key not read).
- March 2026 case spike flagged as potentially extract-driven based on divergent IUCS trend + change log entry.
- Jan–Feb 2026 pattern treated as multi-source operational uplift hypothesis.
- Orphan FK count (47) accepted as background noise for staging DQ gates.

## Open questions (for Run 3 / human review)

1. Authoritative reporting date for DQ001-affected contacts.
2. Treatment of `ExtractInclusionFlag=1` in operational metrics.
3. Bridge table cardinality for ambiguous matches.

## Verification

- Profiler re-runs successfully; 19 files inventoried.
- `human_reviewer_answer_key.md` not modified.
- Existing `site/reports/` pages not modified.
