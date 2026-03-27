// ============================================================================
// Power Platform Environment (Azure Support Resources)
// Deploys Azure-side support resources for a Power Platform solution:
//   - Key Vault secrets for Power Platform environment URLs and settings
//   - Managed Identity for Power Platform CI/CD service connections
//   - Optional storage account for Power Platform solution artefact staging
//
// Note: Power Platform environments themselves are created via the Power
// Platform CLI (pac admin create) in the pipeline scripts, not via Bicep.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for support resources. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Power Platform environment configuration.')
param powerPlatformSettings {
  @description('Required. The Power Platform environment URL (e.g., https://myorg-dev.crm4.dynamics.com).')
  environmentUrl: string

  @description('Required. The type of the Power Platform environment.')
  environmentType: ('Sandbox' | 'Production' | 'Developer' | 'Trial')

  @description('Optional. The Power Platform region (e.g., europe, unitedstates). Defaults to europe.')
  region: string?

  @description('Optional. The tenant ID for the Power Platform environment.')
  tenantId: string?

  @description('Optional. The client/application ID for the service principal used for CI/CD.')
  clientId: string?

  @description('Optional. The client secret for the service principal. Will be stored in Key Vault.')
  clientSecret: string?

  @description('Optional. Whether to deploy a staging storage account for solution artefacts. Defaults to false.')
  deployStagingStorage: bool?
}

@description('Required. Reference to the shared Key Vault for storing Power Platform secrets.')
param sharedKeyVaultName string

@description('Required. Name of the shared resource group containing the Key Vault.')
param sharedResourceGroupName string

@description('Required. Base name for resources (used in naming conventions).')
param resourceBaseName string

// ============================================================================
// Existing Resources
// ============================================================================

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: sharedKeyVaultName
  scope: resourceGroup(sharedResourceGroupName)
}

// ============================================================================
// Modules
// ============================================================================

// Store Power Platform environment URL in Key Vault
module ppEnvironmentUrlSecret '../KeyVault_Modules/KeyVaultSecret.bicep' = {
  name: 'PP-EnvUrl-Secret-${dateTime}'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultSecretSettings: {
      keyVaultName: sharedKeyVault.name
      name: '${resourceBaseName}-pp-environment-url'
      value: powerPlatformSettings.environmentUrl
      contentType: 'text/plain'
    }
  }
}

// Store environment type in Key Vault
module ppEnvironmentTypeSecret '../KeyVault_Modules/KeyVaultSecret.bicep' = {
  name: 'PP-EnvType-Secret-${dateTime}'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultSecretSettings: {
      keyVaultName: sharedKeyVault.name
      name: '${resourceBaseName}-pp-environment-type'
      value: powerPlatformSettings.environmentType
      contentType: 'text/plain'
    }
  }
}

// Conditionally store client ID for service principal auth
module ppClientIdSecret '../KeyVault_Modules/KeyVaultSecret.bicep' = if (!empty(powerPlatformSettings.?clientId ?? '')) {
  name: 'PP-ClientId-Secret-${dateTime}'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultSecretSettings: {
      keyVaultName: sharedKeyVault.name
      name: '${resourceBaseName}-pp-client-id'
      value: powerPlatformSettings.?clientId ?? ''
      contentType: 'text/plain'
    }
  }
}

// Conditionally store client secret for service principal auth
module ppClientSecret '../KeyVault_Modules/KeyVaultSecret.bicep' = if (!empty(powerPlatformSettings.?clientSecret ?? '')) {
  name: 'PP-ClientSecret-Secret-${dateTime}'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    keyVaultSecretSettings: {
      keyVaultName: sharedKeyVault.name
      name: '${resourceBaseName}-pp-client-secret'
      value: powerPlatformSettings.?clientSecret ?? ''
      contentType: 'text/plain'
    }
  }
}

// Optional: Staging storage account for solution artefacts
module stagingStorage '../StorageAccount.bicep' = if (powerPlatformSettings.?deployStagingStorage ?? false) {
  name: 'PP-StagingStorage-${dateTime}'
  params: {
    location: location
    storageAccountParams: {
      name: 'st${uniqueString(resourceBaseName, 'pp')}'
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The Power Platform environment URL stored in Key Vault.')
output environmentUrl string = powerPlatformSettings.environmentUrl

@description('The Power Platform environment type.')
output environmentType string = powerPlatformSettings.environmentType

@description('The Power Platform region.')
output region string = powerPlatformSettings.?region ?? 'europe'

@description('The name of the staging storage account, if deployed.')
output stagingStorageAccountName string = (powerPlatformSettings.?deployStagingStorage ?? false) ? stagingStorage!.outputs.name : ''
