// ============================================================================
// Data Factory Linked Service – Azure Blob Storage
// Connects Data Factory to an Azure Blob Storage account using either a
// managed identity (recommended) or a connection string.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the linked service to create.')
param linkedServiceName string

@description('Required. Blob Storage linked service configuration.')
param blobStorageSettings {
  @description('Required. The URL of the Azure Blob Storage account (e.g. https://mystorageaccount.blob.core.windows.net).')
  serviceEndpoint: string

  @description('Optional. Authentication type. Defaults to system-assigned managed identity.')
  authenticationType: ('ManagedIdentity' | 'ConnectionString')?

  @description('Optional. Connection string. Required when authenticationType is ConnectionString. Can reference a Key Vault secret with @Microsoft.KeyVault(...).')
  connectionString: string?

  @description('Optional. Resource ID of a user-assigned managed identity. Leave empty to use the Data Factory system-assigned identity.')
  credentialResourceId: string?

  @description('Optional. Description of the linked service.')
  description: string?
}

// ============================================================================
// Resources
// ============================================================================

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: linkedServiceName
  properties: {
    type: 'AzureBlobStorage'
    description: blobStorageSettings.?description ?? 'Azure Blob Storage linked service'
    typeProperties: blobStorageSettings.?authenticationType == 'ConnectionString'
      ? {
          connectionString: blobStorageSettings.connectionString!
        }
      : {
          serviceEndpoint: blobStorageSettings.serviceEndpoint
          credential: blobStorageSettings.?credentialResourceId != null
            ? {
                referenceName: 'UserAssignedManagedIdentity'
                type: 'CredentialReference'
              }
            : null
        }
  }
}
