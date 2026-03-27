// ============================================================================
// Container App
// Deploys an Azure Container App with configurable containers, scaling rules,
// ingress, and registry auth. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Container App configuration.')
param containerAppSettings {
  @description('Required. Name of the Container App.')
  name: string

  @description('Required. Resource ID of the Container App Environment to deploy into.')
  environmentResourceId: string

  @description('Optional. Tags to apply to the resource.')
  tags: object?

  @description('Optional. Array of container definitions for the app.')
  containers: {
    @description('Required. Name of the container.')
    name: string

    @description('Required. Container image (e.g. mcr.microsoft.com/azuredocs/containerapps-helloworld:latest).')
    image: string

    @description('Optional. CPU cores allocated to the container (e.g. 0.25, 0.5, 1.0).')
    cpu: string?

    @description('Optional. Memory allocated to the container (e.g. 0.5Gi, 1.0Gi).')
    memory: string?

    @description('Optional. Array of environment variables for the container.')
    env: {
      @description('Required. Name of the environment variable.')
      name: string

      @description('Optional. Plain-text value. Use value or secretRef, not both.')
      value: string?

      @description('Optional. Reference to a secret name defined at the app level.')
      secretRef: string?
    }[]?
  }[]?

  @description('Optional. Ingress configuration for the Container App.')
  ingress: {
    @description('Optional. Whether external ingress is enabled. Defaults to false.')
    external: bool?

    @description('Optional. Target port the container listens on.')
    targetPort: int?

    @description('Optional. Transport protocol. Defaults to auto.')
    transport: ('auto' | 'http' | 'http2' | 'tcp')?
  }?

  @description('Optional. Scaling rules configuration.')
  scaleRules: {
    @description('Optional. Minimum number of replicas. Defaults to 0.')
    minReplicas: int?

    @description('Optional. Maximum number of replicas. Defaults to 10.')
    maxReplicas: int?
  }?

  @description('Optional. Array of container registry credentials.')
  registries: {
    @description('Required. Login server of the container registry (e.g. myregistry.azurecr.io).')
    server: string

    @description('Optional. Managed identity resource ID used to authenticate to the registry.')
    identity: string?

    @description('Optional. Username for the container registry.')
    username: string?

    @description('Optional. Reference to a secret containing the registry password.')
    passwordSecretRef: string?
  }[]?

  @description('Optional. Array of secrets for the Container App.')
  secrets: {
    @description('Required. Name of the secret.')
    name: string

    @description('Optional. Plain-text value of the secret.')
    value: string?

    @description('Optional. Key Vault secret URI for the secret value.')
    keyVaultUrl: string?

    @description('Optional. Managed identity resource ID used to read the Key Vault secret.')
    identity: string?
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module containerApp '../bicep-registry-modules/avm/res/app/container-app/main.bicep' = {
  name: 'ContainerApp-${dateTime}'
  params: {
    name: containerAppSettings.name
    location: location
    environmentResourceId: containerAppSettings.environmentResourceId
    tags: containerAppSettings.?tags
    containers: containerAppSettings.?containers ?? [
      {
        name: containerAppSettings.name
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    ingressExternal: containerAppSettings.?ingress.?external ?? false
    ingressTargetPort: containerAppSettings.?ingress.?targetPort ?? 80
    ingressTransport: containerAppSettings.?ingress.?transport ?? 'auto'
    scaleSettings: {
      maxReplicas: containerAppSettings.?scaleRules.?maxReplicas ?? 10
      minReplicas: containerAppSettings.?scaleRules.?minReplicas ?? 0
    }
    registries: containerAppSettings.?registries ?? []
    secrets: containerAppSettings.?secrets
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Container App.')
output name string = containerApp.outputs.name

@description('Resource ID of the deployed Container App.')
output resourceId string = containerApp.outputs.resourceId

@description('FQDN of the Container App (if ingress is enabled).')
output fqdn string = containerApp.outputs.fqdn
