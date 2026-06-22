# Pipeline parameters (demonstration)

## Environments

| Slot | SQL server | Database | Notes |
|------|------------|----------|-------|
| `dev` | `demo-sql-dev.database.windows.net` | DemoRiversDWH | Fictional |
| `demo` | `demo-sql-demo.database.windows.net` | DemoRiversDWH | Fictional |

**No real connection strings.** Use Key Vault placeholder `kv-demo-rivers` in ADF linked service JSON.

## Parameters

| Name | Type | Default | Used by |
|------|------|---------|---------|
| `reportingMonth` | string | `2026-03` | Mart refresh filter |
| `providerCode` | string | `DRH` | Mart grain |
| `loadBatchId` | string | `@pipeline().RunId` | Staging audit |
| `dqFailOnOrphanPct` | float | `0.05` | DQ gate (warn above) |

## Secrets (placeholders only)

- `sql-demo-connection-string` — Key Vault reference, not populated in repo
- `blob-demo-sas` — Key Vault reference, not populated in repo

## Regeneration without ADF

Run `generator/build_provider_month_measures.py` for offline mart CSV equivalent.
