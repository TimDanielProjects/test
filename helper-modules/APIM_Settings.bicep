// ============================================================================
// APIM Product & Subscription Settings
// Creates a product, subscription, and stores the subscription key in Key Vault.
// Called internally by APIM.bicep for each product — typically not used directly.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Required. Name of the existing API Management instance.')
param apimName string

@description('Required. Resource ID of the existing API Management instance. Used to retrieve subscription keys.')
param apimResourceId string

@description('Required. Name of the product to create (e.g., "internal", "external").')
param product string

@description('Required. Name of the Key Vault where the subscription key will be stored.')
param keyVaultName string

module apimProduct '../bicep-registry-modules/avm/res/api-management/service/product/main.bicep' ={
  name: 'apimProduct-${product}-${dateTime}'
  params: {
    name: product
    displayName: product
    apiManagementServiceName: apimName
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
  }
}

module apimSubscription '../bicep-registry-modules/avm/res/api-management/service/subscription/main.bicep' = {
  name: 'apimSubscription-${product}-subscription-${dateTime}'
  params: {
    name: '${product}-subscription'
    displayName: '${product} Subscription'
    apiManagementServiceName: apimName
    allowTracing: true
    scope: apimProduct.outputs.resourceId
  }
}

module keyVaultSecret 'KeyVault_Modules/KeyVaultSecret.bicep' = {
  name: 'keyVaultSecret-${product}-${dateTime}'
  dependsOn: [
    apimSubscription
  ]
  params: {
    keyVaultSecretSettings: {
      name: 'APIM-${product}-subscription-key'
      keyVaultName: keyVaultName
      value: listSecrets('${apimResourceId}/subscriptions/${product}-subscription', '2021-08-01').primaryKey
    }
  }
}
