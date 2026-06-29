#!/usr/bin/env python3
"""Render allow-listed Markdown files under site/ to styled HTML in site/docs-html/."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import markdown

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_ROOT = REPO_ROOT / "site"
DOCS_HTML_ROOT = SITE_ROOT / "docs-html"

ALLOW_LIST: tuple[str, ...] = (
    # Checks
    "checks/site_explanation_guide.md",
    "checks/final_site_critical_sweep_checkpoint.md",
    "checks/business_performance_role_alignment_audit.md",
    "checks/final_claim_evidence_audit.md",
    "checks/public_vs_synthetic_separation_audit.md",
    # Warehouse demo
    "warehouse-demo/source-notes/demo_run_index.md",
    "warehouse-demo/profile-output/source_profiling_report.md",
    "warehouse-demo/design/warehouse_design_proposal.md",
    "warehouse-demo/design/human_review_pack.md",
    "warehouse-demo/design/linkage_resolution_strategy.md",
    "warehouse-demo/sql/README.md",
    "warehouse-demo/sql/DEPLOYMENT_NOTES.md",
    "warehouse-demo/sql/EXPECTED_SYNTHETIC_LOAD_COUNTS.md",
    "warehouse-demo/pipelines/pipeline_overview.md",
    "warehouse-demo/checkpoints/runs_2_5_internal_qa.md",
    "warehouse-demo/README.md",
    # Examples
    "examples/warehouse-report-qa-conversation.md",
    "examples/warehouse-draft-urgent-care-brief-flawed.md",
    "examples/warehouse-design-conversation.md",
    "examples/warehouse-source-profiling-conversation.md",
    "examples/synthetic-draft-talking-therapies-flawed.md",
    "examples/report-analysis-agent-conversation.md",
    "examples/mhsds-sme-agent-conversation.md",
    # Public method / readme
    "public-data/PUBLIC_REPORTS_METHOD.md",
    "public-data/FINAL_SIMPLIFICATION_SUMMARY.md",
    "public-data/FINAL_REPORT_QA_SUMMARY.md",
    "public-data/metadata/public_report_audit_nof_overview.md",
    # Docs
    "docs/synthetic-mhsds-local-dictionary.md",
    # Secondment demo
    "secondment-demo/README.md",
    "secondment-demo/data_dictionary.md",
    "secondment-demo/mhsds_like_sources.md",
    # Agent rules — worked-example only
    "agent-rules/mhsds-expert-agent.md",
    "agent-rules/report-analysis-agent.md",
    "agent-rules/source-profiling-agent.md",
    "agent-rules/warehouse-design-agent.md",
    "agent-rules/warehouse-report-qa-agent.md",
)

DENY_LIST: tuple[str, ...] = (
    "warehouse-demo/source-notes/human_reviewer_answer_key.md",
    "warehouse-demo/checkpoints/manual_answer_key_comparison_template.md",
    "warehouse-demo/checkpoints/run2_checkpoint.md",
    "warehouse-demo/checkpoints/run3_checkpoint.md",
    "warehouse-demo/checkpoints/run4_checkpoint.md",
    "warehouse-demo/checkpoints/run5_checkpoint.md",
    "warehouse-demo/checkpoints/dedicated_page_checkpoint.md",
    "warehouse-demo/checkpoints/reporting_pages_checkpoint.md",
    "warehouse-demo/source-notes/suggested_next_agent_task.md",
    "warehouse-demo/source-notes/suggested_run3_agent_task.md",
    "warehouse-demo/source-notes/suggested_run4_agent_task.md",
)

FORBIDDEN_HTML_SUBSTRINGS = (
    "human_reviewer_answer_key",
    "planted artefact",
)

ANSWER_KEY_DENY: frozenset[str] = frozenset({
    "warehouse-demo/source-notes/human_reviewer_answer_key.md",
    "warehouse-demo/checkpoints/manual_answer_key_comparison_template.md",
})

DENY_LINK_REPLACEMENT = "human-only reviewer checklist (not published on site)"

CONTEXT_PARENT: dict[str, tuple[str, str]] = {
    "checks/": ("Home", "index.html"),
    "warehouse-demo/": ("Warehouse demo", "data-warehouse-agent-demo.html"),
    "examples/": ("Agent operating model", "agent-operating-model.html"),
    "public-data/": ("Draft reports", "draft-reports.html"),
    "docs/": ("Agent operating model", "agent-operating-model.html"),
    "agent-rules/": ("Agent operating model", "agent-operating-model.html"),
}

NAV_ITEMS = (
    ("Home", "index.html"),
    ("Mandatory reporting map", "mandatory-reporting-map.html"),
    ("Draft reports", "draft-reports.html"),
    ("Warehouse demo", "data-warehouse-agent-demo.html"),
    ("Agent operating model", "agent-operating-model.html"),
    ("Governance and benefits", "governance-and-benefits.html"),
    ("Six-month plan", "six-months-trusted-performance.html"),
)

LINK_PATTERN = re.compile(r"(!?\[)([^\]]*)\](\([^)]+\))")
HREF_PATTERN = re.compile(r"\(([^)]+)\)")
H1_PATTERN = re.compile(r"^#\s+(.+)$", re.MULTILINE)


def normalize_site_path(path: str) -> str:
    return path.replace("\\", "/").lstrip("/")


def site_relative_path(from_dir: Path, to_path: Path) -> str:
    rel = Path(os_path_relpath(from_dir, to_path))
    return rel.as_posix()


def os_path_relpath(from_dir: Path, to_path: Path) -> str:
    import os

    return os.path.relpath(to_path, start=from_dir)


def md_to_docs_html_rel(site_md: str) -> str:
    rel = normalize_site_path(site_md)
    if not rel.endswith(".md"):
        raise ValueError(f"Not a markdown path: {site_md}")
    return f"docs-html/{rel[:-3]}.html"


def is_answer_key_denied(site_md: str) -> bool:
    rel = normalize_site_path(site_md)
    return rel in ANSWER_KEY_DENY or "human_reviewer_answer_key" in rel


def is_denied(site_md: str) -> bool:
    rel = normalize_site_path(site_md)
    if rel in DENY_LIST:
        return True
    if "human_reviewer_answer_key" in rel:
        return True
    if rel.startswith("warehouse-demo/source-notes/suggested_"):
        return True
    return False


def is_allowed(site_md: str) -> bool:
    rel = normalize_site_path(site_md)
    return rel in ALLOW_LIST


def resolve_md_link(source_md: Path, href: str) -> Path | None:
    href = href.strip()
    if not href or href.startswith("#") or "://" in href or href.startswith("mailto:"):
        return None
    if not href.lower().endswith(".md"):
        return None
    base = source_md.parent
    return (base / href).resolve()


def rewrite_markdown_links(source_md: Path, output_html: Path, text: str) -> str:
    output_dir = output_html.parent

    def replace_link(match: re.Match[str]) -> str:
        prefix, label, paren = match.group(1), match.group(2), match.group(3)
        href_match = HREF_PATTERN.search(paren)
        if not href_match:
            return match.group(0)
        href = href_match.group(1).strip()
        if prefix.startswith("!"):
            return rewrite_non_md_link(output_dir, source_md, match.group(0), href, label, image=True)

        resolved = resolve_md_link(source_md, href)
        if resolved is None:
            return rewrite_non_md_link(output_dir, source_md, match.group(0), href, label, image=False)

        try:
            rel_to_site = resolved.relative_to(SITE_ROOT.resolve())
        except ValueError:
            return rewrite_non_md_link(output_dir, source_md, match.group(0), href, label, image=False)

        site_rel = rel_to_site.as_posix()
        if is_answer_key_denied(site_rel):
            return DENY_LINK_REPLACEMENT

        if is_allowed(site_rel):
            target_html = SITE_ROOT / md_to_docs_html_rel(site_rel)
            new_href = site_relative_path(output_dir, target_html)
            return f"[{label}]({new_href})"

        new_href = site_relative_path(output_dir, resolved)
        return f"[{label}]({new_href})"

    return LINK_PATTERN.sub(replace_link, text)


def rewrite_non_md_link(
    output_dir: Path,
    source_md: Path,
    original: str,
    href: str,
    label: str,
    *,
    image: bool,
) -> str:
    if href.startswith("#") or "://" in href or href.startswith("mailto:"):
        return original
    resolved = (source_md.parent / href).resolve()
    try:
        resolved.relative_to(SITE_ROOT.resolve())
    except ValueError:
        return original
    new_href = site_relative_path(output_dir, resolved)
    if image:
        return f"![{label}]({new_href})"
    return f"[{label}]({new_href})"


def extract_title(md_text: str, fallback: str) -> str:
    match = H1_PATTERN.search(md_text)
    if match:
        return match.group(1).strip()
    return fallback


def wrap_tables(html: str) -> str:
    return re.sub(r"<table>", '<div class="table-wrap"><table>', html).replace(
        "</table>", "</table></div>"
    )


def sanitize_html(html: str) -> str:
    html = re.sub(
        r'<a[^>]*href="[^"]*human_reviewer_answer_key[^"]*"[^>]*>(.*?)</a>',
        DENY_LINK_REPLACEMENT,
        html,
        flags=re.IGNORECASE | re.DOTALL,
    )
    html = html.replace("human_reviewer_answer_key", DENY_LINK_REPLACEMENT)
    html = html.replace("human_reviewer_answer_key.md", DENY_LINK_REPLACEMENT)
    lowered = html.lower()
    if "planted artefact" in lowered:
        raise ValueError("Forbidden phrase 'planted artefact' found in generated HTML")
    return html


def relative_to_site_root(output_html: Path) -> str:
    rel = output_html.relative_to(DOCS_HTML_ROOT)
    return rel.as_posix()


def contextual_parent(site_md_rel: str) -> tuple[str, str]:
    for prefix, value in CONTEXT_PARENT.items():
        if site_md_rel.startswith(prefix):
            return value
    return ("Home", "index.html")


def build_shell(
    *,
    title: str,
    body_html: str,
    site_md_rel: str,
    output_html: Path,
) -> str:
    output_dir = output_html.parent
    depth = len(output_dir.relative_to(DOCS_HTML_ROOT).parts)
    ups_to_site = depth + 1
    site_up = "/".join([".."] * ups_to_site)
    asset_prefix = f"{site_up}/assets"

    def site_href(target: str) -> str:
        fragment = ""
        if "#" in target:
            target, frag = target.split("#", 1)
            fragment = f"#{frag}"
        return f"{site_up}/{target}{fragment}"

    parent_label, parent_target = contextual_parent(site_md_rel)
    source_md_path = SITE_ROOT / site_md_rel
    source_md_href = site_relative_path(output_dir, source_md_path)

    caveats = [
        (
            "Supporting documentation for Joe Salmon's Business &amp; Performance "
            "Business Partner demonstration site. Demonstration material only."
        )
    ]
    if "warehouse-demo" in site_md_rel:
        caveats.append(
            "Synthetic Demo Rivers Health material only — not Dorset HealthCare/RDY public data."
        )
    if site_md_rel.startswith("checks/"):
        caveats.append(
            "Private review/support note for understanding and assurance of the demonstration site."
        )

    caveat_html = "\n".join(
        f'      <div class="caveat-box"><p>{text}</p></div>' for text in caveats
    )

    nav_items = []
    for label, href in NAV_ITEMS:
        nav_href = site_href(href)
        nav_items.append(f'        <li><a href="{nav_href}">{label}</a></li>')
    nav_html = "\n".join(nav_items)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title} — Joe Salmon demonstration site</title>
  <meta name="description" content="{title}">
  <link rel="stylesheet" href="{asset_prefix}/styles.css">
  <link rel="stylesheet" href="{asset_prefix}/docs.css">
</head>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <header class="site-header">
    <div class="header-inner">
      <p class="site-title">Joe Salmon - Business &amp; Performance Business Partner Application</p>
      <p class="site-subtitle">Supporting documentation</p>
      <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="main-nav">Menu</button>
    </div>
    <nav class="nav" id="main-nav" aria-label="Main navigation">
      <ul class="nav-list">
{nav_html}
      </ul>
    </nav>
  </header>

  <main id="main-content" class="docs-article">
{caveat_html}
    <nav class="docs-toolbar" aria-label="Document navigation">
      <a href="{site_href('index.html')}">&larr; Home</a>
      <span class="docs-toolbar-sep" aria-hidden="true">·</span>
      <a href="{site_href(parent_target)}">{parent_label}</a>
      <span class="docs-toolbar-sep" aria-hidden="true">·</span>
      <a class="docs-source-link" href="{source_md_href}">View source Markdown</a>
    </nav>
    <article class="docs-content">
{body_html}
    </article>
  </main>

  <footer class="site-footer">
    <div class="footer-inner">
      <p class="footer-caveat">This is a personal demonstration site using synthetic and public reference data only. It is not an official Dorset HealthCare website or report and does not contain confidential or patient-identifiable information.</p>
    </div>
  </footer>

  <script src="{asset_prefix}/site.js"></script>
</body>
</html>
"""


