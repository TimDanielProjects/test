// ============================================================================
// Private Endpoint
// Deploys an Azure Private Endpoint for connecting to PaaS services over
// a private IP within your VNet. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Private Endpoint configuration.')
param privateEndpointSettings {
  @description('Required. Name of the Private Endpoint.')
  name: string

  @description('Optional. Tags to apply to the resource.')
  tags: object?

  @description('Required. Resource ID of the subnet to deploy the private endpoint into.')
  subnetResourceId: string

  @description('Required. Resource ID of the target resource to connect to (e.g. Storage Account, Key Vault, SQL Server).')
  serviceResourceId: string

  @description('Required. The group ID (sub-resource) for the private link service (e.g. blob, vault, sqlServer).')
  groupId: string

  @description('Optional. Private DNS zone group configuration for automatic DNS registration.')
  privateDnsZoneGroup: {
    @description('Required. Name of the private DNS zone group.')
    name: string

    @description('Required. Array of private DNS zone resource IDs to link.')
    privateDnsZoneResourceIds: string[]
  }?
}

// ============================================================================
// Modules
// ============================================================================

module privateEndpoint '../bicep-registry-modules/avm/res/network/private-endpoint/main.bicep' = {
  name: 'PE-${dateTime}'
  params: {
    name: privateEndpointSettings.name
    location: location
    tags: privateEndpointSettings.?tags
    subnetResourceId: privateEndpointSettings.subnetResourceId
    privateLinkServiceConnections: [
      {
        name: privateEndpointSettings.name
        properties: {
          privateLinkServiceId: privateEndpointSettings.serviceResourceId
          groupIds: [
            privateEndpointSettings.groupId
          ]
        }
      }
    ]
    privateDnsZoneGroup: privateEndpointSettings.?privateDnsZoneGroup
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Private Endpoint.')
output name string = privateEndpoint.outputs.name

@description('Resource ID of the deployed Private Endpoint.')
output resourceId string = privateEndpoint.outputs.resourceId
