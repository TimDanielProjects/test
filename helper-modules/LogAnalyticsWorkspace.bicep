// ============================================================================
// Log Analytics Workspace
// Deploys an Azure Log Analytics Workspace used as the data sink for
// Application Insights, diagnostic settings, and Azure Monitor.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. Name of the Log Analytics Workspace (e.g., "contoso-int-shared-law-sdc-dev").')
param logAnalyticsname string

@description('Optional. Number of days to retain data. Default is 30 days.')
param retentionInDays int = 30

// ============================================================================
// Resources
// ============================================================================

module Log '../bicep-registry-modules/avm/res/operational-insights/workspace/main.bicep' = {
  name: 'logAnalytics-${dateTime}'
  params: {
    location: location
    name: logAnalyticsname
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed Log Analytics Workspace.')
output logAnalyticsResourceId string = Log.outputs.resourceId

@description('The name of the deployed Log Analytics Workspace.')
output name string = Log.outputs.name
