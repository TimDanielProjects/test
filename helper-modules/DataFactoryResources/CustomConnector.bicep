// ============================================================================
// Custom API Connector
// Deploys a custom API connector (Microsoft.Web/customApis) that can be used
// by Logic Apps and Power Platform to connect to external APIs.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the custom API connector resource.')
param connectorName string

@description('Required. URL to the Swagger/OpenAPI definition for the connector.')
param swaggerUrl string

// ============================================================================
// Resources
// ============================================================================

resource connector 'Microsoft.Web/customApis@2018-07-01-preview' = {
  name: connectorName
  properties: {
    displayName: connectorName
    swagger: {
      url: swaggerUrl
    }
  }
}