def validate_lists() -> None:
    allow = {normalize_site_path(p) for p in ALLOW_LIST}
    deny = {normalize_site_path(p) for p in DENY_LIST}
    overlap = allow & deny
    if overlap:
        raise SystemExit(f"Allow-list overlaps deny-list: {sorted(overlap)}")
    for path in allow:
        full = SITE_ROOT / path
        if not full.is_file():
            raise SystemExit(f"Allow-listed file missing: {path}")
        if is_denied(path):
            raise SystemExit(f"Allow-listed file is denied: {path}")


def render_one(site_md_rel: str) -> Path:
    site_md_rel = normalize_site_path(site_md_rel)
    source = SITE_ROOT / site_md_rel
    output = DOCS_HTML_ROOT / f"{site_md_rel[:-3]}.html"
    output.parent.mkdir(parents=True, exist_ok=True)

    md_text = source.read_text(encoding="utf-8")
    md_text = rewrite_markdown_links(source, output, md_text)

    md_converter = markdown.Markdown(extensions=["tables", "fenced_code", "sane_lists"])
    body_html = md_converter.convert(md_text)
    body_html = wrap_tables(body_html)
    body_html = sanitize_html(body_html)

    title = extract_title(md_text, Path(site_md_rel).stem.replace("_", " ").title())
    page = build_shell(
        title=title,
        body_html=body_html,
        site_md_rel=site_md_rel,
        output_html=output,
    )
    output.write_text(page, encoding="utf-8")
    return output


