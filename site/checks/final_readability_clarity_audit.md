# Phase 4 — Readability and clarity audit

**Purpose:** Check the site is clear and readable for a non-technical NHS audience, supports the application without becoming repetitive or boastful, and explains "agentic AI" in practical terms rather than hype.

**Style preference:** plain English; professional but not corporate; confident but not hype-driven; short sentences; concrete verbs (draft, support, check, flag, propose, requires human review); "demonstrates / shows / is relevant to / supports" rather than "proves".

The **Action** column records the correction made after Phase 6.

---

## Overall

- The homepage explains the site purpose quickly and in plain English.
- Each page opens with a plain-English summary, which helps non-technical readers.
- The site supports the application without being a personal statement; tone is mostly "demonstration of approach".
- Two pages are long and jargon-dense (`agent-operating-model.html`, `data-warehouse-agent-demo.html`) but both lead with non-technical framing and signpost between each other, so no deletion is recommended.
- Main readability fixes are small: a counting inconsistency, a casual anecdote, an over-broad caveat, and softening one production-implying word.

---

## Page-by-page

| Page | Clarity assessment | Issues | Fix | Action |
|---|---|---|---|---|
| `index.html` | Strong. Purpose clear in the hero; cards explain each page | "three linked demonstrations" miscount; casual "while Spain beat Saudi Arabia" anecdote; Explore buttons omit the warehouse demo | Fix count; replace anecdote with neutral wording; add warehouse demo to Explore | Action applied |
| `index.html` (repetition check) | "Why this is relevant to the role" overlaps slightly with "What this site is designed to show", but each adds value (skills list vs thinking themes) | Not repetitive enough to trim | Keep both; add only one subtle role-relevance sentence | Action applied (insert only) |
| `draft-reports.html` | Strong. Review-first structure explained plainly | Rscript regeneration commands in body may intimidate non-technical readers | Acceptable for assessors; keep but framed as reviewer/technical detail (already in an info box). No edit required | No change needed |
| `data-warehouse-agent-demo.html` | Good but long (14 numbered sections). Reader-facing report cards near the top give a non-technical entry point | Jargon (grain, linkage, staging, mart, ADF) is unavoidable but mostly explained; no role-relevance framing | Add one short "why this matters for performance partnering" note; do not duplicate operating-model §E | Action applied |
| `agent-operating-model.html` | Adequate. Longest, densest page; "In plain English" boxes help | "operationalised safely" reads slightly corporate/production-implying; surfaces the raw answer-key filename | Soften "operationalised"; rephrase answer-key wording. No deletion | Action applied |
| `agent-operating-model.html` (duplication check) | §E intro (L466) already points non-technical readers to the warehouse demo page and calls itself a technical reference | No duplication problem | No change needed | No change needed |
| `governance-and-benefits.html` | Concise and readable | Caveat says "synthetic data" only, understating public-data strand | Broaden caveat/control wording | Action applied |
| `mandatory-reporting-map.html` | Strong. Collapsible glossary is a good accessibility pattern; filters add utility | "In production" badges can scan as live Trust status before the caveat is read | Add a short clarifying sentence above the table | Action applied |
| `warehouse-demo/reports/*.html` | Clear, well-caveated | `urgent-care-provider-month-brief.html` nav is thinner than siblings | Align nav | Action applied |

---

## "Agentic AI" explained in practical terms?

Yes. The operating model defines an agent as "a well-briefed, source-bound assistant for one task — not a general chatbot, and never the decision-maker", and the homepage lists concrete tasks (drafting text, checking figures, summarising trends). This is practical, not hype-driven. No change needed.

## Caveats readable, not buried?

Yes. Every page places a caveat box above the fold and repeats a short caveat in the footer. The governance caveat is the only one needing a wording fix (scope of data types), addressed in Phase 6.

## Jargon check

Acronyms are generally expanded on first use (MHSDS, CSDS, IG, QA, ADF). The mandatory map provides a glossary. The two technical pages are inherently denser but lead with plain-English framing. No urgent jargon fixes required beyond the role-relevance inserts, which themselves use plain language.

---

## Conclusion

Readability is good for the intended audience. The applied fixes are small wording changes that remove the few distracting or over-broad phrases and add brief, plain-English role relevance. No section needs rewriting or deleting.
