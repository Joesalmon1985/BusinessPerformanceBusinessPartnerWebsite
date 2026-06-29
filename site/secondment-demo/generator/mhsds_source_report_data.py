"""MHSDS-like source-to-report artefacts for DRH secondment demo (stdlib only)."""

from __future__ import annotations

TRUST_ODS = "DRH"
ANCHOR = "DRH-PAT-002896"

MAP_COLS = [
    "map_row_id", "report_name", "report_type", "report_section", "report_field",
    "metric_code", "kpi_id", "service_event", "service_definition",
    "system_workflow_capture", "source_system", "source_table", "source_field",
    "source_grain", "staging_table", "warehouse_fact_or_dimension", "fact_grain",
    "transformation_rule", "inclusion_rule", "exclusion_rule", "validation_check",
    "reconciliation_check", "migration_risk", "reporting_confidence",
    "sign_off_owner", "sign_off_status", "management_decision_supported",
    "local_performance_use", "national_or_local_use", "related_output_file", "notes",
]

_REPORT_OUTPUT_FILES = {
    "MHSDS-like monthly submission": "mhsds_like_submission_fields.csv",
    "Local demand and access performance pack": "local_demand_access_pack_metrics.csv",
    "Waiting list and pathway risk report": "demand_capacity_weekly.csv",
    "Senior performance brief": "senior_brief_sections.csv",
    "Data quality and reporting confidence report": "reporting_confidence_register.csv",
    "CSDS-like monthly submission": "mandatory_mhsds_like_monthly.csv",
    "Source impact analysis": "source_to_report_map.csv",
}


def _derive_report_type(report_name: str) -> str:
    if report_name == "Source impact analysis":
        return "Source impact"
    if "MHSDS" in report_name or "CSDS" in report_name:
        return "Mandatory"
    if "confidence" in report_name.lower() or report_name.startswith("Data quality"):
        return "Assurance"
    return "Local"


def _derive_kpi_id(metric_code: str) -> str:
    return metric_code if metric_code.startswith("KPI-") else ""


def _derive_national_local(reporting_use: str, local_use: str, report_type: str) -> str:
    if report_type in ("Assurance", "Source impact"):
        return "Assurance" if report_type == "Assurance" else "Both"
    ru = (reporting_use or "").lower()
    lu = (local_use or "").lower()
    national = any(x in ru for x in ("nhse", "mandatory", "csds", "national"))
    local = bool(lu) and lu not in ("n/a", "do not use for decisions")
    if national and local:
        return "Both"
    if national:
        return "National"
    return "Local"


def _finalize_map_rows(rows: list[dict]) -> list[dict]:
    """Assign IDs and derived columns; normalize legacy keys."""
    out = []
    for i, row in enumerate(rows, start=1):
        reporting_use = row.get("reporting_use", "")
        r = {c: "" for c in MAP_COLS}
        for k, v in row.items():
            key = "report_section" if k == "report_section_or_table" else k
            if key in r:
                r[key] = v or ""
        r["map_row_id"] = f"STR-{i:03d}"
        rn = r["report_name"]
        r["report_type"] = _derive_report_type(rn)
        r["kpi_id"] = _derive_kpi_id(r.get("metric_code", ""))
        r["national_or_local_use"] = _derive_national_local(
            reporting_use, r.get("local_performance_use", ""), r["report_type"])
        r["related_output_file"] = _REPORT_OUTPUT_FILES.get(
            rn, "fact_mh_referral_episode.csv" if "fact_mh" in r.get("source_table", "") else "")
        if not r.get("notes"):
            if r.get("metric_code") == "DRH-REF-OPT-C":
                r["notes"] = "Mar 2026 agreed count 134 vs dashboard 154. Vignette DRH-PAT-002896."
            elif r.get("metric_code") == "DRH-REF-DASH":
                r["notes"] = "Not for submission — VAL-MH-03 failed."
            elif r["report_type"] == "Source impact":
                r["notes"] = f"Affected reports: {reporting_use}"
        out.append(r)
    return out

FACT_COLS = [
    "episode_id", "synthetic_patient_id", "source_referral_id", "legacy_case_id",
    "referral_received_datetime", "referral_accepted_datetime", "referral_rejected_datetime",
    "rejection_reason", "pathway_start_datetime", "first_clinical_contact_datetime",
    "outcome_datetime", "closure_datetime", "responsible_team_code", "responsible_team_name",
    "service_line", "reporting_month", "referral_status", "episode_status",
    "first_contact_wait_days", "clinical_contact_count", "attended_contact_count", "dna_count",
    "outcome_code", "mhsds_like_inclusion_flag", "local_reporting_inclusion_flag",
    "exclusion_reason", "derivation_rule", "derivation_confidence", "validation_status",
]

TEAM_NAMES = {
    "CMHT-N": "Community MH North", "CMHT-S": "Community MH South", "CMHT-E": "Community MH East",
    "CRHT": "Crisis Resolution", "PC-LIAISON": "Primary Care Liaison",
    "AA-MH-NORTH-01": "Community MH North", "AA-MH-SOUTH-01": "Community MH South",
    "AA-MH-EAST-01": "Community MH East", "AA-CRISIS-01": "Crisis Resolution",
    "AA-PCL-01": "Primary Care Liaison", "INVALID_TEAM": "Unmapped team",
}


