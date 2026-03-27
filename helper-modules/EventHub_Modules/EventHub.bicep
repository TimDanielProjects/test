// ============================================================================
// Event Hub
// Deploys an Event Hub on an existing Event Hub Namespace.
// Used in integration templates to provision per-integration Event Hubs.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Event Hub configuration.')
param eventHub {
  @description('Required. Name of the Event Hub (e.g., "order-events").')
  name: string

  @description('Required. Name of the existing Event Hub Namespace.')
  namespaceName: string

  @description('Optional. Number of partitions. Allowed values 1–32. Default is 2.')
  partitionCount: int?

  @description('Optional. Number of days to retain events (1–7 for Basic/Standard, up to 90 for Premium). Default is 1.')
  messageRetentionInDays: int?

  @description('Optional. Consumer groups to create. A $Default group is always created automatically by the AVM module.')
  consumerGroups: consumerGroupConfig[]?
}

// ============================================================================
// Types
// ============================================================================

@description('Configuration for an Event Hub consumer group.')
type consumerGroupConfig = {
  @description('Required. Name of the consumer group.')
  name: string

  @description('Optional. User metadata describing the consumer group.')
  userMetadata: string?
}

// ============================================================================
// Resources
// ============================================================================

module hub '../../bicep-registry-modules/avm/res/event-hub/namespace/eventhub/main.bicep' = {
  name: 'EventHub-${eventHub.name}-${dateTime}'
  params: {
    namespaceName: eventHub.namespaceName
    name: eventHub.name
    partitionCount: eventHub.?partitionCount ?? 2
    messageRetentionInDays: eventHub.?messageRetentionInDays ?? 1
    consumergroups: eventHub.?consumerGroups ?? [
      {
        name: '$Default'
      }
    ]
    enableTelemetry: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Event Hub.')
output name string = hub.outputs.name

@description('The resource ID of the deployed Event Hub.')
output resourceId string = hub.outputs.resourceId
