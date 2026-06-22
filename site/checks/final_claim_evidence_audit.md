# Phase 1 — Final claim and evidence audit

**Purpose:** Record significant claims across the demonstration site that could affect credibility, and check each against the evidence visible or linked on the site.

**Reviewer:** Final critical sweep (human-directed AI review).
**Date:** June 2026.
**Role reference:** [`docs/152-S030.26_Business_Performance_Business_Partner_Job_Description.txt`](../../docs/152-S030.26_Business_Performance_Business_Partner_Job_Description.txt) and [`docs/152-S030.26_Business_Performance_Business_Partner_Person_Specification.txt`](../../docs/152-S030.26_Business_Performance_Business_Partner_Person_Specification.txt) — both confirmed present and used only as an internal alignment reference.

**Claim types:** public-data | synthetic-data | AI/agentic capability | personal/application | governance/safety | technical implementation | role-suitability.

**Assessment scale:** Supported | Supported – clearer wording | Unclear / needs caveat | Unsupported / remove-or-evidence.

The **Action** column is updated after Phase 6 so this audit records both the original issue and any correction made (`Action applied` / `No change needed` / `Flagged for Joe`).

---

## Summary of findings

- No fabricated or unsupported public-data figures found. Public reports use real published NHS aggregate values for RDY with consistent "demonstration only / human review required" caveats.
- Synthetic Demo Rivers Health (DRH) material is clearly labelled fictional throughout.
- Azure SQL / ADF material is consistently framed as specification artefact, not live deployment.
- No occurrences of `proves`, `automates performance management`, `production-ready`, `perfect for this role`, or `automatically approves` in public-facing claims (only `proves` appears inside a deliberately flawed draft that the QA example then rejects).
- Main credibility issues are wording-level: a homepage counting inconsistency, a casual builder anecdote, an over-broad "synthetic only" caveat on the governance page, and `In production` badges that can scan as live Trust status.
- Personal/application claims (operational leadership, performance experience, SQL) are appropriate for an application but are **not** evidenced by the site itself; they are flagged for Joe to support through CV/interview.

---

## Claim register

### Homepage — `site/index.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 1 | "The site now includes three linked demonstrations" (L69) | technical | Five cards/pages are listed immediately below | Unsupported / inconsistent | Reword to describe the actual content (five linked pages across three strands: public reporting, governance/operating model, synthetic warehouse) | Action applied |
| 2 | "built entirely by a cursor agent … while Spain beat Saudi Arabia" (L105) | personal | None; off-topic anecdote | Supported – clearer wording | Replace with neutral phrasing about human direction and review | Action applied |
| 3 | Agentic AI "can help NHS business and performance teams work faster, more clearly and more consistently" (L44) | AI capability | Draft reports + mandatory map demonstrate drafting/checking | Supported | No change needed | No change needed |
| 4 | "AI cannot and should not replace professional judgement" (L60) | governance/safety | Reinforced site-wide | Supported | No change needed | No change needed |
| 5 | Personal capability list: NHS operational management, performance/service improvement, SQL/reporting (L150–158) | personal/application | Not evidenced by the site (demonstration artefacts only) | Unclear / needs caveat | Keep as application statement; site already frames itself as "demonstration of approach", so no public change. Flag that this rests on Joe's CV/interview | Flagged for Joe |
| 6 | "This is not a finished Trust product. It is a demonstration of approach." (L161) | role-suitability | Whole site | Supported | No change needed | No change needed |
| 7 | No backend, no connection to live Trust systems (L112–113) | technical | Static site; consistent with rest of site | Supported | No change needed | No change needed |

