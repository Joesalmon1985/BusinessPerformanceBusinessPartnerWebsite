# Phase 3 — Business & Performance Business Partner role-alignment audit

**Purpose:** Assess how well the site supports Joe's application for the Business & Performance Business Partner role (Band 8a, ref 152-S030.26), and identify subtle, low-risk wording that connects existing demonstrations to the role without sounding like a sales pitch.

**Role documents:** Both confirmed present:
- [`docs/152-S030.26_Business_Performance_Business_Partner_Job_Description.txt`](../../docs/152-S030.26_Business_Performance_Business_Partner_Job_Description.txt)
- [`docs/152-S030.26_Business_Performance_Business_Partner_Person_Specification.txt`](../../docs/152-S030.26_Business_Performance_Business_Partner_Person_Specification.txt)

**Strength scale:** Strong | Adequate | Weak | Missing.

**Guardrail observed:** Role relevance is not forced into every paragraph. The site remains a demonstration site first; role framing is added only where it fits naturally. No employment-history claims are invented.

---

## Theme-by-theme assessment

| # | Role requirement / theme | Where the site demonstrates it | Strength | Recommended improvement | Manual evidence needed? |
|---|---|---|---|---|---|
| 1 | Performance management & KPI thinking (JD 1.1, 1.7; PS 1.4, 5.11) | `index.html` "how I think about performance"; public NOF and Talking Therapies briefs (figure / standard / trend / action); mandatory map | Strong | Light touch only — homepage already frames "what the figure is, what it should be, whether it's improving" | No |
| 2 | Business performance of assigned services (JD 1.5) | Draft briefs interpret RDY service performance; warehouse demo distinguishes extract change from operational change | Adequate | Warehouse role-relevance note connects extract-vs-operational distinction to service performance reading | Partly — real service-management experience is CV/interview |
| 3 | Capacity and demand (JD 1.1) | Warehouse urgent-care analysis (Jan–Feb pressure vs March artefact); legacy demand/capacity prototype (orphaned) | Adequate | Name capacity/demand explicitly in the warehouse role-relevance note | No |
| 4 | Service improvement & pathway redesign (JD JOB PURPOSE, 1.1, 1.4, 1.6) | Report QA workflow improving a flawed draft; structured briefs that prompt action | Strong | Subtle framing only — "distinguishing genuine operational change from data artefact" supports service-improvement decisions | Partly — pathway redesign delivery is CV/interview |
| 5 | Accurate, validated and useful information (JD 1.8) | R validation scripts; QA checklists; warehouse DQ register and checkpoints; confidence levels | Strong | Governance page: tie checklist to "accurate, validated and useful information" language | No |
| 6 | NHS reporting & monitoring requirements (PS 1.6) | Mandatory reporting map (14 returns, owners, frequency, references); public briefs aligned to national returns | Strong | Keep "proof-of-concept register" framing clear | No |
| 7 | Analysis of performance, activity, budget & workforce data (PS 5.4; JD 1.8) | Public briefs (activity, access, estates); warehouse marts (contacts, bank/agency spend, shifts) | Adequate | Note that warehouse example touches activity, workforce (RosterFlow) and spend (LedgerWise) signals | Budget depth is thin — flag for Joe |
| 8 | Communication of complex performance information to senior audiences (JD 1.2; PS 2.5) | Plain-English "bottom line" sections; executive summary agent; report structure | Adequate | Draft-reports: one sentence on decision support for senior operational/clinical readers | Partly — presenting to Boards/CCG is interview evidence |
| 9 | Matrix working / engagement across services (JD KEY RELATIONSHIPS; PS 5.2) | Mandatory map owner columns; per-agent sign-off roles (Information Lead, Performance Manager, Service Director) | Weak | Subtle wording only; do **not** invent engagement examples | Yes — engagement track record is CV/interview |
| 10 | Governance, transparency & accountability (PS 2.4) | Governance page; IG/Safety agent; checkpoints; audit logs; named sign-off | Strong | Link checklist to public service values of transparency and accountability | No |
| 11 | SQL / Excel / analytical capability (PS 4.1, 4.2, 4.3, 5.1) | Warehouse SQL DDL/QA views; R analytical workflow; mart CSVs | Adequate | Keep technical detail in linked artefacts, not on homepage; SQL is "desirable" so this is a genuine plus | No |
| 12 | Managing competing priorities & complex work (PS 5.8, 5.9) | Breadth of agent catalogue; multi-stage warehouse workflow | Weak | Do not overstate; flag for interview/CV | Yes |
| 13 | Human review, assurance & safe AI use (JD 1.8; PS 2.4) | Site-wide: human sign-off, refusal to over-interpret, IG gate | Strong | Minor consistency fixes only (answer-key wording) | No |
| 14 | Leadership / influencing / decision support (PS 3.1, 5.5, 5.7) | `index.html` personal block; decision-support framing of reports | Weak | Site shows method, not leadership track record; flag for Joe | Yes |

---

## Strengths (where the site supports the application well)

- **Performance and KPI thinking, NHS reporting, validated information, governance and safe AI** are all demonstrated concretely, not just asserted.
- The site shows the **end-to-end performance-intelligence chain**: source profiling → warehouse design → reporting tables → QA → caveated brief → human sign-off. This is directly relevant to "ensuring adequate, accurate, validated and useful information" (JD 1.8).
- The **distinction between genuine operational change and data artefact** is a strong, role-relevant theme for service-improvement decisions.
- **SQL and statistical/complex-data analysis** (person spec desirables 4.2, 4.3, 5.4) are evidenced through real artefacts.

## Gaps (better evidenced by Joe's application/interview, not the site)

- Senior management experience, performance/change management in a complex organisation, performance-framework development (PS 2.1–2.3).
- Contract/SLA negotiation (PS 2.7).
- Leadership, negotiation, influencing, representing the Trust externally (PS 3.1, 5.5).
- Managing concurrent projects and competing demands (PS 5.8, 5.9).
- Formal qualifications (PS 1.1, 1.2).

These are correctly **not** claimed as delivered on the site. The homepage frames the site as a "demonstration of approach", which is the right posture.

---

## Low-risk role-framing inserts applied (subtle, not salesy)

| Page | Insert | Action |
|---|---|---|
| `index.html` | Short sentence: the examples are designed to show performance, reporting, assurance and service-improvement thinking relevant to the role — demonstrated through practice | Action applied |
| `data-warehouse-agent-demo.html` | "Why this matters for performance partnering" note: capacity/demand signals, reporting assurance before tables are trusted, genuine change vs data artefact | Action applied |
| `draft-reports.html` | One sentence on performance narrative, caveats and decision support for senior operational/clinical readers | Action applied |
| `governance-and-benefits.html` | One sentence linking the assurance checklist to accountability, validated information and public service values | Action applied |

All inserts use "demonstrates / shows / is relevant to / supports" rather than "proves". None claim Joe has personally delivered the work in a Trust setting.
