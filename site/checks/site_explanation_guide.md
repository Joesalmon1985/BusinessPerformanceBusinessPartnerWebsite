# Website explanation guide

Companion notes for Joe Salmon — use while browsing the demonstration site. This is **not** public website text.

---

## How to use this guide

Keep this file open beside the live site. Use the headings to jump to the page you are on. When you explain the site to someone else, lead with caveats: personal demonstration, not official Trust reporting, human review required.

Each page section follows the same pattern:

- **What this page is for** — plain-English purpose  
- **Why it matters for the application** — link to the Business & Performance Business Partner role  
- **What to notice while browsing** — what to point at on screen  
- **How Joe can explain it** — short spoken script  
- **Caveats to remember** — warnings  
- **Useful links on this page** — only the important ones  

**Path convention:** Page locations are shown as `site/...` paths. Clickable links use `../` from this folder (for example [Homepage](../index.html)).

### Interview-use caveat

The website demonstrates approach, thinking and technical capability. It does **not** by itself evidence every employment criterion. Use the application form, CV and interview examples for senior management, contract negotiation, leadership, influencing and managing competing priorities.

That matches what the site QA audits recorded: the site shows method well; leadership track record and formal qualifications belong in your application materials, not on the website.

---

## One-minute explanation of the whole site

You can say something like this:

“This is a personal demonstration site I built to support my application for the Business & Performance Business Partner role. It is not an official Dorset HealthCare website.

It shows how I would approach performance work in practice: turning public NHS data into clear, caveated first-draft briefs; keeping mandatory reporting organised; using agentic AI with governance; and walking through a synthetic data-warehouse example from messy source files to reporting QA.

The public briefs use published aggregate data for Dorset HealthCare as provider — RDY. The warehouse demo uses entirely fictional Demo Rivers Health data — DRH. Those two must not be mixed up.

Everything on the site is a draft or demonstration. A named person would still validate definitions, check figures, agree interpretation and sign off before any operational use.”

---

## The three strands of the site

The site has three kinds of content, kept deliberately separate:

### 1. Public aggregate reporting examples

- **What:** Six agent-assisted analytical briefs built from published NHS data filtered to RDY (Dorset HealthCare as provider).  
- **Where:** [Draft reports](../draft-reports.html) and the six `site/reports/public-*.html` pages.  
- **Data type:** Real public aggregate statistics — not patient-identifiable, not internal Trust data.  
- **Point:** Shows how performance intelligence can be structured: figure, standard or comparator, trend, caveats, human checks.

### 2. Agent operating model and governance

- **What:** How bounded AI agents could support performance teams safely — SME agents, report QA, IG boundaries, human sign-off.  
- **Where:** [Agent operating model](../agent-operating-model.html), [Governance and benefits](../governance-and-benefits.html), [Mandatory reporting map](../mandatory-reporting-map.html).  
- **Data type:** Illustrative rules and sample register metadata; public reference links where available.  
- **Point:** AI can draft and organise; people remain accountable for definitions, validation and sign-off.

### 3. Synthetic data warehouse demonstration

- **What:** End-to-end worked example for fictional Demo Rivers Health (DRH): source profiling → warehouse design → SQL/pipeline specs → mart → report QA.  
- **Where:** [Warehouse demo](../data-warehouse-agent-demo.html) and three pages under `site/warehouse-demo/reports/`.  
- **Data type:** Synthetic CSV/XLSX extracts — fictional systems, fictional patients and staff identifiers.  
- **Point:** Shows upstream work behind performance reporting: data quality, linkage, extract changes, and telling real pressure from data artefacts.

### Separation rules (repeat whenever needed)

| Rule | Meaning |
|------|---------|
| **RDY ≠ DRH** | Dorset HealthCare public data and fictional Demo Rivers Health are different providers and different datasets. |
| **Not official Trust reporting** | Personal demonstration only — not operationally validated. |
| **Agent outputs are drafts** | Human review, owner confirmation and sign-off always required. |
| **Azure SQL / ADF not live** | DDL and pipeline JSON are specification artefacts, not a deployed warehouse. |

---

## Page-by-page guide

### Page: What this website is about (Homepage)

**Path:** `site/index.html` · [Open](../index.html)

#### What this page is for

Orientation. It explains why the site exists, the main idea (agentic AI supporting performance work with human accountability), the three content types, how the site was built, and what it is designed to show about performance, assurance, service improvement and responsible AI.

#### Why it matters for the application

This page frames the whole application story: you are not just claiming skills — you are showing how you think about performance partnering, validated information, and governed use of new technology. It connects operational experience with data and reporting thinking.

#### What to notice while browsing

- The subtitle: “public and synthetic data only”.  
- The **demonstration caveat** box at the bottom — not official Dorset HealthCare.  
- The card grid naming five areas: mandatory map, draft reports, agent model, governance, warehouse demo.  
- The four “how I think” cards: performance, assurance, service improvement, responsible AI.  
- “How this was built” — Cursor agent under your direction; static site; no live Trust connection.  
- Explore buttons linking to all main sections.

#### How Joe can explain it

“This is my personal demo site for the application. It shows how I would use public data, structured reporting and responsible AI to support business and performance work — always with human review. It is not a finished Trust product.”

#### Caveats to remember

- Not an official Dorset HealthCare website or report.  
- Leadership and senior management experience come from your CV and interview — the homepage lists skills but does not prove employment history.  
- No backend database; no connection to live systems.

#### Useful links on this page

- [Mandatory reporting map](../mandatory-reporting-map.html)  
- [Draft reports](../draft-reports.html)  
- [Warehouse demo](../data-warehouse-agent-demo.html)  
- [Agent operating model](../agent-operating-model.html)  
- [Governance and benefits](../governance-and-benefits.html)

