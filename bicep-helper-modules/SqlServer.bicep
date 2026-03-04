// ============================================================================
// SQL Server + Optional Database
// Deploys an Azure SQL logical server with optional SQL Database.
// Supports Microsoft Entra (AAD) admin, firewall rules, and minimum TLS.
// Uses the AVM registry module.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Optional. UTC timestamp used to generate unique deployment names. Defaults to current time.')
param dateTime string = utcNow()

@description('Optional. Azure region. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Required. SQL Server configuration.')
param sqlServerSettings {
  @description('Required. Name of the SQL Server (must be globally unique).')
  name: string

  @description('Optional. Tags to apply to the server resource.')
  tags: object?

  @description('Optional. Administrator login name. Required if not using Entra-only auth.')
  administratorLogin: string?

  @description('Optional. Administrator login password. Required if not using Entra-only auth.')
  @secure()
  administratorLoginPassword: string?

  @description('Optional. Minimum TLS version. Defaults to 1.2.')
  minimalTlsVersion: ('1.0' | '1.1' | '1.2')?

  @description('Optional. Whether public network access is allowed. Defaults to Enabled.')
  publicNetworkAccess: ('Enabled' | 'Disabled')?

  @description('Optional. Microsoft Entra (AAD) administrator configuration.')
  entraAdministrator: {
    @description('Required. Login name for the Entra admin.')
    login: string

    @description('Required. Object ID of the Entra admin user, group, or service principal.')
    sid: string

    @description('Required. Principal type of the Entra admin.')
    principalType: ('Application' | 'Group' | 'User')

    @description('Optional. Whether Entra-only authentication is enabled. Defaults to false.')
    azureADOnlyAuthentication: bool?

    @description('Optional. Tenant ID of the Entra admin. Defaults to the current tenant.')
    tenantId: string?
  }?

  @description('Optional. Array of firewall rules to create on the server.')
  firewallRules: {
    @description('Required. Name of the firewall rule.')
    name: string

    @description('Required. Start IP address of the allowed range.')
    startIpAddress: string

    @description('Required. End IP address of the allowed range.')
    endIpAddress: string
  }[]?

  @description('Optional. Array of databases to create on the server.')
  databases: {
    @description('Required. Name of the database.')
    name: string

    @description('Optional. SKU name (e.g. Basic, S0, S1, P1, GP_S_Gen5_1). Defaults to Basic.')
    skuName: string?

    @description('Optional. Maximum size of the database in bytes.')
    maxSizeBytes: int?

    @description('Optional. Collation of the database. Defaults to SQL_Latin1_General_CP1_CI_AS.')
    collation: string?

    @description('Optional. Availability zone for the database (-1 for no preference, 1, 2, or 3). Defaults to -1.')
    availabilityZone: (-1 | 1 | 2 | 3)?
  }[]?
}

// ============================================================================
// Modules
// ============================================================================

module sqlServer '../bicep-registry-modules/avm/res/sql/server/main.bicep' = {
  name: 'SqlServer-${dateTime}'
  params: {
    name: sqlServerSettings.name
    location: location
    tags: sqlServerSettings.?tags
    administratorLogin: sqlServerSettings.?administratorLogin ?? ''
    administratorLoginPassword: sqlServerSettings.?administratorLoginPassword ?? ''
    minimalTlsVersion: sqlServerSettings.?minimalTlsVersion ?? '1.2'
    publicNetworkAccess: sqlServerSettings.?publicNetworkAccess ?? 'Enabled'
    administrators: sqlServerSettings.?entraAdministrator != null
      ? {
          administratorType: 'ActiveDirectory'
          login: sqlServerSettings.entraAdministrator!.login
          sid: sqlServerSettings.entraAdministrator!.sid
          principalType: sqlServerSettings.entraAdministrator!.principalType
          azureADOnlyAuthentication: sqlServerSettings.entraAdministrator!.?azureADOnlyAuthentication ?? false
          tenantId: sqlServerSettings.entraAdministrator!.?tenantId
        }
      : null
    firewallRules: sqlServerSettings.?firewallRules ?? []
    databases: [
      for db in (sqlServerSettings.?databases ?? []): {
        name: db.name
        availabilityZone: db.?availabilityZone ?? -1
        sku: {
          name: db.?skuName ?? 'Basic'
        }
        maxSizeBytes: db.?maxSizeBytes
        collation: db.?collation ?? 'SQL_Latin1_General_CP1_CI_AS'
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the deployed SQL Server.')
output name string = sqlServer.outputs.name

@description('Resource ID of the deployed SQL Server.')
output resourceId string = sqlServer.outputs.resourceId

@description('Fully qualified domain name of the SQL Server.')
output fullyQualifiedDomainName string = sqlServer.outputs.fullyQualifiedDomainName
