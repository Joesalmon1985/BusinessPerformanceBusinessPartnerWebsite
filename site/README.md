# Joe Salmon — Business & Performance Business Partner Application

A personal demonstration static website showing how **governed agentic AI** can support NHS business and performance work — reporting drafts, analysis structure, mandatory reporting assurance, admin coordination and subject matter support.

**Central message:** AI can help draft, structure, analyse, check and explain performance intelligence, but accountable humans remain responsible for definitions, validation, judgement and sign-off.

## What this site is

- A practical AI demonstration microsite built with Cursor agent support under human direction
- Five main HTML pages, five synthetic draft reports, and an expanded agent operating model
- Public NHS source metadata in `public-data/` (local reference; not all deployed to Cloudflare)
- Static assets only — no backend, no database, no Shiny

## What this site is not

- An official Dorset HealthCare website, report or operationally validated register
- A live performance dashboard or production AI deployment
- A source of confidential, unpublished internal or patient-identifiable data

## View locally

Open `site/index.html` in a browser, or:

```bash
cd site && python3 -m http.server 8080
```

## Regenerate data, register and reports

Requires R (base R only for `site/R/` scripts).

```bash
cd site/R
Rscript 01_generate_synthetic_data.R
Rscript 03_sync_mandatory_register_html.R
Rscript 02_render_reports.R
```

## Regenerate documentation HTML

Allow-listed Markdown artefacts are published as styled HTML under `site/docs-html/` for Cloudflare Pages.

```bash
pip install -r requirements.txt   # once
python3 tools/render_markdown_docs.py
```

Run this after editing published `.md` files or before deploy. Generated HTML is committed so local preview works without the script.

## Site structure

```
site/
├── index.html                      # Home — what this website is about
├── mandatory-reporting-map.html    # Mandatory reporting assurance demo
├── draft-reports.html              # AI-assisted draft reporting demo
├── agent-operating-model.html      # Agent categories and rule files
├── governance-and-benefits.html    # Benefits, controls, checklist
├── public-data/                    # Public NHS source catalogue (see README inside)
├── assets/                         # styles.css, site.js
├── reports/                        # R-generated report pages
├── data/                           # Synthetic CSV files
├── R/                              # Data generation and rendering scripts
└── agent-rules/                    # Reusable Cursor-style agent rules
```

**Do not deploy** `public-data/R_libs/` to Cloudflare — local R package cache only.

## Information governance

- Report data is **synthetic aggregate** unless explicitly labelled as public reference
- **No patient-identifiable information** or unpublished internal documents
- **Human sign-off** required for any real-world use
- IG/Safety agent rules document hard boundaries

## Deployment

See [CLOUDFLARE_DEPLOYMENT.md](CLOUDFLARE_DEPLOYMENT.md).
