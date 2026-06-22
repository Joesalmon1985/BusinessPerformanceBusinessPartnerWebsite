# Agent rules index

Reusable Cursor-style agent rule documents for the Business & Performance demonstration site.

## Categories

### A. Reporting specification SME agents
Answer only from approved sources with citations.

| Agent | File |
|-------|------|
| MHSDS Expert | [mhsds-expert-agent.md](mhsds-expert-agent.md) — [worked example](../examples/mhsds-sme-agent-conversation.md) |
| CSDS Expert | [csds-expert-agent.md](csds-expert-agent.md) |
| PLCM Expert | [plcm-expert-agent.md](plcm-expert-agent.md) |
| ADC Expert | [adc-expert-agent.md](adc-expert-agent.md) |

### B. Performance and reporting workflow
| Agent | File |
|-------|------|
| Performance Manager | [performance-manager-agent.md](performance-manager-agent.md) |
| Demand & Capacity | [demand-capacity-agent.md](demand-capacity-agent.md) |
| Report Analysis and Improvement | [report-analysis-agent.md](report-analysis-agent.md) — [worked example](../examples/report-analysis-agent-conversation.md) (workflow alias: [Report QA](report-qa-agent.md)) |
| Executive Summary | [executive-summary-agent.md](executive-summary-agent.md) |

### C. Admin and delivery

Coordination (Project / Admin), reconciliation (Backlog Sync) and branch close-out (Branch Review & Delivery).

| Agent | File |
|-------|------|
| Project / Admin | [project-admin-agent.md](project-admin-agent.md) |
| Backlog Sync | [backlog-sync-agent.md](backlog-sync-agent.md) |
| Branch Review & Delivery | [branch-review-delivery-agent.md](branch-review-delivery-agent.md) |

### D. Information governance
| Agent | File |
|-------|------|
| IG / Safety (hard gate) | [ig-safety-agent.md](ig-safety-agent.md) |

### E. Warehouse design demo (synthetic DRH)
Agentic warehouse-design worked example — profile sources before proposing models.

| Agent | File |
|-------|------|
| Source Profiling | [source-profiling-agent.md](source-profiling-agent.md) — [worked example](../examples/warehouse-source-profiling-conversation.md) |
| Warehouse Design | [warehouse-design-agent.md](warehouse-design-agent.md) — [worked example](../examples/warehouse-design-conversation.md) |
| Report QA (warehouse briefs) | [warehouse-report-qa-agent.md](warehouse-report-qa-agent.md) — extends [report-analysis-agent.md](report-analysis-agent.md) |

Index: [warehouse-demo/source-notes/demo_run_index.md](../warehouse-demo/source-notes/demo_run_index.md)

## How to use

1. Load the relevant `.md` file as a Cursor rule or system prompt fragment.
2. Attach only approved source documents for SME agents.
3. Run IG/Safety check before sharing output externally.
4. Require human sign-off per agent file.

## Demonstration only

These rules are illustrative. They are not deployed in production and do not connect to live Trust systems.
