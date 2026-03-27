// ============================================================================
// Naming Conventions
// Centralized resource naming for all PlatyPal-generated Azure deployments.
//
// Usage:
//   var names = resourceNames(organisationSuffix, integrationId, regionSuffix, environmentSuffix)
//   var sharedNames = sharedResourceNames(organisationSuffix, regionSuffix, environmentSuffix)
//
// This module uses Bicep user-defined functions to provide a single source
// of truth for all resource naming patterns. It eliminates duplicated naming
// logic across templates and the C# code generator.
// ============================================================================

// ── Resource Abbreviation Map ──────────────────────────────────────────────
// These follow the Azure Cloud Adoption Framework (CAF) naming conventions
// where available, with project-specific additions.

@export()
@description('Generates all resource names for a given integration project.')
func resourceNames(
  organisationSuffix string,
  integrationId string,
  regionSuffix string,
  environmentSuffix string,
  separator string
) object => {
  // Base building blocks
  resourceBaseName: toLower('${organisationSuffix}${separator}int${separator}${integrationId}')
  resourceEnding: toLower('${regionSuffix}${separator}${environmentSuffix}')

  // Compute
  logicApp: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-la-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  functionApp: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-fa-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Storage (special: no dashes, uses uniqueString)
  storageAccount: 'st${uniqueString(organisationSuffix, integrationId, environmentSuffix)}'

  // Messaging
  serviceBusNamespace: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-sbns-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  eventHubNamespace: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-ehns-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Security
  keyVault: keyVaultName(
    '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-kv-${toLower('${regionSuffix}${separator}${environmentSuffix}')}',
    '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-kv-${toLower(environmentSuffix)}'
  )
  managedIdentity: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-id-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Monitoring
  logAnalyticsWorkspace: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-law-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  applicationInsights: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-ai-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Integration
  apiManagement: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-apim-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  appServicePlanLogic: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-aspla-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  appServicePlanFunction: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-aspfa-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  dataFactory: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-df-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Database
  cosmosDb: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-cosmos-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  sqlServer: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-sql-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  redisCache: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-redis-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Containers
  containerAppEnvironment: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-cae-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Networking
  virtualNetwork: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-vnet-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'

  // Resource Group
  resourceGroup: '${toLower('${organisationSuffix}${separator}int${separator}${integrationId}')}-rg-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
}

@export()
@description('Generates the shared resource group names (used for cross-references from integration/api/powerplatform templates).')
func sharedResourceNames(
  organisationSuffix string,
  sharedIdentifier string,
  regionSuffix string,
  environmentSuffix string,
  separator string
) object => {
  resourceBaseName: toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')
  resourceEnding: toLower('${regionSuffix}${separator}${environmentSuffix}')

  // Security
  keyVault: keyVaultName(
    '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-kv-${toLower('${regionSuffix}${separator}${environmentSuffix}')}',
    '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-kv-${toLower(environmentSuffix)}'
  )

  // Resources commonly referenced from integration templates
  serviceBusNamespace: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-sbns-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  eventHubNamespace: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-ehns-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  apiManagement: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-apim-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  applicationInsights: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-ai-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  appServicePlanLogic: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-aspla-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  appServicePlanFunction: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-aspfa-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
  storageAccount: 'st${uniqueString(organisationSuffix, sharedIdentifier, environmentSuffix)}'
  resourceGroup: '${toLower('${organisationSuffix}${separator}int${separator}${sharedIdentifier}')}-rg-${toLower('${regionSuffix}${separator}${environmentSuffix}')}'
}

@export()
@description('Generates Power Platform-specific resource names (uses -pp- segment instead of -int-).')
func powerPlatformResourceNames(
  organisationSuffix string,
  integrationId string,
  regionSuffix string,
  environmentSuffix string
) object => {
  resourceBaseName: toLower('${organisationSuffix}-pp-${integrationId}')
  resourceEnding: toLower('${regionSuffix}-${environmentSuffix}')
}

@export()
@description('Generates NSG and subnet names for the network template.')
func networkNames(resourceBaseName string, resourceEnding string) object => {
  nsgNames: {
    apim: '${resourceBaseName}-nsg-apim-${resourceEnding}'
    logicapp: '${resourceBaseName}-nsg-logicapp-${resourceEnding}'
    functionapp: '${resourceBaseName}-nsg-functionapp-${resourceEnding}'
    privateendpoints: '${resourceBaseName}-nsg-pe-${resourceEnding}'
    defaultSubnet: '${resourceBaseName}-nsg-default-${resourceEnding}'
  }
  subnetNames: {
    apim: 'snet-apim'
    logicapp: 'snet-logicapp'
    functionapp: 'snet-functionapp'
    privateendpoints: 'snet-privateendpoints'
    defaultSubnet: 'snet-default'
  }
}

@export()
@description('Generates Nodinite logging resource names.')
func nodiniteNames(organisationSuffix string, environmentSuffix string) object => {
  storageAccount: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}')
}

// ── Internal Helpers ───────────────────────────────────────────────────────

@description('Handles the Key Vault 24-character name limit by falling back to a shorter name without the region suffix.')
func keyVaultName(fullName string, shortName string) string =>
  length(fullName) <= 24 ? fullName : shortName