def _team_name(code: str) -> str:
    return TEAM_NAMES.get(code, code)


def _wait_days(ref: str, contact: str) -> str:
    if not ref or not contact:
        return ""
    from datetime import date
    try:
        r = date.fromisoformat(ref[:10])
        c = date.fromisoformat(contact[:10])
        return str((c - r).days)
    except ValueError:
        return ""


def build_episodes(legendary: list[dict], actions: list[dict]) -> list[dict]:
    """Derive fact_mh_referral_episode rows from cases and actions."""
    by_patient: dict[str, list[dict]] = {}
    for a in actions:
        by_patient.setdefault(a["PatientPseudoId"], []).append(a)

    episodes = []
    for i, case in enumerate(legendary, start=1):
        pid = case["PatientPseudoId"]
        acts = by_patient.get(pid, [])
        accepted = next((a for a in acts if a["ActionType"] == "ACCESS_ACCEPTED"), None)
        rejected = next((a for a in acts if a["ActionType"] == "ACCESS_REJECTED"), None)
        first_contact = next((a for a in acts if a["ActionType"] == "CARE_FIRST_CONTACT"), None)
        care = [a for a in acts if a["ActionType"] in ("CARE_ONGOING", "CARE_FIRST_CONTACT")]
        admin = [a for a in acts if a["ActionType"] == "ADMIN_CANCEL"]
        team = acts[0]["TeamCode"] if acts else case["ResponsibleTeam"]
        ref_dt = f"{case['ReferralDate']} 09:00:00"
        acc_dt = f"{accepted['ActionDate']} 10:00:00" if accepted else ""
        rej_dt = f"{rejected['ActionDate']} 11:00:00" if rejected else ""
        rej_reason = rejected.get("RejectionReason", "") if rejected else case.get("OutcomeText", "")
        fc_dt = first_contact["ActionDate"] + " 14:00:00" if first_contact else (case["FirstContactDate"] + " 14:00:00" if case["FirstContactDate"] else "")
        path_start = fc_dt or acc_dt
        closure = case["ClosureDate"] + " 16:00:00" if case["ClosureDate"] else ""
        status = case["PathwayStatus"]
        month = case["ReportingMonth"]

        # OPT-C inclusion rules (simplified for demo)
        opt_c = "1"
        excl = ""
        if status == "Rejected" and rej_reason in ("Wrong service", "NOT_APPROPRIATE"):
            opt_c = "0"
            excl = "Rejected — exclude unless CLINICAL_TRIAGE"
        if pid == "DRH-PAT-005663":
            opt_c = "0"
            excl = "Duplicate ACCESS_ACCEPTED"
        if team == "INVALID_TEAM":
            excl = (excl + "; INVALID_TEAM").strip("; ")

        mhsds = opt_c if status != "Rejected" or rej_reason == "CLINICAL_TRIAGE" else "0"
        local = "1" if team != "INVALID_TEAM" else "0"
        if team == "AA-PCL-01" or case["ResponsibleTeam"] == "PC-LIAISON":
            mhsds = "0"
            local = "1"
            if not excl:
                excl = "National exclude; local include"

        conf = "High" if opt_c == "1" and not excl else ("Medium" if excl else "Low")
        val = "Pass" if conf == "High" else ("Review" if excl else "Fail")

        episodes.append({
            "episode_id": f"EP-{i:04d}",
            "synthetic_patient_id": pid,
            "source_referral_id": f"REF-{i:04d}",
            "legacy_case_id": case["CaseId"],
            "referral_received_datetime": ref_dt,
            "referral_accepted_datetime": acc_dt,
            "referral_rejected_datetime": rej_dt,
            "rejection_reason": rej_reason,
            "pathway_start_datetime": path_start,
            "first_clinical_contact_datetime": fc_dt,
            "outcome_datetime": closure,
            "closure_datetime": closure,
            "responsible_team_code": team,
            "responsible_team_name": _team_name(team if team != "INVALID_TEAM" else case["ResponsibleTeam"]),
            "service_line": "All Age MH Access",
            "reporting_month": month,
            "referral_status": status,
            "episode_status": "Closed" if closure else ("Waiting" if status == "Waiting" else "Open"),
            "first_contact_wait_days": _wait_days(case["ReferralDate"], fc_dt[:10] if fc_dt else ""),
            "clinical_contact_count": str(len(care)),
            "attended_contact_count": str(len(care)),
            "dna_count": "0",
            "outcome_code": case.get("OutcomeText", "") or "",
            "mhsds_like_inclusion_flag": mhsds,
            "local_reporting_inclusion_flag": local,
            "exclusion_reason": excl,
            "derivation_rule": "OPT-C hybrid",
            "derivation_confidence": conf,
            "validation_status": val,
        })

    # Extra vignette episodes (no legacy case — action-only post-cutover)
    extras = [
        {"episode_id": "EP-0019", "synthetic_patient_id": "DRH-PAT-006101", "source_referral_id": "REF-019",
         "legacy_case_id": "", "referral_received_datetime": "2026-03-08 09:00:00",
         "referral_accepted_datetime": "2026-03-08 10:00:00", "referral_rejected_datetime": "",
         "rejection_reason": "", "pathway_start_datetime": "2026-03-15 14:00:00",
         "first_clinical_contact_datetime": "2026-03-15 14:00:00", "outcome_datetime": "",
         "closure_datetime": "", "responsible_team_code": "AA-MH-NORTH-01",
         "responsible_team_name": "Community MH North", "service_line": "All Age MH Access",
         "reporting_month": "2026-03", "referral_status": "Accepted", "episode_status": "Open",
         "first_contact_wait_days": "7", "clinical_contact_count": "1", "attended_contact_count": "1",
         "dna_count": "0", "outcome_code": "", "mhsds_like_inclusion_flag": "1",
         "local_reporting_inclusion_flag": "1", "exclusion_reason": "",
         "derivation_rule": "OPT-C post-cutover action only", "derivation_confidence": "Medium",
         "validation_status": "Pass"},
        {"episode_id": "EP-0020", "synthetic_patient_id": "DRH-PAT-006102", "source_referral_id": "REF-020",
         "legacy_case_id": "", "referral_received_datetime": "2026-03-10 09:00:00",
         "referral_accepted_datetime": "", "referral_rejected_datetime": "2026-03-10 11:00:00",
         "rejection_reason": "DUPLICATE_REFERRAL", "pathway_start_datetime": "",
         "first_clinical_contact_datetime": "", "outcome_datetime": "", "closure_datetime": "",
         "responsible_team_code": "AA-MH-SOUTH-01", "responsible_team_name": "Community MH South",
         "service_line": "All Age MH Access", "reporting_month": "2026-03", "referral_status": "Rejected",
         "episode_status": "Closed", "first_contact_wait_days": "", "clinical_contact_count": "0",
         "attended_contact_count": "0", "dna_count": "0", "outcome_code": "Duplicate",
         "mhsds_like_inclusion_flag": "0", "local_reporting_inclusion_flag": "1",
         "exclusion_reason": "Duplicate referral — DQ only", "derivation_rule": "OPT-C exclude duplicate",
         "derivation_confidence": "High", "validation_status": "Pass"},
    ]
    episodes.extend(extras)
    return episodes


