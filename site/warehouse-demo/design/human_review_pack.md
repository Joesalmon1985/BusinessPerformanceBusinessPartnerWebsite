# Human review pack (design sign-off)

> **For Information Lead and Performance Manager (demo roles).** Questions only — no pre-filled answers.

## Decision log

| Decision ID | Topic | Options | Decision | Decided by | Date |
|-------------|-------|---------|----------|------------|------|
| D001 | Operational case definition | A) Exclude ExtractInclusionFlag=1 B) Separate measure C) Include all | | | |
| D002 | Contact reporting date (DQ001) | A) ContactDate B) CreatedDateTime C) Dual publish | | | |
| D003 | Ambiguous match default | A) No default B) Nearest referral time C) Manual table | | | |
| D004 | Callback dedup in marts | A) All contacts B) Distinct patient-day | | | |
| D005 | Inferred match in facts | A) Bridge only B) Auto-promote high confidence | | | |

## Sign-off checklist

- [ ] Staging model reviewed against source extracts
- [ ] Linkage strategy acceptable for IUCS reporting
- [ ] ExtractInclusionFlag handling agreed
- [ ] LocalOps mapping confidence rules agreed
- [ ] Provider-month mart measures defined (stock vs activity)
- [ ] IG / synthetic data caveats acceptable for demo site
- [ ] Approved to proceed to SQL artefacts (Run 4)

## Questions for reviewers

1. Should March 2026 admin-status cases appear in **operational** IUCS case-open measures?  
2. Is `CreatedDateTime` or `ContactDate` authoritative for CareCall monthly counts when date-boundary flag is set?  
3. Are bridge tables sufficient for ambiguous matches, or is a manual resolution workflow required?  
4. Which staff mapping confidence levels are trusted for finance ↔ roster joins?  
5. Should provider-month marts use calendar month or financial month for ledger spend?  
6. What caveats must appear on any published demo brief using this warehouse?

## Escalation

If profiling hypotheses (extract-driven March vs operational Jan–Feb) are disputed, pause Run 4 SQL build until data owner confirms extract change log entries.

**Status:** Awaiting human input.
