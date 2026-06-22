# Homepage index — proposed changes

**Purpose:** Reviewable proposal for improving [`site/index.html`](../index.html). This file supplies copy-ready replacement text and link targets. **Do not apply to HTML until approved.**

**Tone target:** Warm, confident, practical, human. Plain English for a non-technical NHS reader (around reading age 12). No hype or marketing fluff.

**Safety rules preserved throughout:** personal demonstration site; not official Dorset HealthCare; public aggregate and synthetic data only; no patient-identifiable, staff-identifiable or confidential Trust data; RDY public briefs kept separate from DRH synthetic examples; AI supports human judgement, not replaces it; no invented claims.

---

## 1. Evidence map

Strongest examples already on the site, grouped by the four thinking themes used on the homepage.

### How I think about performance

| Page / file | What it demonstrates | Data type | Suggested homepage link text |
|-------------|----------------------|-----------|------------------------------|
| [`reports/public-performance-overview.html`](../reports/public-performance-overview.html) | Trust-wide KPI brief: figure, peer median/rank, trend, validation status and priority review flags (long-stay inpatients, UCR, crisis access, cost index) | Public aggregate (RDY) | NHS Oversight Framework performance brief |
| [`reports/public-mh-access-profile.html`](../reports/public-mh-access-profile.html) | Six-month MHSDS access and activity: stock vs activity, rising caseload vs flat contacts, MHS69 validation flag | Public aggregate (RDY) | MHSDS access and activity profile |
| [`reports/public-community-services-profile.html`](../reports/public-community-services-profile.html) | CSDS community activity: MoM vs six-month trend, “Other” coding flag, honest scope limits | Public aggregate (RDY) | Community services activity profile |
| [`reports/public-talking-therapies-profile.html`](../reports/public-talking-therapies-profile.html) | IAPT access standards (75% six-week, 95% eighteen-week), falling six-week trend, waiting-band stock | Public aggregate (RDY) | Talking Therapies access and waits brief |
| [`reports/public-urgent-diagnostics-check.html`](../reports/public-urgent-diagnostics-check.html) | Source-applicability check for A&E, DM01 and KH03 — what each source can and cannot support for an MH/community trust | Public aggregate (RDY) | Urgent care, diagnostics and beds source check |
| [`warehouse-demo/reports/synthetic-urgent-care-analysis.html`](../warehouse-demo/reports/synthetic-urgent-care-analysis.html) | Figure, comparator, trend and judgement for Jan–Feb pressure vs March extract artefact vs December date-boundary issue | Synthetic (DRH) | Synthetic urgent-care warehouse analysis |

### How I think about assurance