def run_check() -> int:
    errors: list[str] = []
    for path in sorted(DOCS_HTML_ROOT.rglob("*.html")):
        text = path.read_text(encoding="utf-8").lower()
        for forbidden in FORBIDDEN_HTML_SUBSTRINGS:
            if forbidden in text:
                errors.append(f"{path.relative_to(REPO_ROOT)}: contains '{forbidden}'")
    answer_key = DOCS_HTML_ROOT / "warehouse-demo/source-notes/human_reviewer_answer_key.html"
    if answer_key.exists():
        errors.append(str(answer_key))

    expected = len(ALLOW_LIST)
    actual = len(list(DOCS_HTML_ROOT.rglob("*.html")))
    print(f"Generated HTML files: {actual} (expected {expected})")
    if actual != expected:
        errors.append(f"Expected {expected} HTML files, found {actual}")

    if errors:
        print("CHECK FAILED:")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("CHECK PASSED: no forbidden content; file count matches allow-list.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify generated output (forbidden strings, file count)",
    )
    args = parser.parse_args()

    validate_lists()

    if args.check:
        if not DOCS_HTML_ROOT.is_dir():
            print("CHECK FAILED: docs-html directory missing")
            return 1
        return run_check()

    rendered: list[Path] = []
    for site_md_rel in ALLOW_LIST:
        rendered.append(render_one(site_md_rel))

    print(f"Rendered {len(rendered)} documents to {DOCS_HTML_ROOT.relative_to(REPO_ROOT)}/")
    return run_check()


if __name__ == "__main__":
    sys.exit(main())