---

### Page: Draft reports

**Path:** `site/draft-reports.html` · [Open](../draft-reports.html)

#### What this page is for

Hub for six worked examples of agent-assisted analytical briefs using **public aggregate NHS data** for RDY. It explains the review-first report structure and how the briefs were created (public sources → R processing → rendered HTML).

#### Why it matters for the application

A Business & Performance Business Partner turns data into useful performance intelligence — not just numbers, but figure, comparator, trend, caveats and what still needs checking. This page shows that workflow in practice.

#### What to notice while browsing

- Hero states **public aggregate NHS data** and “first draft for human review”.  
- The list of what each brief contains: question, data used, headline reading, key findings, human validation checklist, bottom line, audit trail.  
- Six cards linking to the public reports.  
- “How these briefs were created” — reproducible R workflow, not hand-waved text.  
- The **related demonstration** info box: warehouse demo is **separate synthetic DRH** — not the same provider as these RDY briefs.

#### How Joe can explain it

“These are first drafts an agent helped structure from published NHS files. Each one says what the figure is, how it compares, whether it is moving, what caveats apply, and what a human owner must still confirm. They are prompts for review, not board-ready reports.”

#### Caveats to remember

- Not official Dorset HealthCare reports.  
- Public data may be provisional or delayed vs local operational position.  
- Most briefs use **Provider/RDY rows only** — not Dorset population or ICB-resident views.  
- Median and rank on NOF brief are NHS England pass-through fields — not recalculated here.

#### Useful links on this page