### Draft reports — `site/draft-reports.html` and `site/reports/public-*.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 8 | "Six worked examples … using public aggregate NHS data for Dorset HealthCare" (L34) | public-data | Public reports cite NHS England / NHS Digital sources with access dates | Supported | No change needed | No change needed |
| 9 | "first draft for human review … not official … should not be used for operational decision-making" (L35) | governance/safety | Caveat box + per-report warnings/footers | Supported | No change needed | No change needed |
| 10 | "repeatable workflow that links source data, processing and narrative" via R scripts (L130–132) | technical | `DATA_SOURCE_REGISTER.csv`, `R/03_*`, `R/04_*` linked | Supported | No change needed | No change needed |
| 11 | Talking Therapies: "RDY at 88% remains above the 75% six-week access standard but has fallen from 95%" | public-data | Cited NHS Talking Therapies statistics with confidence note | Supported | No change needed (figures unchanged) | No change needed |
| 12 | CQC "Overall Outstanding" (public-assurance-profile) | public-data | Cited as July 2019 main report, "regulatory context only" | Supported | No change needed | No change needed |
| 13 | Briefs demonstrate turning data into "clear, useful performance intelligence" (L45) | role-suitability | Report structure shown | Supported | Add one subtle sentence on decision support for senior operational/clinical readers | Action applied |

### Mandatory reporting map — `site/mandatory-reporting-map.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 14 | Returns marked "In production" assurance status (table rows) | technical/public-data | Strong caveat box says statuses are "illustrative sample data" | Supported – clearer wording | Add a short sentence directly above the table restating that assurance badges are illustrative demo metadata, not verified Trust status | Action applied |
| 15 | Demo due dates (e.g. 2026-04-15) | technical | Caveat states dates are illustrative | Supported | No change needed (covered by caveat + new table note) | No change needed |
| 16 | "the kind of clear overview a Business & Performance Business Partner would want" (L33) | role-suitability | Register table demonstrates this | Supported | No change needed | No change needed |
| 17 | AI "would not approve anything" — owners sign off (L77) | governance/safety | Warning box | Supported | No change needed | No change needed |
| 18 | Public reference links point to published NHS sources | public-data | External links to digital.nhs.uk / england.nhs.uk etc. | Supported | No change needed | No change needed |

### Data warehouse demo — `site/data-warehouse-agent-demo.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 19 | "Demo Rivers Health is fictional … not Dorset HealthCare, RDY, patient-identifiable … Azure SQL and ADF material … not a live deployment" (caveat) | synthetic/technical | Caveat box; DEPLOYMENT_NOTES.md; SQL README | Supported | No change needed | No change needed |
| 20 | "DRH and RDY must not be read as the same provider" (§4) | synthetic-data | Explicit separation section | Supported | No change needed | No change needed |
| 21 | Agents "can support data engineering, source profiling, documentation, validation, reporting assurance and analysis — but does not replace accountable human review" (§1) | AI capability | Worked artefacts + checkpoints linked | Supported | No change needed | No change needed |
| 22 | Reader reports classify Jan–Feb escalation / March spike / December boundary | AI capability | Synthetic reports hedge with "needs review / treat as extract-driven" | Supported – clearer wording | Ensure a role-relevance note frames these as draft agent readings that distinguish genuine change from data artefact (not validated findings) | Action applied |
| 23 | No explicit role-relevance framing on this page | role-suitability | Page is method-focused | Unclear / needs caveat | Add a short "why this matters for performance partnering" note after §1 (capacity/demand signals, reporting assurance, change vs artefact) | Action applied |

### Agent operating model — `site/agent-operating-model.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 24 | "how agentic AI could be operationalised safely in a Business & Performance team" (L34) | AI capability | Agent rules + worked examples | Supported – clearer wording | Soften "operationalised" to plainer wording ("used safely") to reduce production-implying tone | Action applied |
| 25 | Agent "Must not: Read human answer key …" (L475, L494) | governance/safety | Refers to reviewer-only file in `warehouse-demo/source-notes/` | Supported – clearer wording | Rephrase to "human-only reviewer checklist (not an agent source)" so the public page does not surface the raw filename | Action applied |
| 26 | Agents are "narrow, source-bound assistant … never the decision-maker" (L44) | AI capability | Rule files define bounded scope | Supported | No change needed | No change needed |
| 27 | Workflows end in IG/Safety gate and named human sign-off | governance/safety | Sign-off roles listed per agent | Supported | No change needed | No change needed |
| 28 | "June 2026 public-data report improvement pass" caught total/period/standard/trend errors (L156) | technical | Flawed draft + corrected brief + QA summary linked | Supported | No change needed | No change needed |

