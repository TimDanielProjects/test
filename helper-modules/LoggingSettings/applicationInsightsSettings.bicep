// ============================================================================
// Application Insights Settings
// Deploys Log Analytics Workspace, Application Insights, APIM logger, and
// diagnostic settings on Service Bus and Storage Account.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Required. Application Insights shared infrastructure settings.')
param applicationInsightsSettings {
  @description('Required. Name for the Application Insights resource.')
  applicationInsightsName: string

  @description('Required. Name for the Log Analytics Workspace.')
  logAnalyticsName: string

  @description('Required. Name of the existing API Management instance to configure the logger on.')
  apiManagementServiceName: string

  @description('Required. Name of the existing Service Bus Namespace to enable diagnostic settings on.')
  serviceBusNamespaceName: string

  @description('Required. Name of the existing Storage Account to enable diagnostic settings on.')
  storageAccountName: string
}

// ============================================================================
// Modules – Logging Infrastructure
// ============================================================================

// Log Analytics Workspace
module logAnalyticsWorkspace '../../helper-modules/LogAnalyticsWorkspace.bicep' = {
  name: 'LogAnalytics-Main-${dateTime}'
  params: {
    logAnalyticsname: applicationInsightsSettings.logAnalyticsName
  }
}

// Application Insights
module ai '../../bicep-registry-modules/avm/res/insights/component/main.bicep' = {
  name: 'ApplicationInsights-${dateTime}'
  params: {
    name: applicationInsightsSettings.applicationInsightsName
    workspaceResourceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
  }
}

// APIM Logger → Application Insights
module applicationInsightsAPIMSettings '../../bicep-registry-modules/avm/res/api-management/service/logger/main.bicep' = {
  name: 'ApplicationInsightsAPIMSettings-${dateTime}'
  params: {
    name: 'applicationInsightsAPIMLogger'
    apiManagementServiceName: applicationInsightsSettings.apiManagementServiceName
    credentials: {
      instrumentationKey: ai.outputs.instrumentationKey
    }
    targetResourceId: ai.outputs.resourceId
    type: 'applicationInsights'
    description: 'Application Insights logger'
  }
}

// Diagnostic settings on existing Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: applicationInsightsSettings.serviceBusNamespaceName
}

resource serviceBus_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'ServiceBusDiagnosticSetting'
  scope: serviceBusNamespace
  properties: {
    workspaceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
    logs: [
      {
        category: 'OperationalLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
      }
    ]
  }
}

// Diagnostic settings on existing Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: applicationInsightsSettings.storageAccountName
}

resource storage_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'StorageDiagnosticSetting'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.outputs.logAnalyticsResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource ID of the deployed Application Insights instance.')
output applicationInsightsResourceId string = ai.outputs.resourceId

@description('Instrumentation key of the deployed Application Insights instance.')
output applicationInsightsInstrumentationKey string = ai.outputs.instrumentationKey

@description('Resource ID of the deployed Log Analytics Workspace.')
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.logAnalyticsResourceId
