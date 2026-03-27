// ============================================================================
// Data Factory Linked Service – Azure SQL Database
// Connects Data Factory to an Azure SQL Database.
// Supports Managed Identity (recommended) or Connection String authentication.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the linked service to create.')
param linkedServiceName string

@description('Required. Azure SQL Database linked service configuration.')
param sqlDatabaseSettings {
  @description('Optional. Authentication type. Defaults to ManagedIdentity.')
  authenticationType: ('ManagedIdentity' | 'SQL' | 'ServicePrincipal')?

  @description('Conditional. Fully qualified SQL Server hostname (e.g. myserver.database.windows.net). Required when using ManagedIdentity or ServicePrincipal auth.')
  serverFqdn: string?

  @description('Conditional. Name of the database. Required when using ManagedIdentity or ServicePrincipal auth.')
  databaseName: string?

  @description('Conditional. Full ADO.NET connection string. Required when authenticationType is SQL.')
  connectionString: string?

  @description('Conditional. Azure Key Vault secret reference for the password/connection string. Use instead of inline secrets.')
  keyVaultSecretReference: {
    @description('Required. Name of the Key Vault linked service.')
    linkedServiceName: string
    @description('Required. Name of the secret in Key Vault.')
    secretName: string
    @description('Optional. Version of the secret.')
    secretVersion: string?
  }?

  @description('Conditional. Service principal ID. Required when authenticationType is ServicePrincipal.')
  servicePrincipalId: string?

  @description('Conditional. Tenant ID of the service principal. Required when authenticationType is ServicePrincipal.')
  tenant: string?

  @description('Optional. Resource ID of a user-assigned managed identity credential.')
  credentialResourceId: string?

  @description('Optional. Description of the linked service.')
  description: string?
}

// ============================================================================
// Variables
// ============================================================================

var authType = sqlDatabaseSettings.?authenticationType ?? 'ManagedIdentity'

var managedIdentityTypeProperties = {
  connectionString: 'Integrated Security=False;Data Source=${sqlDatabaseSettings.?serverFqdn ?? ''};Initial Catalog=${sqlDatabaseSettings.?databaseName ?? ''};Encrypt=True;'
}

var sqlAuthTypeProperties = sqlDatabaseSettings.?keyVaultSecretReference != null
  ? {
      connectionString: {
        type: 'AzureKeyVaultSecret'
        store: {
          referenceName: sqlDatabaseSettings.keyVaultSecretReference!.linkedServiceName
          type: 'LinkedServiceReference'
        }
        secretName: sqlDatabaseSettings.keyVaultSecretReference!.secretName
        secretVersion: sqlDatabaseSettings.keyVaultSecretReference!.?secretVersion
      }
    }
  : {
      connectionString: sqlDatabaseSettings.?connectionString ?? ''
    }

var servicePrincipalTypeProperties = {
  connectionString: 'Integrated Security=False;Data Source=${sqlDatabaseSettings.?serverFqdn ?? ''};Initial Catalog=${sqlDatabaseSettings.?databaseName ?? ''};Encrypt=True;'
  servicePrincipalId: sqlDatabaseSettings.?servicePrincipalId
  tenant: sqlDatabaseSettings.?tenant
  servicePrincipalCredentialType: 'ServicePrincipalKey'
}

var typePropertiesMap = {
  ManagedIdentity: managedIdentityTypeProperties
  SQL: sqlAuthTypeProperties
  ServicePrincipal: servicePrincipalTypeProperties
}

// ============================================================================
// Resources
// ============================================================================

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: linkedServiceName
  properties: {
    type: 'AzureSqlDatabase'
    description: sqlDatabaseSettings.?description ?? 'Azure SQL Database linked service'
    typeProperties: typePropertiesMap[authType]
  }
}
