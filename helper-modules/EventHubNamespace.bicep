// ============================================================================
// Event Hub Namespace
// Deploys an Azure Event Hub Namespace with system-assigned managed identity.
// Used for event streaming, e.g., Nodinite diagnostic log capture.
// ============================================================================

@description('Required. Name of the Event Hub Namespace (e.g., "contoso-int-shared-ehns-sdc-dev").')
param eventHubNamespaceName string

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Optional. The SKU/tier of the Event Hub Namespace.')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Standard'

// ============================================================================
// Resources
// ============================================================================

module eventHubNamespace '../bicep-registry-modules/avm/res/event-hub/namespace/main.bicep' = {
  name: 'EventhubNamespace-${dateTime}'
  params: {
    location: location
    name: eventHubNamespaceName
    managedIdentities: {
      systemAssigned: true
    }
    disableLocalAuth: false
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed Event Hub Namespace.')
output eventHubResourceId string = eventHubNamespace.outputs.resourceId

@description('The system-assigned managed identity principal ID.')
output systemAssignedMIPrincipalId string = eventHubNamespace.outputs.?systemAssignedMIPrincipalId!

@description('The name of the deployed Event Hub Namespace.')
output name string = eventHubNamespace.outputs.name
