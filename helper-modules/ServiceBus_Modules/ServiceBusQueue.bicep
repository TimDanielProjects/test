// ============================================================================
// Service Bus Queue
// Deploys a queue on an existing Service Bus Namespace.
// Used in integration templates to provision per-integration queues.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Service Bus Queue configuration.')
param serviceBusQueue {
  @description('Required. Name of the queue (e.g., "order-inbound").')
  name: string

  @description('Required. Name of the existing Service Bus Namespace.')
  namespaceName: string

  @description('Optional. The maximum size of the queue in megabytes. Default is 1024.')
  maxSizeInMegabytes: int?

  @description('Optional. ISO 8601 default message time-to-live. Default is 14 days (P14D).')
  defaultMessageTimeToLive: string?

  @description('Optional. ISO 8601 lock duration for peek-lock. Default is 1 minute (PT1M).')
  lockDuration: string?

  @description('Optional. Maximum number of deliveries before dead-lettering. Default is 10.')
  maxDeliveryCount: int?

  @description('Optional. Enable dead-lettering when messages expire. Default is true.')
  deadLetteringOnMessageExpiration: bool?

  @description('Optional. Require duplicate detection. Default is false.')
  requiresDuplicateDetection: bool?

  @description('Optional. Enable session support on the queue. Default is false.')
  requiresSession: bool?

  @description('Optional. Enable partitioning across message brokers. Default is false.')
  enablePartitioning: bool?
}

// ============================================================================
// Resources
// ============================================================================

module queue '../../bicep-registry-modules/avm/res/service-bus/namespace/queue/main.bicep' = {
  name: 'ServiceBusQueue-${serviceBusQueue.name}-${dateTime}'
  params: {
    namespaceName: serviceBusQueue.namespaceName
    name: serviceBusQueue.name
    maxSizeInMegabytes: serviceBusQueue.?maxSizeInMegabytes ?? 1024
    defaultMessageTimeToLive: serviceBusQueue.?defaultMessageTimeToLive ?? 'P14D'
    lockDuration: serviceBusQueue.?lockDuration ?? 'PT1M'
    maxDeliveryCount: serviceBusQueue.?maxDeliveryCount ?? 10
    deadLetteringOnMessageExpiration: serviceBusQueue.?deadLetteringOnMessageExpiration ?? true
    requiresDuplicateDetection: serviceBusQueue.?requiresDuplicateDetection ?? false
    requiresSession: serviceBusQueue.?requiresSession ?? false
    enablePartitioning: serviceBusQueue.?enablePartitioning ?? false
    enableBatchedOperations: true
    enableTelemetry: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Service Bus Queue.')
output name string = queue.outputs.name

@description('The resource ID of the deployed Service Bus Queue.')
output resourceId string = queue.outputs.resourceId
