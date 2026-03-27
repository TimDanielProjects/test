// ============================================================================
// Nodinite Settings
// Deploys the full Nodinite logging infrastructure: Event Hub, storage account,
// managed identity with RBAC, APIM update with user-assigned identity and
// named values, and the generic Nodinite logging policy fragment.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Nodinite logging configuration including storage, Event Hub, and capture settings.')
param NodiniteLoggingSettings {
  @description('Required. Name of the blob container for Nodinite log events (non-function resources).')
  nodiniteBlobContainerName: string

  @description('Required. Name of the Nodinite Storage Account for log persistence.')
  nodiniteStorageAccountName: string

  @description('Required. Name of the blob container for Function App Nodinite log events.')
  nodiniteFunctionBlobContainerName: string

  @description('Required. Event Hub configuration for Nodinite diagnostic event streaming.')
  EventHubSettings: {
    @description('Required. Name of the Event Hub Namespace.')
    eventHubNamespaceName: string

    @description('Required. Number of partitions for the Event Hub.')
    partitioncount: int

    @description('Required. Message retention in days for the Event Hub.')
    mmessageRetentionInDays: int

    @description('Required. Name of the Event Hub used for Nodinite logging.')
    nodiniteLoggingEventHubName: string

    @description('Required. Whether Event Hub capture is enabled.')
    captureDescriptionEnabled: bool

    @description('Required. Blob container name for Event Hub checkpoint and capture data.')
    captureDescriptionDestinationBlobContainer: string
  }
}

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for resource deployment. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. API Management instance settings (redeployed to add managed identity and named values).')
param APIMSettings {
  @description('Required. Name of the existing API Management instance.')
  name: string

  @description('Required. SKU tier of the API Management instance.')
  tier: 'Basic' | 'BasicV2' | 'Consumption' | 'Developer' | 'Premium' | 'Standard' | 'StandardV2' | null

  @description('Required. Publisher email address for the APIM instance.')
  publisherEmail: string

  @description('Required. Publisher name for the APIM instance.')
  publisherName: string
}

@description('Required. Environment suffix (e.g. dev, test, prod). Used in managed identity naming.')
param environmentSuffix string

// ============================================================================
// Modules – Nodinite Infrastructure
// ============================================================================

module eventhubsNamespace '../../helper-modules/EventHubNamespace.bicep' = {
  name: 'eventHubNamespace-Main-${dateTime}'
  params: {
    eventHubNamespaceName: NodiniteLoggingSettings.EventHubSettings.eventHubNamespaceName
    
  }
}

// Storage account for Nodinite logging
module nodiniteStorageAccount '../../helper-modules/NodiniteStorageAccount.bicep' = {
  name: 'StorageAccount-NodiniteLogging-Main-${dateTime}'
  params: {
    storageAccountParams: {
      name: NodiniteLoggingSettings.nodiniteStorageAccountName
    }
    nodiniteLogging_blobName: NodiniteLoggingSettings.nodiniteBlobContainerName
    nodiniteLogging_FunctionBlobName: NodiniteLoggingSettings.nodiniteFunctionBlobContainerName
    nodiniteLogging_EventHub_CheckpointCaptureContainerName: NodiniteLoggingSettings.EventHubSettings.captureDescriptionDestinationBlobContainer
  }
}

// Create managed identity for Nodinite
// Create managed identity for Nodinite (used for blob storage access from APIM)
module Nodinite_managedIdentity '../../bicep-registry-modules/avm/res/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'managedIdentity'
  params: {
    name: 'NodiniteManagedIdentity${environmentSuffix}'
  }
}

// Assign Storage Blob Data Contributor to the Nodinite managed identity
module Nodinite_RBAC '../AccessControlWithRBAC/Nodinite_RBAC.bicep' = {
  params: {
    RBACSettings: {
      NodiniteStorageAccountSettings: {
        storageAccountName: nodiniteStorageAccount.outputs.name
        roleAssignments: [
          {
            roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
            principalId: Nodinite_managedIdentity.outputs.principalId
            principalType: 'ServicePrincipal'
          }
        ]
      }
    }
  }
}

// Deploy Event Hub for Nodinite diagnostic event streaming
module NodiniteLogging_eh_la '../../bicep-registry-modules/avm/res/event-hub/namespace/eventhub/main.bicep' = {
  name: 'NodiniteLogging_eh_la-${dateTime}'
  params: {
    name: NodiniteLoggingSettings.EventHubSettings.nodiniteLoggingEventHubName
    namespaceName: NodiniteLoggingSettings.EventHubSettings.eventHubNamespaceName
    messageRetentionInDays: NodiniteLoggingSettings.EventHubSettings.mmessageRetentionInDays
    retentionDescriptionRetentionTimeInHours: 24* NodiniteLoggingSettings.EventHubSettings.mmessageRetentionInDays
    partitionCount: NodiniteLoggingSettings.EventHubSettings.partitioncount
    status: 'Active'
  }
}

// Update APIM with user-assigned managed identity and Nodinite named values
module apim '../../bicep-registry-modules/avm/res/api-management/service/main.bicep' = {
  name: 'apim-update_for_nodinite_logging${dateTime}'
  params: {
    location: location
    name: APIMSettings.name
    publisherEmail: APIMSettings.publisherEmail
    publisherName: APIMSettings.publisherName
    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        Nodinite_managedIdentity.outputs.resourceId
      ]
    }
    sku: APIMSettings.?tier
    namedValues: [
      {
        name: 'logging-blob-mid-client-id'
        displayName: 'logging-blob-mid-client-id'
        value: Nodinite_managedIdentity.outputs.clientId
      }
      {
        name: 'logging-blob-url'
        displayName: 'logging-blob-url'
        value: 'https://${NodiniteLoggingSettings.nodiniteStorageAccountName}.blob.${environment().suffixes.storage}/${NodiniteLoggingSettings.nodiniteBlobContainerName}/'
      }
    ]
  }
}

// ============================================================================
// APIM Policy Configuration
// ============================================================================

//Create the All API policy for logging to Nodinite
module allApiPolicy '../../bicep-registry-modules/avm/res/api-management/service/policy/main.bicep' = {
  name: 'allApiPolicy'
  dependsOn: [
    apim
    genericNodiniteLoggingPolicyFragmentLoadContent
  ]
  params: {
    format: 'rawxml'
    apiManagementServiceName: APIMSettings.name
    value: loadTextContent('../policies/allApiPolicy.xml')
  }
}
//Generic policy fragment for logging to Nodinite
resource genericNodiniteLoggingPolicyFragmentLoadContent 'Microsoft.ApiManagement/service/policyFragments@2024-06-01-preview' ={
  dependsOn: [
    apim
  ]
  name: '${APIMSettings.name}/genericNodiniteLoggingPolicyFragment'
  properties: {
    format: 'rawxml'
    description: 'Generic policy fragment for logging to Nodinite'
    value: loadTextContent('../policies/genericNodiniteLoggingPolicyFragment.xml')
  }
}
