// ============================================================================
// Data Factory Linked Service – HTTP / REST
// Connects Data Factory to a generic HTTP or REST endpoint.
// Supports Anonymous, Basic, ClientCertificate, and Managed Identity auth.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the linked service to create.')
param linkedServiceName string

@description('Required. HTTP linked service configuration.')
param httpSettings {
  @description('Required. Base URL of the HTTP endpoint (e.g. https://api.example.com).')
  url: string

  @description('Optional. Authentication type. Defaults to Anonymous.')
  authenticationType: ('Anonymous' | 'Basic' | 'ClientCertificate' | 'ManagedServiceIdentity')?

  @description('Optional. Whether to validate the server SSL certificate. Defaults to true.')
  enableServerCertificateValidation: bool?

  @description('Conditional. User name for Basic authentication.')
  userName: string?

  @description('Conditional. Azure Key Vault secret reference for the password or client certificate. Recommended over inline secrets.')
  keyVaultSecretReference: {
    @description('Required. Name of the Key Vault linked service.')
    linkedServiceName: string
    @description('Required. Name of the secret in Key Vault.')
    secretName: string
    @description('Optional. Version of the secret.')
    secretVersion: string?
  }?

  @description('Optional. Resource ID of a user-assigned managed identity credential (for ManagedServiceIdentity auth).')
  credentialResourceId: string?

  @description('Optional. AAD resource / audience for managed identity token acquisition (for ManagedServiceIdentity auth).')
  aadResourceId: string?

  @description('Optional. Description of the linked service.')
  description: string?
}

// ============================================================================
// Variables
// ============================================================================

var authType = httpSettings.?authenticationType ?? 'Anonymous'

var keyVaultRef = httpSettings.?keyVaultSecretReference != null
  ? {
      type: 'AzureKeyVaultSecret'
      store: {
        referenceName: httpSettings.keyVaultSecretReference!.linkedServiceName
        type: 'LinkedServiceReference'
      }
      secretName: httpSettings.keyVaultSecretReference!.secretName
      secretVersion: httpSettings.keyVaultSecretReference!.?secretVersion
    }
  : null

var baseTypeProperties = {
  url: httpSettings.url
  authenticationType: authType
  enableServerCertificateValidation: httpSettings.?enableServerCertificateValidation ?? true
}

var basicAuthProperties = authType == 'Basic'
  ? {
      userName: httpSettings.?userName ?? ''
      password: keyVaultRef
    }
  : {}

var clientCertAuthProperties = authType == 'ClientCertificate'
  ? {
      embeddedCertData: keyVaultRef
    }
  : {}

var managedIdentityProperties = authType == 'ManagedServiceIdentity'
  ? {
      aadResourceId: httpSettings.?aadResourceId ?? ''
      credential: httpSettings.?credentialResourceId != null
        ? {
            referenceName: 'UserAssignedManagedIdentity'
            type: 'CredentialReference'
          }
        : null
    }
  : {}

var typeProperties = union(baseTypeProperties, basicAuthProperties, clientCertAuthProperties, managedIdentityProperties)

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
    type: 'HttpServer'
    description: httpSettings.?description ?? 'HTTP linked service'
    typeProperties: typeProperties
  }
}
