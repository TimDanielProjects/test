// ============================================================================
// Azure Data Factory
// Deploys an Azure Data Factory instance with system-assigned managed identity.
// ============================================================================

@description('Required. Name of the Data Factory instance (e.g., "contoso-int-shared-df-sdc-dev").')
param DataFactoryName string

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

// ============================================================================
// Resources
// ============================================================================

module dataFactory '../bicep-registry-modules/avm/res/data-factory/factory/main.bicep' = {
  name: 'DataFactory-${dateTime}'
  params: {
    name: DataFactoryName
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed Data Factory.')
output id string = dataFactory.outputs.resourceId

@description('The name of the deployed Data Factory.')
output name string = dataFactory.outputs.name

@description('The system-assigned managed identity principal ID.')
output principalId string = dataFactory.outputs.?systemAssignedMIPrincipalId!
