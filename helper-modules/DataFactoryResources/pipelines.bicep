// ============================================================================
// Data Factory Pipeline (Template)
// Stub module for deploying a Data Factory pipeline. Replace the properties
// section with the actual pipeline definition (activities, parameters, etc.).
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

// ============================================================================
// Resources
// ============================================================================

resource pipelines 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${dataFactoryName}/integrationRuntimePipelines'
  properties: {
    // TODO: Define pipeline activities, parameters, and variables
  }
}
