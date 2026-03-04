// ============================================================================
// Logic App Standard — Core Deployment
// Single unified module handling all logging combinations conditionally.
// Called by LogicAppStandard.bicep with feature flags for logging providers.
//
// Replaces the previous four separate files:
//   - LogicAppStandard_NoLogging.bicep
//   - LogicAppStandard_AppInsightsOnly.bicep
//   - LogicAppStandard_NodiniteOnly.bicep
//   - LogicAppStandard_BothLogging.bicep
// ============================================================================

@description('Required. Azure region for the Logic App.')
param location string

@description('Required. Name of the Logic App Standard.')
param logicAppName string

@description('Required. Resource ID of the App Service Plan.')
param serverFarmResourceId string

@description('Required. Merged environment variables (base + custom) as an object.')
param logicAppSettings object

@description('Optional. Enable Application Insights logging. When true, App Insights instrumentation settings are added to the app configuration.')
param enableAppInsights bool = false

@description('Optional. Resource ID of the Application Insights instance. Required when enableAppInsights is true.')
param applicationInsightResourceId string = ''

@description('Optional. Enable Nodinite diagnostic logging (WorkflowRuntime logs → Event Hub).')
param enableNodinite bool = false

@description('Optional. Shared resources object containing Event Hub namespace info for Nodinite diagnostic settings. Required when enableNodinite is true.')
param sharedResources object = {}

@description('Optional. Enable Azure Arc (Kubernetes) hosting. Changes the Logic App kind and adds extendedLocation.')
param isArcEnabled bool = false

@description('Optional. Custom Location resource ID for Azure Arc deployment. Required when isArcEnabled is true.')
param customLocationResourceId string = ''

// ============================================================================
// Variables
// ============================================================================

var appInsightsSettings = enableAppInsights && !empty(applicationInsightResourceId) ? [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(applicationInsightResourceId, '2020-02-02').InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: reference(applicationInsightResourceId, '2020-02-02').ConnectionString
  }
] : []

var baseAppSettings = [for item in items(logicAppSettings): {
  name: item.key
  value: item.value
}]

var allAppSettings = empty(appInsightsSettings) ? baseAppSettings : concat(baseAppSettings, appInsightsSettings)

// ============================================================================
// Resources
// ============================================================================

resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  kind: isArcEnabled ? 'functionapp,workflowapp,kubernetes' : 'functionapp,workflowapp'
  #disable-next-line BCP073
  extendedLocation: isArcEnabled && !empty(customLocationResourceId) ? {
    name: customLocationResourceId
    type: 'CustomLocation'
  } : null
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmResourceId
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      functionsRuntimeScaleMonitoringEnabled: false
      ftpsState: 'Disabled'
      appSettings: allAppSettings
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableNodinite) {
  name: 'nodiniteDiagnosticSetting'
  scope: logicApp
  properties: {
    eventHubAuthorizationRuleId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${sharedResources.sharedResourceGroupName}/providers/microsoft.eventhub/namespaces/${sharedResources.sharedEventHubsNamespaceName}/authorizationrules/RootManageSharedAccessKey'
    eventHubName: 'nodinitelogevents'
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
      }
    ]
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Logic App.')
output logicAppName string = logicApp.name

@description('The resource ID of the deployed Logic App.')
output logicAppId string = logicApp.id

@description('The system-assigned managed identity principal ID.')
output systemAssignedPrincipalId string = logicApp.identity.principalId

@description('The HTTPS URL of the deployed Logic App.')
output logicAppUrl string = 'https://${logicApp.properties.defaultHostName}'