| Page / file | What it demonstrates | Data type | Suggested homepage link text |
|-------------|----------------------|-----------|------------------------------|
| [`mandatory-reporting-map.html`](../mandatory-reporting-map.html) | Return name, owner, frequency, due date, assurance status, risk and public reference links | Synthetic local metadata + public NHS references | Mandatory reporting map |
| [`reports/public-assurance-profile.html`](../reports/public-assurance-profile.html) | Which statutory assurance sources contain RDY rows; who to contact; not a composite scorecard | Public aggregate (RDY) | Public statutory assurance source map |
| [`warehouse-demo/reports/synthetic-reporting-table-assurance.html`](../warehouse-demo/reports/synthetic-reporting-table-assurance.html) | Pre-trust checks on row counts, keys, linkage ambiguity and extract-change impacts | Synthetic (DRH) | Reporting-table assurance |
| [`warehouse-demo/profile-output/dq_register.csv`](../warehouse-demo/profile-output/dq_register.csv) | Data-quality register with priorities, owners and human actions | Synthetic (DRH) | Data-quality register |
| [`governance-and-benefits.html#checklist`](../governance-and-benefits.html#checklist) | Interactive AI assurance checklist before sharing output with services or Board | Illustrative framework | AI assurance checklist |
| [`examples/report-analysis-agent-conversation.md`](../examples/report-analysis-agent-conversation.md) | Report QA catching arithmetic, definition and trend errors before publication | Public RDY demo workflow | Report Analysis Agent conversation |
| [`public-data/PUBLIC_REPORTS_METHOD.md`](../public-data/PUBLIC_REPORTS_METHOD.md) | Reproducible method from public source to draft brief with validation | Public methodology | Public reports method |

### How I think about service improvement

| Page / file | What it demonstrates | Data type | Suggested homepage link text |
|-------------|----------------------|-----------|------------------------------|
| [`warehouse-demo/reports/synthetic-urgent-care-analysis.html`](../warehouse-demo/reports/synthetic-urgent-care-analysis.html) | Demand/capacity signals (contacts, cases, bank shifts, agency spend); distinguishing real pressure from extract-driven spike | Synthetic (DRH) | Synthetic urgent-care warehouse analysis |
| [`warehouse-demo/reports/urgent-care-provider-month-brief.html`](../warehouse-demo/reports/urgent-care-provider-month-brief.html) | Corrected brief after QA — stock vs activity, explicit caveats, no single “demand surge” narrative without validation | Synthetic (DRH) | Corrected urgent-care provider-month brief |
| [`reports/public-mh-access-profile.html`](../reports/public-mh-access-profile.html) | Caseload rising while contacts flat — prompts operational questions without over-claiming access performance | Public aggregate (RDY) | MHSDS access and activity profile |
| [`reports/public-community-services-profile.html`](../reports/public-community-services-profile.html) | Activity profile with coding-quality warning; signposts to correct source for waiting times | Public aggregate (RDY) | Community services activity profile |
| [`reports/public-talking-therapies-profile.html`](../reports/public-talking-therapies-profile.html) | Above standard but falling six-week access — early breach-risk conversation | Public aggregate (RDY) | Talking Therapies access and waits brief |

### How I think about responsible AI

| Page / file | What it demonstrates | Data type | Suggested homepage link text |
|-------------|----------------------|-----------|------------------------------|
| [`agent-operating-model.html`](../agent-operating-model.html) | Bounded agents, approved sources, citations, human sign-off, IG gate | Illustrative framework | Agent operating model |
| [`examples/mhsds-sme-agent-conversation.md`](../examples/mhsds-sme-agent-conversation.md) | Tracing a figure to source; DQ vs operational hypotheses; refusal to over-interpret | Synthetic demo | MHSDS Expert Agent conversation |
| [`examples/report-analysis-agent-conversation.md`](../examples/report-analysis-agent-conversation.md) | Checking a flawed draft against approved sources; numbered findings; no autonomous approval | Public RDY QA demo | Report Analysis Agent conversation |
| [`governance-and-benefits.html`](../governance-and-benefits.html) | Benefits vs controls; public/synthetic only; named owner sign-off | Framework | Governance and benefits |
| [`data-warehouse-agent-demo.html`](../data-warehouse-agent-demo.html) | End-to-end synthetic workflow with human review at every stage; DRH ≠ RDY | Synthetic (DRH) | Warehouse demo |
| [`agent-rules/README.md`](../agent-rules/README.md) | Version-controlled agent rules by category (SME, workflow, IG, warehouse) | Illustrative rules | Agent rules index |
| [`examples/warehouse-source-profiling-conversation.md`](../examples/warehouse-source-profiling-conversation.md) | Bounded source-profiling agent on synthetic extracts | Synthetic (DRH) | Source profiling conversation |
| [`examples/warehouse-report-qa-conversation.md`](../examples/warehouse-report-qa-conversation.md) | Report QA on a flawed synthetic brief before correction | Synthetic (DRH) | Warehouse report QA conversation |

---

## 2. Current homepage diagnosis

### What works well

- **Subtitle and footer** clearly state “public and synthetic data only” and “not an official Dorset HealthCare website or report.”
- **Demonstration caveat box** (lines 165–167) is strong, specific and should be kept verbatim or near-verbatim.
- **Three-strand separation** in “Purpose of this site” (public RDY briefs / synthetic DRH warehouse / agent governance) is correct and important.
- **Five navigation cards** give a clear map of the site; structure is sound.
- **“How this was built”** is honest about human-directed Cursor use, static site, no live Trust connection.
- **Warning box under “The main idea”** correctly states AI cannot replace professional judgement.
- **“Why this is relevant to the role”** skills list is reasonable; the info-box correctly frames the site as “demonstration of approach,” not a finished Trust product.

### What could be stronger

#### Opening hook (`h1` “What this website is about”)

The hero opens with “This website supports my application…” That is true but application-framed rather than demonstration-framed. It does not quickly answer:

- **What is this site?** — only implied.
- **Why did Joe build it?** — skills are listed, but not “to show the method in one place.”
- **What does it prove?** — asserted (“shows how I would use…”) without pointing to worked examples.
- **Where can the reader see examples?** — no links in the hero.

The role-context paragraphs (bridge between services, corporate, finance) are good but come before the reader knows what they are looking at.

#### “The main idea”

- The info-box opens with coding and apps (“While Agentic AI has some obvious benefits when it comes to writing code and creating apps…”). That is a weak entry for an NHS business partner audience and understates the performance story.
- The nine bullets are useful but **completely unlinked** — the biggest single missed opportunity on the page.
- AI is introduced before concrete NHS performance work.

#### “Purpose of this site”

- Solid three-strand explanation and card grid.
- Card blurbs describe pages generically; none name a specific worked example (e.g. Talking Therapies brief, mandatory map register, warehouse urgent-care analysis).
- Repeats ideas already in the hero without adding specificity.

#### “What this site is designed to show”

- Four cards state the right principles (performance, assurance, service improvement, responsible AI).
- **No links to any example** — principles only, despite the site having six public briefs and three warehouse reader pages that embody these ideas.
- This is the section most likely to engage a reviewer; it currently under-delivers.

#### AI “It can help with” list

- Good task list but reads like a generic capability brochure.
- No proof points; reader must navigate elsewhere to find examples.

#### “Why this is relevant to the role”

- Skills list overlaps slightly with “What this site is designed to show” but each adds value (skills vs thinking themes).
- Does not point to where those skills are demonstrated on the site.

#### Explore / navigation cards

- Explore buttons duplicate the nav; fine for navigation but do not guide a first-time reader.
- No suggested reading route (e.g. “start with one public brief, then the warehouse analysis”).

#### Repeated points

- “Practical demonstration,” “how I would approach the role,” and the four thinking themes appear in multiple sections without new detail each time.
- Fix: keep the structure but make each pass **more specific** (add example links) rather than shorter.

---

## 3. Proposed section-by-section changes

Copy-ready text below uses paths relative to `site/index.html`. In HTML, use standard `<a href="...">` markup.

---

### 3.1 Hero — replace `h1` and hero paragraphs

**Current section name:** Hero — “What this website is about”

**Reason for change:** Answer the four reader questions in plain English; sound purposeful without hype; link early to concrete examples.

**Proposed replacement text:**

```html
<h1>A practical demonstration of Business &amp; Performance work</h1>
<p class="hero-lead">This is my personal demonstration site for the Business &amp; Performance Business Partner role. It is not an official Dorset HealthCare website or report.</p>
<p>I built it to show how I would approach the work in practice — not just list skills on an application form. The examples walk through turning data into clear performance intelligence, checking assurance risks, supporting service improvement, and using AI safely under human control.</p>
<p>You can explore <a href="draft-reports.html">six draft briefs from public NHS data</a> (for Dorset HealthCare as provider — RDY), a separate <a href="data-warehouse-agent-demo.html">synthetic warehouse demonstration</a> for fictional Demo Rivers Health (DRH), and pages on <a href="agent-operating-model.html">how bounded AI agents could support the work</a> with governance and sign-off.</p>
<p>The role is not just about producing reports. It is about helping services understand what is happening, spot risks early, and make better decisions. A good Business &amp; Performance Business Partner connects services, corporate teams, finance, information teams and senior leaders — and makes performance information useful, not just available.</p>
```

**Links to include:** `draft-reports.html`, `data-warehouse-agent-demo.html`, `agent-operating-model.html`

**Caveat that must remain nearby:** Hero lead states “not an official Dorset HealthCare website or report”; full demonstration caveat box stays below (unchanged).

---

### 3.2 “The main idea” — replace info-box, intro and bullet list

**Current section name:** The main idea

**Reason for change:** Remove coding/apps opener; lead with NHS performance work; weave example links into bullets (see also Section 5).

**Proposed replacement text:**

```html
<h2 id="main-idea">The main idea</h2>
<div class="info-box">
  <p>Agentic AI can help NHS business and performance teams work faster, more clearly and more consistently — when it is used with clear sources, human review and honest caveats.</p>
</div>
<p>In this demonstration, AI supports the work; it does not replace professional judgement. It can help with:</p>
```

Then use the revised bullet list from **Section 5** (below).

Keep the existing warning box unchanged:

```html
<div class="warning-box" role="note">
  <p><strong>However, AI cannot and should not replace professional judgement.</strong></p>
  <p>People must still be responsible for definitions, data checks, interpretation, decisions, escalation and sign-off.</p>
</div>
```

**Caveat:** Warning box must stay immediately after the bullet list.

---

### 3.3 “Purpose of this site” — tighten prose and enrich cards

**Current section name:** Purpose of this site

**Reason for change:** Add one woven example per strand; enrich card blurbs without lengthening excessively.

**Proposed replacement text (prose before cards):**

```html
<h2 id="site-purpose">Purpose of this site</h2>
<p>This site is a practical demonstration of how I would approach the role — shown through worked examples, not just described.</p>
<p>It shows how performance information can be made clearer (see the <a href="reports/public-performance-overview.html">NHS Oversight Framework brief</a>), how mandatory reporting can be organised and checked (see the <a href="mandatory-reporting-map.html">mandatory reporting map</a>), and how bounded AI agents could support busy teams when used safely (see the <a href="agent-operating-model.html">agent operating model</a>).</p>
<p>The material falls into three kinds, kept clearly separate: draft reports built from <strong>public aggregate NHS data</strong> for RDY; a <strong>synthetic</strong> Demo Rivers Health (DRH) data warehouse example; and an agent operating model and governance explanation. <strong>RDY and DRH are different providers and must not be mixed up.</strong></p>
```

**Proposed card-purpose replacements:**

| Card | Proposed `card-purpose` text |
|------|------------------------------|
| Mandatory reporting map | Owners, frequency, due dates and assurance status for NHS returns — with public reference links. Example: MHSDS monthly return row in the register. |
| Draft performance reports | Six agent-assisted briefs from public NHS data — e.g. the <a href="reports/public-talking-therapies-profile.html">Talking Therapies access brief</a> with standards, trends and human checks. |
| Agent operating model | Bounded agents with approved sources and citations — e.g. the <a href="agent-operating-model.html#mhsds-worked-example">MHSDS trace example</a> and <a href="agent-operating-model.html#report-analysis-worked-example">Report Analysis QA example</a>. |
| Governance and benefits | Benefits, controls and the <a href="governance-and-benefits.html#checklist">AI assurance checklist</a> — human sign-off before anything goes to services or Board. |
| Synthetic data warehouse demonstration | Fictional DRH source extracts through profiling, warehouse design, SQL/pipeline specs and reporting QA — e.g. the <a href="warehouse-demo/reports/synthetic-urgent-care-analysis.html">urgent-care analysis</a> separating real pressure from data artefacts. |

Keep closing line: “Each page starts with a plain-English summary, so the site can be followed without a technical background.”

**Caveat:** RDY ≠ DRH separation must remain explicit in prose.

---

### 3.4 “How this was built” — minor addition only (optional)

**Current section name:** How this was built

**Reason for change:** Optional one-sentence link to governance page; otherwise keep as-is.

**Proposed addition** (after first paragraph):

```html
<p>This is itself an example of responsible AI use — see <a href="governance-and-benefits.html">governance and benefits</a> for the controls that would apply in a Trust setting.</p>
```

**Recommendation:** Optional. Section can stay unchanged if homepage length is a concern.

---

### 3.5 “What this site is designed to show” — replace card grid with prose sections

**Current section name:** What this site is designed to show

**Reason for change:** Cards state principles without proof; convert to prose with woven links (full text in **Section 6**).

**Structural change:** Replace four `card` articles with four subsections (`h3` + paragraphs), or keep cards but add linked prose inside each — see Section 6 for full wording.

---

### 3.6 “Why this is relevant to the role” — light edit

**Current section name:** Why this is relevant to the role

**Reason for change:** Connect skills list to on-site evidence without new claims.

**Proposed replacement** (add one sentence after the skills list intro):

```html
<p>This site shows the mix of skills I would bring to the Business &amp; Performance Business Partner role:</p>
<ul>
  <!-- keep existing seven bullets unchanged -->
</ul>
<p>Those skills are demonstrated in the worked examples above — for instance, performance narrative in the <a href="draft-reports.html">draft reports</a>, assurance discipline in the <a href="mandatory-reporting-map.html">mandatory reporting map</a> and <a href="governance-and-benefits.html">governance pages</a>, and responsible AI in the <a href="agent-operating-model.html">agent operating model</a>.</p>
```

Keep the existing info-box unchanged.

**Caveat:** Do not claim the site proves leadership track record or senior management experience — those remain CV/interview evidence.

---

### 3.7 “Explore this demonstration” — add guided route

**Current section name:** Explore this demonstration

**Reason for change:** Buttons alone do not orient first-time readers.

**Proposed replacement text** (before or after button row):

```html
<h2 id="explore">Explore this demonstration</h2>
<p>If you have five minutes, try this route: start with one <a href="reports/public-performance-overview.html">public performance brief</a>, open the <a href="warehouse-demo/reports/synthetic-urgent-care-analysis.html">synthetic urgent-care analysis</a> to see how upstream data quality affects the story, then read one <a href="agent-operating-model.html#mhsds-worked-example">agent conversation example</a> and the <a href="governance-and-benefits.html#checklist">assurance checklist</a>.</p>
<div class="explore-links">
  <!-- keep existing five buttons -->
</div>
```

---

### 3.8 Sections to keep unchanged

- **Demonstration caveat box** (lines 165–167) — keep verbatim.
- **Footer caveat** — keep verbatim.
- **“How this was built”** — keep unless optional governance link is approved.

---

## 4. Work links into the actual text

The proposals above follow the woven-link pattern throughout. Examples:

- Hero links to draft reports, warehouse demo and agent operating model in explanatory sentences — not a trailing “see also” list.
- “Purpose” links to NOF brief, mandatory map and operating model in the same paragraph as the three-strand explanation.
- Card blurbs name specific examples inline.
- “Designed to show” (Section 6) embeds links in each theme paragraph.
- Bullet list (Section 5) uses “as shown in [example]” for each item where a strong example exists.

**Avoid:** Closing each section with “Examples: A, B, C.” **Prefer:** One example per sentence where it clarifies the claim.

---

## 5. Rewrite the “It can help with” list

Proposed HTML for the nine bullets. Paths relative to `index.html`.

```html
<ul>
  <li>drafting report text, as shown in the <a href="reports/public-mh-access-profile.html">MHSDS access and activity profile</a></li>
  <li>checking figures against sources, as shown in the <a href="examples/report-analysis-agent-conversation.md">Report Analysis Agent conversation</a> and the corrected <a href="reports/public-talking-therapies-profile.html">Talking Therapies brief</a></li>
  <li>summarising trends, as shown in the <a href="reports/public-talking-therapies-profile.html">Talking Therapies access brief</a> (six-week access above standard but falling)</li>
  <li>explaining performance changes, as shown in the <a href="warehouse-demo/reports/synthetic-urgent-care-analysis.html">synthetic urgent-care warehouse analysis</a> (operational pressure vs extract-driven spike)</li>
  <li>preparing meetings, as shown in the <a href="reports/public-assurance-profile.html">public statutory assurance source map</a> (which sources exist and who to speak to)</li>
  <li>checking reporting rules, as shown in the <a href="mandatory-reporting-map.html">mandatory reporting map</a> and the <a href="examples/mhsds-sme-agent-conversation.md">MHSDS Expert Agent conversation</a></li>
  <li>organising evidence, as shown in the <a href="data-warehouse-agent-demo.html">warehouse demo workflow</a> and <a href="warehouse-demo/profile-output/source_profiling_report.md">source profiling report</a></li>
  <li>reducing admin-heavy work, as shown in <a href="mandatory-reporting-map.html#ai-help">how agentic AI could help maintain a reporting register</a></li>
  <li>answering reporting technical and definition questions from approved sources, as shown in the <a href="agent-operating-model.html">agent operating model</a> and <a href="examples/mhsds-sme-agent-conversation.md">MHSDS Expert Agent conversation</a></li>
</ul>
```

### Bullets without a strong dedicated example

| Bullet | Assessment |
|--------|------------|
| **preparing meetings** | Supported by the assurance source map (“who to speak to”) and mandatory map (what is due, who owns it). Thinner than other bullets but genuine — **keep linked**, not dropped. |
| **reducing admin-heavy work** | Supported by mandatory map `#ai-help` section; no separate “project admin agent” page for readers. **Keep linked** to mandatory map. |

No bullets recommended for removal. All nine have at least one on-site example.

---

## 6. Proposed improved “What this site is designed to show” section

Replace the four principle-only cards with the following prose. Can be implemented as four `article.card` blocks with linked paragraphs, or as `h3` subsections.

```html
<h2 id="designed-to-show">What this site is designed to show</h2>

<article class="card">
  <h3>1. How I think about performance</h3>
  <p class="card-purpose">Good performance reporting should explain what the figure is, what it should be, whether it is getting better or worse, and what action may be needed. It should help people understand the position, not just give them more numbers.</p>
  <p class="card-purpose">The <a href="reports/public-performance-overview.html">NHS Oversight Framework brief</a> shows figure, peer position, trend and priority review flags. The <a href="reports/public-mh-access-profile.html">MHSDS access profile</a> separates stock measures from activity. The <a href="reports/public-talking-therapies-profile.html">Talking Therapies brief</a> applies national access standards with a falling-trend warning. The <a href="warehouse-demo/reports/synthetic-urgent-care-analysis.html">synthetic urgent-care analysis</a> (DRH only) shows the same discipline on fictional warehouse data — including when not to trust a headline movement.</p>
</article>

<article class="card">
  <h3>2. How I think about assurance</h3>
  <p class="card-purpose">Mandatory reporting needs clear definitions, source checks, trend analysis, known limitations and human sign-off. AI can help organise and test this work, but it must be clear where the information came from and what still needs checking.</p>
  <p class="card-purpose">The <a href="mandatory-reporting-map.html">mandatory reporting map</a> shows owners, frequency, due dates and assurance status (local fields are illustrative sample data). The <a href="reports/public-assurance-profile.html">statutory assurance source map</a> shows which public sources contain RDY rows — it is a navigation aid, not a scorecard. The <a href="warehouse-demo/reports/synthetic-reporting-table-assurance.html">reporting-table assurance</a> page applies the same discipline to a synthetic mart before anyone trusts it for narrative. The <a href="examples/report-analysis-agent-conversation.md">Report Analysis Agent conversation</a> shows QA catching errors before publication. The <a href="governance-and-benefits.html#checklist">AI assurance checklist</a> sets the human gate before sharing output.</p>
</article>

<article class="card">
  <h3>3. How I think about service improvement</h3>
  <p class="card-purpose">Good business partnering means understanding the real pressures services face — demand, capacity, staffing, pathways, finance, quality and patient care. Information should support improvement. It should not just create extra reporting work.</p>
  <p class="card-purpose">The <a href="warehouse-demo/reports/synthetic-urgent-care-analysis.html">synthetic urgent-care analysis</a> triangulates contacts, cases, bank shifts and agency spend — and separates possible Jan–Feb operational pressure from a March extract-driven spike. The <a href="warehouse-demo/reports/urgent-care-provider-month-brief.html">corrected provider-month brief</a> is what a service lead would see after QA. Public briefs add service-context discipline too: the <a href="reports/public-community-services-profile.html">community services profile</a> flags coding quality and signposts to the right waiting-list source; the <a href="reports/public-mh-access-profile.html">MHSDS profile</a> warns against reading access performance from contact counts alone.</p>
</article>

<article class="card">
  <h3>4. How I think about responsible AI</h3>
  <p class="card-purpose">AI should be used carefully, with clear rules, human review, audit trails, data protection safeguards and honest caveats. The aim is not to use AI for its own sake. The aim is to give analysts, managers and services better support.</p>
  <p class="card-purpose">The <a href="agent-operating-model.html">agent operating model</a> defines bounded, source-bound agents — not general chatbots and never the decision-maker. The <a href="examples/mhsds-sme-agent-conversation.md">MHSDS Expert Agent conversation</a> traces a figure to source and refuses to over-interpret. The <a href="data-warehouse-agent-demo.html">warehouse demo</a> walks through profiling, design, pipelines and report QA on synthetic data only. <a href="agent-rules/README.md">Agent rules</a> and <a href="governance-and-benefits.html">governance and benefits</a> document controls: no patient-identifiable data, human sign-off, version-controlled rules, and clear confidence levels.</p>
</article>
```

**Caveats to keep visible:** DRH synthetic examples labelled as fictional; mandatory map local fields illustrative; agent outputs are drafts requiring human sign-off.

---

## 7. Proposed improved opening hook

Standalone copy for the hero (same as Section 3.1; repeated here for quick review).

**Proposed `h1`:** A practical demonstration of Business & Performance work

**Proposed hero text:**

> This is my personal demonstration site for the Business & Performance Business Partner role. It is not an official Dorset HealthCare website or report.
>
> I built it to show how I would approach the work in practice — not just list skills on an application form. The examples walk through turning data into clear performance intelligence, checking assurance risks, supporting service improvement, understanding the data journey behind reporting tables, and using AI safely under human control.
>
> You can explore six draft briefs from public NHS data (for Dorset HealthCare as provider — RDY), a separate synthetic warehouse demonstration for fictional Demo Rivers Health (DRH), and pages on how bounded AI agents could support the work with governance and sign-off.
>
> The role is not just about producing reports. It is about helping services understand what is happening, spot risks early, and make better decisions. A good Business & Performance Business Partner connects services, corporate teams, finance, information teams and senior leaders — and makes performance information useful, not just available.

**Tone check:** Confident and purposeful; states limitations early; names RDY/DRH separation; no superlatives (“groundbreaking,” “revolutionary”).

---

## 8. Link validation

Every proposed link checked against the filesystem (June 2026).

| Proposed link text | Target path (from `site/`) | Exists | Public or synthetic | Reason for including |
|--------------------|----------------------------|--------|---------------------|----------------------|
| Draft reports hub | `draft-reports.html` | Yes | Public RDY hub | Six public briefs entry point |
| Warehouse demo hub | `data-warehouse-agent-demo.html` | Yes | Synthetic DRH hub | End-to-end warehouse workflow |
| Agent operating model | `agent-operating-model.html` | Yes | Framework | Bounded agents, principles, worked examples |
| NHS Oversight Framework brief | `reports/public-performance-overview.html` | Yes | Public RDY | Trust-wide KPI / performance narrative |
| MHSDS access profile | `reports/public-mh-access-profile.html` | Yes | Public RDY | Stock vs activity, validation flags |
| Community services profile | `reports/public-community-services-profile.html` | Yes | Public RDY | Activity, coding flags, scope limits |
| Talking Therapies brief | `reports/public-talking-therapies-profile.html` | Yes | Public RDY | Access standards, trends, waiting bands |
| Urgent/diagnostics check | `reports/public-urgent-diagnostics-check.html` | Yes | Public RDY | Source applicability |
| Assurance source map | `reports/public-assurance-profile.html` | Yes | Public RDY | Assurance navigation, who to contact |
| Mandatory reporting map | `mandatory-reporting-map.html` | Yes | Synthetic metadata + public refs | Owners, due dates, assurance status |
| Mandatory map — AI help | `mandatory-reporting-map.html#ai-help` | Yes (anchor) | Synthetic metadata + public refs | Admin reduction example |
| Synthetic urgent-care analysis | `warehouse-demo/reports/synthetic-urgent-care-analysis.html` | Yes | Synthetic DRH | Performance change vs data artefact |
| Reporting-table assurance | `warehouse-demo/reports/synthetic-reporting-table-assurance.html` | Yes | Synthetic DRH | Pre-trust table checks |
| Corrected provider-month brief | `warehouse-demo/reports/urgent-care-provider-month-brief.html` | Yes | Synthetic DRH | Post-QA service-facing brief |
| Source profiling report | `warehouse-demo/profile-output/source_profiling_report.md` | Yes | Synthetic DRH | Organising upstream evidence |
| Data-quality register | `warehouse-demo/profile-output/dq_register.csv` | Yes | Synthetic DRH | DQ priorities and owners |
| Report Analysis conversation | `examples/report-analysis-agent-conversation.md` | Yes | Public RDY QA demo | Figure checking workflow |
| MHSDS Expert conversation | `examples/mhsds-sme-agent-conversation.md` | Yes | Synthetic demo | Definition / lineage questions |
| Warehouse source profiling conversation | `examples/warehouse-source-profiling-conversation.md` | Yes | Synthetic DRH | Bounded profiling agent |
| Warehouse report QA conversation | `examples/warehouse-report-qa-conversation.md` | Yes | Synthetic DRH | Synthetic brief QA |
| Governance and benefits | `governance-and-benefits.html` | Yes | Framework | Benefits vs controls |
| AI assurance checklist | `governance-and-benefits.html#checklist` | Yes (anchor) | Framework | Human gate before distribution |
| Agent rules index | `agent-rules/README.md` | Yes | Illustrative rules | Version-controlled agent briefs |
| Public reports method | `public-data/PUBLIC_REPORTS_METHOD.md` | Yes | Public methodology | Reproducible public-data workflow |
| MHSDS worked example (on-page) | `agent-operating-model.html#mhsds-worked-example` | Yes (anchor) | Synthetic demo | Trace unusual movement |
| Report Analysis worked example (on-page) | `agent-operating-model.html#report-analysis-worked-example` | Yes (anchor) | Public RDY QA demo | Flawed draft review |

**Not linked (deliberately):** Orphan reports in `site/reports/` (`demand-and-capacity-prototype.html`, `learning-disability-performance.html`, `cyp-waiting-list-overview.html`, `all-age-mental-health-access.html`) — not referenced anywhere on the live site navigation or hub pages.

---

## 9. Risks and wording to avoid

Wording deliberately avoided in the proposals above:

| Avoid | Why |
|-------|-----|
| “Official Dorset HealthCare report” / “Trust-approved” | Site is personal demonstration only |
| “Live Trust data” / “real patient data” | Only public aggregate and synthetic data used |
| “AI decided…” / “the agent proved…” | AI drafts and checks; humans judge and sign off |
| “Demo Rivers Health performance” as if RDY | DRH is fictional; must stay separate from RDY public briefs |
| “Production warehouse” / “deployed Azure SQL” | SQL and ADF artefacts are specifications only |
| “This proves I meet every criterion” | Site shows method; leadership and qualifications are CV/interview |
| “Public data confirms local operational position” | Public aggregates may lag and cannot replace local dashboards |
| “Demand surge in March” (warehouse) without caveat | March pattern is likely extract-driven until data owner confirms |
| “Strong performance” without standards context | Talking Therapies example shows above standard but falling — nuance required |
| “AI will reduce headcount” / “replace analysts” | Framed as reducing admin-heavy draft work, not removing roles |
| “Complete mandatory register” | Mandatory map is proof-of-concept with illustrative local fields |

---

## 10. Final recommendation

### Sections that should definitely change

1. **Hero** — new `h1`, application + demonstration framing, early example links, RDY/DRH pointer.
2. **“The main idea”** — remove coding/apps opener; replace nine bullets with linked version (Section 5).
3. **“What this site is designed to show”** — add linked prose per theme (Section 6).
4. **“Purpose of this site”** — woven links in intro paragraph; richer card blurbs with one example each.

### Sections that should probably stay mostly as they are

1. **Demonstration caveat box** — verbatim.
2. **“How this was built”** — keep; optional single governance link only if desired.
3. **“Why this is relevant to the role”** — keep skills list; add one bridging sentence to examples.
4. **Footer caveat** — verbatim.

### Homepage length

**Recommendation: same overall length, more specific.** Do not shorten by removing sections. Do not substantially expand. Replace vague repetition with example-linked sentences so each section earns its place.

### Apply in one pass or review first?

**Review this Markdown file first**, then apply to `index.html` in **one implementation pass** so link paths, caveat placement and tone stay consistent. After HTML update, spot-check in browser: hero readability, link targets, and that the demonstration caveat still appears before “Explore.”

---

*Proposal prepared for human review. No changes applied to `site/index.html`.*
