// ============================================================================
// Key Vault Secret
// Deploys a secret into an existing Key Vault. Uses the AVM registry module.
// Used by integration and Power Platform templates to store connection strings,
// environment URLs, client credentials, and other sensitive configuration.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Key Vault Secret configuration.')

param keyVaultSecretSettings {
  @description('Required. Name of the existing Key Vault to store the secret in.')
  keyVaultName: string

  @description('Required. Name of the secret (letters, numbers, and hyphens; 1-127 characters).')
  @minLength(1)
  @maxLength(127)
  name: string

  @description('Required. The secret value.')
  @secure()
  value: string

  @description('Optional. Content type tag for the secret (e.g., "text/plain", "application/json").')
  contentType: string?

  @description('Optional. Whether the secret is enabled. Defaults to true.')
  enabled: bool?

  @description('Optional. Expiry date in seconds since 1970-01-01T00:00:00Z.')
  expirationDate: int?

  @description('Optional. Not-before date in seconds since 1970-01-01T00:00:00Z.')
  notBeforeDate: int?
}

// ============================================================================
// Modules
// ============================================================================

module secret '../../bicep-registry-modules/avm/res/key-vault/vault/secret/main.bicep' = {
  name: 'KeyVaultSecret-${keyVaultSecretSettings.name}-${dateTime}'
  params: {
    keyVaultName: keyVaultSecretSettings.keyVaultName
    name: keyVaultSecretSettings.name
    value: keyVaultSecretSettings.value
    contentType: keyVaultSecretSettings.?contentType
    attributesEnabled: keyVaultSecretSettings.?enabled ?? true
    attributesExp: keyVaultSecretSettings.?expirationDate
    attributesNbf: keyVaultSecretSettings.?notBeforeDate
    enableTelemetry: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed secret.')
output name string = secret.outputs.name

@description('The resource ID of the deployed secret.')
output resourceId string = secret.outputs.resourceId
