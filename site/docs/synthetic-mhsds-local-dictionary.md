# Synthetic MHSDS local dictionary (demonstration only)

> **Synthetic demonstration logic only.** This is not an official Dorset HealthCare or Trust data dictionary. It is invented for this personal demonstration site and is not for operational use, submission or reporting.

Real Trust metric definitions are IG-controlled, versioned and maintained by an Information Lead. Any figure used in a live report must be validated against the approved local dictionary and signed off by the accountable owner.

RiO is named below as a plausible PAS for demo context only — **not** asserting real Dorset HealthCare schema, forms or warehouse objects.

---

## Synthetic data lineage (Metric 1 — demonstration only)

End-to-end fictional lineage for **Synthetic All Age Mental Health Access Contacts**:

| Layer | Fictional artefact |
|-------|-------------------|
| Source system | RiO contact / appointment record (synthetic demo reference — not live Trust) |
| Source form / fields | `DemoMHContactForm`; fields `ContactStatusCode`, `ContactDate`, `AppointmentType`, `TeamCode` |
| Staging extract | `StgMHSDSContactExtractDemo` — nightly RiO → warehouse staging |
| Team mapping | `DimMHSDSServiceTeamDemo` — maps `TeamCode` to All Age MH inclusion flag (`AllAgeMHFlag`) |
| Fact table | `FactMHSDSContactDemo` — one row per contact event after ETL and deduplication |
| Filters | `ContactStatusCode = 'ATT'` (attended); `ContactMonth = ReportingMonth`; `AllAgeMHFlag = 1` |
| Dedup logic | `ROW_NUMBER()` on `(PersonID, ContactDate, TeamCode)` keeping earliest attended row (synthetic rule) |
| Late recording flag | `LateRecordedFlag = 1` where contact date falls in a prior month but record created in reporting month |
| Reporting output | Aggregate count → [`data/synthetic_mhsds_sme_demo.csv`](../data/synthetic_mhsds_sme_demo.csv) |

**Lineage flow:**

```
RiO contact / appointment record (DemoMHContactForm)
  → StgMHSDSContactExtractDemo
  → FactMHSDSContactDemo (join DimMHSDSServiceTeamDemo)
  → filter: attended + reporting month + All Age MH teams
  → aggregate count
  → synthetic_mhsds_sme_demo.csv
```

---

## Metric 1: Synthetic All Age Mental Health Access Contacts

| Field | Definition |
|-------|------------|
| **Metric name** | Synthetic All Age Mental Health Access Contacts |
| **Plain-English definition** | Count of attended contacts recorded in the reporting month for selected all-age mental health access services in this synthetic demo. |
| **Source system** | RiO (synthetic demo reference) |
| **Source form** | `DemoMHContactForm` |
| **Key fields** | `ContactStatusCode`, `ContactDate`, `AppointmentType`, `TeamCode`, `PersonID` (synthetic demo field names) |
| **Extract table** | `StgMHSDSContactExtractDemo` |
| **Fact table** | `FactMHSDSContactDemo` |
| **Mapping table** | `DimMHSDSServiceTeamDemo` |
| **Numerator** | Attended contacts where `ContactStatusCode = 'ATT'` and `ContactDate` falls within the reporting month |
| **Denominator** | Not applicable (count metric) |
| **Dedup rule** | `ROW_NUMBER()` on `(PersonID, ContactDate, TeamCode)` — keep earliest attended row per synthetic demo rule |
| **Included synthetic services** | Demo Community MH Access Team; Demo All Age Crisis Resolution Team; Demo Primary Care Liaison MH Service (via `AllAgeMHFlag = 1` in `DimMHSDSServiceTeamDemo`) |
| **Excluded synthetic services** | Inpatient wards; LD/autism specialist teams; IAPT/Talking Therapies (separate pathway in demo); admin-only contacts |
| **Reporting period** | Calendar month (e.g. 2026-02, 2026-03) |
| **Known caveats** | Synthetic PAS extract logic; late-recorded contacts may appear in a later month (`LateRecordedFlag`); duplicate contact rules not fully validated in demo |
| **Owner / sign-off role** | Synthetic demo: Information Lead (MHSDS accountability) and Performance Manager |

**Pseudologic (synthetic demo):**

```sql
SELECT COUNT(*)
FROM FactMHSDSContactDemo f
JOIN DimMHSDSServiceTeamDemo d ON f.TeamCode = d.TeamCode
WHERE f.ContactStatusCode = 'ATT'
  AND f.ContactMonth = @ReportingMonth
  AND d.AllAgeMHFlag = 1
```

---

## Metric 2: Synthetic First Attended Contact Rate

| Field | Definition |
|-------|------------|
| **Metric name** | Synthetic First Attended Contact Rate |
| **Plain-English definition** | Proportion of referrals received in the reporting month where a first attended contact occurred in the same month (synthetic demo logic). |
| **Numerator** | First attended contacts in the reporting month (`FirstContactFlag = 1` in `FactMHSDSContactDemo`) |
| **Denominator** | Referrals received in the reporting month (from synthetic referral extract — demo only) |
| **Included synthetic services** | Same as Metric 1 |
| **Excluded synthetic services** | Same as Metric 1; referrals closed before first contact with no attended contact are excluded from numerator but remain in denominator |
| **Reporting period** | Calendar month |
| **Known caveats** | Sensitive to referral timing within the month; not comparable to national MHSDS published measures without mapping validation |
| **Owner / sign-off role** | Synthetic demo: Information Lead and Performance Manager |

---

## Metric 3: Synthetic Referral-to-First-Contact Median Wait

| Field | Definition |
|-------|------------|
| **Metric name** | Synthetic Referral-to-First-Contact Median Wait |
| **Plain-English definition** | Median number of days from referral date to first attended contact for referrals reaching first contact in the reporting month (synthetic demo logic). |
| **Numerator** | Days from referral to first attended contact (per referral reaching first contact in month) |
| **Denominator** | Count of referrals reaching first attended contact in the reporting month (for median calculation) |
| **Included synthetic services** | Same as Metric 1 |
| **Excluded synthetic services** | Same as Metric 1; referrals with no first attended contact in the month are excluded |
| **Reporting period** | Calendar month (based on first contact date) |
| **Known caveats** | Does not reflect full pathway wait for referrals still waiting; affected by late recording and DNA/rebook patterns |
| **Owner / sign-off role** | Synthetic demo: Information Lead and Performance Manager |

---

## Demo data reference

Aggregate figures for these metrics are in [`data/synthetic_mhsds_sme_demo.csv`](../data/synthetic_mhsds_sme_demo.csv).

Public MHSDS source references are in [`public-data/mhsds-source-pack-register.csv`](../public-data/mhsds-source-pack-register.csv).