- Six public reports (see [Explaining the public reports](#explaining-the-public-reports) below)  
- `site/public-data/PUBLIC_REPORTS_METHOD.md` — method documentation  
- [Warehouse demo](../data-warehouse-agent-demo.html) — synthetic strand, clearly separated

---

### Page: Mandatory reporting map

**Path:** `site/mandatory-reporting-map.html` · [Open](../mandatory-reporting-map.html)

#### What this page is for

A proof-of-concept register of NHS mandatory and statutory returns: return name, owner, frequency, due date, assurance status, risk, notes and public reference link. It also explains how agentic AI could help maintain such a register from public specifications.

#### Why it matters for the application

The role involves NHS reporting and monitoring requirements, assurance meetings and knowing who owns what. This page shows the kind of overview a business partner needs at a glance — and how AI could reduce admin without replacing owners.

#### What to notice while browsing

- Subtitle: “synthetic metadata only” for local fields.  
- Caveat: owners, due dates and assurance statuses are **illustrative sample data**.  
- Note above the table: “In production” badges are demo labels, not verified Trust status.  
- Public reference links point to real published NHS sources.  
- “How agentic AI could help” vs “However, the agent would not approve anything.”

#### How Joe can explain it

“This is the kind of register I would want in a performance team — what is due, who owns it, where the risks are. AI could help draft and maintain the structure from public specs, but named owners still own the local truth and sign-off.”

#### Caveats to remember

- Not a complete or official Dorset HealthCare register.  
- Local owners, source systems and escalation routes are demonstration placeholders.  
- In a live Trust, every return would be checked against local SOPs and governance.

#### Useful links on this page

- `site/data/mandatory_returns_register.csv` — extended fields behind the table  
- [Agent operating model](../agent-operating-model.html) — if asked about automating register maintenance

---

### Page: Agent operating model

**Path:** `site/agent-operating-model.html` · [Open](../agent-operating-model.html)

#### What this page is for

Practical framework for how bounded AI agents could support a Business & Performance team: core principles, SME agents paired with approved sources, workflow diagrams, agent catalogue (categories A–E), and two conversation examples.

#### Why it matters for the application

Shows responsible AI thinking — not hype. Agents are narrow, source-bound assistants with citations and escalation; humans keep accountability for validation, judgement and sign-off. That matches assurance and IG expectations in NHS performance work.

#### What to notice while browsing

- Definition of “an agent”: narrow brief, fixed approved sources, cites answers, escalates when out of scope.  
- **Example 1:** MHSDS Expert Agent tracing an unusual movement — data lineage, DQ vs operational hypotheses, refuses to approve publication.  
- **Example 2:** Report Analysis Agent reviewing a flawed Talking Therapies draft — flags errors before publication.  
- Workflow diagrams ending in **Human sign-off**.  
- Category **E:** Warehouse design demo — links to synthetic DRH work.  
- IG/Safety Agent can block the workflow.

#### How Joe can explain it

“An agent here means a well-briefed assistant for one task — bound to approved sources, always citing where an answer came from. It can draft, structure, check and explain, but it does not sign off returns or make operational decisions.”

#### Caveats to remember

- Agent rules in `site/agent-rules/` are illustrative templates — not deployed in production.  
- MHSDS worked example uses synthetic demonstration records — not a live Trust agent.  
- Local SOPs and IG-approved dictionaries are referenced but not published on the site.

#### Useful links on this page

- [MHSDS worked example](../agent-operating-model.html#mhsds-worked-example)  
- [Report Analysis worked example](../agent-operating-model.html#report-analysis-worked-example)  
- [Category E — Warehouse demo](../agent-operating-model.html#cat-e)  
- `site/agent-rules/` — rule files (technical evidence)

---

### Page: Agentic AI data warehouse demonstration

**Path:** `site/data-warehouse-agent-demo.html` · [Open](../data-warehouse-agent-demo.html)

#### What this page is for

Hub for the synthetic DRH warehouse story — what happens **before** a reporting table exists. Walks through source profiling, design, SQL/pipeline artefacts, marts, report QA, and the three key data-quality stories (Jan–Feb, March, December).

#### Why it matters for the application

Real performance reporting depends on upstream data quality. This demo shows capacity/demand signals, reporting assurance before a table is trusted, and — critically — distinguishing genuine operational change from a data artefact. Agent classifications are draft readings for human confirmation, not validated findings.

#### What to notice while browsing

- **Synthetic demonstration only** — DRH fictional, not RDY, not live Azure.  
- Three reader-facing report cards.  
- End-to-end workflow diagram: extracts → profile → design → SQL → pipelines → marts → QA → human review.  
- Section 4 explicitly separates this from [draft reports](../draft-reports.html) (public RDY data).  
- Fictional source systems list (CareCall, CareCase, etc.).  
- “Likely genuine vs likely artefact” summary for three periods.

#### How Joe can explain it

“This goes one step earlier in the data journey. It starts with messy fictional source extracts and shows how bounded agents could help profile the data, propose a warehouse design, create SQL and pipeline specs, build a mart, and QA a brief — with human review at every stage. It is synthetic because we cannot put real patient data on a public demo site.”

#### Caveats to remember

- Demo Rivers Health (DRH) must not be read as Dorset HealthCare (RDY).  
- Azure SQL and ADF material is specification only — not deployed.  
- Mart built offline by Python script, not a live pipeline.  
- Do not treat agent “likely genuine / likely artefactual” labels as confirmed findings.

#### Useful links on this page

- [Urgent-care warehouse analysis](../warehouse-demo/reports/synthetic-urgent-care-analysis.html)  
- [Reporting-table assurance](../warehouse-demo/reports/synthetic-reporting-table-assurance.html)  
- [Corrected provider-month brief](../warehouse-demo/reports/urgent-care-provider-month-brief.html)  
- Technical cards: `site/warehouse-demo/README.md`, profiling report, design proposal, SQL README, pipeline overview

---

### Page: Governance and benefits

**Path:** `site/governance-and-benefits.html` · [Open](../governance-and-benefits.html)

#### What this page is for

Balanced view of responsible agentic AI: benefits (faster drafts, consistency, audit trail, more time for judgement) vs controls (no PID without IG approval, human sign-off, source-linked definitions, version-controlled rules). Includes an interactive AI assurance checklist.

#### Why it matters for the application

Shows you understand both opportunity and risk — accountability, validated information, transparency and public service values. The checklist is the kind of gate a performance team would use before sharing AI-assisted output with services or Board.

#### What to notice while browsing

- Benefits and controls side by side — neither fearful nor reckless.  
- Checklist items: data approved? definition linked? human owner named? caveats included?  
- Site uses **public aggregate and synthetic demonstration data** — stated explicitly in controls.  
- Closing link between checklist and accountability / validated information.

#### How Joe can explain it

“Used well, agents can speed up first drafts and keep structure consistent. Used carelessly, they create risk. This page is the control framework: clear benefits, hard boundaries, and a checklist a human owner runs before anything goes to services or directors.”

#### Caveats to remember

- Checklist is illustrative for the demonstration — a live Trust would embed this in local governance.  
- Building the site with a Cursor agent is mentioned as an example of human-directed AI use — not autonomous publication.

#### Useful links on this page

- Cross-references to [draft reports](../draft-reports.html) and [warehouse demo](../data-warehouse-agent-demo.html)  
- Agent rules and audit trail concepts on [agent operating model](../agent-operating-model.html)

---

### Page: Synthetic urgent-care warehouse analysis

**Path:** `site/warehouse-demo/reports/synthetic-urgent-care-analysis.html` · [Open](../warehouse-demo/reports/synthetic-urgent-care-analysis.html)

#### What this page is for

Main narrative investigation page for the DRH warehouse demo. Answers: how does the mock warehouse support investigation of urgent-care movements in early 2026, separating genuine operational pressure from extract or attribution artefacts?

#### Why it matters for the application

This is the business-facing story of the warehouse work — triangulating sources, flagging when numbers move together vs when they diverge, and naming what a data owner must confirm. That is core performance partnering when figures shift.

#### What to notice while browsing

- Three finding blocks with figure / comparator / trend / judgement / evidence / human confirmation tables.  
- **Jan–Feb:** IUCS contacts elevated; cases and agency spend corroborate — likely genuine, needs review.  
- **March:** Cases up, IUCS down; many cases without CareCall link; CareCase extract rule change — likely artefactual.  
- **December:** 46 date-boundary mismatches; CareCall export schedule change — attribution issue.  
- Caveat banner: synthetic DRH, not RDY, human sign-off required.

#### How Joe can explain it

“This is where the warehouse demo becomes a performance conversation. In Jan and Feb several sources move together — contacts, cases, bank shifts, spend — which suggests possible real pressure, but still needs an operational lead to confirm. In March cases rise but urgent contacts fall, and the extract log shows a CareCase rule change — so I would not treat March as a demand surge without validation.”

#### Caveats to remember

- All figures are synthetic DRH — not Dorset HealthCare operational data.  
- Judgements are draft agent classifications — not signed-off findings.  
- Evidence comes from profiler outputs and mart CSVs — not live warehouse queries.

#### Useful links on this page

- `site/warehouse-demo/marts/demo_provider_month_measures.csv`  
- `site/warehouse-demo/profile-output/volume_trends.csv`  
- `site/warehouse-demo/profile-output/source_profiling_report.md`  
- [Warehouse demo hub](../data-warehouse-agent-demo.html)

---

### Page: Synthetic reporting-table assurance

**Path:** `site/warehouse-demo/reports/synthetic-reporting-table-assurance.html` · [Open](../warehouse-demo/reports/synthetic-reporting-table-assurance.html)

#### What this page is for

Pre-trust checks on mock warehouse and mart tables before anyone trusts them for narrative use — analogous to mandatory reporting assurance. Row counts, missing keys, linkage ambiguity, expired mappings, date-boundary flags, extract change impacts.

#### Why it matters for the application

Assurance work is not just about statutory returns — it is about knowing whether a reporting table is fit for purpose before it feeds a brief or board paper. This page shows that discipline applied to a synthetic mart.

#### What to notice while browsing

- Assurance results table: check, figure, comparator, trend, status, human action.  
- Row count reconciliation vs source manifest — pass at demo load.  
- March spike in cases without `SourceContactId` — review required.  
- 1,016 ambiguous call-to-case matches — do not force a single match.  
- Extract change log cross-reference for March divergence.

#### How Joe can explain it

“Before I would use a reporting table in a performance brief, I would want checks like this — row counts, keys, linkage quality, extract changes. Agents can help run and document the checks; a BI or information lead still signs off.”

#### Caveats to remember

- Not valid NHS submissions — fictional DRH only.  
- QA view SQL is spec only — not deployed to live Azure.  
- “Pass — demo” means consistent with synthetic load expectations, not production certification.

#### Useful links on this page

- `site/warehouse-demo/sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md`  
- `site/warehouse-demo/profile-output/dq_register.csv`  
- `site/warehouse-demo/design/linkage_resolution_strategy.md`  
- [Urgent-care analysis](../warehouse-demo/reports/synthetic-urgent-care-analysis.html) — interprets the same DQ signals

---

### Page: Urgent care provider-month brief (corrected)

**Path:** `site/warehouse-demo/reports/urgent-care-provider-month-brief.html` · [Open](../warehouse-demo/reports/urgent-care-provider-month-brief.html)

#### What this page is for

Corrected urgent-care brief after Report QA — the kind of output a performance reader would see once profiling evidence is applied. Provider-month measures for DRH Sep 2025–May 2026 with headline reading, caveats and bottom line.

#### Why it matters for the application

Shows the full loop: flawed draft → QA against source evidence → corrected narrative with explicit caveats. That is how AI-assisted reporting should work in practice — not publish the first draft.

#### What to notice while browsing

- Headline reading mirrors the three DQ stories in plain language.  
- Provider-month table: IUCS contacts (activity) vs cases opened (stock-style) vs operational cases vs agency spend.  
- Note on operational case filter (excludes extract-inclusion flag and missing source contact).  
- Caveats: stock vs activity; March extract log; ambiguous linkage; fictional NHS identifiers.  
- Bottom line: do not publish a single “demand surge” narrative without data owner validation.

#### How Joe can explain it

“This is the corrected brief after QA. It separates activity from stock measures, flags March as extract-driven until confirmed, and refuses to over-interpret December date boundaries. It is what I would put in front of a service lead — still a draft needing sign-off, but much safer than the first version.”

#### Caveats to remember

- Synthetic only; `_synthetic=TRUE` tagging in source data.  
- Not RDY-calibrated — fictional trust.  
- Corrected from a deliberately flawed draft (`site/examples/warehouse-draft-urgent-care-brief-flawed.md`) — the QA conversation is the teaching point.

#### Useful links on this page

- [Report QA example on agent operating model](../agent-operating-model.html#report-analysis-worked-example)  
- `site/examples/warehouse-report-qa-conversation.md` — worked QA transcript  
- [Synthetic urgent-care analysis](../warehouse-demo/reports/synthetic-urgent-care-analysis.html)

---

### Page: NHS Oversight Framework performance brief (public)

**Path:** `site/reports/public-performance-overview.html` · [Open](../reports/public-performance-overview.html)

#### What this page is for

First-draft RDY performance brief from public NHS Oversight Framework (NOF) data — which metrics exist, peer median/rank position, quarter-over-quarter trends where available, and priority review flags.

#### Why it matters for the application

Shows KPI thinking at trust level: figure, standard, peer position, trend, validation status, named human check. Flags areas that may need local review without claiming to explain why performance changed.

#### What to notice while browsing

- Priority flags: long-stay adult MH inpatients (OF0063), UCR 2-hour (OF0057), crisis 24h face-to-face (OF0016), relative cost index (OF0086).  
- Main metric table with peer median, rank, trend badges, validation status.  
- “What this report can and cannot tell us” — cannot explain why or confirm local position.  
- Audit trail linking to NHS England published fields — median/rank not recalculated.  
- Human validation checklist and bottom line for business partner use.

#### How Joe can explain it

“This brief triangulates public NOF data for RDY. It highlights where published rank and peer median suggest local review priorities — long-stay inpatients and urgent community response among them — but every figure still needs the service or finance owner to confirm definition and local position before any action.”

#### Caveats to remember

- Public aggregate only; not official Dorset HealthCare reporting.  
- Most metrics are latest-quarter snapshots; only four have QoQ trend in this demo.  
- Rank direction (whether higher or lower is better) needs confirmation against NHS England definitions.

#### Useful links on this page

- `site/public-data/processed/demo_nof_overview.csv`  
- `site/public-data/PUBLIC_REPORTS_METHOD.md`  
- [Draft reports hub](../draft-reports.html)

*Full comparison of all six public reports: [Explaining the public reports](#explaining-the-public-reports).*

---

### Page: MHSDS access and activity profile (public)

**Path:** `site/reports/public-mh-access-profile.html` · [Open](../reports/public-mh-access-profile.html)

#### What this page is for

Six-month public MHSDS briefing for RDY as **provider**: open referrals, people in contact, contacts, and CYP two-contact measure — with descriptive trends and validation flags.

#### Why it matters for the application

Mental health access and activity are central to an MH/community trust. The brief shows stock vs activity thinking and when not to infer access performance from contact counts alone.

#### What to notice while browsing

- Scope badge: Provider/RDY only — not ICB-resident population.  
- Open referrals (MHS23) and in-contact counts (MHS01) rising over six months; contacts (MHS29) broadly stable.  
- **MHS69** volatile — large April movement; major validation flag, not operational improvement.  
- MHS01 renamed nationally from April 2026 — definition change risk.  
- Provisional MHSDS; suppressed values excluded from averages.

#### How Joe can explain it

“Over six months, caseload-style measures rose while contact volume was flat. That might mean pressure on open referrals, but it does not prove access got worse or better — and MHS69 needs a data owner before anyone treats the April jump as real improvement.”

#### Caveats to remember

- Cannot combine provider and resident breakdowns into one headline.  
- Provisional monthly MHSDS may revise.  
- Stock measures ≠ activity measures — do not conflate.

#### Useful links on this page

- `site/public-data/processed/trend_mhsds_access_rdy.csv`  
- [Agent operating model — MHSDS trace example](../agent-operating-model.html#mhsds-worked-example)

---

### Page: CSDS community activity profile (public)

**Path:** `site/reports/public-community-services-profile.html` · [Open](../reports/public-community-services-profile.html)

#### What this page is for

CSDS community **activity** profile for RDY — March 2026 snapshot plus six-month descriptive trends for Assessment and Clinical Intervention where the historic stack supports them.

#### Why it matters for the application

Community services performance needs honest scope limits. This brief shows activity counts, coding quality flags, and signposting to the right source for waiting times.

#### What to notice while browsing

- MoM up for Assessment and Clinical Intervention in March, but **six-month trend down** vs start of window.  
- **“Other”** is 42% of activity — major interpretability flag.  
- Explicit note: community **waiting times** need CHS SitRep / NHS waiting-list data, not CSDS activity alone.  
- Activity counts are coded submissions — not unique patients.

#### How Joe can explain it

“This is an activity profile, not a community waiting-time report. March ticked up month-on-month but six-month movement is down for key types, and nearly half the activity sits in ‘Other’ — so I would want the CSDS owner to validate coding before drawing service conclusions.”

#### Caveats to remember

- Cannot prove referral demand, waiting times or team performance from public aggregate CSDS.  
- Provisional monthly CSDS.  
- Provider/RDY scope only.

#### Useful links on this page

- `site/public-data/processed/trend_csds_activity_rdy.csv`  
- NHS England community waiting-list publication (linked in report)

---

### Page: NHS Talking Therapies access and waits (public)

**Path:** `site/reports/public-talking-therapies-profile.html` · [Open](../reports/public-talking-therapies-profile.html)

#### What this page is for

Public NHS Talking Therapies (IAPT) access and waits brief for RDY: referrals, self-referral mix, six-week and eighteen-week access standards, open referrals with no activity by waiting band.

#### Why it matters for the application

Access standards, pathway mix and waiting-band stock are everyday performance partnering topics. The brief applies national standards where documented and flags pathway-owner validation.

#### What to notice while browsing

- M053 six-week access: **88%** — above 75% national standard but **falling** in trend window.  
- M055 eighteen-week: 99% in latest month — still needs denominator check.  
- Self-referrals ~75% of referrals — confirm expected locally.  
- M019–M022 waiting bands: 6,780 open referrals with no activity; 910 over 120 days.  
- 36 suppressed provider rows — do not infer from missing cells.  
- Outcomes/recovery not covered — access brief only.

#### How Joe can explain it

“RDY remains above national six-week and eighteen-week access standards in the latest month, but six-week access is trending down — worth a pathway review before it becomes a breach risk. Self-referrals dominate volume, and the waiting-band figures need the IAPT lead to confirm how ‘no activity’ is coded locally.”

#### Caveats to remember

- Access measures ≠ clinical outcomes or recovery rates.  
- Link to [Report Analysis worked example](../agent-operating-model.html#report-analysis-worked-example) is about QA methodology — not claiming this brief was published after live QA in Trust.  
- Non-consecutive months in some trend extracts.

#### Useful links on this page

- `site/public-data/processed/demo_talking_therapies.csv`  
- [Agent operating model — flawed draft QA](../agent-operating-model.html#report-analysis-worked-example)

---

### Page: Public statutory assurance source map

**Path:** `site/reports/public-assurance-profile.html` · [Open](../reports/public-assurance-profile.html)

#### What this page is for

Maps which public assurance artefacts contain RDY rows — KO41a complaints, ERIC estates, DSPT IG assessment history, FFT gap, CQC regulatory context. A **source map**, not a performance scorecard.

#### Why it matters for the application

Assurance partnering means knowing which sources exist, what each is useful for, where gaps are, and who to speak to next — without blending unrelated returns into one league table.

#### What to notice while browsing

- KO41a 2024-25: 403 new complaints, 98 upheld — complaints team confirms themes.  
- ERIC 2024/25: estates benchmarking context — not good/bad score.  
- DSPT: latest public assessment Standards met — confirm current-year v8 submission with IG.  
- FFT: **no org-level RDY rows** in downloaded summary — workflow gap, not proof of poor experience.  
- CQC: Outstanding overall (main report 2019) — regulatory context only.  
- “Who to speak to” column on assurance source map table.

#### How Joe can explain it

“This tells me which statutory assurance sources actually contain RDY rows and what each can safely support in a conversation. It is not a composite score — it is a navigation aid so I know to call the complaints team, estates lead, IG owner or patient experience lead as appropriate.”

#### Caveats to remember

- Cannot combine into one assurance score or operational IG conclusion.  
- Annual snapshots — may lag operational position.  
- CQC ratings may be dated; focused inspections may be newer.

#### Useful links on this page

- `site/public-data/processed/demo_assurance_profile.csv`  
- `site/public-data/metadata/fft_manual_download_needed.md` — FFT org-level gap notes

---

### Page: Urgent care, diagnostics and beds source check (public)

**Path:** `site/reports/public-urgent-diagnostics-check.html` · [Open](../reports/public-urgent-diagnostics-check.html)

#### What this page is for

Checks whether RDY appears in public A&E, DM01 diagnostics and KH03 bed-stock files; explains what each source can safely support for a **trust without a Type 1/2 emergency department**.

#### Why it matters for the application

Not every national urgent-care metric applies to an MH/community trust. This brief shows source-applicability thinking — validating service model before drawing ED-style conclusions.

#### What to notice while browsing

- Sources grouped for checking convenience — **not** one performance pathway.  
- A&E: RDY present; **zero Type 1/2 attendances** — source validation, not ED performance.  
- DM01 Apr 2026: audiology dominates waiting-list volume (2,306 of 2,361).  
- KH03: quarterly mental illness bed snapshots — may lag A&E/DM01 dates.  
- Bottom line: applicability check, not unified urgent-care performance report.

#### How Joe can explain it

“For RDY I checked whether these national files actually apply. A&E confirms we do not run a Type 1/2 ED — so those rows validate coding, not A&E performance. DM01 is mainly an audiology/community diagnostics picture here. KH03 gives quarterly MH bed-stock context. Each needs a local owner before operational use.”

#### Caveats to remember

- Does not prove urgent care or diagnostic performance standing.  
- Small A&E “other emergency admissions” counts need service-model confirmation.  
- KH03 latest snapshot in extract may be older than monthly DM01/A&E.

#### Useful links on this page

- `site/public-data/processed/trend_ae_rdy.csv`, `trend_dm01_rdy.csv`, `trend_kh03_beds_rdy.csv`  
- Filter notes in `site/public-data/metadata/`

---

## Explaining the public reports

Quick reference for all six RDY public briefs. Each is a **first draft** from published aggregate data — human review required.

### Jargon used across the reports

| Term | Plain English |
|------|----------------|
| **Figure** | The latest published value for RDY from the NHS source file. |
| **Standard / expected** | National target or threshold where one exists in published guidance (e.g. 75% six-week IAPT access). |
| **Peer median / rank** | NHS England published comparators for the peer group — on the NOF brief, **not recalculated** by this demo. |
| **Trend** | Descriptive direction over available historic months — not proof of cause. |
| **Provider / RDY rows** | Trust as **provider** of services — not Dorset population or ICB-resident views. |
| **Stock vs activity** | **Stock:** caseload at a point in time (e.g. open referrals). **Activity:** events in the month (e.g. contacts). They tell different stories. |

### 1. Performance overview (NOF)

- **Question:** Where does RDY sit on NOF metrics vs peer median and rank?  
- **Notice:** Priority review on long-stay inpatients, UCR, crisis 24h contact, cost index.  
- **Does not prove:** Why metrics moved; that public figures match latest internal dashboards.  
- **Role link:** Trust-wide KPI scanning and prioritising what to validate with service and finance owners.

### 2. MHSDS access profile

- **Question:** Six-month MHSDS access and activity for RDY provider?  
- **Notice:** Stock up, contacts flat; MHS69 volatile — do not read April spike as improvement.  
- **Does not prove:** Access improved or worsened; ICB-resident picture.  
- **Role link:** Mental health data quality and cautious access narrative.

### 3. Community services profile (CSDS)

- **Question:** What did community **activity** look like in Mar 2026 and over six months?  
- **Notice:** MoM up, six-month down; 42% “Other” category.  
- **Does not prove:** Waiting times — need CHS waiting-list sources.  
- **Role link:** Honest scope limits and coding-quality flags for community services.

### 4. Talking Therapies profile

- **Question:** IAPT referrals, access standards and waiting bands for RDY?  
- **Notice:** Above six-week standard but falling trend; heavy self-referral mix.  
- **Does not prove:** Recovery, reliable improvement or clinical outcomes.  
- **Role link:** Pathway access monitoring and early breach-risk conversation.

### 5. Assurance profile

- **Question:** Which assurance sources have RDY rows and who should you call?  
- **Notice:** KO41a, ERIC, DSPT confirmed; FFT org gap; CQC context only.  
- **Does not prove:** Composite assurance rating or operational IG compliance.  
- **Role link:** Statutory assurance navigation and meeting preparation.

### 6. Urgent, diagnostics and beds check

- **Question:** Do A&E, DM01 and KH03 apply to RDY and what can each support?  
- **Notice:** Zero Type 1/2 A&E; audiology-heavy DM01; quarterly KH03 beds.  
- **Does not prove:** ED performance or a single urgent-care dashboard.  
- **Role link:** Service-model-aware use of national sources.

---

## Explaining the synthetic data warehouse demo

### The story in seven steps

1. **Synthetic source data created** — Python generator produced fictional CSV/XLSX extracts for Demo Rivers Health (CareCall, CareCase, Legendary Care, RosterFlow, LedgerWise, LocalOps).  
2. **Agents profiled messy sources** — grain, keys, linkage scenarios, volume trends, data-quality register, extract-change risks.  
3. **Agents proposed warehouse design** — staging with DQ flags, dimensions, facts, bridge tables for ambiguous matches, provider-month marts.  
4. **SQL artefacts generated** — Azure SQL-style DDL and QA views (**specification only**, not live deployment).  
5. **Pipeline specs generated** — ADF-style JSON for ingest, stage, load, refresh marts (**not live**).  
6. **Reporting tables and QA examples produced** — offline mart CSV; flawed brief corrected after Report QA; three HTML reader pages.  
7. **Site explains findings** — urgent-care analysis, reporting-table assurance, corrected brief — all with human review gates.

### Fictional source systems

| System | Role in the demo |
|--------|------------------|
| **CareCall** | Urgent and unscheduled care contacts (IUCS pathway) |
| **CareCase** | Case management — case opens and status |
| **Legendary Care** | Referrals and encounters |
| **RosterFlow** | Bank and substantive staff shifts |
| **LedgerWise** | Agency and bank spend by cost centre |
| **LocalOps spreadsheets** | Extract change logs, user ID mappings, validation notes |

### Three data-quality stories (primary evidence: profiling report and urgent-care analysis)

**1. Jan–Feb 2026 — possible genuine operational pressure**

- IUCS contacts elevated (~1,592 Jan, ~1,477 Feb) vs Sep–Nov baseline ~1,263.  
- Operational cases, urgent-care bank shifts and agency spend move in the same direction.  
- LocalOps validation notes reference bank-holiday pressure.  
- **Interpretation:** Several sources corroborate — may reflect real pressure, but urgent care and performance leads must confirm before board or service reporting.  
- **Not proof of:** Cause (demand vs capacity vs coding); sustained trend beyond Feb.

**2. March 2026 — likely extract / data issue**

- Case opens rise (542, +3% MoM) but IUCS contacts **fall** (1,272, −14% MoM).  
- 322 of 542 March cases lack CareCall `SourceContactId` (vs 123 in Feb).  
- LocalOps extract change log records **CareCase inclusion rule change** effective March run (2026-02-28).  
- **Interpretation:** Pattern fits extract-driven case inflation more than front-door demand surge — CareCall activity does not support the same story.  
- **Not proof of:** That March is entirely non-operational — data owner must confirm rule change impact.

**3. December 2025 — date-boundary / reporting period issue**

- 46 IUCS contacts have `ContactDate` one calendar day earlier than `CreatedDateTime` date (DQ001).  
- CareCall export schedule moved to 02:00 UTC on 2025-12-04 per extract change log.  
- **Interpretation:** Month attribution may be wrong for those contacts — flag, do not silently dedupe.  
- **Not proof of:** Operational change in December — headline MoM movement was modest (+4.6% IUCS).

---

## Shorter notes for supporting artefacts

These are mainly **technical evidence**. Reader-facing pages above are what you show in an interview first.

### `site/warehouse-demo/source-notes/demo_run_index.md`

[Open](../warehouse-demo/source-notes/demo_run_index.md)

Table of contents for warehouse Runs 1–5: source pack → profiling → design → SQL → pipelines/mart/QA. Use when you need to find a specific artefact path. An internal reviewer checklist exists for warehouse QA — that is for reviewers only, not evidence for this guide.

### `site/warehouse-demo/profile-output/source_profiling_report.md`

[Open](../warehouse-demo/profile-output/source_profiling_report.md)

First deep-dive on synthetic sources: file inventory, grain and keys, linkage scenarios, volume trends, extract vs reality table, DQ register priorities. **Primary evidence** for the three DQ stories.

### `site/warehouse-demo/design/warehouse_design_proposal.md`

[Open](../warehouse-demo/design/warehouse_design_proposal.md)

How profiling findings became design choices: staging flags, bridge tables, provider-month marts, open decisions in human review pack. Status: draft pending human review — not approved for production.

### `site/warehouse-demo/sql/README.md`

[Open](../warehouse-demo/sql/README.md)

DDL run order and optional local loader. **Demonstration specification** — explicitly not deployed to live Azure SQL.

### `site/warehouse-demo/pipelines/pipeline_overview.md`

[Open](../warehouse-demo/pipelines/pipeline_overview.md)

Four fictional ADF pipelines with schedules and DQ gates between activities. Shows how loads would be orchestrated in a real project — JSON specs only.

### `site/checks/final_site_critical_sweep_checkpoint.md`

[Open](final_site_critical_sweep_checkpoint.md)

What was QA’d before submission: separation, caveats, nav fixes, role-framing inserts. Lists what the site **cannot** prove (leadership, qualifications, contract negotiation — CV/interview).

### `site/checks/business_performance_role_alignment_audit.md`

[Open](business_performance_role_alignment_audit.md)

Private map from site pages to job description themes (Strong / Adequate / Weak / Missing). Useful prep — not for showing interviewers unless they ask about alignment methodology.

---

## Questions Joe might be asked and suggested answers

### Why did you build a website for the application?

“A CV lists skills; this site shows the **method** in one place — public-data briefs, assurance thinking, governed agents and a synthetic warehouse walkthrough. It keeps public and synthetic data separated and every output marked as draft. It is easier to explore than a long PDF appendix.”

### Is this official Dorset HealthCare reporting?

“No. It is a personal demonstration site. Every page says so. Nothing here should be used for operational decisions without local validation.”

### What data did you use?

“Two separate types: published **aggregate NHS data** for RDY on the draft reports, and entirely **fictional synthetic data** for the Demo Rivers Health warehouse demo. No patient-identifiable or confidential Trust data.”

### What is agentic AI in this context?

“AI assistants given a **narrow written brief** and **approved sources** — for example one return’s published specification. They draft, structure, check and cite. They stop and escalate when something is outside their sources. They do not sign off or submit returns.”

### Does this mean AI replaces analysts?

“No. It reduces admin-heavy first-draft work so analysts and business partners spend more time on judgement, stakeholder conversations and validation. The site repeats that humans own definitions, figures, interpretation and sign-off.”

### Why use synthetic data for the warehouse demo?

“Real patient data, staff records and live Azure resources cannot go on a public application site. Synthetic data lets me show realistic multi-system mess — extract changes, linkage problems, date boundaries — without confidentiality risk.”

### What does the data warehouse demo show?

“The journey **before** a reporting table exists: profile sources, design a warehouse, spec SQL and pipelines, build a mart, assure the table, QA a brief. The business punchline is telling Jan–Feb corroborated pressure from a March extract artefact.”

### How does this relate to the Business & Performance Business Partner role?

“It touches performance management, NHS reporting, validated information, senior-readable narratives, capacity/demand signals, assurance and governance — through worked examples. Senior management and leadership examples come from my application and interview, not from the site alone.”

### What would still need human review?

“Everything operational: metric definitions, source freshness, figure accuracy, interpretation, caveats, whether a brief is fit for a service meeting or Board, and formal sign-off. Agent outputs are starting points.”

### What are the limitations of the site?

“Static HTML — no live database. Warehouse SQL/ADF not deployed. Public data may be provisional. Agent ‘likely genuine / artefactual’ labels are draft. It does not evidence every person-spec criterion.”

### What would you do next if this were a real Trust project?

“IG and information governance approval for data and tools; named owners to validate definitions; connect to approved sources and local dictionaries; pilot one bounded agent with audit logging; deploy warehouse through normal change control; never skip Report QA before distribution.”

---

## Things not to claim

Do **not** say:

- “This is official Trust reporting.”  
- “This uses real patient data.”  
- “This is a production Azure warehouse.”  
- “The agent proved the answer.”  
- “AI can sign off reports.”  
- “This alone proves I meet every role criterion.”  
- “This demonstrates I have led at senior management level” — unless you support that from CV/interview, not the site.  
- “This shows contract/SLA negotiation experience” — site does not cover that.  

Also avoid implying live deployment, Trust endorsement, or that public brief figures match current internal dashboards without validation.

See **Interview-use caveat** at the top — the site supports the application but does not replace work-history evidence for senior management, negotiation, leadership, influencing or managing competing priorities.

---

## If asked for technical detail

Stay brief. The business story matters more than syntax in most conversations.

**Useful angles:**

- “The technical artefacts are there as evidence that the demonstration is **concrete** — not because I expect you to read every SQL file in an interview.”  
- “The important business point is **source-to-report assurance**: profiling messy inputs, checking a table before you trust it, and separating real operational change from a data artefact.”  
- “In a real Trust project, data owners, IG, analysts and operational leads would validate definitions before anything went near a board pack.”

### “So did you actually build a warehouse?”

Answer honestly:

- There is **no live Azure deployment**. DDL and pipeline JSON are **demonstration specifications**.  
- Synthetic source data was generated locally; the mart was built with an **offline Python script**, not a running ADF pipeline.  
- What **was** built end-to-end is the **method** — profile → design → spec artefacts → mart → QA’d brief — with checkpoints and human review gates visible on the site.  
- Offer the **reader-facing pages**: [warehouse demo hub](../data-warehouse-agent-demo.html), [urgent-care analysis](../warehouse-demo/reports/synthetic-urgent-care-analysis.html), [reporting-table assurance](../warehouse-demo/reports/synthetic-reporting-table-assurance.html). Open `site/warehouse-demo/sql/` only if they explicitly want depth.

**Redirect phrases:**

- “Happy to point you at the profiling report or the assurance checklist.”  
- “The SQL folder is supporting evidence — the story is on the analysis page.”

---

## Best route through the site for an interviewer

About **5–10 minutes**. Adjust depth to their interest.

| Step | Page | Point out |
|------|------|-----------|
| 1 | [Homepage](../index.html) | Three content types; demonstration caveat; built with agent under your direction |
| 2 | [Draft reports](../draft-reports.html) | Review-first brief structure; public RDY data only |
| 3 | One public report — [NOF overview](../reports/public-performance-overview.html) or [Talking Therapies](../reports/public-talking-therapies-profile.html) | Figure, standard, trend, human check; priority flags or access standards |
| 4 | [Warehouse demo](../data-warehouse-agent-demo.html) | Workflow diagram; **DRH ≠ RDY**; synthetic only |
| 5 | [Urgent-care analysis](../warehouse-demo/reports/synthetic-urgent-care-analysis.html) | Three DQ stories: Jan–Feb vs March vs December |
| 6 | [Agent operating model](../agent-operating-model.html) | MHSDS trace or Report QA example; human sign-off |
| 7 | [Governance](../governance-and-benefits.html) | Benefits vs controls; assurance checklist |

**Optional if they ask about returns:** [Mandatory reporting map](../mandatory-reporting-map.html) — illustrative owners, real public reference links.

---

## Final short script (60–90 seconds)

“This is a personal demonstration site for my Business & Performance Business Partner application — not an official Dorset HealthCare website.

It shows how I would approach the role in practice. One part uses published NHS aggregate data to produce caveated first-draft performance briefs for RDY — figure, comparator, trend, and what a human owner must still check. Another part explains how bounded AI agents could support reporting and assurance work safely, with governance and human sign-off at every step.

There is also a synthetic warehouse demonstration for a fictional trust — Demo Rivers Health — that walks from messy source extracts through profiling, design, and reporting QA. That is separate from the public RDY briefs. The key business lesson there is telling when several sources corroborate possible operational pressure versus when a spike is more likely an extract or data-quality artefact.

Nothing on the site is operationally validated. I built it with a Cursor agent under my direction, using public and synthetic data only. The value is the method — clear performance narrative, assurance discipline, and responsible use of AI — and I would still rely on named owners to validate definitions and sign off before any real operational use.”

---

*Guide version: companion to demonstration site as of June 2026. For internal use by Joe Salmon only.*
