// ============================================================================
// Logic App API Connection
// Deploys a Microsoft.Web/connections resource for managed API connections
// (e.g., File System with MSI authentication).
// ============================================================================

@description('Required. The name of the API connection (e.g., "filesystem").')
param connectionName string

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. The managed API type ID (e.g., "filesystem", "office365").')
param apiType string

@description('Optional. The display name for the connection.')
param displayName string = connectionName

@description('Optional. The authentication type. Defaults to ManagedServiceIdentity.')
param authenticationType string = 'ManagedServiceIdentity'

// ── Computed values ──────────────────────────────────────────
var managedApiId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${apiType}'

// ── API Connection resource ─────────────────────────────────
resource apiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  kind: 'V1'
  properties: {
    api: {
      id: managedApiId
      displayName: displayName
      type: 'Microsoft.Web/locations/managedApis'
    }
    displayName: displayName
    parameterValueType: authenticationType
  }
}

// ── Outputs ─────────────────────────────────────────────────
@description('The name of the deployed API connection.')
output name string = apiConnection.name

@description('The resource ID of the deployed API connection.')
output resourceId string = apiConnection.id

@description('The runtime URL for the API connection.')
output connectionRuntimeUrl string = reference(apiConnection.id, '2016-06-01', 'full').properties.connectionRuntimeUrl
