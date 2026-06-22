# Source system overview (demonstration only)

> **Synthetic demonstration data only.** These fictional systems do not reproduce real supplier schemas, Dorset HealthCare systems or live operational extracts.

This pack supports a future **agentic warehouse-design** worked example. The profiling agent should analyse these sources before proposing any warehouse model.

## Fictional trust

- **Name:** Demo Rivers Health NHS Foundation Trust
- **ODS code:** DRH

## Source systems

### CareCall

Front-door urgent care call and contact system. Captures IUCS, mental health, dental, palliative, admin, abandoned calls, transfers and signposting.

| Extract | Grain | Typical use |
|---------|-------|-------------|
| `carecall_contacts.csv` | One row per contact | Volume, pathway mix, linkage to downstream systems |
| `carecall_call_events.csv` | One row per handling event | Queue timing, agent activity |

Some contacts link directly to CareCase or Legendary Care; many do not.

### CareCase

IUCS case-management system. Cases are created from a subset of CareCall IUCS contacts.

| Extract | Grain |
|---------|-------|
| `carecase_cases.csv` | One row per case |
| `carecase_case_events.csv` | One row per case lifecycle event |
| `carecase_clinician_contacts.csv` | One row per clinician contact on a case |

### Legendary Care

Fictional EPR/PAS-style system for wider referrals, appointments, encounters and waiting-list-related activity. **Not** based on any real supplier data model.

| Extract | Grain |
|---------|-------|
| `legendary_care_patients.csv` | One row per patient with activity |
| `legendary_care_referrals.csv` | One row per referral |
| `legendary_care_appointments.csv` | One row per appointment |
| `legendary_care_encounters.csv` | One row per encounter |

### RosterFlow

Fictional staff rostering system: staff, planned/worked shifts, sickness and absence.

### LedgerWise

Fictional finance ledger: cost centres and posting lines (pay and non-pay).

### LocalOps spreadsheets

Human-maintained Excel files for cross-system mappings, validation notes, waiting-list adjustments and extract change logs. Expect inconsistent naming and imperfect mappings.

## Relationship flow

```
CareCall contact
  ├─► CareCase case (some IUCS contacts)
  ├─► Legendary Care referral / encounter (some contacts)
  └─► No downstream case (signpost, abandon, admin, etc.)

Legendary Care referral
  ├─► appointments
  └─► encounters

RosterFlow staff ◄──► LocalOps user mapping ◄──► system usernames
LedgerWise cost centres ◄──► LocalOps team mapping
```

## Extract cadence (fictional)

| System | Extract pattern |
|--------|-----------------|
| CareCall | Daily contact export |
| CareCase | Nightly case extract |
| Legendary Care | Nightly PAS extracts |
| RosterFlow | Weekly shift export |
| LedgerWise | Month-end finance postings |
| LocalOps | Ad hoc manual refresh |

## Month range

Current pack: **September 2025 – May 2026** (nine reporting months).

## Next step

Do **not** assume a warehouse design. Profile these sources first — see [`suggested_next_agent_task.md`](suggested_next_agent_task.md).
