// ============================================================================
// App Service Plan
// Deploys an Azure App Service Plan (Server Farm) used to host
// Logic Apps Standard, Function Apps, or Web Apps.
// ============================================================================

@description('Optional. Timestamp used for unique deployment names. No need to modify.')
param dateTime string = utcNow()

@description('Optional. Azure region for the resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required. App Service Plan configuration.')
param appServicePlan {
  @description('Required. Name of the App Service Plan (e.g., "contoso-int-shared-aspla-sdc-dev").')
  name: string

  @description('Required. The SKU name/size. Common values: "WS1" (Workflow Standard), "EP1" (Elastic Premium), "B1" (Basic), "S1" (Standard), "P1v3" (Premium v3).')
  skuName: string

  @description('Required. Number of instances (workers) to allocate. Minimum is 1.')
  skuCapacity: int

  @description('Required. Maximum number of workers for elastic scale burst. Only applies when elasticScaleEnabled is true.')
  maximumScaleBurst: int

  @description('Required. Whether the plan supports elastic scale-out. Set to true for Logic App Standard (WS1) and Elastic Premium (EP1) plans.')
  elasticScaleEnabled: bool
}

// ============================================================================
// Resources
// ============================================================================

module asp '../bicep-registry-modules/avm/res/web/serverfarm/main.bicep' = {
  name: '${appServicePlan.name}-${dateTime}'
  params: {
    name: appServicePlan.name
    location: location
    skuCapacity: appServicePlan.skuCapacity
    maximumElasticWorkerCount: appServicePlan.maximumScaleBurst
    elasticScaleEnabled: appServicePlan.elasticScaleEnabled
    skuName: appServicePlan.skuName
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed App Service Plan.')
output id string = asp.outputs.resourceId

@description('The name of the deployed App Service Plan.')
output name string = asp.outputs.name
