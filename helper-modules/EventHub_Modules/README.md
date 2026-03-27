# Event Hub Modules

This folder contains Bicep modules for deploying Event Hubs on an existing Event Hub Namespace. These are used by integration templates to provision per-integration event streaming resources.

## Module Files

### EventHub.bicep

Deploys an Event Hub on an existing Event Hub Namespace via the AVM `event-hub/namespace/eventhub` module.

**Key configurable properties:**
- **Event Hub Name** — Name of the Event Hub (auto-generated from integration name if left empty)
- **Partition Count** — Number of partitions for parallel processing (1–32, default: 2)
- **Message Retention (Days)** — Number of days to retain messages (1–7 for Basic/Standard, default: 1)
- **Consumer Groups** — Optional array of consumer groups (a `$Default` group is always created)

## Prerequisites

- An **Event Hub Namespace** must exist in the shared infrastructure (module id: `event-hub-namespace`)

## Outputs

- `name` — The name of the deployed Event Hub
- `resourceId` — The Azure resource ID of the deployed Event Hub
