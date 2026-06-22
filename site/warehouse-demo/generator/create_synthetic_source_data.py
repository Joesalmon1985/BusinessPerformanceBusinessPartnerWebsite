#!/usr/bin/env python3
"""
create_synthetic_source_data.py

Generates fictional multi-system healthcare source extracts for the
warehouse-demo worked example. Demonstration only — no real patient or staff data.

Re-run is idempotent: wipes and regenerates source-data/ and profile-output/.
"""

from __future__ import annotations

import calendar
import hashlib
import random
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

RANDOM_SEED = 42
TRUST_NAME = "Demo Rivers Health NHS Foundation Trust"
TRUST_ODS = "DRH"
GENERATED_AT: str | None = None  # live timestamp; set ISO string for fixed demo runs

MONTH_SPECS: list[tuple[int, int]] = [
    (2025, 9),
    (2025, 10),
    (2025, 11),
    (2025, 12),
    (2026, 1),
    (2026, 2),
    (2026, 3),
    (2026, 4),
    (2026, 5),
]

BASELINE_CONTACTS_PER_MONTH = 2800
STAFF_COUNT = 145
PATIENT_POOL_SIZE = 6500

SCRIPT_DIR = Path(__file__).resolve().parent
SOURCE_DATA_DIR = SCRIPT_DIR / ".." / "source-data"
PROFILE_OUTPUT_DIR = SCRIPT_DIR / ".." / "profile-output"

FIRST_NAMES = [
    "Alex", "Blake", "Casey", "Drew", "Ellis", "Finley", "Gray", "Harper",
    "Indigo", "Jules", "Kai", "Logan", "Morgan", "Noel", "Oakley", "Parker",
    "Quinn", "Reese", "Sage", "Taylor", "Uma", "Vale", "Winter", "Xen",
    "Yael", "Zephyr", "Avery", "Bailey", "Cameron", "Dakota",
]
LAST_NAMES = [
    "Ashford", "Briar", "Caldwell", "Denholm", "Ellerby", "Fairweather",
    "Glenwood", "Hartley", "Iverson", "Jardine", "Kestrel", "Langford",
    "Merrick", "Northcott", "Oakden", "Pemberton", "Quillan", "Redwood",
    "Sterling", "Thornley", "Underhill", "Vernon", "Whitmore", "Yardley",
]

CONTACT_TYPE_WEIGHTS = [
    ("IUCS", 0.45),
    ("MentalHealth", 0.20),
    ("Dental", 0.08),
    ("Palliative", 0.05),
    ("Admin", 0.07),
    ("Abandoned", 0.06),
    ("Transfer", 0.05),
    ("Signpost", 0.04),
]

LINKAGE_WEIGHTS_IUCS = [
    ("DIRECT_CARECASE", 0.38),
    ("DIRECT_LEGENDARY", 0.14),
    ("INFERRED_MATCH", 0.11),
    ("NO_CASE", 0.22),
    ("AMBIGUOUS", 0.08),
    ("CALLBACK_DUPLICATE", 0.07),
]

TEAM_DEFS = [
    ("IUCS-HUB", "Urgent Care Hub", "CC-URG-401", "IUCS Hub"),
    ("IUCS-CTR", "Urgent Care Centre", "CC-URG-401", "Urgent Care Centre"),
    ("MH-CRHT", "Crisis Resolution", "CC-MH-210", "CRHT East"),
    ("MH-ACCESS", "MH Access Team", "CC-MH-210", "MH Access"),
    ("DENT-UC", "Dental Urgent Care", "CC-DEN-115", "Dental UC"),
    ("PAL-HOME", "Palliative Home", "CC-PAL-330", "Palliative"),
]

COUNTER: dict[str, int] = {}


def reset_counters() -> None:
    COUNTER.clear()


def next_id(prefix: str, width: int = 6) -> str:
    key = prefix
    COUNTER[key] = COUNTER.get(key, 0) + 1
    return f"{prefix}{COUNTER[key]:0{width}d}"


def month_key(year: int, month: int) -> str:
    return f"{year:04d}-{month:02d}"


def month_start(year: int, month: int) -> date:
    return date(year, month, 1)


def month_end(year: int, month: int) -> date:
    last = calendar.monthrange(year, month)[1]
    return date(year, month, last)


def rand_dt(rng: random.Random, year: int, month: int) -> datetime:
    start = month_start(year, month)
    end = month_end(year, month)
    days = (end - start).days + 1
    d = start + timedelta(days=rng.randint(0, days - 1))
    return datetime(d.year, d.month, d.day, rng.randint(8, 20), rng.randint(0, 59))


def weighted_choice(rng: random.Random, pairs: list[tuple[str, float]]) -> str:
    items, weights = zip(*pairs)
    return rng.choices(items, weights=weights, k=1)[0]


def jitter_multiplier(rng: random.Random, low: float = 0.97, high: float = 1.05) -> float:
    return rng.uniform(low, high)


def df_to_markdown(df: pd.DataFrame) -> str:
    if df.empty:
        return "_No rows_"
    headers = "| " + " | ".join(df.columns) + " |"
    sep = "| " + " | ".join("---" for _ in df.columns) + " |"
    rows = ["| " + " | ".join(str(v) for v in row) + " |" for row in df.values]
    return "\n".join([headers, sep, *rows])


def month_contact_target(rng: random.Random, year: int, month: int) -> int:
    """Monthly CareCall volume with scripted Jan/Feb IUCS uplift and background jitter."""
    base = BASELINE_CONTACTS_PER_MONTH * jitter_multiplier(rng)
    if (year, month) == (2026, 1):
        base *= 1.08  # overall uplift; IUCS gets extra in generator
    elif (year, month) == (2026, 2):
        base *= 1.06
    return int(base)


def iucs_multiplier(year: int, month: int) -> float:
    if (year, month) == (2026, 1):
        return 1.14
    if (year, month) == (2026, 2):
        return 1.11
    return 1.0


@dataclass
class StaffMember:
    synthetic_staff_id: str
    display_name: str
    rosterflow_username: str
    carecall_username: str
    carecase_username: str
    legendary_username: str
    ledgerwise_username: str
    primary_team_code: str
    local_team_name: str
    rosterflow_team_name: str
    cost_centre_code: str
    active_from: date
    active_to: date | None
    mapping_confidence: str
    mapping_notes: str


@dataclass
class Patient:
    patient_pseudo_id: str
    nhs_number_demo: str
    legendary_ref: str
    dob: date
    sex: str
    postcode_sector: str
    gp_practice_code: str


