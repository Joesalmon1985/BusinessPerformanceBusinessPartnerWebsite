# Secondment demo — data dictionary

> Synthetic demonstration data only. Demo Rivers Health (DRH) — not Dorset HealthCare (RDY).

Field-level definitions for migration scenario artefacts. See [README](README.md) for timeline and regeneration.

## Definition options (referral count)

| ID | Rule (plain English) |
|----|----------------------|
| OPT-A | Count Legendary Care cases where `ReferralDate` falls in the reporting month |
| OPT-B | Count PathwayOne `ACCESS_ACCEPTED` actions in the reporting month |
| OPT-C | **Agreed hybrid:** pre-Feb-2026 use old case logic; from Feb-2026 use action rules with admin/duplicate exclusions and rejection-reason handling |
| DASH | Legacy dashboard pipeline — blends feeds without full reconciliation (Mar 2026 shows +2% vs agreed) |

## legendary_cmht_cases.csv

| Field | Type | Description | Example | DQ notes | Service question |
|-------|------|-------------|---------|----------|------------------|
| CaseId | string | Legacy case identifier | Case LC-10001 | | |
| PatientPseudoId | string | Pseudonymised patient | DRH-PAT-002896 | | |
| ReferralDate | date | Date referral received | 2025-12-08 | | When referred? |
| PathwayStatus | string | Case status | Rejected | | Pathway state |
| PathwayStartDate | date | Pathway start on case | 2025-12-08 | May differ from first contact | When did pathway start? |
| FirstContactDate | date | First clinical contact | 2026-01-10 | Nullable | Contacts / waiting |
| ClosureDate | date | Case closure | 2026-03-20 | Nullable | Has pathway closed? |
| ResponsibleTeam | string | Team code (old or new) | CMHT-N | Remap issues | Which team owns it? |
| ReportingMonth | string | Month for performance reporting | 2026-01 | Ambiguity across systems | Which month to count? |
| OutcomeText | string | Outcome / rejection reason | Wrong service | | Outcome |
| ContactCount | int | Contacts on case | 2 | | Activity inclusion |
| SourceSystem | string | Always LegendaryCare | LegendaryCare | | |

## pathwayone_actions.csv

| Field | Type | Description | Example | DQ notes | Service question |
|-------|------|-------------|---------|----------|------------------|
| ActionId | string | Action event ID | ACT-90001 | Duplicates possible | |
| PatientPseudoId | string | Patient link | DRH-PAT-002896 | | |
| ActionType | string | Access/Care/Outcome/Admin | ACCESS_REJECTED | | Pathway mapping |
| ActionDate | date | Event date | 2025-12-08 | | Referral / activity timing |
| RejectionReason | string | If rejected | CLINICAL_TRIAGE | Affects inclusion | Rejected = received? |
| TeamCode | string | Team on action | AA-MH-NORTH-01 | INVALID_TEAM possible | Team ownership |
| Notes | string | DQ / scenario notes | Admin inflate | | |
| IncludeInReferralCount_NewDefault | int | 1=include in default new count | 0 | | National vs local rules |

## reconciliation_monthly.csv

| Field | Description |
|-------|-------------|
| reporting_month | YYYY-MM |
| old_case_count | OPT-A style count |
| new_action_count_default | OPT-B style count |
| agreed_definition_count | OPT-C agreed count |
| dashboard_displayed_count | What the dashboard shows |
| dashboard_vs_agreed_pct | % difference (Mar 2026 = +14.9% ≈ +2% narrative on dashboard side) |

## feed_cutover_log.csv

Documents **parallel run** (Dec–Jan) vs **referral feed cutover** (Feb) vs **legacy extract end** (Mar).

## Other files

See `data_manifest.csv` for grain, row counts and linked HTML pages.

### Handover deliverable datasets (new / expanded)

