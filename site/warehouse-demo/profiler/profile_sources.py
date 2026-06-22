#!/usr/bin/env python3
"""Factual source profiler for warehouse-demo. Does not read human_reviewer_answer_key.md."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
WAREHOUSE_DEMO = SCRIPT_DIR.parent
SOURCE_DATA = WAREHOUSE_DEMO / "source-data"
PROFILE_OUTPUT = WAREHOUSE_DEMO / "profile-output"

CSV_FILES = {
    "carecall_contacts.csv": {
        "pk": "ContactId",
        "fks": ["CareCaseCaseId", "LegendaryCareReferralId", "PatientPseudoId"],
        "date_col": "ContactDate",
    },
    "carecall_call_events.csv": {"pk": "EventId", "fks": ["ContactId"], "date_col": "EventDateTime"},
    "carecase_cases.csv": {
        "pk": "CaseId",
        "fks": ["SourceContactId", "PatientPseudoId"],
        "date_col": "OpenedDateTime",
    },
    "carecase_case_events.csv": {"pk": "CaseEventId", "fks": ["CaseId"], "date_col": "EventDateTime"},
    "carecase_clinician_contacts.csv": {
        "pk": "ClinicianContactId",
        "fks": ["CaseId"],
        "date_col": "ContactDateTime",
    },
    "legendary_care_patients.csv": {"pk": "PatientPseudoId", "fks": [], "date_col": "DateOfBirth"},
    "legendary_care_referrals.csv": {
        "pk": "ReferralId",
        "fks": ["PatientPseudoId", "SourceCareCallContactId"],
        "date_col": "ReferralDateTime",
    },
    "legendary_care_appointments.csv": {
        "pk": "AppointmentId",
        "fks": ["PatientPseudoId", "ReferralId"],
        "date_col": "ScheduledDateTime",
    },
    "legendary_care_encounters.csv": {
        "pk": "EncounterId",
        "fks": ["PatientPseudoId", "ReferralId", "SourceCareCallContactId"],
        "date_col": "EncounterDateTime",
    },
    "rosterflow_staff.csv": {"pk": "SyntheticStaffId", "fks": [], "date_col": "ActiveFrom"},
    "rosterflow_shifts.csv": {"pk": "ShiftId", "fks": ["SyntheticStaffId"], "date_col": "ShiftDate"},
    "rosterflow_absence.csv": {"pk": "AbsenceId", "fks": ["SyntheticStaffId"], "date_col": "StartDate"},
    "ledgerwise_cost_centres.csv": {"pk": "CostCentreCode", "fks": [], "date_col": None},
    "ledgerwise_ledger.csv": {
        "pk": "LedgerLineId",
        "fks": ["CostCentreCode"],
        "date_col": "PostingDate",
    },
}


def load_manifest() -> pd.DataFrame:
    return pd.read_csv(PROFILE_OUTPUT / "source_manifest.csv")


def build_file_grain_register(frames: dict[str, pd.DataFrame]) -> pd.DataFrame:
    manifest = load_manifest()
    rows = []
    for _, m in manifest.iterrows():
        fn = m["FileName"]
        if fn not in frames:
            continue
        df = frames[fn]
        meta = CSV_FILES.get(fn, {})
        pk = meta.get("pk", "")
        null_pk = df[pk].isna().mean() if pk and pk in df.columns else None
        rows.append(
            {
                "FileName": fn,
                "RowCount": len(df),
                "ManifestRowCount": m["RowCount"],
                "RowCountMatch": len(df) == m["RowCount"],
                "PrimaryKeyCandidate": pk,
                "PrimaryKeyNullRate": round(null_pk, 4) if null_pk is not None else "",
                "ForeignKeyCandidates": "|".join(meta.get("fks", [])),
                "DateColumn": meta.get("date_col") or m.get("PrimaryDateColumn", ""),
                "DuplicatePKCount": df[pk].duplicated().sum() if pk and pk in df.columns else "",
            }
        )
    return pd.DataFrame(rows)


def build_volume_trends(frames: dict[str, pd.DataFrame]) -> pd.DataFrame:
    cc = frames["carecall_contacts.csv"].copy()
    cc["Month"] = pd.to_datetime(cc["ContactDate"]).dt.to_period("M").astype(str)
    contacts = cc.groupby("Month").size().rename("ContactCount")
    iucs = cc[cc["ContactType"] == "IUCS"].groupby("Month").size().rename("IUCSCount")

    cases = frames["carecase_cases.csv"].copy()
    cases["Month"] = pd.to_datetime(cases["OpenedDateTime"]).dt.to_period("M").astype(str)
    case_open = cases.groupby("Month").size().rename("CaseOpenedCount")
    case_no_src = (
        cases[cases["SourceContactId"].isna() | (cases["SourceContactId"] == "")]
        .groupby("Month")
        .size()
        .rename("CasesWithoutSourceContactId")
    )

    shifts = frames["rosterflow_shifts.csv"].copy()
    shifts["Month"] = pd.to_datetime(shifts["ShiftDate"]).dt.to_period("M").astype(str)
    urg_shifts = (
        shifts[shifts["UrgentCareFlag"] == "Y"].groupby("Month").size().rename("UrgentCareShifts")
    )
    bank_shifts = (
        shifts[(shifts["UrgentCareFlag"] == "Y") & (shifts["IsBankShift"] == "Y")]
        .groupby("Month")
        .size()
        .rename("UrgentCareBankShifts")
    )

    ledger = frames["ledgerwise_ledger.csv"]
    agency = ledger[
        (ledger["CostCentreCode"] == "CC-URG-401")
        & (ledger["AccountCode"].astype(str) == "6100")
    ].copy()
    agency_spend = agency.groupby("FinancialMonth")["AmountGBP"].sum().rename("AgencyNursingSpendGBP")

    vol = pd.concat([contacts, iucs, case_open, case_no_src, urg_shifts, bank_shifts], axis=1)
    vol = vol.fillna(0).reset_index().rename(columns={"index": "Month"})
    agency_df = agency_spend.reset_index().rename(columns={"FinancialMonth": "Month"})
    vol = vol.merge(agency_df, on="Month", how="left")
    vol["AgencyNursingSpendGBP"] = vol["AgencyNursingSpendGBP"].fillna(0)
    vol = vol.sort_values("Month")
    for col in ["ContactCount", "IUCSCount", "CaseOpenedCount"]:
        if col in vol.columns:
            vol[f"{col}MoM_Pct"] = vol[col].pct_change().round(4) * 100
    return vol


def build_linkage_analysis(frames: dict[str, pd.DataFrame]) -> pd.DataFrame:
    cc = frames["carecall_contacts.csv"]
    cases = frames["carecase_cases.csv"]
    refs = frames["legendary_care_referrals.csv"]
    case_ids = set(cases["CaseId"])
    ref_ids = set(refs["ReferralId"])
    contact_ids = set(cc["ContactId"])

    rows = []
    for scenario, grp in cc.groupby("LinkageScenario"):
        direct_case_match = grp["CareCaseCaseId"].fillna("").isin(case_ids).sum()
        direct_ref_match = grp["LegendaryCareReferralId"].fillna("").isin(ref_ids).sum()
        rows.append(
            {
                "LinkageScenario": scenario,
                "ContactCount": len(grp),
                "PctOfAllContacts": round(100 * len(grp) / len(cc), 2),
                "CareCaseCaseIdPopulated": (grp["CareCaseCaseId"].fillna("") != "").sum(),
                "CareCaseCaseIdValidInCases": int(direct_case_match),
                "LegendaryReferralIdPopulated": (grp["LegendaryCareReferralId"].fillna("") != "").sum(),
                "AmbiguousRows": (grp["AmbiguousMatchIds"].fillna("") != "").sum(),
                "CallbackRows": (grp["CallbackOfContactId"].fillna("") != "").sum(),
            }
        )

    iucs = cc[cc["ContactType"] == "IUCS"].copy()
    iucs["Month"] = pd.to_datetime(iucs["ContactDate"]).dt.to_period("M").astype(str)
    for month, grp in iucs.groupby("Month"):
        rows.append(
            {
                "LinkageScenario": f"IUCS_{month}",
                "ContactCount": len(grp),
                "PctOfAllContacts": round(100 * len(grp) / len(cc), 2),
                "CareCaseCaseIdPopulated": (grp["CareCaseCaseId"] != "").sum(),
                "CareCaseCaseIdValidInCases": grp["CareCaseCaseId"].isin(case_ids).sum(),
                "LegendaryReferralIdPopulated": (grp["LegendaryCareReferralId"] != "").sum(),
                "AmbiguousRows": (grp["AmbiguousMatchIds"] != "").sum(),
                "CallbackRows": (grp["CallbackOfContactId"] != "").sum(),
            }
        )

    # Inferred match candidates: same patient, case open within 24h, no direct id
    inferred = cc[(cc["LinkageScenario"] == "INFERRED_MATCH")]
    inferred_count = len(inferred)
    rows.append(
        {
            "LinkageScenario": "INFERRED_MATCH_SUMMARY",
            "ContactCount": inferred_count,
            "PctOfAllContacts": round(100 * inferred_count / len(cc), 2),
            "CareCaseCaseIdPopulated": 0,
            "CareCaseCaseIdValidInCases": 0,
            "LegendaryReferralIdPopulated": 0,
            "AmbiguousRows": 0,
            "CallbackRows": 0,
        }
    )

    # Orphan FK checks
    orphan_case_on_contact = cc[
        (cc["CareCaseCaseId"] != "") & (~cc["CareCaseCaseId"].isin(case_ids))
    ]
    rows.append(
        {
            "LinkageScenario": "ORPHAN_CareCaseCaseId_on_contact",
            "ContactCount": len(orphan_case_on_contact),
            "PctOfAllContacts": round(100 * len(orphan_case_on_contact) / len(cc), 2),
            "CareCaseCaseIdPopulated": len(orphan_case_on_contact),
            "CareCaseCaseIdValidInCases": 0,
            "LegendaryReferralIdPopulated": 0,
            "AmbiguousRows": 0,
            "CallbackRows": 0,
        }
    )

    orphan_src = cases[
        (cases["SourceContactId"] != "") & (~cases["SourceContactId"].isin(contact_ids))
    ]
    rows.append(
        {
            "LinkageScenario": "ORPHAN_SourceContactId_on_case",
            "ContactCount": len(orphan_src),
            "PctOfAllContacts": "",
            "CareCaseCaseIdPopulated": "",
            "CareCaseCaseIdValidInCases": "",
            "LegendaryReferralIdPopulated": "",
            "AmbiguousRows": "",
            "CallbackRows": "",
        }
    )

    return pd.DataFrame(rows)


def build_dq_register(frames: dict[str, pd.DataFrame]) -> pd.DataFrame:
    cc = frames["carecall_contacts.csv"].copy()
    cases = frames["carecase_cases.csv"].copy()
    mapping = frames["localops_user_id_mapping.xlsx"]
    change_log = frames["localops_extract_change_log.xlsx"]

    cc["ContactDateDt"] = pd.to_datetime(cc["ContactDate"])
    cc["CreatedDateDt"] = pd.to_datetime(cc["CreatedDateTime"])
    dec_iucs = cc[
        (cc["ContactType"] == "IUCS")
        & (cc["ContactDateDt"].dt.year == 2025)
        & (cc["ContactDateDt"].dt.month == 12)
    ]
    date_mismatch = dec_iucs[dec_iucs["ContactDateDt"].dt.date < dec_iucs["CreatedDateDt"].dt.date]

    cases["OpenedMonth"] = pd.to_datetime(cases["OpenedDateTime"]).dt.to_period("M").astype(str)
    case_ids = set(cases["CaseId"])
    mar_cases = cases[cases["OpenedMonth"] == "2026-03"]
    mar_no_src = mar_cases[mar_cases["SourceContactId"].isna() | (mar_cases["SourceContactId"] == "")]

    feb_iucs = cc[
        (cc["ContactType"] == "IUCS")
        & (pd.to_datetime(cc["ContactDate"]).dt.to_period("M").astype(str) == "2026-02")
    ]
    jan_iucs = cc[
        (cc["ContactType"] == "IUCS")
        & (pd.to_datetime(cc["ContactDate"]).dt.to_period("M").astype(str) == "2026-01")
    ]
    baseline_iucs = cc[
        (cc["ContactType"] == "IUCS")
        & (pd.to_datetime(cc["ContactDate"]).dt.to_period("M").astype(str).isin(
            ["2025-09", "2025-10", "2025-11"]
        ))
    ]

    expired_mapping = mapping[
        (mapping["ValidToDate"] != "") & (pd.to_datetime(mapping["ValidToDate"]) < pd.Timestamp("2026-01-01"))
    ]

    issues = [
        {
            "IssueId": "DQ001",
            "Severity": "High",
            "SystemName": "CareCall",
            "IssueDescription": "ContactDate earlier than CreatedDateTime calendar date",
            "EvidenceCount": len(date_mismatch),
            "EvidenceDetail": "Dec 2025 IUCS contacts; see also localops_extract_change_log CareCall 2025-12-04",
            "RecommendedStagingCheck": "Flag date_boundary_mismatch; compare ContactDate vs CreatedDateTime",
        },
        {
            "IssueId": "DQ002",
            "Severity": "High",
            "SystemName": "CareCase",
            "IssueDescription": "Cases opened without SourceContactId",
            "EvidenceCount": len(mar_no_src),
            "EvidenceDetail": f"2026-03 total cases={len(mar_cases)}; without source contact={len(mar_no_src)}",
            "RecommendedStagingCheck": "Join to CareCall; review ExtractInclusionFlag and CaseStatus",
        },
        {
            "IssueId": "DQ003",
            "Severity": "Medium",
            "SystemName": "CareCall",
            "IssueDescription": "CareCaseCaseId on contact not found in carecase_cases",
            "EvidenceCount": int(
                (
                    (cc["CareCaseCaseId"].fillna("") != "")
                    & (~cc["CareCaseCaseId"].isin(case_ids))
                ).sum()
            ),
            "EvidenceDetail": "Orphan CareCaseCaseId values on carecall_contacts",
            "RecommendedStagingCheck": "Referential integrity test contact to case",
        },
        {
            "IssueId": "DQ004",
            "Severity": "Medium",
            "SystemName": "LocalOps",
            "IssueDescription": "User mappings with ValidToDate in the past",
            "EvidenceCount": len(expired_mapping),
            "EvidenceDetail": "localops_user_id_mapping expired ValidToDate rows",
            "RecommendedStagingCheck": "Apply mapping confidence tier; do not hard-fail joins",
        },
        {
            "IssueId": "DQ005",
            "Severity": "Low",
            "SystemName": "CareCall",
            "IssueDescription": "AmbiguousMatchIds populated",
            "EvidenceCount": int((cc["AmbiguousMatchIds"].fillna("") != "").sum()),
            "EvidenceDetail": "Multiple candidate referral IDs pipe-delimited",
            "RecommendedStagingCheck": "Route to bridge table; do not force single match",
        },
        {
            "IssueId": "DQ006",
            "Severity": "Info",
            "SystemName": "LocalOps",
            "IssueDescription": "Extract change log entries in reporting period",
            "EvidenceCount": len(change_log),
            "EvidenceDetail": "|".join(change_log["SystemName"].astype(str).tolist()),
            "RecommendedStagingCheck": "Cross-reference volume shifts with ChangeDate and SystemName",
        },
        {
            "IssueId": "DQ007",
            "Severity": "Info",
            "SystemName": "CareCall",
            "IssueDescription": "IUCS volume Jan 2026 vs Sep-Nov 2025 baseline",
            "EvidenceCount": len(jan_iucs),
            "EvidenceDetail": f"Jan={len(jan_iucs)} baseline_avg={len(baseline_iucs)/3:.0f}",
            "RecommendedStagingCheck": "Compare with RosterFlow shifts and LedgerWise agency spend same months",
        },
        {
            "IssueId": "DQ008",
            "Severity": "Info",
            "SystemName": "CareCall",
            "IssueDescription": "IUCS volume Feb 2026 vs Sep-Nov 2025 baseline",
            "EvidenceCount": len(feb_iucs),
            "EvidenceDetail": f"Feb={len(feb_iucs)} baseline_avg={len(baseline_iucs)/3:.0f}",
            "RecommendedStagingCheck": "Compare with RosterFlow bank shifts and validation notes",
        },
    ]
    return pd.DataFrame(issues)


def load_all_frames() -> dict[str, pd.DataFrame]:
    frames: dict[str, pd.DataFrame] = {}
    for fn in CSV_FILES:
        frames[fn] = pd.read_csv(SOURCE_DATA / fn)
    for fn in [
        "localops_user_id_mapping.xlsx",
        "localops_team_mapping.xlsx",
        "localops_validation_notes.xlsx",
        "localops_waiting_list_adjustments.xlsx",
        "localops_extract_change_log.xlsx",
    ]:
        frames[fn] = pd.read_excel(SOURCE_DATA / fn)
    return frames


def main() -> None:
    PROFILE_OUTPUT.mkdir(parents=True, exist_ok=True)
    frames = load_all_frames()

    grain = build_file_grain_register(frames)
    volume = build_volume_trends(frames)
    linkage = build_linkage_analysis(frames)
    dq = build_dq_register(frames)

    grain.to_csv(PROFILE_OUTPUT / "file_grain_register.csv", index=False)
    volume.to_csv(PROFILE_OUTPUT / "volume_trends.csv", index=False)
    linkage.to_csv(PROFILE_OUTPUT / "linkage_analysis.csv", index=False)
    dq.to_csv(PROFILE_OUTPUT / "dq_register.csv", index=False)

    print(f"Profile outputs written to {PROFILE_OUTPUT}")
    print(f"  file_grain_register: {len(grain)} rows")
    print(f"  volume_trends: {len(volume)} rows")
    print(f"  linkage_analysis: {len(linkage)} rows")
    print(f"  dq_register: {len(dq)} rows")


if __name__ == "__main__":
    main()
