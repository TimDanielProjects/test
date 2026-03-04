// ============================================================================
// API Management – API Module
// Deploys a complete APIM API including version set, product link, backends,
// named values, and operations. Uses AVM registry modules.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Required. Environment suffix (e.g. dev, test, prod). Used to conditionally toggle subscription requirements.')
param environmentSuffix string

@description('Required. API configuration object defining the full API surface.')
param api {
  @description('Required. Description of the API shown in the developer portal.')
  description: string

  @description('Required. Display name of the API in the developer portal.')
  displayName: string

  @description('Required. Unique name / identifier for the API resource.')
  name: string

  @description('Required. URL suffix appended to the APIM gateway URL for this API.')
  apiUrlSuffix: string

  @description('Required. Name of the APIM product this API should be linked to.')
  productName: string

  @description('Optional. Raw XML policy to apply to all operations in this API.')
  allOperationsPolicyXml: string?

  @description('Optional. Array of API operations to create.')
  operations: operationsType

  @description('Optional. Array of named values to create in APIM for this API.')
  namedValues: namedValuesType

  @description('Required. The backend web service URL that this API proxies to.')
  webServiceUrl: string

  @description('Required. The API version string (e.g. v1, v2).')
  apiVersion: string

  @description('Optional. Array of backend configurations for this API.')
  backends: array?
}

@description('Required. API Management instance reference for scoping deployments.')
param apiManagement {
  @description('Required. Name of the existing API Management instance.')
  name: string

  @description('Required. Resource group containing the API Management instance.')
  resourceGroupName: string
}

// ============================================================================
// Modules – API Deployment
// ============================================================================

module apiV1 '../../bicep-registry-modules/avm/res/api-management/service/api/main.bicep' = {
  name: 'API-${dateTime}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  dependsOn: [
    backendResource
    namedValuesModule 
  ]
  params: {
    apiManagementServiceName: apiManagement.name
    description: api.description
    displayName: api.displayName
    name: api.name
    path: api.apiUrlSuffix
    serviceUrl: api.webServiceUrl
    apiVersionSetName:  apiVersionSet.outputs.name
    apiVersion: api.apiVersion
    subscriptionRequired: environmentSuffix == 'dev' ? false : true
    //policy for all operations (not required)
    policies: contains(api, 'allOperationsPolicyXml') && !empty(api.?allOperationsPolicyXml) ? [
      {
        format: 'rawxml'
        value: api.allOperationsPolicyXml!
      }
    ] : []
  }
}
module apiVersionSet '../../bicep-registry-modules/avm/res/api-management/service/api-version-set/main.bicep' = {
  name: 'ApiVersionSet-${api.apiVersion}-${dateTime}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  params: {
    apiManagementServiceName: apiManagement.name
    name: api.name
      displayName: api.displayName
      versioningScheme: 'Segment'
  }
}
module product '../../bicep-registry-modules/avm/res/api-management/service/product/api/main.bicep' = {
  name: 'Product-${dateTime}'
  dependsOn: [
    apiV1
  ]
  params: {
    name: api.name
    apiManagementServiceName: apiManagement.name
    productName: api.productName
  }
}
module apiOperations 'API_Operations.bicep' = [
  for (operation, index) in (api.?operations  ?? []): {
  name: 'API-Operations-${dateTime}-${index}'
  dependsOn: [
    product
  ]
  scope:(resourceGroup(apiManagement.resourceGroupName))
  params:{
    api: {
      name: api.name
    }
    apiManagement: {
      name: apiManagement.name
    }
    operation: operation
  }
}]

module backendResource '../../bicep-registry-modules/avm/res/api-management/service/backend/main.bicep' = [
  for (backend, index) in (api.?backends ?? []): {
    name: 'Backend-${dateTime}-${index}'
    scope: resourceGroup(apiManagement.resourceGroupName)
    params: {
      apiManagementServiceName: apiManagement.name
      name: backend.name
      url: backend.url
      // resourceId: '${environment().resourceManager}${substring(backend.resourceId, 1)}' // Remove the first / from the resourceId, otherwise the path will not be correct.
      tls: {
        validateCertificateChain: true
        validateCertificateName: true
      }
    }
  }
]


module namedValuesModule '../../bicep-registry-modules/avm/res/api-management/service/named-value/main.bicep'= [
  for (namedValue, index) in (api.?namedValues  ?? []):{
  name: 'API-NamedValue-${dateTime}-${index}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  params: {
    apiManagementServiceName: apiManagement.name
    displayName: namedValue.displayName
    name: namedValue.name
    secret: true
    value: namedValue.value
  }
}]


// ============================================================================
// User-Defined Types
// ============================================================================

type operationsType = {
  @description('Required. Unique name for the operation.')
  name: string

  @description('Optional. Description of the operation shown in the developer portal.')
  description: string?

  @description('Required. URL path template for the operation (e.g. /orders/{id}).')
  operationPath: string

  @description('Required. HTTP method (GET, POST, PUT, DELETE, PATCH, etc.).')
  method: string

  @description('Optional. Raw XML policy to apply to this specific operation.')
  policyXml: string?

  @description('Optional. Array of query parameter definitions for the operation.')
  queryParameters: array?

  @description('Optional. Array of header parameter definitions for the operation.')
  headerParameters: array?

  @description('Optional. Array of response definitions for the operation.')
  responseParameters: array?
}[]?

type namedValuesType = {
  @description('Required. Internal name of the named value.')
  name: string

  @description('Required. Display name shown in the Azure portal.')
  displayName: string

  @description('Required. The value of the named value (stored as a secret).')
  value: string
}[]?

type backendType = {
  @description('Required. Name of the backend configuration.')
  name: string

  @description('Required. URL of the backend service.')
  url: string

  @description('Optional. Azure resource ID of the backend (e.g. for Function Apps).')
  resourceId: string?
}[]?
