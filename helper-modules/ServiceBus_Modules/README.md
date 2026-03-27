# Service Bus Modules

This folder contains Bicep modules for deploying Service Bus child resources (queues and topics) on an existing Service Bus Namespace. These are used by integration templates to provision per-integration messaging resources.

## Module Files

### ServiceBusQueue.bicep

Deploys a queue on an existing Service Bus Namespace via the AVM `service-bus/namespace/queue` module.

**Key configurable properties:**
- **Queue Name** — Name of the queue (auto-generated from integration name if left empty)
- **Max Delivery Count** — Number of delivery attempts before dead-lettering (default: 10)
- **Dead Letter on Expiration** — Move expired messages to the dead-letter queue (default: true)
- **Lock Duration** — ISO 8601 peek-lock duration (default: PT1M)
- **Duplicate Detection** — Enable duplicate detection (default: false)
- **Sessions** — Enable session support (default: false)
- **Partitioning** — Enable partitioning across brokers (default: false)

### ServiceBusTopic.bicep

Deploys a topic (with optional subscriptions) on an existing Service Bus Namespace via the AVM `service-bus/namespace/topic` module. Topics require **Standard** or **Premium** SKU on the namespace.

**Key configurable properties:**
- **Topic Name** — Name of the topic (auto-generated from integration name if left empty)
- **Duplicate Detection** — Enable duplicate detection (default: true for topics)
- **Ordering** — Enable ordering support (default: false)
- **Partitioning** — Enable partitioning across brokers (default: false)
- **Subscriptions** — Array of subscriptions with name, TTL, max delivery count, and dead-letter settings

## Prerequisites

- A **Service Bus Namespace** must exist in the shared infrastructure (module id: `service-bus-namespace`)
- Topics require **Standard** or **Premium** SKU on the namespace

## Outputs

Both modules return:
- `name` — The name of the deployed queue or topic
- `resourceId` — The Azure resource ID of the deployed queue or topic
