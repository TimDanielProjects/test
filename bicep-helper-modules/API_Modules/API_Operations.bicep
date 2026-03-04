// ============================================================================
// API Operations – Internal Sub-Module
// Deploys a single APIM API operation with optional policy. Called in a loop
// from the parent API.bicep module. Do not call directly.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Operation definition with method, path, and optional policy.')
param operation {
  @description('Required. Unique name for the operation (also used as displayName).')
  name: string

  @description('Optional. Description of the operation.')
  description: string?

  @description('Required. URL path template for the operation.')
  operationPath: string

  @description('Required. HTTP method (GET, POST, PUT, DELETE, etc.).')
  method: string

  @description('Optional. Raw XML policy to apply to this operation.')
  policyXml: string?

  @description('Optional. Query parameter definitions.')
  queryParameters: array?

  @description('Optional. Header parameter definitions.')
  headerParameters: array?

  @description('Optional. Response definitions.')
  responseParameters: array?
}

@description('Required. API Management instance reference.')
param apiManagement {
  @description('Required. Name of the existing API Management instance.')
  name: string
}

@description('Required. Parent API reference.')
param api {
  @description('Required. Name of the parent API resource.')
  name: string
}

// ============================================================================
// Resources
// ============================================================================

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagement.name
  resource existing_api 'apis@2021-08-01' existing = {
    name: api.name
  }
}
resource apiOperations 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  name: operation.name
  parent: service::existing_api
  properties:{
    displayName: operation.name
    description: operation.?description
    method: operation.method
    urlTemplate: operation.operationPath
    responses:operation.?responseParameters
    request: {
      queryParameters: operation.?queryParameters
      headers: operation.?headerParameters
      representations: contains(['GET', 'HEAD', 'OPTIONS'], operation.method) ? [] : [
      {
        contentType: 'application/json'
        examples: {
        example: {
          description: 'example description' 
          value: any({})
        }
        }
      }
      ]
    }
  }
  resource policy 'policies@2023-05-01-preview' = if (operation.?policyXml  != null) {
    name: 'policy'
    properties: {
      value: operation.?policyXml!
      format: 'rawxml'
    }
  }
}
