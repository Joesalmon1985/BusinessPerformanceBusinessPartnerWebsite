# Public data catalogue

Local reference catalogue of **public NHS aggregate data sources** for governed analysis workflows. This folder supports the demonstration site — it is not a live data pipeline.

## What is here

| Path | Purpose |
|------|---------|
| `DATA_SOURCE_REGISTER.csv` | Master register of public sources, URLs, caveats |
| `raw/` | Downloaded public CSV/ZIP files (local dev) |
| `processed/` | RDY-filtered extracts for local analysis |
| `metadata/` | Download logs and inspection notes |
| `01_download_public_data.R` | Download script (requires network + R packages) |
| `R_libs/` | **Local R packages — do not deploy to Cloudflare** |

## Information governance

- **Public aggregate data only** — no patient-identifiable information intended
- **Not Trust management information** — provisional national statistics with publisher caveats
- **Not published on the static site as live dashboards** — referenced from pages for transparency
- Do not commit confidential or unpublished internal documents

## Usage

Run download scripts locally only:

```bash
cd site/public-data
Rscript 01_download_public_data.R
```

See `DATA_SOURCE_REGISTER.csv` for source URLs and download status.

## Site links

- [Mandatory reporting map](../mandatory-reporting-map.html) — public reference URLs in register
- [Draft reports](../draft-reports.html) — links to this catalogue
