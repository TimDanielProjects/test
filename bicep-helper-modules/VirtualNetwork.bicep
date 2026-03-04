// ============================================================================
// Virtual Network
// Deploys an Azure Virtual Network with configurable subnets, address spaces,
// and optional NSG/route table associations. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for the VNet. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Virtual Network configuration.')
param virtualNetworkSettings {
  @description('Required. Name of the Virtual Network.')
  name: string

  @description('Required. Array of address space prefixes (CIDR notation, e.g. ["10.0.0.0/16"]).')
  addressPrefixes: string[]

  @description('Optional. Tags to apply to the VNet resource.')
  tags: object?

  @description('Optional. Array of subnet configurations.')
  subnets: {
    @description('Required. Name of the subnet.')
    name: string

    @description('Required. Address prefix for the subnet in CIDR notation (e.g. 10.0.1.0/24).')
    addressPrefix: string

    @description('Optional. Resource ID of a Network Security Group to associate with the subnet.')
    networkSecurityGroupResourceId: string?

    @description('Optional. Resource ID of a Route Table to associate with the subnet.')
    routeTableResourceId: string?

    @description('Optional. Array of service delegation configurations.')
    delegations: {
      @description('Required. Name of the delegation.')
      name: string

      @description('Required. Service name for the delegation (e.g. Microsoft.Web/serverFarms).')
      serviceName: string
    }[]?

    @description('Optional. Array of service endpoints to enable on the subnet.')
    serviceEndpoints: {
      @description('Required. Service endpoint type (e.g. Microsoft.Storage).')
      service: string
    }[]?

    @description('Optional. Enable or disable private endpoint network policies.')
    privateEndpointNetworkPolicies: ('Disabled' | 'Enabled')?
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module virtualNetwork '../bicep-registry-modules/avm/res/network/virtual-network/main.bicep' = {
  name: 'VNet-${dateTime}'
  params: {
    name: virtualNetworkSettings.name
    location: location
    addressPrefixes: virtualNetworkSettings.addressPrefixes
    tags: virtualNetworkSettings.?tags
    subnets: [
      for subnet in (virtualNetworkSettings.?subnets ?? []): {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        networkSecurityGroupResourceId: subnet.?networkSecurityGroupResourceId
        routeTableResourceId: subnet.?routeTableResourceId
        delegation: subnet.?delegations ?? []
        serviceEndpoints: subnet.?serviceEndpoints ?? []
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Virtual Network.')
output name string = virtualNetwork.outputs.name

@description('Resource ID of the deployed Virtual Network.')
output resourceId string = virtualNetwork.outputs.resourceId

@description('Array of subnet resource IDs.')
output subnetResourceIds array = virtualNetwork.outputs.subnetResourceIds
