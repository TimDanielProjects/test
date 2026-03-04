// ============================================================================
// RBAC Role Assignments
// Assigns Azure RBAC roles to principals on Azure resources.
// All resource sections are optional — only include the types you need.
//
// Supported resources:
//   Storage Account, Service Bus Namespace, API Management, Key Vault,
//   Cosmos DB, Event Hub Namespace, SQL Server, Redis Cache,
//   Data Factory, Web App (Function App / Logic App), Container App
// ============================================================================

type roleAssignmentType = {
  @description('Required. The role to assign. You can provide the role definition GUID or its fully qualified ID in the format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionId: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID. Recommended for managed identities to avoid replication delays.')
  principalType: ('Device' | 'ForeignGroup' | 'Group' | 'ServicePrincipal' | 'User')?

  @description('Optional. Description of the role assignment for auditing purposes.')
  description: string?
}[]?

@description('Required. RBAC configuration. Each section is optional — only include the resource types you need role assignments for.')
param RBACSettings {
  @description('Optional. Storage Account role assignments.')
  storageAccountSettings: {
    @description('Required. Name of the existing Storage Account.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Service Bus Namespace role assignments.')
  serviceBusNamespaceSettings: {
    @description('Required. Name of the existing Service Bus Namespace.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. API Management role assignments.')
  apiManagementSettings: {
    @description('Required. Name of the existing API Management instance.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Key Vault role assignments.')
  keyVaultSettings: {
    @description('Required. Name of the existing Key Vault.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Cosmos DB Account role assignments.')
  cosmosDbSettings: {
    @description('Required. Name of the existing Cosmos DB account.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Event Hub Namespace role assignments.')
  eventHubNamespaceSettings: {
    @description('Required. Name of the existing Event Hub Namespace.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. SQL Server role assignments.')
  sqlServerSettings: {
    @description('Required. Name of the existing SQL Server.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Redis Cache role assignments.')
  redisCacheSettings: {
    @description('Required. Name of the existing Redis Cache.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Data Factory role assignments.')
  dataFactorySettings: {
    @description('Required. Name of the existing Data Factory.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Web App / Function App / Logic App role assignments (Microsoft.Web/sites).')
  webAppSettings: {
    @description('Required. Name of the existing Web App, Function App, or Logic App.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?

  @description('Optional. Container App role assignments.')
  containerAppSettings: {
    @description('Required. Name of the existing Container App.')
    name: string

    @description('Required. Array of role assignments to apply.')
    roleAssignments: roleAssignmentType
  }?
}

// ============================================================================
// Existing Resource References
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (RBACSettings.?storageAccountSettings != null) {
  name: RBACSettings.storageAccountSettings!.name
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = if (RBACSettings.?serviceBusNamespaceSettings != null) {
  name: RBACSettings.serviceBusNamespaceSettings!.name
}

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = if (RBACSettings.?apiManagementSettings != null) {
  name: RBACSettings.apiManagementSettings!.name
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (RBACSettings.?keyVaultSettings != null) {
  name: RBACSettings.keyVaultSettings!.name
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = if (RBACSettings.?cosmosDbSettings != null) {
  name: RBACSettings.cosmosDbSettings!.name
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = if (RBACSettings.?eventHubNamespaceSettings != null) {
  name: RBACSettings.eventHubNamespaceSettings!.name
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = if (RBACSettings.?sqlServerSettings != null) {
  name: RBACSettings.sqlServerSettings!.name
}

resource redisCache 'Microsoft.Cache/redis@2024-03-01' existing = if (RBACSettings.?redisCacheSettings != null) {
  name: RBACSettings.redisCacheSettings!.name
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = if (RBACSettings.?dataFactorySettings != null) {
  name: RBACSettings.dataFactorySettings!.name
}

resource webApp 'Microsoft.Web/sites@2023-12-01' existing = if (RBACSettings.?webAppSettings != null) {
  name: RBACSettings.webAppSettings!.name
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' existing = if (RBACSettings.?containerAppSettings != null) {
  name: RBACSettings.containerAppSettings!.name
}

// ============================================================================
// Role Assignments
// ============================================================================

resource storageAccount_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?storageAccountSettings.?roleAssignments ?? []): if (RBACSettings.?storageAccountSettings != null) {
    name: guid(storageAccount.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: storageAccount
  }
]

resource serviceBusNamespace_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?serviceBusNamespaceSettings.?roleAssignments ?? []): if (RBACSettings.?serviceBusNamespaceSettings != null) {
    name: guid(serviceBusNamespace.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: serviceBusNamespace
  }
]

resource apim_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?apiManagementSettings.?roleAssignments ?? []): if (RBACSettings.?apiManagementSettings != null) {
    name: guid(apim.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: apim
  }
]

resource keyVault_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?keyVaultSettings.?roleAssignments ?? []): if (RBACSettings.?keyVaultSettings != null) {
    name: guid(keyVault.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: keyVault
  }
]

resource cosmosDb_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?cosmosDbSettings.?roleAssignments ?? []): if (RBACSettings.?cosmosDbSettings != null) {
    name: guid(cosmosDb.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: cosmosDb
  }
]

resource eventHubNamespace_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?eventHubNamespaceSettings.?roleAssignments ?? []): if (RBACSettings.?eventHubNamespaceSettings != null) {
    name: guid(eventHubNamespace.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: eventHubNamespace
  }
]

resource sqlServer_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?sqlServerSettings.?roleAssignments ?? []): if (RBACSettings.?sqlServerSettings != null) {
    name: guid(sqlServer.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: sqlServer
  }
]

resource redisCache_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?redisCacheSettings.?roleAssignments ?? []): if (RBACSettings.?redisCacheSettings != null) {
    name: guid(redisCache.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: redisCache
  }
]

resource dataFactory_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?dataFactorySettings.?roleAssignments ?? []): if (RBACSettings.?dataFactorySettings != null) {
    name: guid(dataFactory.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: dataFactory
  }
]

resource webApp_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?webAppSettings.?roleAssignments ?? []): if (RBACSettings.?webAppSettings != null) {
    name: guid(webApp.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: webApp
  }
]

resource containerApp_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?containerAppSettings.?roleAssignments ?? []): if (RBACSettings.?containerAppSettings != null) {
    name: guid(containerApp.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
      description: roleAssignment.?description
    }
    scope: containerApp
  }
]
