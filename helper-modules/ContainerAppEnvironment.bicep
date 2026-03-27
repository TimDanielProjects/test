// ============================================================================
// Container App Environment
// Deploys an Azure Container App Environment (managed Kubernetes environment)
// with optional Log Analytics workspace integration and VNet configuration.
// Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Container App Environment configuration.')
param containerAppEnvironmentSettings {
  @description('Required. Name of the Container App Environment.')
  name: string

  @description('Optional. Tags to apply to the resource.')
  tags: object?

  @description('Optional. Resource ID of the Log Analytics Workspace for container logs.')
  logAnalyticsWorkspaceResourceId: string?

  @description('Optional. Whether the environment is internal-only (no public ingress). Defaults to false.')
  internal: bool?

  @description('Optional. Resource ID of the VNet subnet for the environment infrastructure.')
  infrastructureSubnetResourceId: string?

  @description('Optional. Whether zone redundancy is enabled. Defaults to false.')
  zoneRedundant: bool?
}

// ============================================================================
// Modules
// ============================================================================

module containerAppEnvironment '../bicep-registry-modules/avm/res/app/managed-environment/main.bicep' = {
  name: 'ContainerAppEnv-${dateTime}'
  params: {
    name: containerAppEnvironmentSettings.name
    location: location
    tags: containerAppEnvironmentSettings.?tags
    appLogsConfiguration: containerAppEnvironmentSettings.?logAnalyticsWorkspaceResourceId != null
      ? {
          destination: 'log-analytics'
          logAnalyticsWorkspaceResourceId: containerAppEnvironmentSettings.logAnalyticsWorkspaceResourceId!
        }
      : {
          destination: 'azure-monitor'
        }
    internal: containerAppEnvironmentSettings.?internal ?? false
    infrastructureSubnetResourceId: containerAppEnvironmentSettings.?infrastructureSubnetResourceId
    zoneRedundant: containerAppEnvironmentSettings.?zoneRedundant ?? false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Container App Environment.')
output name string = containerAppEnvironment.outputs.name

@description('Resource ID of the deployed Container App Environment.')
output resourceId string = containerAppEnvironment.outputs.resourceId

@description('Default domain of the Container App Environment.')
output defaultDomain string = containerAppEnvironment.outputs.defaultDomain
