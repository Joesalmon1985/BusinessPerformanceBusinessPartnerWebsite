# Agent-assisted analytical brief reframe — implementation spec

This document records the reframe of the six public-data HTML reports from dataset-summary dashboards into **agent-assisted analytical briefs** that demonstrate a governed workflow: **question → data → analysis → caveats → human review**.

> **Status:** Implemented. Reports rendered by `site/R/03_render_public_reports.R`. Index page: `site/draft-reports.html`.

## 1. Diagnosis (pre-reframe)

### What worked

- Strong governance caveats and human-review warnings
- Bounded descriptive analysis only; no causal inference
- Reproducible `demo_*.csv` → R → static HTML pipeline
- NOF audit infrastructure (CSV, MD, collapsible per-metric detail)

### What was confusing

- Titles read like official Trust performance packs
- Agent role buried in a generic footer section
- Workflow implicit rather than structured

### What felt like a raw dashboard

- Metadata sections preceded analysis narrative
- “Key statistical summary” dominated page length
- NOF audit nested mid-report

## 2. Standard report template

All six reports use this section order via `agent_brief_sections()` in `03_render_public_reports.R`:

| # | Section |
|---|---------|
| — | Title (“Worked example: …”) |
| — | Public-data demonstration caveat |
| 1 | What this report demonstrates |
| 2 | The question given to the agent |
| 3 | Prompt excerpt |
| 4 | Data used |
| 5 | Agent process demonstrated |
| 6 | First-draft analysis |
| 7 | Key figures from the agent’s first draft |
| 8 | Agent-generated observations |
| 9 | What cannot be concluded from this data |
| 10 | Questions for a Business & Performance Partner |
| 11 | How to verify the figures |
| 12 | Human review required |

Header meta: `Agent-assisted analytical brief · Public aggregate data · RDY · Demonstration only`

## 3. Report purposes

| HTML file | Title | Primary demonstration |
|-----------|-------|----------------------|
| `public-performance-overview.html` | Worked example: AI-assisted analysis of NHS Oversight Framework data | NOF → cautious first-draft brief with published comparators |
| `public-mh-access-profile.html` | Worked example: AI-assisted MHSDS public-data briefing | MH access/activity with suppression and breakdown caveats |
| `public-community-services-profile.html` | Worked example: AI-assisted CSDS community services briefing | Structured briefing including sparse/zero public data |
| `public-talking-therapies-profile.html` | Worked example: AI-assisted Talking Therapies public-data briefing | Access/waiting without recovery overclaim |
| `public-assurance-profile.html` | Worked example: AI-assisted public assurance and statutory reporting brief | KO41a, ERIC, DSPT, CQC context — not a scorecard |
| `public-urgent-diagnostics-check.html` | Worked example: AI-assisted urgent care and diagnostics source check | RDY presence in A&E, DM01, KH03 before interpretation |

## 4. Draft reports index

`site/draft-reports.html` presents each card with:

- Question asked
- Agent produced
- Demonstrates
- Human review needed

## 5. Source / audit placement

- Detailed audit tables appear under **How to verify these figures** at the bottom
- NOF audit summary and per-metric detail in collapsible `<details>` blocks
- Urgent/diagnostics: full A&E row and KH03 snapshots in verification appendix
- Assurance: full assurance index and CQC note in collapsible verification blocks

## 6. R render script

Key helpers in `03_render_public_reports.R`:

- `agent_brief_sections()` — shared template
- `agent_prompt_box()`, `agent_process_box()`, `cannot_conclude_box()`, `first_draft_analysis()`
- `verify_section()`, `nof_audit_verify_body()`, `traceability_verify_body()`
- `html_table(..., hide_cols = )` for stripping internal columns

Analysis logic unchanged; narrative structure and section order reframed.

## 7. CSS

Added to `site/assets/nhs-report.css`: `.nhs-agent-box`, `.nhs-prompt-excerpt`, `.nhs-agent-process`, `.nhs-cannot-conclude`, `.nhs-verify-block`.

Added to `site/assets/styles.css`: `.card-badge--agent`.

## 8. Safety / governance (preserved)

- Public aggregate data only; no patient-level or confidential Trust data
- Not an official Dorset HealthCare report; not NHS-endorsed
- No causal claims or unsupported operational recommendations
- First-draft labelling; human reviewer owns sign-off
- DSPT/CQC/FFT gaps described as context or absence

## 9. Implementation phases (completed)

1. Shared report template in R + CSS
2. All six report narratives migrated
3. `draft-reports.html` reframed
4. Method documentation updated
5. Validation and link checks

## 10. Acceptance criteria

- [x] All six reports use the agent-assisted analytical brief structure
- [x] Every report includes question, prompt excerpt, agent process, cannot-conclude, human review
- [x] Key figures follow first-draft narrative
- [x] Audit/traceability under “How to verify these figures”
- [x] `draft-reports.html` presents workflow demonstrations
- [x] “Worked example” titles; static HTML for Cloudflare Pages

## Regenerate

```bash
Rscript site/R/03_render_public_reports.R
```
