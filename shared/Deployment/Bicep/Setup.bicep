
// ── Setup parameters ────────────────────────────────────────────

param environmentSuffix string
param regionSuffix string
param organisationSuffix string
param integrationId string


// ── Variables ───────────────────────────────────────────────────

var resourceBaseName = toLower('${organisationSuffix}-int-${integrationId}')
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')
var keyVaultName = '${resourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${resourceBaseName}-kv-${toLower(environmentSuffix)}'


// ── Outputs ─────────────────────────────────────────────────────

output storageAccountName string = 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}'
output keyVaultName string = length(keyVaultName) > 24 ? fixedKeyVaultName : keyVaultName
output subscriptionId string = subscription().subscriptionId
