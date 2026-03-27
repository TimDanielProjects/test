// ============================================================================
// Service Bus Topic
// Deploys a topic (with optional subscriptions) on an existing Service Bus
// Namespace. Used in integration templates to provision per-integration topics.
// Note: Topics require Standard or Premium SKU on the namespace.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Service Bus Topic configuration.')
param serviceBusTopic {
  @description('Required. Name of the topic (e.g., "order-events").')
  name: string

  @description('Required. Name of the existing Service Bus Namespace.')
  namespaceName: string

  @description('Optional. The maximum size of the topic in megabytes. Default is 1024.')
  maxSizeInMegabytes: int?

  @description('Optional. ISO 8601 default message time-to-live. Default is 14 days (P14D).')
  defaultMessageTimeToLive: string?

  @description('Optional. Require duplicate detection. Default is true for topics.')
  requiresDuplicateDetection: bool?

  @description('Optional. Enable ordering support on the topic. Default is false.')
  supportOrdering: bool?

  @description('Optional. Enable partitioning across message brokers. Default is false.')
  enablePartitioning: bool?

  @description('Optional. Array of subscriptions to create on the topic.')
  subscriptions: subscriptionConfig[]?
}

// ============================================================================
// Types
// ============================================================================

@description('Configuration for a topic subscription.')
type subscriptionConfig = {
  @description('Required. Name of the subscription.')
  name: string

  @description('Optional. ISO 8601 default message time-to-live. Default is 14 days (P14D).')
  defaultMessageTimeToLive: string?

  @description('Optional. Maximum number of deliveries before dead-lettering. Default is 10.')
  maxDeliveryCount: int?

  @description('Optional. ISO 8601 lock duration for peek-lock. Default is 1 minute (PT1M).')
  lockDuration: string?

  @description('Optional. Enable dead-lettering on filter evaluation exceptions. Default is true.')
  deadLetteringOnFilterEvaluationExceptions: bool?

  @description('Optional. Enable dead-lettering when messages expire. Default is false.')
  deadLetteringOnMessageExpiration: bool?
}

// ============================================================================
// Resources
// ============================================================================

module topic '../../bicep-registry-modules/avm/res/service-bus/namespace/topic/main.bicep' = {
  name: 'ServiceBusTopic-${serviceBusTopic.name}-${dateTime}'
  params: {
    namespaceName: serviceBusTopic.namespaceName
    name: serviceBusTopic.name
    maxSizeInMegabytes: serviceBusTopic.?maxSizeInMegabytes ?? 1024
    defaultMessageTimeToLive: serviceBusTopic.?defaultMessageTimeToLive ?? 'P14D'
    requiresDuplicateDetection: serviceBusTopic.?requiresDuplicateDetection ?? true
    supportOrdering: serviceBusTopic.?supportOrdering ?? false
    enablePartitioning: serviceBusTopic.?enablePartitioning ?? false
    enableBatchedOperations: true
    subscriptions: serviceBusTopic.?subscriptions
    enableTelemetry: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Service Bus Topic.')
output name string = topic.outputs.name

@description('The resource ID of the deployed Service Bus Topic.')
output resourceId string = topic.outputs.resourceId
