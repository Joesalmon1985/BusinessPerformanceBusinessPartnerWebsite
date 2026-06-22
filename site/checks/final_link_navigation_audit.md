# Phase 5 — Link and navigation audit

**Purpose:** Confirm internal links resolve, navigation is consistent, the old warehouse hub is a redirect (not a duplicate), and the nav stays uncluttered.

**Method:** Automated resolution check of every internal `href` (excluding `http`, `mailto:` and pure `#` anchors) across the ten key pages, plus manual anchor verification.

The **Action** column records the correction made after Phase 6.

---

## Automated link check result

`ALL INTERNAL LINKS RESOLVE` across the ten checked pages:

- `index.html`
- `data-warehouse-agent-demo.html`
- `draft-reports.html`
- `agent-operating-model.html`
- `governance-and-benefits.html`
- `mandatory-reporting-map.html`
- `warehouse-demo/reports/synthetic-urgent-care-analysis.html`
- `warehouse-demo/reports/synthetic-reporting-table-assurance.html`
- `warehouse-demo/reports/urgent-care-provider-month-brief.html`
- `warehouse-demo/agentic-warehouse-build.html`

No broken file targets were found. (The check resolves file paths; `.md` and `.csv` targets that open as raw files are intentional supporting evidence.)

---

## Checks

| Check | Finding | Status | Action |
|---|---|---|---|
| All homepage links resolve | Header nav (6) + cards (5) + Explore buttons all resolve | Pass | — |
| Homepage Explore section completeness | Explore buttons listed only 4 pages, omitting the warehouse demo | Gap | Add warehouse demo button | Action applied |
| All `data-warehouse-agent-demo.html` links resolve | Reader reports, README, run index, profiling report, design docs, SQL/pipeline docs, checkpoints, cross-links | Pass | — |
| All `agent-operating-model.html` §E links resolve | Rule files, profiling report, design proposal, SQL README, pipeline overview, mart CSV, flawed draft, QA conversation, demo index | Pass | — |
| All `draft-reports.html` → warehouse links resolve | Related-demo info box links to `data-warehouse-agent-demo.html` | Pass | — |
| Synthetic report nav bars point to top-level warehouse demo page | Two of three link `../../data-warehouse-agent-demo.html`; `urgent-care-provider-month-brief.html` did not | Gap | Align brief nav with siblings | Action applied |
| No duplicate full warehouse hub at `warehouse-demo/agentic-warehouse-build.html` | File is a 18-line redirect stub only; single link to `../data-warehouse-agent-demo.html`; no duplicated content | Pass | — |
| Old pointer page works | Redirect link resolves to the live demo page | Pass | — |
| Key anchors exist | `#cat-e`, `#report-analysis-worked-example`, `#mhsds-worked-example` in `agent-operating-model.html`; `#checklist` in `governance-and-benefits.html` | Pass | — |
| Navigation remains uncluttered | Consistent 6-item header nav across all main pages; report sub-navs are short | Pass | — |

---

## Orphaned legacy reports (recorded, not changed)

Five synthetic drafts under `site/reports/` are **not linked** from current navigation:

- `all-age-mental-health-access.html`
- `cyp-waiting-list-overview.html`
- `demand-and-capacity-prototype.html`
- `learning-disability-performance.html`

~~`mandatory-returns-assurance-log.html`~~ — **removed** (outdated; superseded by `mandatory-reporting-map.html`).

Leaving the remaining four unlinked is acceptable and slightly safer (it avoids mixing older synthetic drafts with the public RDY briefs). **No new links added.**

---

## Conclusion

Navigation is consistent and all internal links resolve. Two low-risk additions (warehouse demo in homepage Explore; brief nav alignment) bring navigation fully in line with the rest of the site.
