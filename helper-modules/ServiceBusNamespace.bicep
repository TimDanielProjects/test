// ============================================================================
// Service Bus Namespace
// Deploys an Azure Service Bus Namespace with system-assigned managed identity.
// Used for reliable messaging between integration components.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. Service Bus Namespace configuration.')
param serviceBus {
  @description('Required. Name of the Service Bus Namespace (e.g., "contoso-int-shared-sbns-sdc-dev").')
  namespaceName: string

  @description('Required. Name of the resource group where this namespace will be deployed.')
  resourceGroupName: string

  @description('Required. The pricing tier. "Basic" for simple queues, "Standard" for topics/subscriptions, "Premium" for dedicated throughput and VNet integration.')
  sku: 'Basic' | 'Standard' | 'Premium'
}

// ============================================================================
// Resources
// ============================================================================

module serviceBusNamespace '../bicep-registry-modules/avm/res/service-bus/namespace/main.bicep' = {
  name: 'ServiceBusNamespace-${dateTime}'
  params: {
    managedIdentities: {
      systemAssigned: true
    }
    location: location
    name: serviceBus.namespaceName
    skuObject: {
      name: serviceBus.sku
    }
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed Service Bus Namespace.')
output resourceId string = serviceBusNamespace.outputs.resourceId

@description('The name of the deployed Service Bus Namespace.')
output name string = serviceBusNamespace.outputs.name

@description('The system-assigned managed identity principal ID.')
output principalId string = serviceBusNamespace.outputs.?systemAssignedMIPrincipalId!

