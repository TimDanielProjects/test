// ============================================================================
// Logic App Standard
// Deploys an Azure Logic App Standard (workflow app) with conditional logging:
//   - Nodinite only (diagnostic settings → Event Hub)
//   - Application Insights only
//   - Both Nodinite + Application Insights
//   - No logging
// The logging variant is selected automatically based on the enabled flags.
// ============================================================================

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Enable Nodinite logging. "true" to send WorkflowRuntime diagnostic logs to Event Hub for Nodinite.')
@allowed(['true', 'false'])
param NodiniteLoggingEnabled string

@description('Required. Enable Application Insights logging. "true" to configure App Insights instrumentation.')
@allowed(['true', 'false'])
param ApplicationInsightsLoggingEnabled string

@description('Required. Organisation prefix used for Nodinite storage account naming convention (e.g., "co" for ContosoCompany).')
param organisationSuffix string

@description('Required. Environment identifier used for resource naming (e.g., "dev", "test", "prod").')
param environmentSuffix string

@description('Required. References to shared infrastructure resources deployed by the shared template.')
param sharedResources {
  @description('Required. Resource group name containing shared resources.')
  sharedResourceGroupName: string

  @description('Required. Name of the shared App Service Plan.')
  sharedAppServicePlanName: string

  @description('Required. Resource ID of the shared App Service Plan that will host this Logic App.')
  sharedAppServicePlanResourceId: string

  @description('Required. Name of the shared Event Hub Namespace (for Nodinite logging).')
  sharedEventHubsNamespaceName: string

  @description('Required. Resource ID of the shared Event Hub Namespace.')
  sharedEventHubsNamespaceResourceId: string

  @description('Required. Name of the shared API Management instance.')
  sharedAPIMName: string

  @description('Required. Name of the shared Service Bus Namespace.')
  sharedServiceBusNamespaceName: string

  @description('Required. Resource ID of the shared Service Bus Namespace.')
  sharedServiceBusNamespaceResourceId: string

  @description('Required. Name of the shared Key Vault.')
  sharedKeyVaultName: string

  @description('Required. Name of the shared Function App (Nodinite logger).')
  sharedFunctionAppName: string

  @description('Required. Name of the shared Application Insights instance.')
  sharedApplicationInsightsName: string
}

@description('Optional. Custom environment variables to add to the Logic App. These are merged with base settings (runtime, storage, Nodinite). Use an object where keys are setting names and values are setting values.')
param LogicAppEnvironmentVariables object = {}

@description('Optional. Enable Azure Arc (Kubernetes) hosting. Changes the Logic App kind and adds extendedLocation.')
param isArcEnabled bool = false

@description('Optional. Custom Location resource ID for Azure Arc deployment. Required when isArcEnabled is true.')
param customLocationResourceId string = ''

@description('Required. Storage Account used for Logic App runtime storage, secrets, and content share.')
param storageAccount {
  @description('Required. Resource ID of the storage account.')
  resourceId: string

  @description('Required. Name of the storage account.')
  name: string
}

@description('Required. Name of the Logic App Standard to create (e.g., "contoso-int-myint-la-sdc-dev").')
param logicAppName string

// ============================================================================
// Variables
// ============================================================================

var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}')
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents'
}

resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

resource logicAppStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccount.name
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

var logicAppStandardSettings = {
  // Logic App Standard runtime settings
  APP_KIND: 'workflowApp'
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'node'
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  subscriptionId: subscription().subscriptionId
  resourceGroupName: resourceGroup().name
  sharedResourceGroupName: sharedResources.sharedResourceGroupName
  location: location

  // Required storage settings for Logic App Standard runtime
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${logicAppStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  WEBSITE_CONTENTSHARE: toLower(logicAppName)
  AzureWebJobsSecretStorageType: 'Blob'

  // Nodinite logging parameters (passed regardless of logging method)
  NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
  NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
}

var logicAppCombinedVariables = union(
  logicAppStandardSettings,
  LogicAppEnvironmentVariables
)

// ============================================================================
// Module Deployment (unified — handles all logging combinations)
// ============================================================================

var enableNodinite = NodiniteLoggingEnabled == 'true'
var enableAppInsights = ApplicationInsightsLoggingEnabled == 'true'

module logicAppDeployment './LogicApp_Modules/LogicAppStandard_Core.bicep' = {
  name: 'LogicAppStandard-${dateTime}'
  params: {
    location: location
    logicAppName: logicAppName
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    logicAppSettings: logicAppCombinedVariables
    enableAppInsights: enableAppInsights
    applicationInsightResourceId: enableAppInsights ? sharedAppInsights.id : ''
    enableNodinite: enableNodinite
    sharedResources: sharedResources
    isArcEnabled: isArcEnabled
    customLocationResourceId: customLocationResourceId
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the deployed Logic App.')
output logicAppName string = logicAppName

@description('The system-assigned managed identity principal ID. Use this for RBAC assignments.')
output systemAssignedPrincipalId string = logicAppDeployment.outputs.systemAssignedPrincipalId

@description('The resource ID of the deployed Logic App.')
output logicAppId string = logicAppDeployment.outputs.logicAppId

@description('The HTTPS URL of the deployed Logic App.')
output logicAppUrl string = logicAppDeployment.outputs.logicAppUrl
