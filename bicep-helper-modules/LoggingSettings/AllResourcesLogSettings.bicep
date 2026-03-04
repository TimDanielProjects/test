// ============================================================================
// All Resources Log Settings
// Configures Nodinite diagnostic settings on Logic Apps and Application
// Insights app settings. Called once per Logic App/Function App to enable
// the selected logging providers.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Required. Short organisation suffix used in naming conventions (e.g. contoso).')
param organisationSuffix string

@description('Required. Environment suffix (e.g. dev, test, prod).')
param environmentSuffix string

@description('Required. Name of the Logic App to configure logging on.')
param logicAppName string

@description('Required. Whether Nodinite logging is enabled for this resource.')
@allowed(['true', 'false'])
param NodiniteLoggingEnabled string

@description('Required. Whether Application Insights logging is enabled for this resource.')
@allowed(['true', 'false'])
param ApplicationInsightsLoggingEnabled string

@description('Required. Storage Account reference for the Logic App site configuration.')
param storageAccount {
  @description('Required. Azure resource ID of the Storage Account.')
  resourceId: string

  @description('Required. Name of the Storage Account.')
  name: string
}

@description('Required. Shared infrastructure resource references.')
param sharedResources {
  @description('Required. Name of the shared API Management instance.')
  sharedAPIMName: string

  @description('Required. Name of the shared App Service Plan.')
  sharedAppServicePlanName: string

  @description('Required. Resource ID of the shared App Service Plan.')
  sharedAppServicePlanResourceId: string

  @description('Required. Name of the shared Event Hub Namespace.')
  sharedEventHubsNamespaceName: string

  @description('Required. Resource ID of the shared Event Hub Namespace.')
  sharedEventHubsNamespaceResourceId: string

  @description('Required. Name of the shared Function App.')
  sharedFunctionAppName: string

  @description('Required. Name of the shared Key Vault.')
  sharedKeyVaultName: string

  @description('Required. Name of the shared Service Bus Namespace.')
  sharedServiceBusNamespaceName: string

  @description('Required. Resource ID of the shared Service Bus Namespace.')
  sharedServiceBusNamespaceResourceId: string

  @description('Required. Name of the shared resource group.')
  sharedResourceGroupName: string

  @description('Required. Name of the shared Application Insights instance.')
  sharedApplicationInsightsName: string
}

// ============================================================================
// Variables
// ============================================================================

var nodiniteLoggingSettings = {
  nodiniteLogging_StorageAccountName: toLower('${organisationSuffix}intnodinitelog${environmentSuffix}') // Storage account name for Nodinite logging
  nodiniteLogging_functionLoggingContainerName: 'function-nodinitelogevents' // Blob storage container name for Nodinite logging (Function Apps)
  nodiniteLogging_OtherLoggingContainerName: 'nodinitelogevents' // Blob storage blob name for Nodinite logging (Other resources I.E. APIM)
  nodiniteLogging_EventHubName: 'nodinitelogevents' // Event Hub name for Nodinite logging
  nodiniteLogging_EventHub_CheckpointCaptureContainerName: 'eventhub-nodinitelogevents-checkpoint' // Blob storage container name for Nodinite logging (Event Hub Checkpoint and Capture)
}

// ============================================================================
// Existing Resource References
// ============================================================================

resource nodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = if (NodiniteLoggingEnabled == 'true') {
  name: nodiniteLoggingSettings.nodiniteLogging_StorageAccountName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: sharedResources.sharedApplicationInsightsName
  scope: resourceGroup(sharedResources.sharedResourceGroupName)
}
// ============================================================================
// Nodinite Logging Configuration
// ============================================================================

// THIS IS FOR CONFIGURING NODINITE LOGGING

module logicApp_Nodinite_config '../../bicep-registry-modules/avm/res/web/site/main.bicep' = if (NodiniteLoggingEnabled == 'true') {
  name: 'LogicAppNodinite-Site-${dateTime}'
  params: {
    name: logicAppName
    kind: 'functionapp,workflowapp'
    serverFarmResourceId: sharedResources.sharedAppServicePlanResourceId
    configs: [
      {
        name: 'appsettings'
        properties: {
          //Nodinite Settings
          NodiniteFunctionLoggingContainerName: nodiniteLoggingSettings.nodiniteLogging_functionLoggingContainerName
          NodiniteStorageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${nodiniteLoggingSettings.nodiniteLogging_StorageAccountName};AccountKey=${nodiniteStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        storageAccountResourceId: storageAccount.resourceId
      }
    ]
    diagnosticSettings: [
      {
        name: 'nodiniteDiagnosticSetting'
        eventHubAuthorizationRuleResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${sharedResources.sharedResourceGroupName}/providers/microsoft.eventhub/namespaces/${sharedResources.sharedEventHubsNamespaceName}/authorizationrules/RootManageSharedAccessKey'
        eventHubName: 'nodinitelogevents'
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: false
          }
        ]
        logCategoriesAndGroups: [
          {
            category: 'WorkflowRuntime'
            enabled: true
          }
        ]
      }
    ]
  }
}

// ============================================================================
// Application Insights Logging Configuration
// ============================================================================

// THIS IS FOR CONFIGURING APPLICATION INSIGHTS LOGGING

module logicApp_applicationInsights_config '../../bicep-registry-modules/avm/res/web/site/config/main.bicep' = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: 'logicAppApplicationInsightsConfig'
  params: {
    appName: logicAppName
    name: 'appsettings'
    applicationInsightResourceId: sharedAppInsights.id
    storageAccountResourceId: storageAccount.resourceId
    properties: {}
  }
}
