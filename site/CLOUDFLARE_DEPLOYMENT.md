# Cloudflare Pages Deployment

This site is a **static** HTML/CSS/JavaScript microsite. The deployable folder is `/site`. No build step, backend, or environment variables are required.

## Prerequisites

- A Cloudflare account (free tier is sufficient)
- The `/site` folder with all HTML, CSS, JS, CSV and report files

## Option 1: Direct Upload

Best for a quick demonstration without Git integration.

1. **Prepare the folder**
   - Ensure `/site` contains `index.html` at its root (not nested deeper)
   - Optionally zip the *contents* of `/site` (not the parent folder itself):
     ```bash
     cd site
     zip -r ../nhs-bp-microsite.zip .
     ```

2. **Create a Cloudflare Pages project**
   - Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
   - Go to **Workers & Pages** → **Create** → **Pages** → **Upload assets**

3. **Upload**
   - Drag and drop the `/site` folder contents or the zip file
   - Cloudflare will deploy and provide a `*.pages.dev` URL

4. **Settings**
   - **Build command:** none (leave empty)
   - **Build output directory:** `/` (root of upload)
   - **Environment variables:** none required

5. **Verify**
   - Open the provided URL
   - Check navigation links, report pages, and mobile layout
   - Confirm the synthetic data caveat appears on every page

### Updating a Direct Upload site

Re-upload the folder or zip when files change. Each upload creates a new deployment.

---

## Option 2: Git-based Deployment

Best for version control and automatic redeployment on push.

1. **Push to a Git repository**
   ```bash
   git init
   git add site/
   git commit -m "Add NHS BP demonstration microsite"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Connect Cloudflare Pages to Git**
   - Dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
   - Select your repository

3. **Configure build settings**

   | Setting | Value |
   |---------|-------|
   | Production branch | `main` (or your default branch) |
   | Build command | *(leave empty)* |
   | Build output directory | `site` |
   | Root directory | `/` (repo root) |

4. **Environment variables**
   - None required
   - Do not add API keys or secrets

5. **Deploy**
   - Cloudflare deploys on first connect and on every subsequent push to the production branch

### Custom domain (optional)

- Pages project → **Custom domains** → add your domain
- Follow Cloudflare DNS instructions

---

## What gets deployed

Include the entire `/site` folder:

- HTML pages (main + reports)
- `assets/styles.css` and `assets/site.js`
- `data/*.csv` (synthetic data — safe to publish)
- `agent-rules/*.md` (optional but useful for reviewers)
- `README.md`, `CLOUDFLARE_DEPLOYMENT.md`

**Exclude from upload (large, not needed at runtime):**

- `public-data/R_libs/` — local R package cache (~700 files)
- `public-data/raw/` — optional; large downloaded files (keep `DATA_SOURCE_REGISTER.csv` if linking from site)

**Regenerate before deploy if data changed:**

```bash
cd site/R
Rscript 01_generate_synthetic_data.R
Rscript 03_sync_mandatory_register_html.R
Rscript 02_render_reports.R
```

---

## Post-deployment checks

- [ ] Landing page loads at `/` or `/index.html`
- [ ] All five nav links work
- [ ] All five report links under `/reports/` work
- [ ] Mandatory reporting filters work (owner, risk, confidence, assurance, search)
- [ ] Mobile navigation toggle works
- [ ] Synthetic data caveat visible on every page
- [ ] No 404 errors on internal links

---

## Security notes

- No secrets, API keys or `.env` files are used or needed
- All data is synthetic — no confidential Trust information
- No server-side processing — Cloudflare serves static files only
- External reference links point to public NHS/gov.uk sources where mapped
- `public-data/R_libs/` must not be uploaded to Cloudflare

---

## Troubleshooting

**404 on report pages:** Ensure `reports/*.html` files were included in the upload and paths use relative links (`reports/...` from main pages, `../reports/...` is not needed from main pages).

**Styles missing:** Confirm `assets/styles.css` is at `/assets/styles.css` relative to site root.

**Git deploy shows wrong content:** Verify **Build output directory** is set to `site`, not `/` or `dist`.

**R scripts on Cloudflare:** R is not executed during deployment. Pre-generated CSV and report HTML files must be committed to the repository before deploy.
