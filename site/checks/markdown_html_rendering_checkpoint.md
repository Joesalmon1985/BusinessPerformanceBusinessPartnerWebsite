# Markdown HTML rendering checkpoint

**Date:** 2026-06-22  
**Scope:** Static Markdown-to-HTML publishing layer for Cloudflare Pages.

## Files published as HTML (33)

Output root: `site/docs-html/` (mirrors source paths with `.html` extension).

### Checks (5)

| Source | Output |
|--------|--------|
| `site/checks/site_explanation_guide.md` | `site/docs-html/checks/site_explanation_guide.html` |
| `site/checks/final_site_critical_sweep_checkpoint.md` | `site/docs-html/checks/final_site_critical_sweep_checkpoint.html` |
| `site/checks/business_performance_role_alignment_audit.md` | `site/docs-html/checks/business_performance_role_alignment_audit.html` |
| `site/checks/final_claim_evidence_audit.md` | `site/docs-html/checks/final_claim_evidence_audit.html` |
| `site/checks/public_vs_synthetic_separation_audit.md` | `site/docs-html/checks/public_vs_synthetic_separation_audit.html` |

### Warehouse demo (11)

| Source | Output |
|--------|--------|
| `site/warehouse-demo/source-notes/demo_run_index.md` | `site/docs-html/warehouse-demo/source-notes/demo_run_index.html` |
| `site/warehouse-demo/profile-output/source_profiling_report.md` | `site/docs-html/warehouse-demo/profile-output/source_profiling_report.html` |
| `site/warehouse-demo/design/warehouse_design_proposal.md` | `site/docs-html/warehouse-demo/design/warehouse_design_proposal.html` |
| `site/warehouse-demo/design/human_review_pack.md` | `site/docs-html/warehouse-demo/design/human_review_pack.html` |
| `site/warehouse-demo/design/linkage_resolution_strategy.md` | `site/docs-html/warehouse-demo/design/linkage_resolution_strategy.html` |
| `site/warehouse-demo/sql/README.md` | `site/docs-html/warehouse-demo/sql/README.html` |
| `site/warehouse-demo/sql/DEPLOYMENT_NOTES.md` | `site/docs-html/warehouse-demo/sql/DEPLOYMENT_NOTES.html` |
| `site/warehouse-demo/sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md` | `site/docs-html/warehouse-demo/sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.html` |
| `site/warehouse-demo/pipelines/pipeline_overview.md` | `site/docs-html/warehouse-demo/pipelines/pipeline_overview.html` |
| `site/warehouse-demo/checkpoints/runs_2_5_internal_qa.md` | `site/docs-html/warehouse-demo/checkpoints/runs_2_5_internal_qa.html` |
| `site/warehouse-demo/README.md` | `site/docs-html/warehouse-demo/README.html` |

### Examples (7)

All `site/examples/*.md` → `site/docs-html/examples/*.html`

### Public method / readme (4)

| Source | Output |
|--------|--------|
| `site/public-data/PUBLIC_REPORTS_METHOD.md` | `site/docs-html/public-data/PUBLIC_REPORTS_METHOD.html` |
| `site/public-data/FINAL_SIMPLIFICATION_SUMMARY.md` | `site/docs-html/public-data/FINAL_SIMPLIFICATION_SUMMARY.html` |
| `site/public-data/FINAL_REPORT_QA_SUMMARY.md` | `site/docs-html/public-data/FINAL_REPORT_QA_SUMMARY.html` |
| `site/public-data/metadata/public_report_audit_nof_overview.md` | `site/docs-html/public-data/metadata/public_report_audit_nof_overview.html` |

### Docs (1)

| Source | Output |
|--------|--------|
| `site/docs/synthetic-mhsds-local-dictionary.md` | `site/docs-html/docs/synthetic-mhsds-local-dictionary.html` |

### Agent rules — worked-example only (5)

| Source | Output |
|--------|--------|
| `site/agent-rules/mhsds-expert-agent.md` | `site/docs-html/agent-rules/mhsds-expert-agent.html` |
| `site/agent-rules/report-analysis-agent.md` | `site/docs-html/agent-rules/report-analysis-agent.html` |
| `site/agent-rules/source-profiling-agent.md` | `site/docs-html/agent-rules/source-profiling-agent.html` |
| `site/agent-rules/warehouse-design-agent.md` | `site/docs-html/agent-rules/warehouse-design-agent.html` |
| `site/agent-rules/warehouse-report-qa-agent.md` | `site/docs-html/agent-rules/warehouse-report-qa-agent.html` |

## Files deliberately not published

