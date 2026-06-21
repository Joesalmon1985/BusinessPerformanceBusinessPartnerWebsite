# Final Report QA Summary

**Generated:** 2026-06-21 (public-data report improvement plan — full implementation pass)

> Public-data demonstration only — not official Dorset HealthCare reporting. All figures require human review and local owner confirmation.

## Scope of this pass

Implementation of the **public-data report improvement plan**:

- **Data-error fixes:** TT M019–M022 totals (5,870 and 6,780), KH03 quarter wording, DM01 period labels, CSDS 6/8-month distinction, chronological trend charts, unique section headings
- **Enriched KFE table:** Standard/expected, peer median, trend, validation status and judgement columns with source metadata cites
- **Per-report content:** NOF spec enrichment and priority callouts; MHSDS/CSDS/TT access-activity profiles; assurance source map; urgent-care applicability check
- **Layout slimming:** Collapsed grouped findings and draft interpretation into audit trail; bottom line and why-this-is-useful sections; provider scope badges
- **Automated validation:** `site/R/04_validate_public_reports.R` wired to render pipeline
- **CSS:** Priority callout, scope badge, bottom line, validation badges, period captions, mobile KFE stacking

**Regenerate reports:**

```bash
Rscript site/R/03_render_public_reports.R
Rscript site/R/04_validate_public_reports.R
```

---

## Automated validation

| Check | Result |
|-------|--------|
| All six `public-*.html` files regenerate without error | **Pass** |
| Post-render validation script passes | **Pass** (6 files) |
| No duplicate `<h2>` headings within any report | **Pass** |
| Trend column free of validation-status wording | **Pass** |
| TT M019–M021 (5,870) and M019–M022 (6,780) in HTML | **Pass** |
| Time-series chart labels in chronological order | **Pass** |
| Period captions on Key findings explained sections | **Pass** |
| Bottom line and why-this-is-useful on all reports | **Pass** |

---

## Acceptance criteria (content and structure)

| Criterion | Result |
|-----------|--------|
| No contradictory totals (M019–M022, DM01 periods, KH03 quarter count) | **Pass** |
| Trend column shows direction only; validation in separate column | **Pass** |
| NOF table: figure, standard, peer, trend, judgement, human check | **Pass** |
| OF0063 and UCR prominently flagged in NOF headline/callout | **Pass** |
| MHS69 April spike as validation priority with FY-reset explanation | **Pass** |
| M053 75% standard + falling judgement; 18-week standard included | **Pass** |
| CSDS MoM-up / 6-month-down headline; Other category flagged | **Pass** |
| Assurance traceable KO41a/ERIC values; source map with currentness-risk | **Pass** |
| Urgent-care chronological charts; grouping rationale stated | **Pass** |
| Each report has bottom line paragraph | **Pass** |
| MHSDS, CSDS, TT show Provider/RDY scope badge | **Pass** |
| No duplicate section headings within any report | **Pass** |

---

## Visual QA (desktop and mobile)

**Desktop (≥1024px):**

| Check | Result |
|-------|--------|
| KFE table columns readable with horizontal scroll wrapper | **Pass** |
| Priority callouts visually distinct | **Pass** |
| Validation badges legible in separate column | **Pass** |
| Collapsed audit sections use `<details>` | **Pass** |
| No oversized coloured cells / blue-blob regression | **Pass** |
| Standard cites render as inline footnotes | **Pass** |

**Mobile (≤480px):**

| Check | Result |
|-------|--------|
| KFE table stacks per-row (thead hidden, block layout) | **Pass** |
| Chart labels readable; chronological order preserved | **Pass** |
| Scope badge and bottom line visible without excessive scroll | **Pass** |
| Collapsible summaries present and tappable | **Pass** |

Visual inspection completed on all six reports: `public-performance-overview.html`, `public-mh-access-profile.html`, `public-community-services-profile.html`, `public-talking-therapies-profile.html`, `public-assurance-profile.html`, `public-urgent-diagnostics-check.html`.

---

## Files changed in this pass

| File | Change |
|------|--------|
| `site/R/03_render_public_reports.R` | Shared helpers, enriched KFE, per-report content, slim layout, validation wiring |
| `site/R/04_validate_public_reports.R` | New post-render validation checks |
| `site/assets/nhs-report.css` | New component styles; mobile KFE stacking |
| `site/draft-reports.html` | Revised card titles, descriptions, structure note |
| `site/public-data/PUBLIC_REPORTS_METHOD.md` | KFE column model, metadata schema, validation usage |
| `site/public-data/FINAL_REPORT_QA_SUMMARY.md` | This document |
| `site/reports/public-*.html` | Regenerated (six files) |

---

## Remaining caveats before deployment

1. **FFT org-level gap** — manual download may still be needed (`metadata/fft_manual_download_needed.md`)
2. **KH03 snapshot lag** — trend file ends Jun 2024; verify latest quarter on NHS England site
3. **NOF demo CSV truncated** — full audit CSV/MD provided for verification
4. **Provisional monthly data** — MHSDS, CSDS, IAPT may revise on final refresh
5. **Period mismatch across sources** — urgent report documents A&E May 2026 vs KH03 Jun 2024 explicitly

---

## Ready for final site QA / deployment?

**Yes — ready for final human review and site QA.**

All six public reports meet the improvement plan acceptance criteria. Automated validation passes on regenerate. Operational use still requires local data owner confirmation and accountable sign-off.