@dataclass
class GeneratedData:
    staff: list[StaffMember] = field(default_factory=list)
    patients: list[Patient] = field(default_factory=list)
    carecall_contacts: list[dict[str, Any]] = field(default_factory=list)
    carecall_events: list[dict[str, Any]] = field(default_factory=list)
    carecase_cases: list[dict[str, Any]] = field(default_factory=list)
    carecase_case_events: list[dict[str, Any]] = field(default_factory=list)
    carecase_clinician_contacts: list[dict[str, Any]] = field(default_factory=list)
    legendary_patients: list[dict[str, Any]] = field(default_factory=list)
    legendary_referrals: list[dict[str, Any]] = field(default_factory=list)
    legendary_appointments: list[dict[str, Any]] = field(default_factory=list)
    legendary_encounters: list[dict[str, Any]] = field(default_factory=list)
    rosterflow_staff: list[dict[str, Any]] = field(default_factory=list)
    rosterflow_shifts: list[dict[str, Any]] = field(default_factory=list)
    rosterflow_absence: list[dict[str, Any]] = field(default_factory=list)
    ledgerwise_cost_centres: list[dict[str, Any]] = field(default_factory=list)
    ledgerwise_ledger: list[dict[str, Any]] = field(default_factory=list)
    localops_user_mapping: list[dict[str, Any]] = field(default_factory=list)
    localops_team_mapping: list[dict[str, Any]] = field(default_factory=list)
    localops_validation_notes: list[dict[str, Any]] = field(default_factory=list)
    localops_waiting_list_adjustments: list[dict[str, Any]] = field(default_factory=list)
    localops_extract_change_log: list[dict[str, Any]] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Dimension generators
# ---------------------------------------------------------------------------


def generate_staff(rng: random.Random) -> list[StaffMember]:
    staff: list[StaffMember] = []
    roles = ["Nurse", "HCA", "Coordinator", "Clinician", "Admin", "Manager"]
    for i in range(1, STAFF_COUNT + 1):
        sid = f"DRH-STF-{i:04d}"
        first = rng.choice(FIRST_NAMES)
        last = rng.choice(LAST_NAMES)
        display = f"{first} {last}"
        slug = f"{first[0].lower()}{last.lower()[:6]}"
        team = rng.choice(TEAM_DEFS)
        team_code, local_name, cc, rf_team = team
        confidence = "High"
        notes = ""
        valid_to: date | None = None
        if rng.random() < 0.08:
            valid_to = date(2025, 12, 31)
            notes = "Expired mapping retained for legacy extracts — verify before use"
        elif rng.random() < 0.05:
            confidence = "Low"
            notes = "Legacy AD account — check with ops"
        staff.append(
            StaffMember(
                synthetic_staff_id=sid,
                display_name=display,
                rosterflow_username=f"rf.{slug}{i % 100}",
                carecall_username=f"cc.{slug}{i % 100}",
                carecase_username=f"cs.{slug}{i % 100}",
                legendary_username=f"lc.{slug}{i % 100}",
                ledgerwise_username=f"lw.{slug}{i % 100}",
                primary_team_code=team_code,
                local_team_name=local_name if rng.random() > 0.15 else rf_team,
                rosterflow_team_name=rf_team if rng.random() > 0.12 else local_name,
                cost_centre_code=cc,
                active_from=date(2024, 4, 1),
                active_to=valid_to,
                mapping_confidence=confidence,
                mapping_notes=notes,
            )
        )
    return staff


def generate_patients(rng: random.Random) -> list[Patient]:
    patients: list[Patient] = []
    for i in range(1, PATIENT_POOL_SIZE + 1):
        dob = date(rng.randint(1945, 2015), rng.randint(1, 12), rng.randint(1, 28))
        patients.append(
            Patient(
                patient_pseudo_id=f"DRH-PAT-{i:06d}",
                nhs_number_demo=f"DEMO-NHS-{i:06d}",
                legendary_ref=f"LC-REF-{i:06d}",
                dob=dob,
                sex=rng.choice(["M", "F", "X"]),
                postcode_sector=f"DT{rng.randint(1,9)} {rng.randint(1,9)}{rng.choice('ABCDE')}",
                gp_practice_code=f"DEMO-GP-{rng.randint(100, 999)}",
            )
        )
    return patients


def build_cost_centres() -> list[dict[str, Any]]:
    rows = []
    seen = set()
    for team_code, name, cc, _ in TEAM_DEFS:
        if cc in seen:
            continue
        seen.add(cc)
        rows.append(
            {
                "CostCentreCode": cc,
                "CostCentreName": name,
                "Department": "Urgent & MH Services (Demo)",
                "BudgetHolderUsername": "lw.budget.demo",
                "ActiveFlag": "Y",
            }
        )
    rows.append(
        {
            "CostCentreCode": "CC-CORP-900",
            "CostCentreName": "Corporate Overheads (Demo)",
            "Department": "Finance",
            "BudgetHolderUsername": "lw.corp.demo",
            "ActiveFlag": "Y",
        }
    )
    return rows


# ---------------------------------------------------------------------------
# CareCall + CareCase + Legendary
# ---------------------------------------------------------------------------


def _create_case_from_contact(
    rng: random.Random,
    data: GeneratedData,
    row: dict[str, Any],
    staff: list[StaffMember],
) -> None:
    year, month = row["_year"], row["_month"]
    case_id = next_id("CS-", 7)
    opened = row["_dt"] + timedelta(hours=rng.randint(1, 6))
    closed = None
    status = rng.choice(["Open", "Closed", "PendingAdminClosure", "AwaitingSignoff"])
    if status in ("Closed",) or rng.random() < 0.85:
        status = "Closed"
        closed = opened + timedelta(days=rng.randint(1, 28))
    extract_flag = 0
    if status in ("PendingAdminClosure", "AwaitingSignoff"):
        extract_flag = 1 if (year, month) >= (2026, 3) else 0
        if (year, month) < (2026, 3):
            status = "Closed"
            closed = opened + timedelta(days=rng.randint(5, 20))

    clinician = rng.choice(staff)
    case = {
        "CaseId": case_id,
        "OpenedDateTime": opened.strftime("%Y-%m-%d %H:%M:%S"),
        "ClosedDateTime": closed.strftime("%Y-%m-%d %H:%M:%S") if closed else "",
        "CaseStatus": status,
        "PrimaryPathway": "IUCS",
        "SourceContactId": row["ContactId"],
        "PatientPseudoId": row["PatientPseudoId"],
        "Priority": rng.choice(["Routine", "Urgent", "Critical"]),
        "ClosureReason": rng.choice(["Resolved", "ReferredOn", "DNA", ""]),
        "ExtractInclusionFlag": extract_flag,
        "OpenedByUsername": clinician.carecase_username,
        "_year": year,
        "_month": month,
        "_opened": opened,
    }
    if row.get("_force_mismatch"):
        case["SourceContactId"] = ""
        row["CareCaseCaseId"] = next_id("CS-WRONG-", 5)
    else:
        row["CareCaseCaseId"] = case_id
    data.carecase_cases.append(case)
    _add_case_events(rng, data, case, clinician)


