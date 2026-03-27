// ============================================================================
// Data Factory Linked Service – Azure Key Vault
// Connects Data Factory to an Azure Key Vault for secret retrieval.
// Uses the Data Factory system-assigned or user-assigned managed identity.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the linked service to create.')
param linkedServiceName string

@description('Required. Key Vault linked service configuration.')
param keyVaultSettings {
  @description('Required. Base URL of the Azure Key Vault (e.g. https://myvault.vault.azure.net).')
  baseUrl: string

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
    type: 'AzureKeyVault'
    description: keyVaultSettings.?description ?? 'Azure Key Vault linked service'
    typeProperties: {
      baseUrl: keyVaultSettings.baseUrl
      credential: keyVaultSettings.?credentialResourceId != null
        ? {
            referenceName: 'UserAssignedManagedIdentity'
            type: 'CredentialReference'
          }
        : null
    }
  }
}
