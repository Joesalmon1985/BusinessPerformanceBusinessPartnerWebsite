# MHSDS-like sources consulted (DRH demonstration)

This secondment demonstration uses **MHSDS-like** wording throughout. It is **not** an official NHS England Mental Health Services Data Set (MHSDS) return, Technical Output Specification extract, or published national statistic.

## Official sources consulted (read-only)

| Source | Use in this demonstration |
|--------|---------------------------|
| [NHS England MHSDS information standard (DAPB0011 v6.0)](https://digital.nhs.uk/data-and-information/information-standards/governance/latest-activity/standards-and-collections/dapb0011-mental-health-services-data-set) | Patient-level secondary-uses set scope; we cite measure **concepts** only — not reproduced in full |
| [Mental Health Services Monthly Statistics](https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics) | Metadata-driven published measures; DRH mock uses same **measure IDs** (MHS23, MHS01, MHS29) with **illustrative synthetic values** |
| DRH synthetic warehouse (`fact_mh_referral_episode`) | Local derivation rules (OPT-C, dashboard, legacy) documented in `definition_decision_log.csv` |

## Relationship to public RDY site

The public Derbyshire Healthcare NHS Foundation Trust (RDY) site reuses national trend structure from `trend_mhsds_access_rdy.csv`. **DRH is a fictional trust** for the secondment narrative. RDY pages and values are **not** duplicated here.

## Disclaimer

- All counts, episodes, and submission fields are **synthetic** and smaller-scale than national aggregates.
- DRH-internal codes (e.g. `DRH-REF-OPT-C`, `DRH-REF-DASH`) support the migration story where service-agreed referral-received-in-month differs from dashboard logic.
- Sign-off statuses and confidence tiers are illustrative for Business & Performance assurance workshops.
