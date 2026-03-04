// ============================================================================
// Storage Account
// Deploys a general-purpose v2 Storage Account with system-assigned managed
// identity. Used for Logic App / Function App storage, claim-check pattern, etc.
// ============================================================================

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. Storage Account configuration.')
param storageAccountParams {
  @description('Required. Name of the Storage Account. Must be globally unique, 3-24 lowercase alphanumeric characters.')
  name: string

  @description('Optional. The SKU/redundancy level.')
  skuName: string?

  @description('Optional. The access tier for blob storage.')
  accessTier: ('Hot' | 'Cool' | 'Cold' | 'Premium')?

  @description('Optional. Enable hierarchical namespace for Azure Data Lake Storage Gen2.')
  isHnsEnabled: bool?

  @description('Optional. Enable SSH File Transfer Protocol (SFTP) access. Requires hierarchical namespace (HNS).')
  isSftpEnabled: bool?

  @description('Optional. Allow anonymous public read access to blob data.')
  allowBlobPublicAccess: bool?

  @description('Optional. Allow access via storage account keys. Disable to enforce Entra ID authentication only.')
  allowSharedKeyAccess: bool?

  @description('Optional. Default network access rule. Set to Deny to restrict access to allowed networks only.')
  networkDefaultAction: ('Allow' | 'Deny')?

  @description('Optional. List of blob container names to create in the storage account.')
  blobContainers: array?
}

// ============================================================================
// Variables (resolve optional params to defaults)
// ============================================================================

var skuName = storageAccountParams.?skuName ?? 'Standard_LRS'
var accessTier = storageAccountParams.?accessTier ?? 'Hot'
var isHnsEnabled = storageAccountParams.?isHnsEnabled ?? true
var isSftpEnabled = storageAccountParams.?isSftpEnabled ?? false
var allowBlobPublicAccess = storageAccountParams.?allowBlobPublicAccess ?? false
var allowSharedKeyAccess = storageAccountParams.?allowSharedKeyAccess ?? true
var networkDefaultAction = storageAccountParams.?networkDefaultAction ?? 'Allow'
var blobContainers = storageAccountParams.?blobContainers ?? []

// ============================================================================
// Resources
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountParams.name
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    largeFileSharesState: 'Enabled'
    defaultToOAuthAuthentication: true
    supportsHttpsTrafficOnly: true
    isHnsEnabled: isHnsEnabled
    isSftpEnabled: isSftpEnabled
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: networkDefaultAction
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = if (!empty(blobContainers)) {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for container in blobContainers: {
  parent: blobService
  name: container
  properties: {}
}]

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Storage Account.')
output name string = storageAccount.name

@description('The resource ID of the deployed Storage Account.')
output resourceId string = storageAccount.id

@description('The system-assigned managed identity principal ID.')
output principalId string = storageAccount.identity.principalId
