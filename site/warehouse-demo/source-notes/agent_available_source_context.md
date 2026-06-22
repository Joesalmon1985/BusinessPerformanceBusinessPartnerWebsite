# Agent-available source context

> Safe operational context for profiling agents. **Do not** treat this file as a complete data dictionary. Profile the extracts themselves.

## Ownership (fictional)

| System | Demo owner team | Extract contact |
|--------|-----------------|-----------------|
| CareCall | Urgent Care Operations | demo.cc.ops@demo-rivers.invalid |
| CareCase | IUCS Clinical Services | demo.iucs.clinical@demo-rivers.invalid |
| Legendary Care | PAS / EPR support | demo.pas.support@demo-rivers.invalid |
| RosterFlow | Workforce rostering | demo.roster@demo-rivers.invalid |
| LedgerWise | Finance business partnering | demo.finance@demo-rivers.invalid |
| LocalOps | Performance & BI | demo.bi@demo-rivers.invalid |

## CareCall `LinkageScenario` codes

These codes are populated on `carecall_contacts.csv` for IUCS pathway contacts:

| Code | Meaning |
|------|---------|
| `DIRECT_CARECASE` | Contact row includes a `CareCaseCaseId` |
| `DIRECT_LEGENDARY` | Contact row includes Legendary Care referral and/or encounter ID |
| `INFERRED_MATCH` | No direct ID on contact; case may exist for same patient within ~24 hours |
| `NO_CASE` | No expected downstream case (signpost, abandon, admin, etc.) |
| `AMBIGUOUS` | `AmbiguousMatchIds` lists multiple pipe-delimited candidate referral IDs |
| `CALLBACK_DUPLICATE` | `CallbackOfContactId` points to an earlier contact same day/patient |

Non-IUCS contacts typically use `NO_CASE`.

## Known messy practices (general)

- LocalOps user mappings may have **expired `ValidToDate`** but still appear in extracts
- Team names differ slightly between LocalOps, RosterFlow and CareCall (`IUCS Hub` vs `Urgent Care Centre`)
- Some `MappingConfidence=Low` rows are legacy accounts
- CareCall `ContactDate` and `CreatedDateTime` can disagree when export windows change
- Legendary Care `SourceCareCallContactId` is not always populated even when a link exists
- Orphan foreign keys appear at low rates in most extracts

## Extract change management

LocalOps maintains `localops_extract_change_log.xlsx`. When monthly counts move, check whether an extract or inclusion rule changed before assuming operational change.

## CareCase `ExtractInclusionFlag`

Present on `carecase_cases.csv`. Indicates whether the case met the extract inclusion rules at extract time. Meaning of rule versions is not fully documented in source systems — profile alongside case status and open dates.

## Finance

- Cost centre `CC-URG-401` — urgent care hub (demo)
- Cost centre `CC-MH-210` — mental health services (demo)
- Account `6100` — agency nursing (variable pay pressure indicator)

## What this file does not contain

- Planted anomaly interpretations
- Expected answers for month-on-month spikes
- Warehouse table designs or ETL specifications

Profile the data, document findings, then escalate gaps to a human reviewer.
