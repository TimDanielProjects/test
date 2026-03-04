// ============================================================================
// User-Assigned Managed Identity
// Deploys a user-assigned managed identity that can be used for RBAC-based
// access to Azure resources. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for the managed identity. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Name of the user-assigned managed identity.')
param name string

@description('Optional. Tags to apply to the managed identity resource.')
param tags object?

// ============================================================================
// Modules
// ============================================================================

module managedIdentity '../bicep-registry-modules/avm/res/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'ManagedIdentity-${dateTime}'
  params: {
    name: name
    location: location
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed managed identity.')
output name string = managedIdentity.outputs.name

@description('Resource ID of the deployed managed identity.')
output resourceId string = managedIdentity.outputs.resourceId

@description('Principal (object) ID of the managed identity.')
output principalId string = managedIdentity.outputs.principalId

@description('Client ID of the managed identity.')
output clientId string = managedIdentity.outputs.clientId
