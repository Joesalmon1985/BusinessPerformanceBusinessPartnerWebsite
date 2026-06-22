# Warehouse demo — synthetic source-data pack

Demonstration-only fictional source-system extracts for an agentic warehouse-design worked example.

## Runs

| Run | Focus | Command / location |
|-----|-------|-------------------|
| 1 | Source data | `generator/create_synthetic_source_data.py` |
| 2 | Source profiling | `profiler/profile_sources.py` |
| 3–5 | Design, SQL, ADF, reporting | See [`source-notes/demo_run_index.md`](source-notes/demo_run_index.md) |

## Regenerate source data (Run 1)

```bash
cd site/warehouse-demo/generator
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python create_synthetic_source_data.py
```

## Run source profiler (Run 2)

```bash
cd site/warehouse-demo/profiler
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python profile_sources.py
```

## End-to-end (Runs 1–5)

```bash
# Run 1 — source data
cd site/warehouse-demo/generator && python create_synthetic_source_data.py

# Run 2 — profile
cd site/warehouse-demo/profiler && python profile_sources.py

# Run 5 — mart measures (offline equivalent of ADF mart refresh)
cd site/warehouse-demo/generator && python build_provider_month_measures.py
```

SQL artefacts: [`sql/README.md`](sql/README.md) · Pipelines: [`pipelines/pipeline_overview.md`](pipelines/pipeline_overview.md)

Corrected report: [`reports/urgent-care-provider-month-brief.html`](reports/urgent-care-provider-month-brief.html)

**Human reviewers only:** `source-notes/human_reviewer_answer_key.md` (not for profiling agents).