def _row(**kwargs) -> dict:
    if "report_section_or_table" in kwargs and "report_section" not in kwargs:
        kwargs["report_section"] = kwargs.pop("report_section_or_table")
    base: dict[str, str] = {}
    for k, v in kwargs.items():
        if k in MAP_COLS or k == "reporting_use":
            base[k] = v or ""
    return base


def build_source_to_report_map() -> list[dict]:
    """Report-first source-to-report map (~40 rows)."""
    mh = "MHSDS-like monthly submission"
    local = "Local demand and access performance pack"
    wait = "Waiting list and pathway risk report"
    brief = "Senior performance brief"
    conf = "Data quality and reporting confidence report"
    csds = "CSDS-like monthly submission"

    rows = [
        _row(report_name=mh, report_section="Provider main data", report_field="Open referrals at month end",
             metric_code="MHS23", service_event="Patient has open referral at reporting period end",
             service_definition="Stock measure — open referrals (caseload-style); not automatically good or bad",
             system_workflow_capture="Derived from episode open status at month-end snapshot",
             source_system="Legendary Care + PathwayOne", source_table="fact_mh_referral_episode",
             source_field="episode_status, reporting_month", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Count episodes Open or Waiting at last day of month",
             inclusion_rule="mhsds_like_inclusion_flag=1", exclusion_rule="INVALID_TEAM; national-excluded teams",
             validation_check="Compare to prior month stock; vignette sample",
             reconciliation_check="Cross-check MHS01 subset", reporting_use="NHSE mandatory return",
             local_performance_use="Caseload pressure by team", sign_off_owner="Mandatory reporting owner",
             sign_off_status="Draft Mar 2026", management_decision_supported="National monitoring; local capacity",
             migration_risk="High — open definition changed post-migration", reporting_confidence="Medium"),
        _row(report_name=mh, report_section="Provider main data",
             report_field="People with open referral with services at month end", metric_code="MHS01",
             service_event="Person remains on pathway with open referral",
             service_definition="Stock — people with open referral in contact with services (Apr 2026 label analogue)",
             system_workflow_capture="Episode open after ACCESS_ACCEPTED without OUTCOME_CLOSED",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="episode_status", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Distinct patients with open episode at month end",
             inclusion_rule="mhsds_like_inclusion_flag=1", exclusion_rule="Closed episodes",
             validation_check="Service manager stock check", reconciliation_check="MHS23 >= MHS01 logic check",
             reporting_use="NHSE mandatory", local_performance_use="Caseload management",
             sign_off_owner="Mandatory reporting owner", sign_off_status="Draft",
             management_decision_supported="Workforce planning", migration_risk="Medium",
             reporting_confidence="Medium"),
        _row(report_name=mh, report_section="Provider main data", report_field="Contacts in reporting period",
             metric_code="MHS29", service_event="Clinical contact delivered in month",
             service_definition="Activity measure — contact volume in reporting period",
             system_workflow_capture="CARE_ONGOING and CARE_FIRST_CONTACT actions",
             source_system="PathwayOne", source_table="pathwayone_actions",
             source_field="ActionType CARE_*", source_grain="action",
             staging_table="stg_action", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Sum clinical_contact_count by reporting_month",
             inclusion_rule="Clinical actions only", exclusion_rule="ADMIN_CANCEL; duplicate ActionId",
             validation_check="CSDS-like cross-check", reconciliation_check="VAL-05 admin exclusion",
             reporting_use="NHSE mandatory activity", local_performance_use="Productivity by team",
             sign_off_owner="Mandatory reporting owner", sign_off_status="Pending reconciliation",
             management_decision_supported="Activity monitoring", migration_risk="High — admin inflation",
             reporting_confidence="Medium"),
        _row(report_name=mh, report_section="Internal reconciliation", report_field="Referrals received (agreed OPT-C)",
             metric_code="DRH-REF-OPT-C", service_event="Referral received — service-agreed meaning",
             service_definition="Hybrid OPT-C: pre-Feb cases; post-Feb access rules with exclusions",
             system_workflow_capture="Case ReferralDate or ACCESS_ACCEPTED per agreed rules",
             source_system="Legendary Care + PathwayOne", source_table="fact_mh_referral_episode",
             source_field="derivation_rule=OPT-C", source_grain="episode",
             staging_table="stg_referral_agreed", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Count episodes referral_received in month where OPT-C",
             inclusion_rule="mhsds_like_inclusion_flag=1; reporting_month=2026-03",
             exclusion_rule="Rejected unless CLINICAL_TRIAGE; duplicates; admin",
             validation_check="Monthly parallel-run compare", reconciliation_check="134 vs dashboard 154",
             reporting_use="Mandatory submission after sign-off", local_performance_use="Demand monitoring",
             sign_off_owner="Directorate lead", sign_off_status="Agreed pending workshop",
             management_decision_supported="Submit 134 not 154 to NHSE", migration_risk="High",
             reporting_confidence="Low until signed off"),
        _row(report_name=mh, report_section="Internal reconciliation (do not submit)",
             report_field="Referrals received (dashboard logic)", metric_code="DRH-REF-DASH",
             service_event="Referral counted by legacy dashboard pipeline",
             service_definition="Blended pipeline — not reconciled to OPT-C",
             system_workflow_capture="Legacy fact_referral + fact_access blend",
             source_system="Blended", source_table="fact_referral", source_field="blended logic",
             source_grain="episode", staging_table="stg_case+stg_action",
             warehouse_fact_or_dimension="fact_referral", fact_grain="episode",
             transformation_rule="Legacy dashboard refresh", inclusion_rule="None — legacy",
             exclusion_rule="n/a", validation_check="VAL-03 fail", reconciliation_check="+14.9% vs agreed",
             reporting_use="Executive dashboard only", local_performance_use="Do not use for decisions",
             sign_off_owner="BI lead", sign_off_status="Not for submission",
             management_decision_supported="Withhold from Board", migration_risk="High",
             reporting_confidence="Low"),
        _row(report_name=mh, report_section="Provider main data", report_field="Rejected referrals by reason",
             metric_code="DRH-REJ-BREAK", service_event="Referral rejected at triage",
             service_definition="Rejected referrals — national vs local inclusion differs by reason",
             system_workflow_capture="ACCESS_REJECTED or case Rejected status",
             source_system="Both", source_table="fact_mh_referral_episode",
             source_field="rejection_reason", source_grain="episode",
             staging_table="stg_action", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Group by rejection_reason",
             inclusion_rule="Varies by reason code", exclusion_rule="CLINICAL_TRIAGE may count as received",
             validation_check="Sample with clinical lead", reconciliation_check="Anchor DRH-PAT-002896",
             reporting_use="Mandatory metadata", local_performance_use="Rejection rate review",
             sign_off_owner="Clinical lead", sign_off_status="Workshop required",
             management_decision_supported="Definition agreement", migration_risk="High",
             reporting_confidence="Low"),
        _row(report_name=mh, report_section="Access performance", report_field="First contact within 14 days (%)",
             metric_code="DRH-FC14", service_event="First clinical contact within 14 days of referral",
             service_definition="Numerator: first contact <=14d; denominator: agreed referrals",
             system_workflow_capture="first_contact_wait_days on episode",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="first_contact_wait_days", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Wait clock starts at referral received (agreed)",
             inclusion_rule="Denominator OPT-C referrals", exclusion_rule="No contact yet",
             validation_check="Vignette DRH-PAT-001552 — clock start sensitivity",
             reconciliation_check="Compare access-accepted start vs referral start",
             reporting_use="Mandatory access indicator", local_performance_use="Waiting standards",
             sign_off_owner="Clinical lead", sign_off_status="Agreed",
             management_decision_supported="Access performance review", migration_risk="Medium",
             reporting_confidence="Medium"),
        _row(report_name=mh, report_section="CYP access (optional)", report_field="CYP access cohort",
             metric_code="MHS69", service_event="Children and young people access pathway",
             service_definition="CYP access measure concept — illustrative DRH row only",
             system_workflow_capture="Episode service_line filter",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="service_line", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Count CYP episodes in month",
             inclusion_rule="service_line=CYP", exclusion_rule="Adult CMHT",
             validation_check="Age band cross-check", reconciliation_check="Not in Mar 2026 scope",
             reporting_use="NHSE CYP monitoring", local_performance_use="CYP pathway review",
             sign_off_owner="CYP lead", sign_off_status="Out of scope Mar 2026",
             management_decision_supported="CYP access assurance", migration_risk="Low",
             reporting_confidence="N/A"),
        _row(report_name=mh, report_section="Pathway", report_field="Pathway start datetime",
             metric_code="KPI-02", service_event="Patient begins active care on pathway",
             service_definition="First clinical contact or agreed pathway start rule",
             system_workflow_capture="CARE_FIRST_CONTACT or pathway_start_datetime",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="pathway_start_datetime", source_grain="episode",
             staging_table="stg_action", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Earliest clinical contact post-acceptance",
             inclusion_rule="ACCESS_ACCEPTED required", exclusion_rule="Rejected pathways",
             validation_check="Compare to legacy FirstContactDate", reconciliation_check="Waiting list clock",
             reporting_use="Mandatory metadata", local_performance_use="Pathway performance",
             sign_off_owner="Clinical lead", sign_off_status="Agreed",
             management_decision_supported="Waiting-time review", migration_risk="Medium",
             reporting_confidence="Medium"),
    ]

    # Local demand pack rows
    for field, code, metric in [
        ("Weekly demand index", "DRH-DEM-WK", "Sum demand from weekly pack"),
        ("Backlog stock", "DRH-BACKLOG", "Open waiting episodes"),
        ("Referrals in week", "DRH-REF-WK", "OPT-C referrals in ISO week"),
        ("DNA rate", "DRH-DNA", "DNA / scheduled contacts"),
        ("Demand by team", "DRH-DEM-TEAM", "Episodes grouped by responsible_team_code"),
        ("Median wait to first contact", "DRH-WAIT-MED", "Median first_contact_wait_days"),
    ]:
        rows.append(_row(
            report_name=local, report_section="Weekly pack", report_field=field, metric_code=code,
            service_event="Service demand and capacity signal",
            service_definition="Local operational definition — may differ from national stock measures",
            system_workflow_capture="Rolled from fact_mh_referral_episode + demand_capacity_weekly",
            source_system="PathwayOne + RosterFlow", source_table="fact_mh_referral_episode",
            source_field="multiple", source_grain="episode/week",
            staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
            fact_grain="episode", transformation_rule=metric,
            inclusion_rule="local_reporting_inclusion_flag=1",
            exclusion_rule="National exclusions may still count locally",
            validation_check="Weekly DQ", reconciliation_check="Separate from MHS23 stock",
            reporting_use="Local only", local_performance_use="Capacity meetings",
            sign_off_owner="Service manager", sign_off_status="Prototype",
            management_decision_supported="Team capacity allocation", migration_risk="Medium",
            reporting_confidence="High"))

    # Waiting list, brief, confidence, CSDS — shorter rows
    rows.extend([
        _row(report_name=wait, report_section="Waiting stock", report_field="ACCESS_WAITING count",
             metric_code="KPI-03", service_event="Patient waiting for first contact",
             service_definition="Open ACCESS_WAITING at month end", system_workflow_capture="ACCESS_WAITING action",
             source_system="PathwayOne", source_table="pathwayone_actions", source_field="ACCESS_WAITING",
             source_grain="action", staging_table="stg_action",
             warehouse_fact_or_dimension="fact_mh_referral_episode", fact_grain="episode",
             transformation_rule="Count waiting episodes", inclusion_rule="Exclude INVALID_TEAM",
             exclusion_rule="INVALID_TEAM", validation_check="VAL-02", reconciliation_check="Old case Waiting compare",
             reporting_use="Local", local_performance_use="Prioritisation", sign_off_owner="Service manager",
             sign_off_status="Draft", management_decision_supported="Waiting list review",
             migration_risk="Medium", reporting_confidence="Medium"),
        _row(report_name=wait, report_section="Access gap", report_field="First contact wait days",
             metric_code="DRH-WAIT-DAYS", service_event="Days from referral to first clinical contact",
             service_definition="Median/mean wait — clock start at referral received",
             system_workflow_capture="first_contact_wait_days on episode",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="first_contact_wait_days", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Datediff referral to first contact",
             inclusion_rule="Episodes with contact", exclusion_rule="Still waiting",
             validation_check="DEC-03 clock start", reconciliation_check="DRH-FC14 numerator",
             reporting_use="Local risk report", local_performance_use="Escalation by team",
             sign_off_owner="Service manager", sign_off_status="Agreed",
             management_decision_supported="Capacity allocation", migration_risk="Medium",
             reporting_confidence="Medium"),
        _row(report_name=wait, report_section="Risk flag", report_field="Long wait episodes",
             metric_code="DRH-WAIT-RISK", service_event="Patient waiting beyond threshold",
             service_definition="Episodes with wait &gt;28 days without contact",
             system_workflow_capture="episode_status=Waiting + wait days",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="episode_status", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Filter waiting beyond SLA",
             inclusion_rule="local_reporting_inclusion_flag=1", exclusion_rule="INVALID_TEAM",
             validation_check="Weekly refresh", reconciliation_check="Not MHS23 stock",
             reporting_use="Local escalation", local_performance_use="Clinical prioritisation",
             sign_off_owner="Clinical lead", sign_off_status="Draft",
             management_decision_supported="Risk review meeting", migration_risk="Low",
             reporting_confidence="High"),
        _row(report_name=brief, report_section="Headline", report_field="Referrals Mar 2026",
             metric_code="KPI-01", service_event="Referral received", service_definition="Agreed OPT-C",
             system_workflow_capture="fact_mh_referral_episode", source_system="Both",
             source_table="fact_mh_referral_episode", source_field="reporting_month",
             source_grain="episode", staging_table="stg_episode",
             warehouse_fact_or_dimension="fact_mh_referral_episode", fact_grain="episode",
             transformation_rule="134 agreed / 154 dashboard", inclusion_rule="OPT-C",
             exclusion_rule="Dashboard excluded from narrative", validation_check="VAL-03",
             reconciliation_check="reconciliation_detail_mar2026", reporting_use="SLT assurance",
             local_performance_use="Board narrative", sign_off_owner="Directorate lead",
             sign_off_status="Withheld", management_decision_supported="Do not publish dashboard figure",
             migration_risk="High", reporting_confidence="Low"),
        _row(report_name=brief, report_section="Headline", report_field="Backlog W21",
             metric_code="DRH-BACKLOG", service_event="Open waiting stock",
             service_definition="Local backlog — not MHS23 national stock",
             system_workflow_capture="fact_mh_referral_episode waiting episodes",
             source_system="PathwayOne", source_table="fact_mh_referral_episode",
             source_field="episode_status", source_grain="episode",
             staging_table="stg_episode", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Count Waiting at week end",
             inclusion_rule="local_reporting_inclusion_flag=1", exclusion_rule="National exclusions",
             validation_check="Weekly DQ", reconciliation_check="demand_capacity_weekly",
             reporting_use="Board narrative", local_performance_use="Capacity meetings",
             sign_off_owner="Performance lead", sign_off_status="Medium confidence",
             management_decision_supported="Agency and WTE review", migration_risk="Low",
             reporting_confidence="Medium"),
        _row(report_name=conf, report_section="Product register", report_field="MHSDS-like confidence tier",
             metric_code="CONF-MH", service_event="Reporting assurance", service_definition="Confidence model tier",
             system_workflow_capture="reporting_confidence_register", source_system="n/a",
             source_table="reporting_confidence_register", source_field="confidence_level",
             source_grain="report", staging_table="n/a", warehouse_fact_or_dimension="n/a",
             fact_grain="n/a", transformation_rule="Rules during migration phase D",
             inclusion_rule="n/a", exclusion_rule="n/a", validation_check="All VAL-MH checks",
             reconciliation_check="mhsds_like_reconciliation_summary", reporting_use="Assurance",
             local_performance_use="Publish gate", sign_off_owner="Performance lead",
             sign_off_status="Active", management_decision_supported="Escalation before publish",
             migration_risk="Low", reporting_confidence="High"),
        _row(report_name=conf, report_section="Product register", report_field="Local demand pack confidence",
             metric_code="CONF-LOC", service_event="Local product assurance",
             service_definition="Local pack can be High when national still Medium",
             system_workflow_capture="local_reporting_inclusion_flag rules",
             source_system="n/a", source_table="fact_mh_referral_episode",
             source_field="local_reporting_inclusion_flag", source_grain="episode",
             staging_table="n/a", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Separate inclusion from mandatory",
             inclusion_rule="Documented per team", exclusion_rule="PC Liaison national",
             validation_check="DEC-04", reconciliation_check="local_demand_access_pack_metrics",
             reporting_use="Local publish gate", local_performance_use="Weekly meetings",
             sign_off_owner="Service manager", sign_off_status="Prototype High",
             management_decision_supported="Capacity decisions", migration_risk="Medium",
             reporting_confidence="High"),
        _row(report_name=csds, report_section="Activity return", report_field="Clinical contacts",
             metric_code="CSDS-ACT", service_event="Community activity contact",
             service_definition="Clinical contacts — KPI-05", system_workflow_capture="CARE_* actions",
             source_system="PathwayOne", source_table="pathwayone_actions", source_field="CARE_ONGOING",
             source_grain="action", staging_table="stg_action",
             warehouse_fact_or_dimension="fact_mh_referral_episode", fact_grain="episode",
             transformation_rule="Sum clinical_contact_count", inclusion_rule="Exclude admin",
             exclusion_rule="ADMIN_CANCEL", validation_check="VAL-05",
             reconciliation_check="MHS29 alignment", reporting_use="Mandatory CSDS-like",
             local_performance_use="Productivity", sign_off_owner="CSDS owner",
             sign_off_status="Pending", management_decision_supported="Mandatory submission",
             migration_risk="High", reporting_confidence="Medium"),
        _row(report_name=csds, report_section="Activity return", report_field="Admin contacts excluded",
             metric_code="CSDS-ADM-EX", service_event="Admin action recorded as contact",
             service_definition="ADMIN_CANCEL and non-clinical actions excluded",
             system_workflow_capture="ActionType filter",
             source_system="PathwayOne", source_table="pathwayone_actions",
             source_field="ADMIN_CANCEL", source_grain="action",
             staging_table="stg_action", warehouse_fact_or_dimension="fact_mh_referral_episode",
             fact_grain="episode", transformation_rule="Exclude from clinical_contact_count",
             inclusion_rule="Clinical only", exclusion_rule="ADMIN_CANCEL",
             validation_check="VAL-05; DRH-PAT-003201", reconciliation_check="MHS29 alignment",
             reporting_use="Mandatory CSDS-like", local_performance_use="Productivity accuracy",
             sign_off_owner="CSDS owner", sign_off_status="Pending",
             management_decision_supported="Mandatory submission quality", migration_risk="High",
             reporting_confidence="Medium"),
    ])

    # Source-first rows: legendary and pathwayone → affected reports
    for src_table, src_field, reports in [
        ("legendary_cmht_cases", "ReferralDate", f"{mh}; {brief}; {local}"),
        ("legendary_cmht_cases", "PathwayStatus Rejected", f"{mh}; {local}"),
        ("pathwayone_actions", "ACCESS_ACCEPTED", f"{mh}; {local}; {brief}"),
        ("pathwayone_actions", "ACCESS_REJECTED", f"{mh}; {wait}"),
        ("pathwayone_actions", "CARE_FIRST_CONTACT", f"{wait}; {mh}"),
        ("pathwayone_actions", "ADMIN_CANCEL", f"{csds}; {mh}"),
        ("pathwayone_actions", "TeamCode INVALID_TEAM", f"{local}; {wait}; {conf}"),
        ("fact_mh_referral_episode", "mhsds_like_inclusion_flag", f"{mh}"),
        ("fact_mh_referral_episode", "local_reporting_inclusion_flag", f"{local}; {wait}"),
    ]:
        rows.append(_row(
            report_name="Source impact analysis", report_section="Source dependency",
            report_field=f"{src_table}.{src_field}", metric_code="SRC",
            service_event="Source change impact analysis",
            service_definition="When this source field changes, these reports are affected",
            system_workflow_capture=src_field, source_system="Legendary Care or PathwayOne",
            source_table=src_table, source_field=src_field, source_grain="row",
            staging_table="stg_*", warehouse_fact_or_dimension="fact_mh_referral_episode",
            fact_grain="episode", transformation_rule="Lineage dependency",
            inclusion_rule="n/a", exclusion_rule="n/a", validation_check="Impact assessment",
            reconciliation_check="n/a", reporting_use=reports, local_performance_use=reports,
            sign_off_owner="BI lead", sign_off_status="Documented",
            management_decision_supported="Change impact assessment", migration_risk="High",
            reporting_confidence="Review"))

    return _finalize_map_rows(rows)