| File | Purpose | Linked page |
|------|---------|-------------|
| `kpi_definitions_register.csv` | Layered KPI definition chains (service → sign-off) | `secondment/deliverables/kpi-definitions-register.html` |
| `source_to_report_map.csv` | Report-first field lineage (report_name, report_field filterable) | `secondment/deliverables/source-to-report-map.html` |
| `source_to_report_map_mhsds_view.csv` | MHSDS-like rows filtered from map | `secondment/reports/mhsds-like-submission.html` |
| `source_to_report_map_local_demand_view.csv` | Local demand pack rows filtered from map | `secondment/reports/local-demand-capacity-pack.html` |
| `fact_mh_referral_episode.csv` | Central episode fact — feeds mandatory and local products | `secondment/reports/mhsds-like-submission.html` |
| `mhsds_like_submission_monthly.csv` | Submission header (provider, month, sign-off) | `secondment/reports/mhsds-like-submission.html` |
| `mhsds_like_submission_fields.csv` | One row per submission field (MHS23, MHS01, MHS29, DRH-REF-*) | `secondment/reports/mhsds-like-submission.html` |
| `mhsds_like_validation_checks.csv` | VAL-MH-* pre-submission checks | `secondment/reports/mhsds-like-submission.html` |
| `mhsds_like_reconciliation_summary.csv` | Referral count build-up 151/168/134/154 | `secondment/reports/mhsds-like-submission.html` |
| `definition_decision_log.csv` | OPT-A/B/C and rejection/wait-clock decisions | `secondment/definition-migration.html` |
| `local_demand_access_pack_metrics.csv` | Local pack metrics from same fact | `secondment/reports/local-demand-capacity-pack.html` |
| `reporting_requirements_map.csv` | Stakeholder questions and KPI refs | `secondment/deliverables/source-to-report-map.html` |
| `report_catalogue.csv` | Report names, owners, confidence | `secondment/deliverables/source-to-report-map.html` |
| `validation_checks_register.csv` | Pre-publish validation rules and Mar 2026 results | `secondment/deliverables/reporting-assurance-during-migration.html` |
| `reconciliation_detail_mar2026.csv` | Team/vignette build-up of 154 vs 134 | `secondment/deliverables/reporting-assurance-during-migration.html` |
| `migration_risk_register.csv` | Reporting meaning risks during migration | `secondment/deliverables/reporting-assurance-during-migration.html` |
| `reporting_confidence_register.csv` | Confidence levels and publish decisions | `secondment/deliverables/reporting-assurance-during-migration.html` |
| `demand_capacity_weekly.csv` | Weekly demand, capacity, backlog and wait metrics | `secondment/deliverables/demand-capacity-productivity.html` |
| `demand_capacity_insights.csv` | Analysis insights with status and suggested actions | `secondment/deliverables/demand-capacity-productivity.html` |
| `ideas_under_test_register.csv` | Ideas tested, promoted, parked or dismissed | `secondment/deliverables/ideas-under-test.html` |
| `productivity_by_team.csv` | Contacts per WTE by team and week | `secondment/deliverables/demand-capacity-productivity.html` |
| `improvement_benefits_tracker.csv` | Benefits linked to six-month outcomes | `secondment/deliverables/index.html` |
| `handover_documentation_register.csv` | Document register for M6 handover | `secondment/deliverables/index.html` |
| `change_playbook.csv` | Ten-step reusable migration playbook | `six-months-trusted-performance.html#reusable-approach` |
| `senior_brief_sections.csv` | Brief template sections with Mar 2026 text | `secondment/deliverables/senior-performance-brief.html` |

### kpi_definitions_register.csv (layered columns)

| Field | Description |
|-------|-------------|
| service_definition | What the measure means in the real service |
| system_capture | What staff do and what the source system records |
| fact_table_definition | Warehouse fact / derivation logic |
| reporting_use | Mandatory vs local reporting use |
| exclusions_caveats | Inclusion/exclusion rules and migration caveats |
| validation_check | How we know the chain is still intact |
| owners_sign_off | Operational, BI, performance and final sign-off roles |

### source_to_report_map.csv (canonical map — one map, many views)

Single source of truth for report-first and source-first lineage. The interactive page at `secondment/source-to-report.html` filters this CSV client-side; filtered exports (`source_to_report_map_mhsds_view.csv`, etc.) are convenience downloads only.

