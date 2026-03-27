// ============================================================================
// Application Insights
// Deploys an Application Insights instance backed by a Log Analytics Workspace.
// Optionally creates the workspace if one doesn't exist already.
// Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for the resource. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Application Insights configuration.')
param applicationInsightsSettings {
  @description('Required. Name of the Application Insights resource.')
  name: string

  @description('Optional. The kind of application this component refers to. Defaults to web.')
  kind: ('web' | 'ios' | 'other' | 'store' | 'java' | 'phone')?

  @description('Optional. Type of application being monitored. Defaults to web.')
  applicationType: ('web' | 'other')?

  @description('Required. Resource ID of the Log Analytics Workspace to link to.')
  workspaceResourceId: string

  @description('Optional. Number of days to retain data. Defaults to 90.')
  retentionInDays: (30 | 60 | 90 | 120 | 180 | 270 | 365 | 550 | 730)?

  @description('Optional. Percentage of data to sample (0-100). Defaults to 100 (all data).')
  samplingPercentage: int?

  @description('Optional. Disable IP masking to see real client IPs. Defaults to false.')
  disableIpMasking: bool?
}

// ============================================================================
// Modules
// ============================================================================

module applicationInsights '../bicep-registry-modules/avm/res/insights/component/main.bicep' = {
  name: 'ApplicationInsights-${dateTime}'
  params: {
    name: applicationInsightsSettings.name
    location: location
    kind: applicationInsightsSettings.?kind ?? 'web'
    applicationType: applicationInsightsSettings.?applicationType ?? 'web'
    workspaceResourceId: applicationInsightsSettings.workspaceResourceId
    retentionInDays: applicationInsightsSettings.?retentionInDays ?? 90
    samplingPercentage: applicationInsightsSettings.?samplingPercentage ?? 100
    disableIpMasking: applicationInsightsSettings.?disableIpMasking ?? false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Application Insights resource.')
output name string = applicationInsights.outputs.name

@description('Resource ID of the deployed Application Insights resource.')
output resourceId string = applicationInsights.outputs.resourceId

@description('Instrumentation key for the Application Insights resource.')
output instrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('Connection string for the Application Insights resource.')
output connectionString string = applicationInsights.outputs.connectionString
