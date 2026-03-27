// ============================================================================
// Function App — Core Deployment
// Single unified module handling all logging combinations conditionally.
// Called by FunctionApp.bicep with feature flags for logging providers.
//
// Replaces the previous four separate files:
//   - FunctionApp_NoLogging.bicep
//   - FunctionApp_AppInsightsOnly.bicep
//   - FunctionApp_NodiniteOnly.bicep
//   - FunctionApp_BothLogging.bicep
// ============================================================================

@description('Required. Azure region for the Function App.')
param location string

@description('Required. Name of the Function App.')
param functionAppName string

@description('Required. Resource ID of the App Service Plan.')
param serverFarmResourceId string

@description('Required. Merged environment variables (base + custom) as an object.')
param functionAppSettings object

@description('Optional. Enable Application Insights logging. When true, App Insights instrumentation settings are added to the app configuration.')
param enableAppInsights bool = false

@description('Optional. Resource ID of the Application Insights instance. Required when enableAppInsights is true.')
param applicationInsightResourceId string = ''

@description('Optional. Enable Nodinite diagnostic logging (FunctionAppLogs → Event Hub).')
param enableNodinite bool = false

@description('Optional. Shared resources object containing Event Hub namespace info for Nodinite diagnostic settings. Required when enableNodinite is true.')
param sharedResources object = {}

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

var baseAppSettings = [for item in items(functionAppSettings): {
  name: item.key
  value: item.value
}]

var allAppSettings = empty(appInsightsSettings) ? baseAppSettings : concat(baseAppSettings, appInsightsSettings)

// ============================================================================
// Resources
// ============================================================================

resource functionApp 'Microsoft.Web/sites@2025-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmResourceId
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      ftpsState: 'Disabled'
      netFrameworkVersion: 'v9.0'
      alwaysOn: true
      minTlsVersion: '1.2'
      http20Enabled: true
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      remoteDebuggingEnabled: false
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      appSettings: allAppSettings
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableNodinite) {
  name: 'nodiniteDiagnosticSetting'
  scope: functionApp
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
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Function App.')
output functionAppName string = functionApp.name

@description('The resource ID of the deployed Function App.')
output functionAppId string = functionApp.id

@description('The system-assigned managed identity principal ID.')
output systemAssignedPrincipalId string = functionApp.identity.principalId

@description('The default hostname of the deployed Function App.')
output defaultHostname string = functionApp.properties.defaultHostName