### Governance and benefits — `site/governance-and-benefits.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 29 | "personal demonstration site using synthetic data" (caveat L38) and footer (L140) | public/synthetic | The site also uses **public aggregate** data (draft reports, mandatory map) | Unclear / over-broad | Broaden to "public aggregate and synthetic demonstration data" to match the homepage footer | Action applied |
| 30 | Control: "Synthetic data for demonstration — this site uses fabricated aggregates only" (L67) | public/synthetic | Same inconsistency as #29 | Unclear / over-broad | Reword to reflect both public aggregate and synthetic data | Action applied |
| 31 | Benefits list (faster drafts, consistent structure, reusable SME rules, etc.) | AI capability | Demonstrated across site | Supported | No change needed | No change needed |
| 32 | Controls list (no PID without IG approval, named sign-off, audit log, etc.) | governance/safety | Reflected in agent rules + checkpoints | Supported | No change needed | No change needed |
| 33 | Closing line ties checklist to "judgement and leadership the … role calls for" | role-suitability | Checklist demonstrated | Supported | Optionally add a short link to public service values / validated information (JD 1.8, person spec 2.4) where it fits naturally | Action applied |

### Synthetic warehouse reports — `site/warehouse-demo/reports/*.html`

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 34 | "Synthetic demonstration only … Not RDY public data … Human sign-off required" (caveats) | synthetic/safety | Title, meta, caveat, footer on each | Supported | No change needed | No change needed |
| 35 | "Likely genuine — needs review" / "treat as extract-driven until confirmed" | AI capability | Hedged classifications, synthetic data | Supported | No change needed (hedging is appropriate) | No change needed |
| 36 | SQL "not deployed to live Azure" | technical | Stated in report + DEPLOYMENT_NOTES.md | Supported | No change needed | No change needed |
| 37 | `urgent-care-provider-month-brief.html` nav omits warehouse demo page + public draft reports | technical/navigation | Sibling reports link both | Supported – clearer wording | Align nav bar with sibling warehouse reports | Action applied |

### Legacy synthetic drafts — `site/reports/` (non-`public-*`, orphaned)

| # | Claim (paraphrase) | Type | Evidence on site | Assessment | Recommended fix | Action |
|---|---|---|---|---|---|---|
| 38 | ~~`mandatory-returns-assurance-log.html`~~ (removed) | technical | Outdated legacy synthetic report; superseded by `mandatory-reporting-map.html` | Unsupported / remove | Removed entirely at Joe's request; generator block removed from `R/02_render_reports.R` | Action applied — file deleted |
| 39 | Other legacy drafts (all-age MH, CYP, demand/capacity, LD) carry "synthetic data only" + "not reviewed or approved" | synthetic/safety | Header/caveat/footer present | Supported | No change needed (orphaned but safe) | No change needed |

---

## Claims requiring Joe's manual evidence (not provable by the site)

- Substantial senior NHS management experience (person spec 2.1).
- Experience managing performance and change in a complex organisation (2.2).
- Developing performance frameworks (2.3).
- Contract/SLA negotiation (2.7).
- Leadership, negotiation and influencing (3.1, 5.5).
- Masters-level qualification / recognised management qualification (1.1, 1.2).

These are appropriately presented as application statements on the homepage. The site demonstrates **method and thinking**; it cannot evidence employment history. Joe should ensure the homepage capability list matches his CV and supporting statement.
