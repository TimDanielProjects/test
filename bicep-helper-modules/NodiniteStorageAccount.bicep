// ============================================================================
// Nodinite Storage Account
// Deploys a dedicated Storage Account for Nodinite logging with three
// pre-configured blob containers: APIM logs, Function App logs, and
// Event Hub checkpoint/capture data.
// ============================================================================

@description('Required. Name of the blob container for Nodinite APIM/general log events (e.g., "nodinitelogevents").')
param nodiniteLogging_blobName string

@description('Required. Name of the blob container for Nodinite Function App log events (e.g., "function-nodinitelogevents").')
param nodiniteLogging_FunctionBlobName string

@description('Required. Name of the blob container for Event Hub checkpoint and capture data (e.g., "eventhub-nodinitelogevents-checkpoint").')
param nodiniteLogging_EventHub_CheckpointCaptureContainerName string

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. Storage account name configuration.')
param storageAccountParams {
  @description('Required. Name of the storage account. Must be globally unique, 3-24 lowercase alphanumeric characters.')
  name: string
}

// ============================================================================
// Resources
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountParams.name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    defaultToOAuthAuthentication: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource blobContainer_1 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccount.name}/default/${nodiniteLogging_blobName}'
  properties: {}
}

resource blobContainer_2 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccount.name}/default/${nodiniteLogging_FunctionBlobName}'
  properties: {}
}

resource blobContainer_3 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccount.name}/default/${nodiniteLogging_EventHub_CheckpointCaptureContainerName}'
  properties: {}
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Nodinite Storage Account.')
output name string = storageAccount.name

@description('The resource ID of the deployed Nodinite Storage Account.')
output resourceId string = storageAccount.id
