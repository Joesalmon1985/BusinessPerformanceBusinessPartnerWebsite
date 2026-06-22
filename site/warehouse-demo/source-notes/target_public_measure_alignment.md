# Target public measure alignment (loose)

> This source pack is calibrated for a **warehouse-design demonstration**, not national submission.

## Core principle

The synthetic data should be calibrated to produce **plausible monthly trends and reporting-style measures**. It must **not** attempt to reproduce RDY counts, rates, patient-level distributions or any real provider activity.

This pack is **not** reverse-engineered from public Dorset HealthCare (RDY) extracts. Similarity to published briefs on this site is intentional only at the level of **measure types** and **Provider-month thinking**.

## Measure families a future warehouse might support

Reference [`PUBLIC_REPORTS_METHOD.md`](../../public-data/PUBLIC_REPORTS_METHOD.md) for how public briefs on this site use Provider-month aggregates. From these fictional sources, a later warehouse **might** eventually support analogues such as:

| Public-style family | Possible source-derived analogue | Stock vs activity |
|---------------------|----------------------------------|-------------------|
| MHSDS open referrals (MHS23) | Open Legendary Care referrals at month end | Stock |
| MHSDS people in contact (MHS01) | Distinct patients with open referral or active case | Stock |
| MHSDS contacts (MHS29) | CareCase clinician contacts + Legendary encounters | Activity |
| Crisis / urgent access | IUCS contacts → case conversion, time-to-first clinician contact | Activity / access |
| UCR-style urgent response | CareCall queue events to first answer (demo only) | Performance |
| Waiting-list pressure | Referral open status + LocalOps manual adjustments | Stock / DQ |

Exact definitions, filters and deduplication rules are **not pre-decided**. The profiling agent must propose them from source profiling.

## Reporting grain

- **Organisation:** DRH (fictional)
- **Time:** Calendar month (primary); some sources have event-level timestamps
- **Do not** sum across incompatible grains (e.g. contacts plus cases without conversion logic)

## What agents should not do

- Tune or validate synthetic volumes against RDY public CSVs
- Claim national MHSDS compliance from this pack
- Treat `DEMO-NHS-*` values as real identifiers
- Assume IUCS in this demo maps 1:1 to any national return definition

## Relationship to existing site demos

This pack complements — but does not replace — existing synthetic aggregates in `site/data/` and public RDY extracts in `site/public-data/processed/`. A future agent might **compare patterns** (stock vs activity divergence, provisional monthly revision risk) without matching magnitudes.
