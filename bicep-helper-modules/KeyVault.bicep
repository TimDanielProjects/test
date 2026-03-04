// ============================================================================
// Key Vault
// Deploys an Azure Key Vault with RBAC authorization, optional soft delete,
// purge protection, and secret seeding. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for the Key Vault. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Key Vault configuration.')
param keyVaultSettings {
  @description('Required. Name of the Key Vault. Must be globally unique (3-24 alphanumeric characters and hyphens).')
  name: string

  @description('Optional. SKU family of the Key Vault. Defaults to standard.')
  skuFamily: ('standard' | 'premium')?

  @description('Optional. Whether soft delete is enabled. Defaults to true.')
  enableSoftDelete: bool?

  @description('Optional. Number of days to retain soft-deleted vaults (7-90). Defaults to 90.')
  softDeleteRetentionInDays: int?

  @description('Optional. Whether purge protection is enabled. Cannot be disabled once enabled. Defaults to true.')
  enablePurgeProtection: bool?

  @description('Optional. Whether RBAC authorization is used instead of vault access policies. Defaults to true.')
  enableRbacAuthorization: bool?

  @description('Optional. Whether the vault can be accessed from public networks. Defaults to Enabled.')
  publicNetworkAccess: ('Enabled' | 'Disabled')?

  @description('Optional. Array of secrets to seed into the Key Vault on creation.')
  secrets: {
    @description('Required. Name of the secret.')
    name: string

    @description('Required. Value of the secret.')
    value: string
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module keyVault '../bicep-registry-modules/avm/res/key-vault/vault/main.bicep' = {
  name: 'KeyVault-${dateTime}'
  params: {
    name: keyVaultSettings.name
    location: location
    sku: keyVaultSettings.?skuFamily ?? 'standard'
    enableSoftDelete: keyVaultSettings.?enableSoftDelete ?? true
    softDeleteRetentionInDays: keyVaultSettings.?softDeleteRetentionInDays ?? 90
    enablePurgeProtection: keyVaultSettings.?enablePurgeProtection ?? true
    enableRbacAuthorization: keyVaultSettings.?enableRbacAuthorization ?? true
    publicNetworkAccess: keyVaultSettings.?publicNetworkAccess ?? 'Enabled'
    secrets: [
      for secret in (keyVaultSettings.?secrets ?? []): {
        name: secret.name
        value: secret.value
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Key Vault.')
output name string = keyVault.outputs.name

@description('Resource ID of the deployed Key Vault.')
output resourceId string = keyVault.outputs.resourceId

@description('URI of the Key Vault (e.g. https://<name>.vault.azure.net/).')
output uri string = keyVault.outputs.uri