| Field | Description |
|-------|-------------|
| map_row_id | STR-001 etc. — stable row identifier |
| report_name | Filter key — e.g. MHSDS-like monthly submission |
| report_type | Mandatory / Local / Assurance / Source impact |
| report_section | Section or table within the report |
| report_field | Output field on the report |
| metric_code | MHS23, MHS01, DRH-REF-OPT-C, KPI-01, etc. |
| kpi_id | KPI-01 when linked to KPI register; else blank |
| service_event | Real-world service event |
| warehouse_fact_or_dimension | Primary fact — usually fact_mh_referral_episode |
| inclusion_rule / exclusion_rule | National vs local counting rules |
| national_or_local_use | National / Local / Both / Assurance |
| related_output_file | CSV or report artefact this row feeds |
| notes | Vignettes, reconciliation notes, preset hints |
| reporting_confidence | High / Medium / Low for Mar 2026 |

Filtered exports (not separate truth): `source_to_report_map_mhsds_view.csv`, `source_to_report_map_local_demand_view.csv`.

### fact_mh_referral_episode.csv

Central episode grain derived from `legendary_cmht_cases` + `pathwayone_actions`. Key fields:

| Field | Description |
|-------|-------------|
| episode_id | Synthetic episode identifier |
| derivation_rule | OPT-C, OPT-A, DASH, etc. |
| mhsds_like_inclusion_flag | 1 = include in MHSDS-like submission roll-up |
| local_reporting_inclusion_flag | 1 = include in local demand pack |
| first_contact_wait_days | Wait clock — definition-sensitive (see DEC-03) |
| reporting_month | YYYY-MM for monthly roll-ups |

Mar 2026 referrals received (agreed OPT-C) = **134**; dashboard logic = **154** (reconciliation_monthly / mhsds_like_reconciliation_summary).

### reporting_requirements_map.csv

| Field | Description |
|-------|-------------|
| requirement_id | REQ-01 etc. |
| stakeholder | Who needs the answer |
| question | Business question |
| mandatory_or_local | Mandatory / Local |
| kpi_ref | KPI-01 etc. |
| report_ref | Report catalogue ID |

### report_catalogue.csv

| Field | Description |
|-------|-------------|
| report_id | CAT-01 etc. |
| report_name | Report title |
| audience | SLT, NHSE, service etc. |
| frequency | Monthly, weekly |
| owner | Role title |
| requirement_ids | Linked REQ IDs |
| confidence_mar2026 | High / Medium / Low |
| data_sources | Primary feeds |

### validation_checks_register.csv

| Field | Description |
|-------|-------------|
| check_id | VAL-01 etc. |
| rule | Validation rule |
| source | Table or pipeline |
| expected | Expected outcome |
| mar2026_result | Actual result |
| pass_fail | Pass / Fail |
| action | Follow-up |

### reconciliation_detail_mar2026.csv

| Field | Description |
|-------|-------------|
| level | Trust total or team/vignette |
| old_case_count | OPT-A |
| new_action_count | OPT-B default |
| agreed_count | OPT-C |
| dashboard_count | Dashboard displayed |
| notes | e.g. duplicate ActionId |

### productivity_by_team.csv

| Field | Description |
|-------|-------------|
| team_code | AA-MH-NORTH-01 etc. |
| week | W10, W21 |
| available_hours | WTE availability |
| contacts_delivered | Care contacts |
| contacts_per_wte | Productivity metric |

### improvement_benefits_tracker.csv

| Field | Description |
|-------|-------------|
| benefit_id | BEN-01 etc. |
| benefit | Benefit description |
| baseline | Starting point |
| target | Target state |
| status | Green / Amber / Red |
| owner | Role title |
| evidence_link | Deliverable or report |
| month | M1–M6 |

### handover_documentation_register.csv

| Field | Description |
|-------|-------------|
| doc_id | DOC-01 etc. |
| document_name | Artefact name |
| purpose | Why it exists |
| owner | Role title |
| location | Path or URL |
| handover_status | Draft / Ready |

### change_playbook.csv

| Field | Description |
|-------|-------------|
| step | 1–10 |
| phase | Listen, map, define etc. |
| activity | What to do |
| artefact_produced | Deliverable produced |
| reuse_note | How to reuse |

### senior_brief_sections.csv

| Field | Description |
|-------|-------------|
| section | Bottom line, headlines etc. |
| content_template | Template wording |
| mar2026_example | Filled example |
| confidence | High / Medium / Low |