def generate_carecall_and_cases(
    rng: random.Random, data: GeneratedData
) -> None:
    staff = data.staff
    patients = data.patients
    timezone_shift_ids: list[str] = []
    contact_seq = 0
    cases_by_contact: dict[str, str] = {}
    referrals_by_contact: dict[str, str] = {}
    encounters_by_contact: dict[str, str] = {}
    pending_inferred: list[tuple[dict[str, Any], str]] = []
    pending_ambiguous: list[dict[str, Any]] = []
    callback_parents: list[dict[str, Any]] = []

    for year, month in MONTH_SPECS:
        mk = month_key(year, month)
        n_contacts = month_contact_target(rng, year, month)
        iucs_extra = iucs_multiplier(year, month)

        type_counts: dict[str, int] = {t: 0 for t, _ in CONTACT_TYPE_WEIGHTS}
        for _ in range(n_contacts):
            ctype = weighted_choice(rng, CONTACT_TYPE_WEIGHTS)
            if ctype == "IUCS" and iucs_extra > 1.0:
                if rng.random() < min(0.35, iucs_extra - 1.0):
                    ctype = weighted_choice(
                        rng,
                        [(t, w) for t, w in CONTACT_TYPE_WEIGHTS if t != "IUCS"],
                    )
                else:
                    type_counts["IUCS"] += 1
            else:
                type_counts[ctype] += 1

        # Rebalance to hit target IUCS uplift
        target_iucs = int(n_contacts * 0.45 * iucs_multiplier(year, month))
        current_iucs = type_counts.get("IUCS", 0)
        deficit = target_iucs - current_iucs
        if deficit > 0:
            for _ in range(min(deficit, n_contacts // 10)):
                type_counts["IUCS"] = type_counts.get("IUCS", 0) + 1
                # steal from admin/signpost
                for steal in ("Admin", "Signpost"):
                    if type_counts.get(steal, 0) > 0:
                        type_counts[steal] -= 1
                        break

        month_types: list[str] = []
        for t, c in type_counts.items():
            month_types.extend([t] * c)
        while len(month_types) < n_contacts:
            month_types.append(weighted_choice(rng, CONTACT_TYPE_WEIGHTS))
        while len(month_types) > n_contacts:
            month_types.pop()
        rng.shuffle(month_types)

        for ctype in month_types:
            contact_seq += 1
            contact_id = f"CC-{mk.replace('-', '')}-{contact_seq:05d}"
            patient = rng.choice(patients)
            agent = rng.choice(staff)
            dt = rand_dt(rng, year, month)
            contact_date = dt.date()
            created_dt = dt + timedelta(hours=rng.randint(0, 4))
            if created_dt.date() != contact_date:
                created_dt = datetime.combine(
                    contact_date, created_dt.time().replace(second=0, microsecond=0)
                )
            pathway = ctype
            outcome = rng.choice(
                ["Resolved", "Referred", "Signposted", "Transferred", "Abandoned", "CaseOpened"]
            )
            if ctype == "Abandoned":
                outcome = "Abandoned"
            queue = "IUCS-MAIN" if ctype == "IUCS" else f"{ctype[:3].upper()}-Q"

            linkage = "NO_CASE"
            carecase_id = ""
            referral_id = ""
            encounter_id = ""
            callback_of = ""
            ambiguous = ""
            if ctype == "IUCS":
                linkage = weighted_choice(rng, LINKAGE_WEIGHTS_IUCS)

            row = {
                "ContactId": contact_id,
                "ContactDateTime": dt.strftime("%Y-%m-%d %H:%M:%S"),
                "ContactDate": contact_date.isoformat(),
                "ContactType": ctype,
                "Pathway": pathway,
                "Outcome": outcome,
                "PatientPseudoId": patient.patient_pseudo_id,
                "NHSNumberDemo": patient.nhs_number_demo,
                "CallerPhoneHash": hashlib.sha256(
                    f"phone-{patient.patient_pseudo_id}-{rng.randint(1,9999)}".encode()
                ).hexdigest()[:16],
                "CareCaseCaseId": carecase_id,
                "LegendaryCareReferralId": referral_id,
                "LegendaryCareEncounterId": encounter_id,
                "CallbackOfContactId": callback_of,
                "LinkageScenario": linkage,
                "AmbiguousMatchIds": ambiguous,
                "AgentUsername": agent.carecall_username,
                "QueueName": queue,
                "AbandonedFlag": "Y" if ctype == "Abandoned" or outcome == "Abandoned" else "N",
                "TransferTarget": "ExternalDemo" if ctype == "Transfer" else "",
                "CreatedDateTime": created_dt.strftime("%Y-%m-%d %H:%M:%S"),
                "ExtractBatchDate": (month_end(year, month) + timedelta(days=2)).isoformat(),
                "_year": year,
                "_month": month,
                "_patient": patient,
                "_agent": agent,
                "_dt": dt,
            }
            data.carecall_contacts.append(row)

            if linkage == "CALLBACK_DUPLICATE" and callback_parents:
                parent = rng.choice(callback_parents)
                row["CallbackOfContactId"] = parent["ContactId"]
                row["PatientPseudoId"] = parent["PatientPseudoId"]
                row["NHSNumberDemo"] = parent["NHSNumberDemo"]
            elif linkage in ("DIRECT_CARECASE", "INFERRED_MATCH", "AMBIGUOUS") and ctype == "IUCS":
                callback_parents.append(row)

            if linkage == "DIRECT_LEGENDARY":
                pending_ambiguous.append(row)
            elif linkage == "INFERRED_MATCH":
                pending_inferred.append((row, "case"))
            elif linkage == "AMBIGUOUS":
                pending_ambiguous.append(row)

            # Dec 2025 timezone artefact — first 47 IUCS contacts
            if (year, month) == (2025, 12) and ctype == "IUCS" and len(timezone_shift_ids) < 47:
                row["ContactDate"] = (contact_date - timedelta(days=1)).isoformat()
                timezone_shift_ids.append(contact_id)

            # Background noise: mismatched case id
            if ctype == "IUCS" and rng.random() < 0.03 and linkage == "DIRECT_CARECASE":
                row["_force_mismatch"] = True

            # Benign duplicate-looking test contact
            if rng.random() < 0.004:
                row["AgentUsername"] = "cc.test.account"
                row["Outcome"] = "TestCall"

    # Create CareCase cases from DIRECT_CARECASE and some IUCS volume
    case_open_targets = [
        r for r in data.carecall_contacts
        if r["ContactType"] == "IUCS"
        and r["LinkageScenario"] in ("DIRECT_CARECASE", "DIRECT_LEGENDARY")
    ]
    # ~17% of IUCS become cases
    iucs_all = [r for r in data.carecall_contacts if r["ContactType"] == "IUCS"]
    target_cases = int(len(iucs_all) * 0.17)
    rng.shuffle(iucs_all)
    case_contacts = [
        r for r in iucs_all if r["LinkageScenario"] == "DIRECT_CARECASE"
    ]
    for r in iucs_all:
        if r not in case_contacts and len(case_contacts) < target_cases:
            if r["LinkageScenario"] in ("NO_CASE", "INFERRED_MATCH"):
                r["LinkageScenario"] = "DIRECT_CARECASE"
                case_contacts.append(r)

    for row in case_contacts[:target_cases]:
        _create_case_from_contact(rng, data, row, staff)

    # Feb 2026 genuine operational uplift — additional IUCS cases (~10%)
    feb_iucs = [
        r
        for r in iucs_all
        if (r["_year"], r["_month"]) == (2026, 2)
        and not r.get("CareCaseCaseId")
        and r["LinkageScenario"] in ("NO_CASE", "INFERRED_MATCH")
    ]
    rng.shuffle(feb_iucs)
    feb_extra = max(1, int(len([r for r in iucs_all if (r["_year"], r["_month"]) == (2026, 2)]) * 0.10))
    for row in feb_iucs[:feb_extra]:
        row["LinkageScenario"] = "DIRECT_CARECASE"
        _create_case_from_contact(rng, data, row, staff)

    # March 2026 extract artefact: +180 admin-status cases without CareCall link
    march_admin = 0
    while march_admin < 180:
        patient = rng.choice(patients)
        opened = rand_dt(rng, 2026, 3)
        case_id = next_id("CS-", 7)
        status = rng.choice(["PendingAdminClosure", "AwaitingSignoff"])
        case = {
            "CaseId": case_id,
            "OpenedDateTime": opened.strftime("%Y-%m-%d %H:%M:%S"),
            "ClosedDateTime": "",
            "CaseStatus": status,
            "PrimaryPathway": "IUCS",
            "SourceContactId": "",
            "PatientPseudoId": patient.patient_pseudo_id,
            "Priority": "Routine",
            "ClosureReason": "",
            "ExtractInclusionFlag": 1,
            "OpenedByUsername": rng.choice(staff).carecase_username,
            "_year": 2026,
            "_month": 3,
            "_opened": opened,
        }
        data.carecase_cases.append(case)
        _add_case_events(rng, data, case, rng.choice(staff))
        march_admin += 1

    # INFERRED_MATCH: cases without direct id on contact
    for row, _ in pending_inferred:
        if row.get("CareCaseCaseId"):
            continue
        case_id = next_id("CS-", 7)
        opened = row["_dt"] + timedelta(hours=rng.randint(2, 20))
        case = {
            "CaseId": case_id,
            "OpenedDateTime": opened.strftime("%Y-%m-%d %H:%M:%S"),
            "ClosedDateTime": (opened + timedelta(days=rng.randint(3, 14))).strftime(
                "%Y-%m-%d %H:%M:%S"
            ),
            "CaseStatus": "Closed",
            "PrimaryPathway": "IUCS",
            "SourceContactId": "",
            "PatientPseudoId": row["PatientPseudoId"],
            "Priority": "Urgent",
            "ClosureReason": "Resolved",
            "ExtractInclusionFlag": 0,
            "OpenedByUsername": rng.choice(staff).carecase_username,
            "_year": row["_year"],
            "_month": row["_month"],
            "_opened": opened,
        }
        data.carecase_cases.append(case)
        _add_case_events(rng, data, case, rng.choice(staff))

    # Legendary referrals/encounters
    _generate_legendary_from_contacts(rng, data, pending_ambiguous, referrals_by_contact, encounters_by_contact)

    # CareCall events
    for row in data.carecall_contacts:
        n_events = rng.randint(2, 4)
        base = row["_dt"]
        for i, etype in enumerate(["queue_enter", "answered", "hold", "wrap_up"][:n_events]):
            ev_dt = base + timedelta(minutes=i * rng.randint(1, 8))
            data.carecall_events.append(
                {
                    "EventId": next_id("CCE-", 8),
                    "ContactId": row["ContactId"],
                    "EventDateTime": ev_dt.strftime("%Y-%m-%d %H:%M:%S"),
                    "EventType": etype,
                    "AgentUsername": row["AgentUsername"],
                    "DurationSeconds": rng.randint(30, 600),
                    "QueueName": row["QueueName"],
                }
            )

    # Strip internal keys from contacts
    for row in data.carecall_contacts:
        for k in list(row.keys()):
            if k.startswith("_"):
                del row[k]


def _add_case_events(
    rng: random.Random, data: GeneratedData, case: dict[str, Any], clinician: StaffMember
) -> None:
    case_id = case["CaseId"]
    opened: datetime = case["_opened"]
    events = ["CaseOpened", "TriageCompleted", "ClinicianAssigned", "CaseUpdated"]
    if case["CaseStatus"] == "Closed":
        events.append("CaseClosed")
    for i, et in enumerate(events):
        ev_dt = opened + timedelta(hours=i * rng.randint(2, 12))
        data.carecase_case_events.append(
            {
                "CaseEventId": next_id("CSE-", 8),
                "CaseId": case_id,
                "EventDateTime": ev_dt.strftime("%Y-%m-%d %H:%M:%S"),
                "EventType": et,
                "EventDetail": f"Demo event {et}",
                "RecordedByUsername": clinician.carecase_username,
            }
        )
    for _ in range(rng.randint(1, 3)):
        c_dt = opened + timedelta(days=rng.randint(0, 5), hours=rng.randint(1, 8))
        data.carecase_clinician_contacts.append(
            {
                "ClinicianContactId": next_id("CSC-", 8),
                "CaseId": case_id,
                "ContactDateTime": c_dt.strftime("%Y-%m-%d %H:%M:%S"),
                "ContactMode": rng.choice(["Phone", "Video", "FaceToFace"]),
                "ClinicianUsername": clinician.carecase_username,
                "OutcomeCode": rng.choice(["ATT", "DNA", "PART"]),
                "DurationMinutes": rng.randint(10, 45),
            }
        )


def _generate_legendary_from_contacts(
    rng: random.Random,
    data: GeneratedData,
    pending_ambiguous: list[dict[str, Any]],
    referrals_by_contact: dict[str, str],
    encounters_by_contact: dict[str, str],
) -> None:
    patients = {p.patient_pseudo_id: p for p in data.patients}
    patient_rows = {
        p.patient_pseudo_id: {
            "PatientPseudoId": p.patient_pseudo_id,
            "LegendaryCarePatientRef": p.legendary_ref,
            "DateOfBirth": p.dob.isoformat(),
            "Sex": p.sex,
            "PostcodeSector": p.postcode_sector,
            "GPPracticeCode": p.gp_practice_code,
        }
        for p in data.patients
    }

    used_patients: set[str] = set()
    target_referrals = 0
    for year, month in MONTH_SPECS:
        target_referrals += int(650 * jitter_multiplier(rng))

    # Referrals linked to contacts
    linkable = [
        r
        for r in data.carecall_contacts
        if r.get("LinkageScenario") in ("DIRECT_LEGENDARY", "AMBIGUOUS", "DIRECT_CARECASE")
    ]
    rng.shuffle(linkable)

    for row in linkable:
        if len(data.legendary_referrals) >= target_referrals:
            break
        pid = row["PatientPseudoId"]
        used_patients.add(pid)
        ref_id = next_id("LC-REF-", 7)
        dt = row.get("_dt") or datetime.strptime(row["ContactDateTime"], "%Y-%m-%d %H:%M:%S")
        data.legendary_referrals.append(
            {
                "ReferralId": ref_id,
                "PatientPseudoId": pid,
                "ReferralDateTime": (dt + timedelta(days=rng.randint(0, 3))).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "ReferralSource": rng.choice(
                    ["PrimaryCare", "Self", "IUCS", "Acute", "Internal"]
                ),
                "ServiceCode": rng.choice(["MH-ACCESS", "CRHT", "IUCS-FU", "DENT-UC"]),
                "Urgency": rng.choice(["Routine", "Urgent"]),
                "Status": rng.choice(["Open", "Closed", "Active"]),
                "SourceCareCallContactId": row["ContactId"]
                if row.get("LinkageScenario") != "AMBIGUOUS"
                else "",
            }
        )
        if row.get("LinkageScenario") == "DIRECT_LEGENDARY":
            row["LegendaryCareReferralId"] = ref_id
        referrals_by_contact[row["ContactId"]] = ref_id

        enc_id = next_id("LC-ENC-", 7)
        data.legendary_encounters.append(
            {
                "EncounterId": enc_id,
                "PatientPseudoId": pid,
                "ReferralId": ref_id,
                "EncounterDateTime": (dt + timedelta(days=rng.randint(1, 10))).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "EncounterType": rng.choice(["Clinic", "HomeVisit", "Telephone"]),
                "LocationCode": rng.choice(["DEMO-LOC-A", "DEMO-LOC-B", "DEMO-HUB"]),
                "SourceCareCallContactId": row["ContactId"]
                if rng.random() > 0.2
                else "",
            }
        )
        if row.get("LinkageScenario") == "DIRECT_LEGENDARY":
            row["LegendaryCareEncounterId"] = enc_id

    # Ambiguous second candidates
    for row in pending_ambiguous:
        if row.get("LinkageScenario") != "AMBIGUOUS":
            continue
        cands = []
        for _ in range(2):
            ref_id = next_id("LC-REF-", 7)
            pid = row["PatientPseudoId"]
            dt = datetime.strptime(row["ContactDateTime"], "%Y-%m-%d %H:%M:%S")
            data.legendary_referrals.append(
                {
                    "ReferralId": ref_id,
                    "PatientPseudoId": pid,
                    "ReferralDateTime": (dt + timedelta(hours=rng.randint(-12, 24))).strftime(
                        "%Y-%m-%d %H:%M:%S"
                    ),
                    "ReferralSource": "IUCS",
                    "ServiceCode": "IUCS-FU",
                    "Urgency": "Urgent",
                    "Status": "Open",
                    "SourceCareCallContactId": "",
                }
            )
            cands.append(ref_id)
        row["AmbiguousMatchIds"] = "|".join(cands)

    # Standalone referrals to hit volume
    while len(data.legendary_referrals) < target_referrals:
        p = rng.choice(data.patients)
        used_patients.add(p.patient_pseudo_id)
        year, month = rng.choice(MONTH_SPECS)
        dt = rand_dt(rng, year, month)
        ref_id = next_id("LC-REF-", 7)
        data.legendary_referrals.append(
            {
                "ReferralId": ref_id,
                "PatientPseudoId": p.patient_pseudo_id,
                "ReferralDateTime": dt.strftime("%Y-%m-%d %H:%M:%S"),
                "ReferralSource": rng.choice(["PrimaryCare", "Self", "LA", "Acute"]),
                "ServiceCode": rng.choice(["MH-ACCESS", "CRHT", "LD-SVC", "PAL-HOME"]),
                "Urgency": rng.choice(["Routine", "Urgent"]),
                "Status": rng.choice(["Open", "Closed", "Active"]),
                "SourceCareCallContactId": "",
            }
        )

    # Appointments (~1200/month)
    appt_target = 0
    for year, month in MONTH_SPECS:
        appt_target += int(1200 * jitter_multiplier(rng))
    for ref in data.legendary_referrals:
        if len(data.legendary_appointments) >= appt_target:
            break
        n_appt = rng.randint(1, 2)
        ref_dt = datetime.strptime(ref["ReferralDateTime"], "%Y-%m-%d %H:%M:%S")
        for _ in range(n_appt):
            sched = ref_dt + timedelta(days=rng.randint(3, 21))
            data.legendary_appointments.append(
                {
                    "AppointmentId": next_id("LC-APT-", 7),
                    "PatientPseudoId": ref["PatientPseudoId"],
                    "ReferralId": ref["ReferralId"],
                    "ScheduledDateTime": sched.strftime("%Y-%m-%d %H:%M:%S"),
                    "AppointmentType": rng.choice(["Assessment", "Review", "Treatment"]),
                    "Status": rng.choice(["Attended", "Cancelled", "DNA"]),
                    "DNAFlag": "Y" if rng.random() < 0.08 else "N",
                }
            )

    # Encounters for remaining volume
    enc_target = sum(int(900 * jitter_multiplier(rng)) for _ in MONTH_SPECS)
    while len(data.legendary_encounters) < enc_target:
        ref = rng.choice(data.legendary_referrals)
        ref_dt = datetime.strptime(ref["ReferralDateTime"], "%Y-%m-%d %H:%M:%S")
        data.legendary_encounters.append(
            {
                "EncounterId": next_id("LC-ENC-", 7),
                "PatientPseudoId": ref["PatientPseudoId"],
                "ReferralId": ref["ReferralId"],
                "EncounterDateTime": (ref_dt + timedelta(days=rng.randint(1, 30))).strftime(
                    "%Y-%m-%d %H:%M:%S"
                ),
                "EncounterType": rng.choice(["Clinic", "HomeVisit", "Telephone"]),
                "LocationCode": rng.choice(["DEMO-LOC-A", "DEMO-LOC-B"]),
                "SourceCareCallContactId": ref.get("SourceCareCallContactId", ""),
            }
        )

    # Patient dimension — only patients with activity
    active_pids = used_patients.copy()
    for r in data.carecall_contacts:
        active_pids.add(r["PatientPseudoId"])
    for c in data.carecase_cases:
        active_pids.add(c["PatientPseudoId"])
    data.legendary_patients = [patient_rows[pid] for pid in sorted(active_pids) if pid in patient_rows]

    # Background noise: orphan referral id on ~1% contacts
    for row in data.carecall_contacts:
        if rng.random() < 0.012:
            row["LegendaryCareReferralId"] = next_id("LC-ORPH-", 5)


# ---------------------------------------------------------------------------
# RosterFlow + LedgerWise
# ---------------------------------------------------------------------------


def generate_rosterflow(rng: random.Random, data: GeneratedData) -> None:
    for s in data.staff:
        data.rosterflow_staff.append(
            {
                "SyntheticStaffId": s.synthetic_staff_id,
                "DisplayName": s.display_name,
                "RosterFlowUsername": s.rosterflow_username,
                "JobRole": rng.choice(["Nurse", "HCA", "Coordinator", "Clinician"]),
                "EmploymentType": rng.choice(["Permanent", "Bank", "Agency"]),
                "PrimaryTeamCode": s.primary_team_code,
                "ActiveFrom": s.active_from.isoformat(),
                "ActiveTo": s.active_to.isoformat() if s.active_to else "",
            }
        )

    bank_shifts_feb = 0
    for year, month in MONTH_SPECS:
        days = calendar.monthrange(year, month)[1]
        shifts_this_month = int(4500 * jitter_multiplier(rng))
        for _ in range(shifts_this_month):
            s = rng.choice(data.staff)
            day = rng.randint(1, days)
            shift_date = date(year, month, day)
            is_bank = rng.random() < 0.12
            urgent = s.primary_team_code.startswith("IUCS")
            if (year, month) == (2026, 2) and urgent and is_bank and bank_shifts_feb < 22:
                is_bank = True
                bank_shifts_feb += 1
            data.rosterflow_shifts.append(
                {
                    "ShiftId": next_id("RF-SH-", 8),
                    "SyntheticStaffId": s.synthetic_staff_id,
                    "ShiftDate": shift_date.isoformat(),
                    "ShiftType": rng.choice(["planned", "worked"]),
                    "TeamCode": s.primary_team_code,
                    "StartTime": f"{rng.randint(7, 9):02d}:00",
                    "EndTime": f"{rng.randint(16, 21):02d}:00",
                    "IsBankShift": "Y" if is_bank else "N",
                    "UrgentCareFlag": "Y" if urgent else "N",
                }
            )

        # Absence — slightly lower in Feb 2026
        absence_rate = 0.08 if (year, month) != (2026, 2) else 0.06
        for s in data.staff:
            if rng.random() < absence_rate:
                start = date(year, month, rng.randint(1, max(1, days - 3)))
                data.rosterflow_absence.append(
                    {
                        "AbsenceId": next_id("RF-AB-", 8),
                        "SyntheticStaffId": s.synthetic_staff_id,
                        "AbsenceType": rng.choice(["Sickness", "AnnualLeave", "Training"]),
                        "StartDate": start.isoformat(),
                        "EndDate": (start + timedelta(days=rng.randint(1, 5))).isoformat(),
                        "HoursLost": round(rng.uniform(7.5, 37.5), 1),
                    }
                )


def generate_ledgerwise(rng: random.Random, data: GeneratedData) -> None:
    data.ledgerwise_cost_centres = build_cost_centres()
    accounts = [
        ("6100", "Agency nursing", "pay"),
        ("6200", "Bank staff", "pay"),
        ("7100", "Medical supplies", "non-pay"),
        ("7200", "Equipment", "non-pay"),
    ]
    for year, month in MONTH_SPECS:
        lines = int(800 * jitter_multiplier(rng))
        for _ in range(lines):
            cc = rng.choice(data.ledgerwise_cost_centres)["CostCentreCode"]
            acct, desc, spend_type = rng.choice(accounts)
            amount = round(rng.uniform(50, 2500), 2)
            if cc == "CC-URG-401" and acct == "6100" and (year, month) == (2026, 2):
                amount *= 1.18  # agency uplift Feb
            posting = rand_dt(rng, year, month).date()
            data.ledgerwise_ledger.append(
                {
                    "LedgerLineId": next_id("LW-", 8),
                    "PostingDate": posting.isoformat(),
                    "FinancialMonth": month_key(year, month),
                    "CostCentreCode": cc,
                    "AccountCode": acct,
                    "AccountDescription": desc,
                    "SpendType": spend_type,
                    "AmountGBP": amount,
                    "Description": f"Demo posting {desc}",
                    "SourceDocumentRef": f"DEMO-INV-{rng.randint(10000, 99999)}",
                }
            )


# ---------------------------------------------------------------------------
# LocalOps spreadsheets
# ---------------------------------------------------------------------------


def generate_localops(rng: random.Random, data: GeneratedData) -> None:
    for s in data.staff:
        data.localops_user_mapping.append(
            {
                "SyntheticStaffId": s.synthetic_staff_id,
                "DisplayName": s.display_name,
                "LegendaryCareUsername": s.legendary_username,
                "CareCallUsername": s.carecall_username,
                "CareCaseUsername": s.carecase_username,
                "RosterFlowUsername": s.rosterflow_username,
                "LedgerWiseUsername": s.ledgerwise_username,
                "LocalTeamName": s.local_team_name,
                "RosterFlowTeamName": s.rosterflow_team_name,
                "CostCentreCode": s.cost_centre_code,
                "ValidFromDate": s.active_from.isoformat(),
                "ValidToDate": s.active_to.isoformat() if s.active_to else "",
                "MappingConfidence": s.mapping_confidence,
                "MappingNotes": s.mapping_notes,
            }
        )

    for team_code, name, cc, rf_team in TEAM_DEFS:
        data.localops_team_mapping.append(
            {
                "LocalTeamName": name,
                "CareCallTeamCode": team_code,
                "CareCaseTeamCode": team_code.replace("IUCS", "ICS"),
                "LegendaryServiceCode": team_code,
                "RosterFlowTeamName": rf_team,
                "CostCentreCode": cc,
                "Notes": "Demo mapping — verify quarterly",
            }
        )

    notes = [
        (
            "2026-02-10",
            "UrgentCare",
            "Feb bank-holiday weekend — IUCS volumes elevated; recovery plan activated per ops brief.",
            "demo.ops.coord",
        ),
        (
            "2026-02-18",
            "RosterFlow",
            "Additional bank shifts logged for IUCS hub 14–21 Feb. Matches temp escalation plan.",
            "demo.roster.lead",
        ),
        (
            "2026-01-22",
            "CareCall",
            "January demand higher than Q4 average — monitor IUCS queue times.",
            "demo.cc.manager",
        ),
        (
            "2025-12-05",
            "CareCall",
            "Overnight export window changed — check contact date vs created date on early Dec extracts.",
            "demo.bi.engineer",
        ),
        (
            "2026-03-01",
            "CareCase",
            "Nightly case extract deployment tonight — data owner signed off.",
            "demo.data.owner",
        ),
        (
            "2025-11-14",
            "LegendaryCare",
            "Referral source code 'Internal' inconsistent with CareCall signpost list — tidy-up backlog.",
            "demo.mig.lead",
        ),
    ]
    for ndate, system, text, author in notes:
        data.localops_validation_notes.append(
            {
                "NoteDate": ndate,
                "SystemName": system,
                "NoteCategory": rng.choice(["DataQuality", "Operational", "Extract"]),
                "NoteText": text,
                "Author": author,
            }
        )

    wl_adjustments = [
        ("2026-02-15", "MH-ACCESS", 12, "Remove duplicates from manual WL export"),
        ("2026-02-20", "IUCS-FU", -8, "Patients already seen — manual correction"),
        ("2025-10-03", "CRHT", 5, "Paper list backlog entered"),
    ]
    for adate, svc, delta, reason in wl_adjustments:
        data.localops_waiting_list_adjustments.append(
            {
                "AdjustmentDate": adate,
                "ServiceCode": svc,
                "AdjustmentCount": delta,
                "Reason": reason,
                "OperatorInitials": "DO",
                "ApprovedBy": "demo.ops.lead",
            }
        )

    data.localops_extract_change_log = [
        {
            "ChangeDate": "2025-12-04",
            "SystemName": "CareCall",
            "ExtractName": "DailyContactExport",
            "ChangeType": "Schedule change",
            "Description": "Export batch window moved to 02:00 UTC",
            "RaisedBy": "demo.bi.engineer",
            "ExpectedImpact": "Possible date boundary shifts on contact date",
            "ConfirmedByDataOwner": "demo.data.owner",
        },
        {
            "ChangeDate": "2026-02-28",
            "SystemName": "CareCase",
            "ExtractName": "NightlyCaseExtract",
            "ChangeType": "Inclusion rule change",
            "Description": "Include PendingAdminClosure and AwaitingSignoff from March run",
            "RaisedBy": "demo.ops.lead",
            "ExpectedImpact": "Higher case counts from March; not activity-led",
            "ConfirmedByDataOwner": "demo.data.owner",
        },
        {
            "ChangeDate": "2026-01-10",
            "SystemName": "RosterFlow",
            "ExtractName": "WeeklyShiftExport",
            "ChangeType": "Field added",
            "Description": "IsBankShift column added to shift export",
            "RaisedBy": "demo.roster.admin",
            "ExpectedImpact": "None on historical rows",
            "ConfirmedByDataOwner": "demo.roster.lead",
        },
    ]


# ---------------------------------------------------------------------------
# Output, manifest, summary
# ---------------------------------------------------------------------------

FILE_SPECS: list[dict[str, str]] = [
    {
        "file": "carecall_contacts.csv",
        "system": "CareCall",
        "date_col": "ContactDate",
        "grain": "One row per front-door contact",
        "purpose": "Urgent care and related contact records",
    },
    {
        "file": "carecall_call_events.csv",
        "system": "CareCall",
        "date_col": "EventDateTime",
        "grain": "One row per call-handling event",
        "purpose": "Queue and handling events linked to contacts",
    },
    {
        "file": "carecase_cases.csv",
        "system": "CareCase",
        "date_col": "OpenedDateTime",
        "grain": "One row per IUCS case",
        "purpose": "Case management records from urgent care pathway",
    },
    {
        "file": "carecase_case_events.csv",
        "system": "CareCase",
        "date_col": "EventDateTime",
        "grain": "One row per case lifecycle event",
        "purpose": "Case audit and status events",
    },
    {
        "file": "carecase_clinician_contacts.csv",
        "system": "CareCase",
        "date_col": "ContactDateTime",
        "grain": "One row per clinician contact on a case",
        "purpose": "Clinical contact activity on cases",
    },
    {
        "file": "legendary_care_patients.csv",
        "system": "Legendary Care",
        "date_col": "DateOfBirth",
        "grain": "One row per patient",
        "purpose": "Fictional EPR patient demographic extract",
    },
    {
        "file": "legendary_care_referrals.csv",
        "system": "Legendary Care",
        "date_col": "ReferralDateTime",
        "grain": "One row per referral",
        "purpose": "Referral records across services",
    },
    {
        "file": "legendary_care_appointments.csv",
        "system": "Legendary Care",
        "date_col": "ScheduledDateTime",
        "grain": "One row per appointment",
        "purpose": "Scheduled appointment records",
    },
    {
        "file": "legendary_care_encounters.csv",
        "system": "Legendary Care",
        "date_col": "EncounterDateTime",
        "grain": "One row per encounter",
        "purpose": "Clinical encounter activity",
    },
    {
        "file": "rosterflow_staff.csv",
        "system": "RosterFlow",
        "date_col": "ActiveFrom",
        "grain": "One row per staff member",
        "purpose": "Staff roster dimension",
    },
    {
        "file": "rosterflow_shifts.csv",
        "system": "RosterFlow",
        "date_col": "ShiftDate",
        "grain": "One row per planned or worked shift",
        "purpose": "Staff shift patterns and bank usage",
    },
    {
        "file": "rosterflow_absence.csv",
        "system": "RosterFlow",
        "date_col": "StartDate",
        "grain": "One row per absence episode",
        "purpose": "Sickness and leave records",
    },
    {
        "file": "ledgerwise_cost_centres.csv",
        "system": "LedgerWise",
        "date_col": "",
        "grain": "One row per cost centre",
        "purpose": "Finance cost centre reference",
    },
    {
        "file": "ledgerwise_ledger.csv",
        "system": "LedgerWise",
        "date_col": "PostingDate",
        "grain": "One row per ledger posting line",
        "purpose": "Pay and non-pay spend transactions",
    },
]

XLSX_SPECS = [
    ("localops_user_id_mapping.xlsx", "LocalOps", "ValidFromDate", "Cross-system staff username mapping"),
    ("localops_team_mapping.xlsx", "LocalOps", "", "Team and cost centre crosswalk"),
    ("localops_validation_notes.xlsx", "LocalOps", "NoteDate", "Manual data quality and operational notes"),
    ("localops_waiting_list_adjustments.xlsx", "LocalOps", "AdjustmentDate", "Manual waiting list corrections"),
    ("localops_extract_change_log.xlsx", "LocalOps", "ChangeDate", "Extract and inclusion rule change log"),
]


def _date_range(df: pd.DataFrame, col: str) -> tuple[str, str]:
    if not col or col not in df.columns or df[col].empty:
        return "", ""
    series = pd.to_datetime(df[col], errors="coerce").dropna()
    if series.empty:
        return "", ""
    return series.min().strftime("%Y-%m-%d"), series.max().strftime("%Y-%m-%d")


def write_outputs(data: GeneratedData) -> dict[str, pd.DataFrame]:
    SOURCE_DATA_DIR.mkdir(parents=True, exist_ok=True)
    PROFILE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    frames: dict[str, pd.DataFrame] = {
        "carecall_contacts.csv": pd.DataFrame(data.carecall_contacts),
        "carecall_call_events.csv": pd.DataFrame(data.carecall_events),
        "carecase_cases.csv": pd.DataFrame(
            [{k: v for k, v in c.items() if not k.startswith("_")} for c in data.carecase_cases]
        ),
        "carecase_case_events.csv": pd.DataFrame(data.carecase_case_events),
        "carecase_clinician_contacts.csv": pd.DataFrame(data.carecase_clinician_contacts),
        "legendary_care_patients.csv": pd.DataFrame(data.legendary_patients),
        "legendary_care_referrals.csv": pd.DataFrame(data.legendary_referrals),
        "legendary_care_appointments.csv": pd.DataFrame(data.legendary_appointments),
        "legendary_care_encounters.csv": pd.DataFrame(data.legendary_encounters),
        "rosterflow_staff.csv": pd.DataFrame(data.rosterflow_staff),
        "rosterflow_shifts.csv": pd.DataFrame(data.rosterflow_shifts),
        "rosterflow_absence.csv": pd.DataFrame(data.rosterflow_absence),
        "ledgerwise_cost_centres.csv": pd.DataFrame(data.ledgerwise_cost_centres),
        "ledgerwise_ledger.csv": pd.DataFrame(data.ledgerwise_ledger),
    }

    xlsx_frames = {
        "localops_user_id_mapping.xlsx": pd.DataFrame(data.localops_user_mapping),
        "localops_team_mapping.xlsx": pd.DataFrame(data.localops_team_mapping),
        "localops_validation_notes.xlsx": pd.DataFrame(data.localops_validation_notes),
        "localops_waiting_list_adjustments.xlsx": pd.DataFrame(
            data.localops_waiting_list_adjustments
        ),
        "localops_extract_change_log.xlsx": pd.DataFrame(data.localops_extract_change_log),
    }

    for name, df in frames.items():
        df.to_csv(SOURCE_DATA_DIR / name, index=False)

    for name, df in xlsx_frames.items():
        df.to_excel(SOURCE_DATA_DIR / name, index=False)

    frames.update(xlsx_frames)
    return frames


def write_manifest(frames: dict[str, pd.DataFrame]) -> None:
    rows = []
    for spec in FILE_SPECS:
        fn = spec["file"]
        df = frames[fn]
        mn, mx = _date_range(df, spec["date_col"])
        rows.append(
            {
                "FileName": fn,
                "SystemName": spec["system"],
                "RowCount": len(df),
                "PrimaryDateColumn": spec["date_col"],
                "MinDate": mn,
                "MaxDate": mx,
                "GrainDescription": spec["grain"],
                "KnownSyntheticPurpose": spec["purpose"],
                "GeneratedByScript": "create_synthetic_source_data.py",
            }
        )
    for fn, system, date_col, purpose in XLSX_SPECS:
        df = frames[fn]
        mn, mx = _date_range(df, date_col)
        rows.append(
            {
                "FileName": fn,
                "SystemName": system,
                "RowCount": len(df),
                "PrimaryDateColumn": date_col,
                "MinDate": mn,
                "MaxDate": mx,
                "GrainDescription": "Spreadsheet extract",
                "KnownSyntheticPurpose": purpose,
                "GeneratedByScript": "create_synthetic_source_data.py",
            }
        )
    pd.DataFrame(rows).to_csv(PROFILE_OUTPUT_DIR / "source_manifest.csv", index=False)


def write_summary(frames: dict[str, pd.DataFrame]) -> None:
    generated = GENERATED_AT or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    contacts = frames["carecall_contacts.csv"]
    cases = frames["carecase_cases.csv"]
    shifts = frames["rosterflow_shifts.csv"]
    ledger = frames["ledgerwise_ledger.csv"]

    contacts = contacts.copy()
    contacts["Month"] = pd.to_datetime(contacts["ContactDate"]).dt.to_period("M").astype(str)
    cases = cases.copy()
    cases["Month"] = pd.to_datetime(cases["OpenedDateTime"]).dt.to_period("M").astype(str)
    shifts = shifts.copy()
    shifts["Month"] = pd.to_datetime(shifts["ShiftDate"]).dt.to_period("M").astype(str)
    ledger = ledger.copy()
    ledger["Month"] = ledger["FinancialMonth"]

    monthly_contacts = contacts.groupby("Month").size().reset_index(name="ContactCount")
    monthly_iucs = (
        contacts[contacts["ContactType"] == "IUCS"].groupby("Month").size().reset_index(name="IUCSCount")
    )
    monthly_cases = cases.groupby("Month").size().reset_index(name="CaseOpenedCount")
    monthly_shifts = (
        shifts[shifts["UrgentCareFlag"] == "Y"].groupby("Month").size().reset_index(name="UrgentCareShifts")
    )
    monthly_spend = (
        ledger[ledger["CostCentreCode"] == "CC-URG-401"]
        .groupby("Month")["AmountGBP"]
        .sum()
        .reset_index(name="UrgentCareSpendGBP")
    )
    linkage = contacts["LinkageScenario"].value_counts().reset_index()
    linkage.columns = ["LinkageScenario", "Count"]

    lines = [
        "# Source data summary",
        "",
        f"- **Generated at:** {generated}",
        f"- **Random seed:** {RANDOM_SEED}",
        f"- **Trust:** {TRUST_NAME} ({TRUST_ODS})",
        f"- **Month range:** {month_key(*MONTH_SPECS[0])} to {month_key(*MONTH_SPECS[-1])}",
        "",
        "See `source_manifest.csv` for per-file row counts and date ranges.",
        "",
        "## Monthly CareCall contacts",
        "",
        df_to_markdown(monthly_contacts),
        "",
        "## Monthly IUCS contacts",
        "",
        df_to_markdown(monthly_iucs),
        "",
        "## Monthly CareCase cases opened",
        "",
        df_to_markdown(monthly_cases),
        "",
        "## Monthly urgent-care shifts (RosterFlow)",
        "",
        df_to_markdown(monthly_shifts),
        "",
        "## Monthly urgent-care ledger spend (CC-URG-401)",
        "",
        df_to_markdown(monthly_spend),
        "",
        "## CareCall linkage scenario counts",
        "",
        df_to_markdown(linkage),
        "",
    ]
    (PROFILE_OUTPUT_DIR / "source_summary.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    rng = random.Random(RANDOM_SEED)
    reset_counters()

    data = GeneratedData()
    data.staff = generate_staff(rng)
    data.patients = generate_patients(rng)

    generate_carecall_and_cases(rng, data)
    generate_rosterflow(rng, data)
    generate_ledgerwise(rng, data)
    generate_localops(rng, data)

    frames = write_outputs(data)
    write_manifest(frames)
    write_summary(frames)

    print(f"Generated {len(frames)} datasets into {SOURCE_DATA_DIR.resolve()}")
    print(f"Manifest and summary written to {PROFILE_OUTPUT_DIR.resolve()}")


if __name__ == "__main__":
    main()
