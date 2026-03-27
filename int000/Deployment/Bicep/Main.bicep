
// ── Parameters ──────────────────────────────────────────────────

@minLength(3)
param integrationId string
param organisationSuffix string
param environmentSuffix string
param regionSuffix string
param NodiniteLoggingEnabled bool
param ApplicationInsightsLoggingEnabled bool
param location string = az.resourceGroup().location
param dateTime string = utcNow()

// ── Variables ───────────────────────────────────────────────────

var resourceBaseName = toLower('${organisationSuffix}-int-${integrationId}')
var sharedResourceBaseName = toLower('${organisationSuffix}-int-shared')
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')

var sharedResourceGroup = {
  name: '${sharedResourceBaseName}-rg-${resourceEnding}'
}

var keyVaultName = '${sharedResourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${sharedResourceBaseName}-kv-${toLower(environmentSuffix)}'

var storageAccountName = 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}'

var logicAppName = '${resourceBaseName}-la-${resourceEnding}'
var functionAppName = '${resourceBaseName}-fa-${resourceEnding}'
var eventHubConfig = {
  name: '${toLower(integrationId)}-eh'
  namespaceName: sharedEventhubNamespace.name
  partitionCount: 2
  messageRetentionInDays: 1
}


// ── Existing shared resources ───────────────────────────────────

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: length(keyVaultName) <= 24 ? keyVaultName : fixedKeyVaultName
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedAPIM 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: '${sharedResourceBaseName}-apim-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedServiceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: '${sharedResourceBaseName}-sbns-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedLogicAppASP 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: '${sharedResourceBaseName}-aspla-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedFunctionAppASP 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: '${sharedResourceBaseName}-aspfa-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedEventhubNamespace 'Microsoft.EventHub/namespaces@2024-05-01-preview' existing = {
  name: '${sharedResourceBaseName}-ehns-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'st${uniqueString(organisationSuffix,\'shared\',environmentSuffix)}'
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${sharedResourceBaseName}-ai-${resourceEnding}'
  scope: resourceGroup(sharedResourceGroup.name)
}


// ── Module deployments ──────────────────────────────────────────

module storageAccount '../../../helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    storageAccountParams: {
      name: storageAccountName
      skuName: 'Standard_LRS'
      accessTier: 'Hot'
      isHnsEnabled: true
      isSftpEnabled: false
      allowBlobPublicAccess: false
      allowSharedKeyAccess: true
      networkDefaultAction: 'Allow'
    }
  }
}

module logicAppStandard '../../../helper-modules/LogicAppStandard.bicep' = {
  name: 'LogicApp-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    logicAppName: logicAppName
    storageAccountName: storageAccountName
    NodiniteLoggingEnabled: NodiniteLoggingEnabled
    ApplicationInsightsLoggingEnabled: ApplicationInsightsLoggingEnabled
    sharedResources: {
      appServicePlanId: sharedLogicAppASP.id
      keyVaultName: sharedKeyVault.name
      keyVaultUri: sharedKeyVault.properties.vaultUri
      serviceBusNamespaceName: sharedServiceBusNamespace.name
      apiManagementName: sharedAPIM.name
      eventHubNamespaceName: sharedEventhubNamespace.name
      applicationInsightsName: sharedAppInsights.name
      storageAccountName: sharedStorageAccount.name
    }
    LogicAppEnvironmentVariables: {
      storageAccount_blobStorageEndpoint: 'https://${integrationStorageAccountName}.blob.${environment().suffixes.storage}'
      storageAccount_fileshareEndpoint: 'https://${integrationStorageAccountName}.file.${environment().suffixes.storage}'
      storageAccount_queueStorageEndpoint: 'https://${integrationStorageAccountName}.queue.${environment().suffixes.storage}'
      storageAccount_tableStorageEndpoint: 'https://${integrationStorageAccountName}.table.${environment().suffixes.storage}'
      eventHubs_fullyQualifiedNamespace: sharedEventHubNamespace.properties.serviceBusEndpoint
    }
  }
  dependsOn: [storageAccount]
}

module functionApp '../../../helper-modules/FunctionApp.bicep' = {
  name: 'FunctionApp-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    functionAppName: functionAppName
    NodiniteLoggingEnabled: NodiniteLoggingEnabled
    ApplicationInsightsLoggingEnabled: ApplicationInsightsLoggingEnabled
    sharedResources: {
      appServicePlanId: sharedFunctionAppASP.id
      keyVaultName: sharedKeyVault.name
      keyVaultUri: sharedKeyVault.properties.vaultUri
      serviceBusNamespaceName: sharedServiceBusNamespace.name
      apiManagementName: sharedAPIM.name
    }
  }
  dependsOn: [storageAccount]
}

module serviceBusQueue '../../../helper-modules/ServiceBusQueue.bicep' = {
  name: 'ServiceBusQueue-Main-${dateTime}'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    dateTime: dateTime
    queueName: '${toLower(integrationId)}-queue'
    serviceBusNamespaceName: sharedServiceBusNamespace.name
    maxDeliveryCount: 10
    deadLetteringOnMessageExpiration: true
  }
}

module serviceBusTopic '../../../helper-modules/ServiceBusTopic.bicep' = {
  name: 'ServiceBusTopic-Main-${dateTime}'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    dateTime: dateTime
    topicName: '${toLower(integrationId)}-topic'
    serviceBusNamespaceName: sharedServiceBusNamespace.name
  }
}

module eventHub '../../../helper-modules/EventHub_Modules/EventHub.bicep' = {
  name: 'EventHub-Main-${dateTime}'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    dateTime: dateTime
    eventHub: eventHubConfig
  }
}

module RBAC '../../../helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Main-${dateTime}'
  params: {
    RBACSettings: {
      storageAccountSettings: {
        name: storageAccount.outputs.name
        logicAppPrincipalId: logicAppStandard.outputs.principalId
        functionAppPrincipalId: functionApp.outputs.principalId
      }
    }
  }
  dependsOn: [logicAppStandard, functionApp]
}

module RBAC_Shared_Resources '../../../helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Shared-Main-${dateTime}'
  scope: resourceGroup(sharedResourceGroup.name)
  params: {
    RBACSettings: {
      apiManagementSettings: {
        name: sharedAPIM.name
      }
      serviceBusNamespaceSettings: {
        namespaceName: sharedServiceBusNamespace.name
      }
      keyVaultSettings: {
        name: sharedKeyVault.name
      }
      storageAccountSettings: {
        name: sharedStorageAccount.name
      }
    }
  }
  dependsOn: [logicAppStandard, functionApp]
}


// ── Outputs ─────────────────────────────────────────────────────

output functionAppName string = functionAppName
output logicAppStandardName string = logicAppName
output serviceBusQueueName string = serviceBusQueue.outputs.queueName
output serviceBusTopicName string = serviceBusTopic.outputs.topicName
output eventHubName string = eventHub.outputs.name