| Path | Rationale |
|------|-----------|
| `site/warehouse-demo/source-notes/human_reviewer_answer_key.md` | **Forbidden** — reviewers only; must not appear as HTML |
| `site/warehouse-demo/checkpoints/manual_answer_key_comparison_template.md` | Answer-key comparison template |
| `site/warehouse-demo/checkpoints/run2_checkpoint.md` … `run5_checkpoint.md` | Internal run checkpoints — remain source `.md` |
| `site/warehouse-demo/checkpoints/dedicated_page_checkpoint.md` | Internal checkpoint |
| `site/warehouse-demo/checkpoints/reporting_pages_checkpoint.md` | Internal checkpoint |
| `site/warehouse-demo/source-notes/suggested_*.md` | Internal agent task notes |
| `site/checks/homepage_index_proposed_changes.md` | Internal planning — not on allow-list |
| `site/checks/final_link_navigation_audit.md` | Internal audit — not on allow-list |
| `site/checks/final_readability_clarity_audit.md` | Internal audit — not on allow-list |
| `site/checks/markdown_html_rendering_checkpoint.md` | This checkpoint — internal only |
| Remaining `site/agent-rules/*.md` (12 files) | “View rule file” technical inspection — stay raw `.md` |
| `site/public-data/metadata/fft_manual_download_needed.md` | Cited in assurance brief text only — not linked |

## Public pages updated

| Page | Links updated | Left as `.md` (intentional) |
|------|---------------|------------------------------|
| `site/index.html` | 6 reader-facing → `docs-html/` | `agent-rules/README.md` |
| `site/data-warehouse-agent-demo.html` | 12 → `docs-html/` | `warehouse-demo/README.md`, `sql/README.md`, `sql/DEPLOYMENT_NOTES.md` |
| `site/draft-reports.html` | 3 supporting-doc hrefs → `docs-html/` | Anchors remain filenames |
| `site/agent-operating-model.html` | 18 reader-facing → `docs-html/` | All “View rule file” links; `agent-rules/README.md`; `demo_run_index.md` filename link; `sql/README.md` |
| `site/warehouse-demo/reports/*.html` (3 files) | 5 → `docs-html/` | Audit-trail `<code>` paths unchanged |
| `site/reports/*.html` (6 files) | Nav “Report method” + footer method/audit links → `docs-html/` | — |
| `site/R/03_render_public_reports.R` | Template updated to match report HTML |

## Forbidden files checked

- [x] No `site/docs-html/**/human_reviewer_answer_key.html` created
- [x] `rg -i 'human_reviewer_answer_key|planted artefact' site/docs-html/` — **zero matches**
- [x] `demo_run_index.html` de-links answer key; shows “human-only reviewer checklist (not published on site)”
- [x] Internal checkpoint links in `demo_run_index.html` still point to source `.md` files
- [x] Source `.md` files unchanged (except this new checkpoint and R-regenerated audit metadata)

## Link-check result

Spot-checks (relative paths from `site/`):

| From | Link | Target exists |
|------|------|---------------|
| `index.html` | `docs-html/examples/report-analysis-agent-conversation.html` | Yes |
| `index.html` | `docs-html/warehouse-demo/profile-output/source_profiling_report.html` | Yes |
| `data-warehouse-agent-demo.html` | `docs-html/warehouse-demo/source-notes/demo_run_index.html` | Yes |
| `draft-reports.html` | `docs-html/public-data/PUBLIC_REPORTS_METHOD.html` | Yes |
| `reports/public-mh-access-profile.html` | `../docs-html/public-data/PUBLIC_REPORTS_METHOD.html` | Yes |
| `warehouse-demo/reports/urgent-care-provider-month-brief.html` | `../../docs-html/warehouse-demo/source-notes/demo_run_index.html` | Yes |

Build script self-check: `python3 tools/render_markdown_docs.py --check` — **PASSED**

## Limitations

- “View rule file” agent-rule links remain raw `.md` for technical/repo inspection.
- `fft_manual_download_needed.md` is mentioned in `public-assurance-profile.html` body text but not hyperlinked.
- No syntax highlighting on fenced code blocks.
- Unpublished internal checkpoints linked from `demo_run_index.html` still open as raw Markdown.
- Generated pages include full site nav; report pages use the existing `nhs-report` shell only (unchanged).

## Build command

**Cloudflare Pages (Git):**

```bash
pip install -r requirements.txt && python3 tools/render_markdown_docs.py
```

**Local regeneration:**

```bash
python3 tools/render_markdown_docs.py
```

Output directory remains `site`.
