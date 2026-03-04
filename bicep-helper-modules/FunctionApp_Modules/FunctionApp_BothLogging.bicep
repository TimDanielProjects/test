// ============================================================================
// Function App — Both Nodinite + Application Insights
// Internal sub-module called by FunctionApp.bicep. Do not use directly.
// ============================================================================

@description('Required. Azure region for the Function App.')
param location string

@description('Required. Name of the Function App.')
param functionAppName string

@description('Required. Resource ID of the App Service Plan.')
param serverFarmResourceId string

@description('Required. Merged environment variables (base + custom) as an object.')
param functionAppSettings object

@description('Required. Resource ID of the Application Insights instance.')
param applicationInsightResourceId string

@description('Required. Shared resources object containing Event Hub namespace info for Nodinite diagnostic settings.')
param sharedResources object

var appInsightsSettings = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(applicationInsightResourceId, '2020-02-02').InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: reference(applicationInsightResourceId, '2020-02-02').ConnectionString
  }
]

var baseAppSettings = [for item in items(functionAppSettings): {
  name: item.key
  value: item.value
}]

resource functionAppWithBothLogging 'Microsoft.Web/sites@2023-01-01' = {
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
      appSettings: concat(baseAppSettings, appInsightsSettings)
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'nodiniteDiagnosticSetting'
  scope: functionAppWithBothLogging
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

output functionAppName string = functionAppWithBothLogging.name
output functionAppId string = functionAppWithBothLogging.id
output systemAssignedPrincipalId string = functionAppWithBothLogging.identity.principalId
output defaultHostname string = functionAppWithBothLogging.properties.defaultHostName
