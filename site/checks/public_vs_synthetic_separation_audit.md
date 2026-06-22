# Phase 2 — Public vs synthetic data separation audit

**Purpose:** Confirm the site keeps three content types clearly separated, so a reader never mistakes one for another:

1. **Public aggregate data** — real published NHS figures for Dorset HealthCare (RDY).
2. **Synthetic Demo Rivers Health (DRH)** — fictional source systems and warehouse.
3. **Governance / operating model** — explanation of how agents would be used, with illustrative rules.

**Critical rules checked:**
- Public RDY pages must not imply they use synthetic DRH data.
- Synthetic DRH pages must not imply they use real Dorset HealthCare / RDY / patient / staff / supplier / NHS-internal data.
- Azure SQL / ADF must not be implied as live deployment.

The **Action** column records the correction made after Phase 6.

---

## Result summary

Separation is **strong overall**. The warehouse demo and draft-report pages explicitly distinguish DRH from RDY, and the synthetic reports carry layered caveats. The only real gap is the **governance page**, whose "synthetic only" wording understates the public-aggregate strand and could confuse a reader about what data the site uses. A homepage one-liner naming the three content types and a nav fix on one warehouse report further reduce blur risk.

---

## Checks

| Check | Finding | Status | Action |
|---|---|---|---|
| RDY/public pages clearly labelled as public aggregate data | All six `reports/public-*.html` carry meta "Public aggregate data · RDY · Demonstration only" + caveat box + footer "Not NHS-endorsed". `draft-reports.html` hero and caveat say "public aggregate NHS data" | Pass | No change needed |
| Synthetic DRH pages clearly labelled fictional | `data-warehouse-agent-demo.html` and all three `warehouse-demo/reports/*.html` state "Synthetic demonstration only / fictional DRH / not RDY" in title, meta, caveat and footer | Pass | No change needed |
| Warehouse demo page does not blur public and synthetic evidence | §4 "How this differs from the draft reports page" explicitly separates RDY public data from DRH synthetic systems; "DRH and RDY must not be read as the same provider" | Pass | No change needed |
| Draft-reports → warehouse links carry separation wording | `draft-reports.html` related-demo info box: "separate **synthetic** end-to-end workflow … should not be read alongside these RDY briefs as the same provider" | Pass | No change needed |
| Report nav bars don't imply synthetic reports are public NHS reports | Warehouse report nav links to "Warehouse demo / Public draft reports / Agent operating model"; public report nav links to "All reports / Agent operating model / Report method". Labels keep the two families distinct | Pass | No change needed |
| Azure / ADF not implied as live | Consistent "specification artefact only / not a live deployment / not deployed to live Azure" across warehouse demo, SQL README, DEPLOYMENT_NOTES.md, report bodies | Pass | No change needed |
| Caveats prominent enough | Caveat boxes appear above the fold on every page; per-report footers reinforce | Pass (minor improvements below) | See gaps |

---

## Gaps and low-risk fixes

| # | Location | Issue | Fix | Action |
|---|---|---|---|---|
| 1 | `governance-and-benefits.html` caveat box (L38) and footer (L140) | "using synthetic data" implies the whole site is synthetic; the site also uses public aggregate data | Reword to "public aggregate and synthetic demonstration data" | Action applied |
| 2 | `governance-and-benefits.html` controls bullet (L67) | "this site uses fabricated aggregates only" contradicts the public-data draft reports and mandatory map | Reword to acknowledge public aggregate **and** synthetic demonstration data | Action applied |
| 3 | `index.html` purpose section | The three content types are listed across cards but not named together early, so a quick scanner may not register the separation | Add one sentence naming the three content types (public aggregate briefs; synthetic DRH warehouse; governance/operating model) | Action applied |
| 4 | `warehouse-demo/reports/urgent-care-provider-month-brief.html` nav | Nav omits the warehouse demo page and public draft reports, unlike sibling reports — weakens "this is the synthetic strand" signposting | Align nav bar with sibling warehouse reports | Action applied |
| 5 | ~~`reports/mandatory-returns-assurance-log.html`~~ (removed) | Outdated legacy synthetic report | Removed entirely; mandatory reporting map is the current assurance view | Action applied — file deleted |

---

## Cross-reference matrix (for reviewers)

| Strand | Provider label | Real or fictional | Azure | Pages |
|---|---|---|---|---|
| Public reporting | RDY / Dorset HealthCare | Real published aggregates | Not used | `draft-reports.html`, `reports/public-*.html`, `mandatory-reporting-map.html` (public reference links) |
| Synthetic warehouse | Demo Rivers Health (DRH) | Fictional | Spec artefact only | `data-warehouse-agent-demo.html`, `warehouse-demo/**` |
| Governance / model | n/a (illustrative roles) | Illustrative templates | n/a | `agent-operating-model.html`, `governance-and-benefits.html` |

**Conclusion:** After the four low-risk fixes, public and synthetic strands are clearly separated and no page implies live Azure deployment or cross-contaminates real and fictional data.
