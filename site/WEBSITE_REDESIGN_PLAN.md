# Website Content Redesign — Implementation Summary

This document records the content and information-architecture redesign completed for Joe Salmon's Business & Performance Business Partner application microsite. Visual design and layout were preserved; changes are primarily narrative, data model and agent content.

## What changed

### Home (`index.html`)
- Reframed from role-understanding essay to **site purpose** narrative
- Added sections: how built (Cursor agent), data scope, AI support, AI limits, BP relevance, brief About Joe
- Removed lengthy role essay sections; retained central accountability message

### Mandatory reporting map
- Reframed as AI-assisted **mandatory reporting assurance** demonstration
- Extended CSV schema: `next_due_date`, `assurance_status`, `issues`, `reference_url`, `reference_type`, `escalation_route`
- Public NHS reference URLs replace placeholder links where mapped
- New `R/03_sync_mandatory_register_html.R` single-sources HTML table from CSV
- Added assurance status filter in `site.js`

### Draft reports
- Reframed around **draft vs approved** reporting and analyst workflow
- `R/02_render_reports.R` adds review banner, draft commentary, statistical notes, limits blocks
- Added public data catalogue card linking to `public-data/DATA_SOURCE_REGISTER.csv`

### Agent operating model
- Restructured into four categories: SME, workflow, admin/delivery, IG
- Added 5 new agent rule files (PLCM, ADC, project/admin, backlog sync, developer logging)
- Extended MHSDS, CSDS, Report QA, IG/Safety rules
- Added `agent-rules/README.md`

### Governance and benefits
- Light alignment edits; added citation checklist item; admin benefit bullet

### Documentation
- Updated `README.md`, `CLOUDFLARE_DEPLOYMENT.md`, new `public-data/README.md`

## Regeneration pipeline

```bash
cd site/R
Rscript 01_generate_synthetic_data.R
Rscript 03_sync_mandatory_register_html.R
Rscript 02_render_reports.R
```

## Files not touched

- `public-data/R_libs/` (vendor R packages)
- `assets/styles.css` (no visual redesign)

## Known limitations

- Mandatory register owners/statuses remain illustrative demo metadata
- Agent rules are not wired to live AI
- `public-data/raw/` and `R_libs/` excluded from Cloudflare deploy recommendation
