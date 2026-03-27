// ============================================================================
// Azure Function App
// Deploys an Azure Function App (.NET isolated) with conditional logging:
//   - Nodinite only (diagnostic settings → Event Hub)
//   - Application Insights only
//   - Both Nodinite + Application Insights
//   - No logging
// Logging is controlled via boolean feature flags (enableNodinite, enableAppInsights)
// and handled by a single unified sub-module (FunctionApp_Core.bicep).
// ============================================================================

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Enable Nodinite logging to send diagnostic logs to Event Hub for Nodinite.')
param NodiniteLoggingEnabled bool

@description('Required. Enable Application Insights logging to configure App Insights instrumentation.')
param ApplicationInsightsLoggingEnabled bool

@description('Required. Organisation prefix used for Nodinite storage account naming convention (e.g., "co" for ContosoCompany).')
param organisationSuffix string

@description('Required. Environment identifier used for resource naming (e.g., "dev", "test", "prod").')
param environmentSuffix string

@description('Optional. Custom environment variables to add to the Function App. These are merged with the base settings. Use an object where keys are setting names and values are setting values.')
param functionAppEnvironmentVariables object = {}

@description('Required. References to shared infrastructure resources deployed by the shared template.')
param sharedResources {
  @description('Required. Resource group name containing shared resources.')
  sharedResourceGroupName: string

  @description('Required. Name of the shared App Service Plan.')
  sharedAppServicePlanName: string

  @description('Required. Resource ID of the shared App Service Plan.')
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

@description('Required. The App Service Plan hosting this Function App.')
param appServicePlan {
  @description('Required. Resource ID of the App Service Plan.')
  resourceId: string
}

@description('Required. Storage account used for Function App runtime storage (WebJobs, content share).')
param storageAccount {
  @description('Required. Resource ID of the storage account.')
  resourceId: string

  @description('Required. Name of the storage account.')
  name: string
}

@description('Required. Function App identity and naming.')
param functionAppParameters {
  @description('Required. Name of the Function App to create (e.g., "contoso-int-myint-fa-sdc-dev").')
  functionAppName: string
}

// ============================================================================
// Variables
// ============================================================================

var functionAppName = functionAppParameters.functionAppName
var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}')
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents'
}

resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled) {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

var functionAppEnvironmentSettings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_RUN_FROM_PACKAGE: '1'
  WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  // Identity-based storage connection (no account keys needed; requires RBAC roles:
  // Storage Blob Data Owner, Storage Account Contributor, Storage Queue Data Contributor, Storage Table Data Contributor)
  AzureWebJobsStorage__accountName: storageAccount.name
  WEBSITE_CONTENTSHARE: toLower(functionAppName)
  NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
  // TODO: Migrate NodiniteStorageAccountConnectionString to managed identity when NodiniteLoggerUtility supports DefaultAzureCredential
  NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
}

var functionAppCombinedVariables = union(
  functionAppEnvironmentSettings,
  functionAppEnvironmentVariables
)

// ============================================================================
// Module Deployment (unified — handles all logging combinations)
// ============================================================================

var enableNodinite = NodiniteLoggingEnabled
var enableAppInsights = ApplicationInsightsLoggingEnabled

module functionAppDeployment './FunctionApp_Modules/FunctionApp_Core.bicep' = {
  name: 'FunctionApp-${dateTime}'
  params: {
    location: location
    functionAppName: functionAppName
    serverFarmResourceId: appServicePlan.resourceId
    functionAppSettings: functionAppCombinedVariables
    enableAppInsights: enableAppInsights
    applicationInsightResourceId: enableAppInsights ? sharedAppInsights.id : ''
    enableNodinite: enableNodinite
    sharedResources: sharedResources
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The default hostname of the deployed Function App.')
output defaultHostname string = functionAppDeployment.outputs.defaultHostname

@description('The name of the deployed Function App.')
output name string = functionAppDeployment.outputs.functionAppName

@description('The resource ID of the deployed Function App.')
output resourceId string = functionAppDeployment.outputs.functionAppId

@description('The system-assigned managed identity principal ID. Use this for RBAC assignments.')
output systemAssignedPrincipalId string = functionAppDeployment.outputs.systemAssignedPrincipalId
