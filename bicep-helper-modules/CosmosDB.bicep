// ============================================================================
// Cosmos DB Account
// Deploys an Azure Cosmos DB account with optional SQL databases and
// containers. Supports multi-region, consistency levels, and capacity mode.
// Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Cosmos DB account configuration.')
param cosmosDbSettings {
  @description('Required. Name of the Cosmos DB account (must be globally unique, lowercase).')
  name: string

  @description('Optional. Tags to apply to the resource.')
  tags: object?

  @description('Optional. Default consistency level. Defaults to Session.')
  defaultConsistencyLevel: ('Eventual' | 'ConsistentPrefix' | 'Session' | 'BoundedStaleness' | 'Strong')?

  @description('Optional. Capacity mode. Defaults to Serverless.')
  capacityMode: ('Provisioned' | 'Serverless')?

  @description('Optional. Enable automatic failover. Defaults to true.')
  automaticFailover: bool?

  @description('Optional. Array of additional Azure regions for geo-replication.')
  locations: {
    @description('Required. Azure region name.')
    locationName: string

    @description('Optional. Failover priority (0 = primary). Defaults to 0.')
    failoverPriority: int

    @description('Optional. Whether zone redundancy is enabled for this region.')
    isZoneRedundant: bool?
  }[]?

  @description('Optional. Whether public network access is enabled. Defaults to Enabled.')
  publicNetworkAccess: ('Enabled' | 'Disabled')?

  @description('Optional. Array of SQL databases to create.')
  sqlDatabases: {
    @description('Required. Name of the SQL database.')
    name: string

    @description('Optional. Array of containers to create in this database.')
    containers: {
      @description('Required. Name of the container.')
      name: string

      @description('Required. Partition key paths (e.g. ["/partitionKey"]).')
      paths: string[]

      @description('Optional. Throughput in RU/s (only for Provisioned mode).')
      throughput: int?
    }[]?
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module cosmosDb '../bicep-registry-modules/avm/res/document-db/database-account/main.bicep' = {
  name: 'CosmosDB-${dateTime}'
  params: {
    name: cosmosDbSettings.name
    location: location
    tags: cosmosDbSettings.?tags
    defaultConsistencyLevel: cosmosDbSettings.?defaultConsistencyLevel ?? 'Session'
    capabilitiesToAdd: cosmosDbSettings.?capacityMode == 'Serverless'
      ? ['EnableServerless']
      : []
    enableAutomaticFailover: cosmosDbSettings.?automaticFailover ?? true
    failoverLocations: cosmosDbSettings.?locations ?? [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    networkRestrictions: {
      publicNetworkAccess: cosmosDbSettings.?publicNetworkAccess ?? 'Enabled'
    }
    sqlDatabases: cosmosDbSettings.?sqlDatabases
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Cosmos DB account.')
output name string = cosmosDb.outputs.name

@description('Resource ID of the deployed Cosmos DB account.')
output resourceId string = cosmosDb.outputs.resourceId

@description('Endpoint URI of the Cosmos DB account.')
output endpoint string = cosmosDb.outputs.endpoint
