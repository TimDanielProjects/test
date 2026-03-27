
// ── Parameters ──────────────────────────────────────────────────

param apiId string
param regionSuffix string
param organisationSuffix string
param environmentSuffix string
param dateTime string = utcNow()

// ── Variables ───────────────────────────────────────────────────

var sharedResourceBaseName = toLower('${organisationSuffix}-int-shared')
var sharedResourceGroup = {
  name: resourceGroup().name
}
var productName = split(toLower(apiId), '-')[0]
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')
var apiUrlSuffix = replace(toLower(apiId), '-', '/')

var keyVaultName = '${sharedResourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${sharedResourceBaseName}-kv-${toLower(environmentSuffix)}'

var api = {
  displayName: toLower(apiId)
  description: ''
  name: toLower(apiId)
  apiUrlSuffix: apiUrlSuffix
  webServiceUrl: 'https://placeholder'
  productName: productName
  apiVersion: 'v1'
  backends: []
  allOperationsPolicyXml: ''
  // Named values are created as secrets in APIM. Example:
  //   {
  //     name: 'my-secret'
  //     displayName: 'My Secret'
  //     value: 'placeholder-value'
  //   }
  namedValues: []
  // Each operation supports optional queryParameters, headerParameters, and responseParameters.
  // Example queryParameters:
  //   queryParameters: [
  //     { name: 'filter', type: 'string', required: false, values: [] }
  //   ]
  // Example headerParameters:
  //   headerParameters: [
  //     { name: 'Ocp-Apim-Subscription-Key', type: 'string', required: true }
  //   ]
  operations: [
    {
      name: 'mordin'
      operationPath: '/mordin'
      method: 'GET'
      policyXml: loadTextContent('../Policies/mordin.policy.xml')
    }
    {
      name: 'syrdin'
      operationPath: '/syrdin'
      method: 'GET'
      policyXml: loadTextContent('../Policies/syrdin.policy.xml')
    }
  ]
}

// ── Existing shared resources ───────────────────────────────────

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: length(keyVaultName) <= 24 ? keyVaultName : fixedKeyVaultName
  scope: resourceGroup(sharedResourceGroup.name)
}

resource sharedAPIM 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: '${sharedResourceBaseName}-apim-${resourceEnding}'
  scope: resourceGroup(resourceGroup().name)
}


// ── Module deployments ──────────────────────────────────────────

module apiModule '../../../helper-modules/API_Modules/API.bicep' = {
  name: 'API-Main-${dateTime}'
  params: {
    dateTime: dateTime
    environmentSuffix: environmentSuffix
    api: api
    apiManagement: {
      name: sharedAPIM.name
      resourceGroupName: sharedResourceGroup.name
    }
  }
}

// ── Outputs ─────────────────────────────────────────────────────

output noOutput string = ''
