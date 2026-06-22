#!/usr/bin/env python3
"""Build provider-month mart measures from source data (demo logic)."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

WAREHOUSE_DEMO = Path(__file__).resolve().parents[1]
SOURCE_DATA = WAREHOUSE_DEMO / "source-data"
PROFILE_OUTPUT = WAREHOUSE_DEMO / "profile-output"
MARTS_DIR = WAREHOUSE_DEMO / "marts"

PROVIDER = "DRH"


def main() -> None:
    MARTS_DIR.mkdir(parents=True, exist_ok=True)
    vol = pd.read_csv(PROFILE_OUTPUT / "volume_trends.csv")
    vol = vol[vol["Month"].str.match(r"^\d{4}-\d{2}$")]

    cases = pd.read_csv(SOURCE_DATA / "carecase_cases.csv", parse_dates=["OpenedDateTime"])
    cases["Month"] = cases["OpenedDateTime"].dt.to_period("M").astype(str)
    ops = (
        cases[
            (cases["ExtractInclusionFlag"] != 1)
            & (cases["SourceContactId"].fillna("") != "")
        ]
        .groupby("Month")
        .size()
        .rename("OperationalCaseOpenedCount")
    )

    refs = pd.read_csv(SOURCE_DATA / "legendary_care_referrals.csv", parse_dates=["ReferralDateTime"])
    refs["Month"] = refs["ReferralDateTime"].dt.to_period("M").astype(str)
    open_refs = refs[refs["Status"].isin(["Open", "Active"])].groupby("Month").size().rename("OpenReferralStockProxy")

    cc = pd.read_csv(SOURCE_DATA / "carecall_contacts.csv", parse_dates=["ContactDateTime", "CreatedDateTime"])
    cc_iucs = cc[cc["ContactType"] == "IUCS"].copy()
    cc_iucs["ContactMonth"] = cc_iucs["ContactDateTime"].dt.to_period("M").astype(str)
    cc_iucs["CaseMonth"] = cc_iucs["ContactDateTime"].dt.to_period("M").astype(str)

    clinician = pd.read_csv(SOURCE_DATA / "carecase_clinician_contacts.csv", parse_dates=["ContactDateTime"])
    cases_dt = pd.read_csv(SOURCE_DATA / "carecase_cases.csv", parse_dates=["OpenedDateTime"])
    merged = cases_dt.merge(
        clinician.groupby("CaseId")["ContactDateTime"].min().reset_index(),
        on="CaseId",
        how="left",
    )
    merged["days_to_first"] = (merged["ContactDateTime"] - merged["OpenedDateTime"]).dt.days
    merged["Month"] = merged["OpenedDateTime"].dt.to_period("M").astype(str)
    median_wait = merged.groupby("Month")["days_to_first"].median().rename("MedianDaysToFirstClinicianContact")

    out = vol[
        [
            "Month",
            "IUCSCount",
            "CaseOpenedCount",
            "AgencyNursingSpendGBP",
            "UrgentCareBankShifts",
        ]
    ].copy()
    out = out.rename(columns={"Month": "ReportingMonth", "IUCSCount": "IUCSContactCount"})
    out["ProviderCode"] = PROVIDER
    out = out.merge(ops.reset_index(), left_on="ReportingMonth", right_on="Month", how="left")
    out = out.drop(columns=["Month"], errors="ignore")
    out = out.merge(open_refs.reset_index(), left_on="ReportingMonth", right_on="Month", how="left")
    out = out.drop(columns=["Month"], errors="ignore")
    out = out.merge(median_wait.reset_index(), left_on="ReportingMonth", right_on="Month", how="left")
    out = out.drop(columns=["Month"], errors="ignore")
    out["OpenReferralStockProxy"] = out["OpenReferralStockProxy"].fillna(0).astype(int)
    out["OperationalCaseOpenedCount"] = out["OperationalCaseOpenedCount"].fillna(0).astype(int)
    out["_synthetic"] = True
    out["_demo_source"] = "warehouse_demo_mart_builder"

    cols = [
        "ProviderCode",
        "ReportingMonth",
        "IUCSContactCount",
        "CaseOpenedCount",
        "OperationalCaseOpenedCount",
        "OpenReferralStockProxy",
        "AgencyNursingSpendGBP",
        "UrgentCareBankShifts",
        "MedianDaysToFirstClinicianContact",
        "_synthetic",
        "_demo_source",
    ]
    out[cols].to_csv(MARTS_DIR / "demo_provider_month_measures.csv", index=False)
    print(f"Wrote {len(out)} rows to {MARTS_DIR / 'demo_provider_month_measures.csv'}")


if __name__ == "__main__":
    main()
