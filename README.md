# Business Performance Business Partner — Application Workspace

Repository for Joe Salmon's **Business & Performance Business Partner** job application demonstration site and supporting materials.

## Contents

| Path | Description |
|------|-------------|
| [`site/`](site/) | Static demonstration microsite (HTML, reports, synthetic data, agent rules) |
| `152-S030.26_*.txt` | Job description and person specification reference documents |

## Quick start

See [`site/README.md`](site/README.md) for local viewing, data regeneration, site structure, and Cloudflare deployment.

```bash
cd site && python3 -m http.server 8080
```

Then open http://localhost:8080

## Deploy

Git-based Cloudflare Pages: set **Build output directory** to `site`. See [`site/CLOUDFLARE_DEPLOYMENT.md`](site/CLOUDFLARE_DEPLOYMENT.md).
