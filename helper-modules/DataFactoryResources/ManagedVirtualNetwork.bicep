// ============================================================================
// Data Factory Managed Virtual Network (Template)
// Deploys a managed virtual network for Data Factory with an optional
// managed private endpoint.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the managed virtual network to create.')
param managedVirtualNetworkName string

@description('Optional. Name of the managed private endpoint to create within the virtual network.')
param privateEndpointName string?

// ============================================================================
// Resources
// ============================================================================

resource managedVirtualNetwork 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${dataFactoryName}/${managedVirtualNetworkName}'
  properties: {}
}

resource privateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if (privateEndpointName != null) {
  parent: managedVirtualNetwork
  name: privateEndpointName!
  properties: {
    // TODO: Configure privateLinkResourceId and groupId
  }
}
