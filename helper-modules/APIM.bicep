// ============================================================================
// API Management Service
// Deploys an Azure API Management instance with system-assigned managed identity,
// creates products and subscriptions, and stores subscription keys in Key Vault.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. Name of the Key Vault where APIM subscription keys will be stored.')
param keyVaultName string

@description('Required. API Management Service configuration.')
param APIManagementService {
  @description('Required. Name of the API Management instance (e.g., "contoso-int-shared-apim-sdc-dev").')
  Name: string

  @description('Required. Publisher name displayed in the developer portal.')
  PublisherName: string

  @description('Required. Publisher email for notifications and developer portal contact.')
  PublisherEmail: string

  @description('Optional. The APIM pricing tier. Defaults to null (uses AVM default). Common choices: "Developer" for non-prod, "BasicV2" or "StandardV2" for production.')
  APIMTier: 'Basic' | 'BasicV2' | 'Consumption' | 'Developer' | 'Premium' | 'Standard' | 'StandardV2' | null
}

@description('Optional. List of product names to create in APIM. Each product gets a subscription and its key stored in Key Vault.')
param products array = [
  'internal'
]

// ============================================================================
// Resources
// ============================================================================

module apim '../bicep-registry-modules/avm/res/api-management/service/main.bicep' = {
  name: 'apim-${dateTime}'
  params: {
    location: location
    name: APIManagementService.Name
    publisherEmail: APIManagementService.PublisherEmail
    publisherName: APIManagementService.PublisherName
    managedIdentities: {
      systemAssigned: true
    }
    sku: APIManagementService.?APIMTier
    namedValues: [
      {
        name: 'tenant-id'
        displayName: 'tenant-id'
        value: subscription().tenantId
      }
    ]
  }
}

module apimSettings 'APIM_Settings.bicep' = [for product in products: {
  name: 'apimSettings-${product}-${dateTime}'
  params: {
    apimName: APIManagementService.Name
    apimResourceId: apim.outputs.resourceId
    product: product
    keyVaultName: keyVaultName
  }
}]

// ============================================================================
// Outputs
// ============================================================================

@description('The system-assigned managed identity principal ID of the APIM instance.')
output principalId string = apim.outputs.?systemAssignedMIPrincipalId!

@description('The name of the deployed API Management instance.')
output name string = apim.outputs.name

@description('The resource ID of the deployed API Management instance.')
output resourceId string = apim.outputs.resourceId
