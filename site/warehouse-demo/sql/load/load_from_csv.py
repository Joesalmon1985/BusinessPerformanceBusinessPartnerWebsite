#!/usr/bin/env python3
"""Optional demo loader — not production ETL. Dry-run by default."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd

WAREHOUSE_DEMO = Path(__file__).resolve().parents[2]
SOURCE_DATA = WAREHOUSE_DEMO / "source-data"

LOAD_MAP = {
    "carecall_contacts.csv": ("raw.CareCallContact", 25942),
    "carecase_cases.csv": ("raw.CareCase", 3631),
    "legendary_care_referrals.csv": ("raw.LegendaryReferral", 7928),
    "rosterflow_shifts.csv": ("raw.RosterFlowShift", 40926),
    "ledgerwise_ledger.csv": ("raw.LedgerPosting", 7360),
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Demo CSV loader (dry-run default)")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--execute", action="store_true", help="Attempt SQL insert (requires connection)")
    args = parser.parse_args()
    dry_run = not args.execute

    print("Demo Rivers DWH load plan")
    print("=" * 50)
    for csv_name, (table, expected) in LOAD_MAP.items():
        path = SOURCE_DATA / csv_name
        df = pd.read_csv(path)
        actual = len(df)
        status = "OK" if actual == expected else f"MISMATCH (expected {expected})"
        print(f"{table}: {actual} rows from {csv_name} — {status}")
        if not dry_run:
            print("  [execute] SQL insert not implemented in demo — use BULK INSERT templates")

    if dry_run:
        print("\nDry-run complete. See sql/DEPLOYMENT_NOTES.md")


if __name__ == "__main__":
    main()
