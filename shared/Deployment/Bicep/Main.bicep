
// ── Parameters ──────────────────────────────────────────────────

@minLength(3)
param integrationId string
param organisationSuffix string
param environmentSuffix string
param regionSuffix string
param NodiniteLoggingEnabled string
param ApplicationInsightsLoggingEnabled string
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

var sharedLogAnalytics = {
  name: '${resourceBaseName}-law-${resourceEnding}'
}

var sharedAppInsights = {
  name: '${resourceBaseName}-ai-${resourceEnding}'
}

var sharedAppInsights = {
  name: '${resourceBaseName}-ai-${resourceEnding}'
}



// ── Module deployments ──────────────────────────────────────────

module StorageAccount '../../../bicep-helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-Main-${dateTime}'
  params: {
    dateTime: dateTime
    location: location
    storageAccountParams: sharedStorageAccount
  }
}

module applicationInsightsSettings '../../../bicep-helper-modules/LoggingSettings/applicationInsightsSettings.bicep' = if (ApplicationInsightsLoggingEnabled == 'true') {
  name: 'AppInsights-Main-${dateTime}'
  params: {
    dateTime: dateTime
    applicationInsightsSettings: {
      applicationInsightsName: sharedAppInsights.name
      logAnalyticsName: sharedLogAnalytics.name
      apiManagementServiceName: sharedApiManagement.name
      serviceBusNamespaceName: sharedServiceBus.namespaceName
      servicesBusSku: 'Standard'
      storageAccountName: sharedStorageAccount.name
    }
  }
}

module RBAC '../../../bicep-helper-modules/AccessControlWithRBAC/RBAC.bicep' = {
  name: 'RBAC-Main-${dateTime}'
  params: {
    RBACSettings: {
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

