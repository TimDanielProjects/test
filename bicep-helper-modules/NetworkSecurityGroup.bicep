// ============================================================================
// Network Security Group
// Deploys an Azure Network Security Group with configurable security rules.
// Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region for the NSG. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Network Security Group configuration.')
param nsgSettings {
  @description('Required. Name of the Network Security Group.')
  name: string

  @description('Optional. Tags to apply to the NSG resource.')
  tags: object?

  @description('Optional. Array of security rules to create.')
  securityRules: {
    @description('Required. Name of the security rule.')
    name: string

    @description('Required. Priority of the rule (100-4096). Lower number = higher priority.')
    priority: int

    @description('Required. Whether to allow or deny traffic.')
    access: ('Allow' | 'Deny')

    @description('Required. Direction of the rule.')
    direction: ('Inbound' | 'Outbound')

    @description('Required. Protocol the rule applies to.')
    protocol: ('Tcp' | 'Udp' | 'Icmp' | '*')

    @description('Required. Source address prefix or tag (e.g. 10.0.0.0/24, Internet, VirtualNetwork, *).')
    sourceAddressPrefix: string

    @description('Required. Source port range (e.g. 80, 443, 1024-65535, *).')
    sourcePortRange: string

    @description('Required. Destination address prefix or tag.')
    destinationAddressPrefix: string

    @description('Required. Destination port range (e.g. 80, 443, 1024-65535, *).')
    destinationPortRange: string

    @description('Optional. Description of the rule.')
    description: string?
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module nsg '../bicep-registry-modules/avm/res/network/network-security-group/main.bicep' = {
  name: 'NSG-${dateTime}'
  params: {
    name: nsgSettings.name
    location: location
    tags: nsgSettings.?tags
    securityRules: [
      for rule in (nsgSettings.?securityRules ?? []): {
        name: rule.name
        properties: {
          priority: rule.priority
          access: rule.access
          direction: rule.direction
          protocol: rule.protocol
          sourceAddressPrefix: rule.sourceAddressPrefix
          sourcePortRange: rule.sourcePortRange
          destinationAddressPrefix: rule.destinationAddressPrefix
          destinationPortRange: rule.destinationPortRange
          description: rule.?description
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Network Security Group.')
output name string = nsg.outputs.name

@description('Resource ID of the deployed Network Security Group.')
output resourceId string = nsg.outputs.resourceId