def build_submission_artifacts(episodes: list[dict]) -> dict[str, tuple[list[str], list[dict]]]:
    """Build MHSDS-like submission pack datasets."""
    mar = [e for e in episodes if e["reporting_month"] == "2026-03"]
    opt_c = sum(1 for e in mar if e["mhsds_like_inclusion_flag"] == "1" and e["derivation_rule"].startswith("OPT"))
    open_stock = sum(1 for e in episodes if e["episode_status"] in ("Open", "Waiting") and e["reporting_month"] <= "2026-03")
    contacts = sum(int(e["clinical_contact_count"]) for e in mar)
    mhs01 = sum(1 for e in episodes if e["episode_status"] in ("Open", "Waiting", "InTreatment") and e["mhsds_like_inclusion_flag"] == "1")
    fc14_num = sum(1 for e in mar if e.get("first_contact_wait_days") and int(e["first_contact_wait_days"] or 99) <= 14)
    fc14_den = len([e for e in mar if e["mhsds_like_inclusion_flag"] == "1"])

    submission_monthly = [{
        "provider_ods": TRUST_ODS, "reporting_month": "2026-03", "submission_status": "Draft — pending sign-off",
        "reporting_confidence": "Medium", "central_fact_table": "fact_mh_referral_episode",
        "source_systems": "Legendary Care + PathwayOne", "sign_off_owner": "Mandatory reporting owner",
        "sign_off_status": "Agreed pending workshop", "notes": "Illustrative MHSDS-like pack — not official return",
    }]

    fields = [
        {"metric_code": "MHS23", "metric_label": "Open referrals at end of reporting period",
         "value": str(open_stock), "definition_used": "Episode open/waiting at month end; mhsds_like_inclusion_flag=1",
         "source_fact": "fact_mh_referral_episode", "episode_basis": f"{open_stock} episodes in stock snapshot",
         "submission_status": "Draft", "confidence": "Medium"},
        {"metric_code": "MHS01", "metric_label": "People with open referral with services at month end",
         "value": str(mhs01), "definition_used": "Open referral in contact — Apr 2026 label analogue",
         "source_fact": "fact_mh_referral_episode", "episode_basis": f"{mhs01} distinct open episodes",
         "submission_status": "Draft", "confidence": "Medium"},
        {"metric_code": "MHS29", "metric_label": "Contacts in reporting period",
         "value": str(contacts), "definition_used": "Clinical contacts only — exclude admin",
         "source_fact": "fact_mh_referral_episode", "episode_basis": f"Sum clinical_contact_count Mar 2026",
         "submission_status": "Pending reconciliation", "confidence": "Medium"},
        {"metric_code": "DRH-REF-OPT-C", "metric_label": "Referrals received (agreed OPT-C)",
         "value": "134", "definition_used": "Hybrid OPT-C — submit after sign-off",
         "source_fact": "fact_mh_referral_episode", "episode_basis": "134 agreed (reconciliation_monthly)",
         "submission_status": "Agreed pending workshop", "confidence": "Low"},
        {"metric_code": "DRH-REF-DASH", "metric_label": "Referrals received (dashboard — do not submit)",
         "value": "154", "definition_used": "Legacy dashboard pipeline",
         "source_fact": "fact_referral (legacy)", "episode_basis": "154 — VAL-06 failed",
         "submission_status": "Not for submission", "confidence": "Low"},
        {"metric_code": "DRH-FC14", "metric_label": "First contact within 14 days (%)",
         "value": str(round(100 * fc14_num / fc14_den)) if fc14_den else "0",
         "definition_used": "Wait clock at referral received; denominator OPT-C",
         "source_fact": "fact_mh_referral_episode", "episode_basis": f"{fc14_num}/{fc14_den} episodes",
         "submission_status": "Draft", "confidence": "Medium"},
    ]

    validation = [
        {"check_id": "VAL-MH-01", "rule": "No duplicate referral episode in month",
         "result": "1 duplicate (DRH-PAT-005663)", "pass_fail": "Fail", "action": "Exclude in OPT-C"},
        {"check_id": "VAL-MH-02", "rule": "Team crosswalk complete for submitted episodes",
         "result": "1 INVALID_TEAM (DRH-PAT-000874)", "pass_fail": "Fail", "action": "Fix before team reports"},
        {"check_id": "VAL-MH-03", "rule": "Submission referrals match agreed OPT-C",
         "result": "Dashboard 154 vs agreed 134", "pass_fail": "Fail", "action": "Submit 134 only"},
        {"check_id": "VAL-MH-04", "rule": "MHS29 aligns with clinical action count",
         "result": f"{contacts} from fact vs pathwayone_actions", "pass_fail": "Pass", "action": "Monitor admin"},
        {"check_id": "VAL-MH-05", "rule": "Rejected referral rules documented",
         "result": "DRH-PAT-002896 excluded", "pass_fail": "Review", "action": "Clinical sign-off"},
    ]

    reconciliation = [
        {"definition_id": "OPT-A", "label": "Old case ReferralDate", "mar2026_count": "151", "use_for_submission": "No"},
        {"definition_id": "OPT-B", "label": "ACCESS_ACCEPTED default", "mar2026_count": "168", "use_for_submission": "No"},
        {"definition_id": "OPT-C", "label": "Agreed hybrid", "mar2026_count": "134", "use_for_submission": "Yes — after sign-off"},
        {"definition_id": "DASH", "label": "Dashboard displayed", "mar2026_count": "154", "use_for_submission": "No — withhold from Board"},
    ]

    decisions = [
        {"decision_id": "DEC-01", "topic": "Referral received definition", "options_tested": "OPT-A/B/C/DASH",
         "agreed_rule": "OPT-C hybrid", "sign_off": "Directorate workshop 2026-03-25", "owner": "Performance lead"},
        {"decision_id": "DEC-02", "topic": "Rejected referral counts as received?",
         "options_tested": "Include all / exclude all / reason-based", "agreed_rule": "Exclude unless CLINICAL_TRIAGE",
         "sign_off": "Clinical lead", "owner": "Clinical lead"},
        {"decision_id": "DEC-03", "topic": "First contact wait clock start",
         "options_tested": "Referral received / accepted / pathway start",
         "agreed_rule": "Referral received (KPI-04)", "sign_off": "Agreed", "owner": "Clinical lead"},
        {"decision_id": "DEC-04", "topic": "National vs local team inclusion",
         "options_tested": "PC Liaison national flag", "agreed_rule": "Local yes; national no for AA-PCL-01",
         "sign_off": "Mandatory + performance", "owner": "Mandatory reporting owner"},
    ]

    local_metrics = [
        {"metric_code": "DRH-DEM-WK", "metric_label": "Weekly demand index W21", "value": "218",
         "source_fact": "fact_mh_referral_episode + demand_capacity_weekly", "shared_with_mandatory": "Same fact; different roll-up"},
        {"metric_code": "DRH-BACKLOG", "metric_label": "Backlog stock W21", "value": "264",
         "source_fact": "fact_mh_referral_episode", "shared_with_mandatory": "Local waiting stock — not MHS23"},
        {"metric_code": "DRH-REF-WK", "metric_label": "Referrals in week W21 (OPT-C)", "value": "48",
         "source_fact": "fact_mh_referral_episode", "shared_with_mandatory": "Same OPT-C definition as DRH-REF-OPT-C"},
        {"metric_code": "DRH-WAIT-MED", "metric_label": "Median wait to first contact (days)", "value": "12",
         "source_fact": "fact_mh_referral_episode", "shared_with_mandatory": "Clock-start rule shared with DRH-FC14"},
    ]

    return {
        "fact_mh_referral_episode.csv": (FACT_COLS, episodes),
        "mhsds_like_submission_monthly.csv": (
            ["provider_ods", "reporting_month", "submission_status", "reporting_confidence",
             "central_fact_table", "source_systems", "sign_off_owner", "sign_off_status", "notes"],
            submission_monthly),
        "mhsds_like_submission_fields.csv": (
            ["metric_code", "metric_label", "value", "definition_used", "source_fact",
             "episode_basis", "submission_status", "confidence"],
            fields),
        "mhsds_like_validation_checks.csv": (
            ["check_id", "rule", "result", "pass_fail", "action"], validation),
        "mhsds_like_reconciliation_summary.csv": (
            ["definition_id", "label", "mar2026_count", "use_for_submission"], reconciliation),
        "definition_decision_log.csv": (
            ["decision_id", "topic", "options_tested", "agreed_rule", "sign_off", "owner"], decisions),
        "local_demand_access_pack_metrics.csv": (
            ["metric_code", "metric_label", "value", "source_fact", "shared_with_mandatory"], local_metrics),
    }
