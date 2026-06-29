# Secondment migration demo (DRH)

Synthetic **Legendary Care → PathwayOne** migration scenario for the *Six Months to Trusted Performance* interview section.

## Timeline summary

| Phase | When | Key point |
|-------|------|-----------|
| A | Sep–Nov 2025 | Old system only |
| B | Dec 2025 – Jan 2026 | **Parallel running** — both feeds |
| C | 1 Feb 2026 | Weekly referral supplement **discontinued** |
| D | Feb–Mar 2026 | Open-case extract tail; definition crunch |
| E | 31 Mar 2026 | Legacy extracts end |
| F | Apr–May 2026 | PathwayOne only (+ history in warehouse) |

## Regenerate data

```bash
python3 site/secondment-demo/generator/create_migration_scenario_data.py
```

## Key files

- `data/legendary_cmht_cases.csv` — old case-based world
- `data/pathwayone_actions.csv` — new action-based world
- `data/reconciliation_monthly.csv` — Mar 2026 dashboard vs agreed gap
- `data_dictionary.md` — field definitions
- `data/data_manifest.csv` — auto-generated inventory

Anchor patient for centrepiece: **DRH-PAT-002896**.

Not connected to live Trust systems. DRH ≠ RDY.
