// ============================================================================
// Redis Cache
// Deploys an Azure Cache for Redis instance with configurable SKU, TLS,
// and optional non-SSL port. Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. Redis Cache configuration.')
param redisCacheSettings {
  @description('Required. Name of the Redis Cache instance (must be globally unique).')
  name: string

  @description('Optional. Tags to apply to the resource.')
  tags: object?

  @description('Optional. SKU name. Defaults to Basic.')
  skuName: ('Basic' | 'Standard' | 'Premium')?

  @description('Optional. Cache capacity (family-dependent). Defaults to 0 (250 MB for Basic/Standard C0).')
  capacity: int?

  @description('Optional. Whether the non-SSL port (6379) is enabled. Defaults to false.')
  enableNonSslPort: bool?

  @description('Optional. Minimum TLS version. Defaults to 1.2.')
  minimumTlsVersion: ('1.0' | '1.1' | '1.2')?

  @description('Optional. Whether public network access is enabled. Defaults to Enabled.')
  publicNetworkAccess: ('Enabled' | 'Disabled')?
}

// ============================================================================
// Modules
// ============================================================================

module redisCache '../bicep-registry-modules/avm/res/cache/redis/main.bicep' = {
  name: 'Redis-${dateTime}'
  params: {
    name: redisCacheSettings.name
    location: location
    tags: redisCacheSettings.?tags
    skuName: redisCacheSettings.?skuName ?? 'Basic'
    capacity: redisCacheSettings.?capacity ?? 0
    enableNonSslPort: redisCacheSettings.?enableNonSslPort ?? false
    minimumTlsVersion: redisCacheSettings.?minimumTlsVersion ?? '1.2'
    publicNetworkAccess: redisCacheSettings.?publicNetworkAccess ?? 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed Redis Cache.')
output name string = redisCache.outputs.name

@description('Resource ID of the deployed Redis Cache.')
output resourceId string = redisCache.outputs.resourceId

@description('Hostname of the Redis Cache instance.')
output hostName string = redisCache.outputs.hostName

@description('SSL port of the Redis Cache instance.')
output sslPort int = redisCache.outputs.sslPort
