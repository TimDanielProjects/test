
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
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')

var keyVaultName = '${resourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${resourceBaseName}-kv-${toLower(environmentSuffix)}'

var sharedResourceGroup = {
  name: '${resourceGroup().name}'
}

var sharedAppServicePlanLAStandard = {
  name: '${resourceBaseName}-aspla-${resourceEnding}'
  skuName: 'WS1'
  skuCapacity: 1
  elasticScaleEnabled: true
  maximumScaleBurst: 4
}

var sharedApiManagement = {
  name: '${resourceBaseName}-apim-${resourceEnding}'
  publisherEmail: 'change-me@example.com'
  publisherName: 'Change Me'
  tier: 'Developer'
  skuCapacity: 1
}

var sharedServiceBus = {
  namespaceName: '${resourceBaseName}-sbns-${resourceEnding}'
  sku: 'Standard'
}

var sharedLogAnalytics = {
  name: '${resourceBaseName}-law-${resourceEnding}'
}

var sharedKeyVault = {
  name: length(keyVaultName) <= 24 ? keyVaultName : fixedKeyVaultName
}

var sharedStorageAccount = {
  name: 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}'
  skuName: 'Standard_LRS'
  accessTier: 'Hot'
  isHnsEnabled: true
  isSftpEnabled: false
  allowBlobPublicAccess: false
  allowSharedKeyAccess: true
  networkDefaultAction: 'Allow'
}

var sharedAppServicePlanFunction = {
  name: '${resourceBaseName}-aspfa-${resourceEnding}'
  skuName: 'B1'
  skuCapacity: 1
  elasticScaleEnabled: true
  maximumScaleBurst: 4
}

var sharedEventHub = {
  namespaceName: '${resourceBaseName}-ehns-${resourceEnding}'
}

var sharedAppInsights = {
  name: '${resourceBaseName}-ai-${resourceEnding}'
}



// ── Module deployments ──────────────────────────────────────────

module keyVault '../../../helper-modules/KeyVault.bicep' = {
  name: 'KeyVault-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    keyVaultSettings: sharedKeyVault
  }
}

module StorageAccount '../../../helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    storageAccountParams: sharedStorageAccount
  }
}

module servicebusNamespace '../../../helper-modules/ServiceBusNamespace.bicep' = {
  name: 'ServiceBus-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    serviceBusSettings: sharedServiceBus
  }
}

module apim '../../../helper-modules/APIM.bicep' = {
  name: 'APIM-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    APIManagementService: {
      name: sharedApiManagement.name
      publisherEmail: sharedApiManagement.publisherEmail
      publisherName: sharedApiManagement.publisherName
      tier: sharedApiManagement.tier
    }
    keyVaultName: sharedKeyVault.name
  }
}

module applicationInsightsSettings '../../../helper-modules/LoggingSettings/applicationInsightsSettings.bicep' = if (ApplicationInsightsLoggingEnabled) {
  name: 'AppInsights-Main-${dateTime}'
  params: {
    dateTime: dateTime
    applicationInsightsSettings: {
      applicationInsightsName: sharedAppInsights.name
      logAnalyticsName: sharedLogAnalytics.name
      apiManagementServiceName: sharedApiManagement.name
      serviceBusNamespaceName: sharedServiceBus.namespaceName
      storageAccountName: sharedStorageAccount.name
    }
  }
  dependsOn: [servicebusNamespace, apim]
}

module aspLAStandard '../../../helper-modules/appServicePlan.bicep' = {
  name: 'AppServicePlanLA-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    appServicePlanSettings: sharedAppServicePlanLAStandard
  }
}

module aspFunction '../../../helper-modules/appServicePlan.bicep' = {
  name: 'AppServicePlanFA-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    appServicePlanSettings: sharedAppServicePlanFunction
  }
}

module logAnalyticsWorkspace '../../../helper-modules/LogAnalyticsWorkspace.bicep' = {
  name: 'LogAnalytics-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    logAnalyticsSettings: {
      name: sharedLogAnalytics.name
      skuName: 'PerGB2018'
      retentionInDays: 30
    }
  }
}

module applicationInsights '../../../helper-modules/ApplicationInsights.bicep' = {
  name: 'AppInsights-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    applicationInsightsSettings: {
      name: sharedAppInsights.name
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    }
  }
  dependsOn: [logAnalyticsWorkspace]
}

module eventHubNamespace '../../../helper-modules/EventHubNamespace.bicep' = {
  name: 'EventHub-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    eventHubNamespaceName: sharedEventHub.namespaceName
    skuName: 'Standard'
  }
}

module RBAC '../../../helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Main-${dateTime}'
  params: {
    RBACSettings: {
      apiManagementSettings: {
        name: sharedApiManagement.name
      }
      serviceBusNamespaceSettings: {
        namespaceName: sharedServiceBus.namespaceName
      }
      keyVaultSettings: {
        name: sharedKeyVault.name
      }
      storageAccountSettings: {
        name: sharedStorageAccount.name
      }
    }
  }
  dependsOn: [keyVault]
}


// ── Outputs ─────────────────────────────────────────────────────

