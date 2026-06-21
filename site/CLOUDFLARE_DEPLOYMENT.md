# Cloudflare Pages Deployment

This site is a **static** HTML/CSS/JavaScript microsite. The deployable folder is `/site`. No build step, backend, or environment variables are required.

## Prerequisites

- A Cloudflare account (free tier is sufficient)
- The `/site` folder with all HTML, CSS, JS, CSV and report files

## Option 1: Direct Upload

Best for a quick demonstration without Git integration.

1. **Prepare the folder**
   - Ensure `/site` contains `index.html` at its root (not nested deeper)
   - **Do not upload** local-only folders: `public-data/raw/`, `public-data/metadata/historic_extract/`, or `public-data/R_libs/` — many files exceed Cloudflare's 25 MiB limit
   - Prefer zipping from a fresh Git clone (tracked files only), not your full local `site/` folder:
     ```bash
     git clone <repo-url> deploy-staging && cd deploy-staging/site
     zip -r ../nhs-bp-microsite.zip .
     ```
   - Or zip only if you have confirmed no large gitignored files are present:
     ```bash
     cd site
     find public-data/raw public-data/metadata/historic_extract -type f -size +25M 2>/dev/null | grep -q . && echo "Remove or exclude large local files first" && exit 1
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
   | Root directory | `/` (repo root) |
   | Build command | *(leave empty)* or `exit 0` |
   | Build output directory | `site` |

   Cloudflare Pages has a **25 MiB per-file limit**. Large raw NHS downloads must not be committed to Git (see `.gitignore`).

4. **Environment variables**
   - None required
   - Do not add API keys or secrets

5. **Deploy**
   - Cloudflare deploys on first connect and on every subsequent push to the production branch
   - Git-based deploy publishes **only Git-tracked files** under `site/` — gitignored raw downloads and historic extract caches on your machine are not included
   - After fixing a file-size failure, merge the fix to your production branch and use **Retry deployment** in the Cloudflare dashboard (or push a new commit)

### Custom domain (optional)

- Pages project → **Custom domains** → add your domain
- Follow Cloudflare DNS instructions

---

## What gets deployed

Deploy Git-tracked content under `/site`:

- HTML pages (main + reports)
- `assets/styles.css` and `assets/site.js`
- `data/*.csv` (synthetic data — safe to publish)
- `public-data/processed/` (RDY-filtered demo CSVs used by reports)
- `public-data/DATA_SOURCE_REGISTER.csv` and small metadata notes
- `agent-rules/*.md` (optional but useful for reviewers)
- `README.md`, `CLOUDFLARE_DEPLOYMENT.md`

**Must not be in Git or deployed (local dev only, often over 25 MiB):**

- `public-data/raw/` — downloaded NHS source CSV/ZIP files
- `public-data/metadata/historic_extract/` — historic download cache from script 05
- `public-data/R_libs/` — local R package cache (~700 files)

### Pre-deploy size check

Before pushing, confirm no tracked file exceeds Cloudflare's 25 MiB limit:

```bash
find site -type f -size +25M | sort
# May list gitignored local-only files (raw/, historic_extract/) — those must not be tracked

git ls-files site | while read f; do
  [ -f "$f" ] && [ "$(stat -c%s "$f")" -gt 26214400 ] && echo "FAIL: $f"
done
# Must print nothing — this is the deploy safety check
```

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

**Deploy fails on file size (25 MiB limit):** A large file under `public-data/raw/` or `metadata/historic_extract/` was committed or included in a Direct Upload. Remove it from Git tracking with `git rm --cached`, ensure `.gitignore` excludes those directories, merge to your production branch, and **Retry deployment** in Cloudflare. The live site uses `processed/demo_*.csv` and pre-rendered HTML reports, not raw downloads.

**R scripts on Cloudflare:** R is not executed during deployment. Pre-generated CSV and report HTML files must be committed to the repository before deploy.
