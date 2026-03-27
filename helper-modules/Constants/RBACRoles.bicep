// ============================================================================
// RBAC Role Constants
// Centralized Azure built-in role definition IDs used across PlatyPal Bicep
// deployments. Eliminates hardcoded GUIDs scattered across template files.
//
// Usage:
//   import { roles } from '../Constants/RBACRoles.bicep'
//   roleDefinitionId: roles.storageBlobDataContributor
//
// Reference: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// ============================================================================

// ── Storage Roles ──────────────────────────────────────────────────────────

@export()
@description('Storage Blob Data Contributor — Read, write, and delete Azure Storage containers and blobs.')
var storageBlobDataContributor = '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

@export()
@description('Storage File Data SMB Share Contributor — Read, write, and delete in Azure Storage file shares over SMB.')
var storageFileDataSmbShareContributor = '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd'

@export()
@description('Storage Account Contributor — Manage storage accounts (not data access).')
var storageAccountContributor = '/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'

@export()
@description('Storage Blob Data Reader — Read Azure Storage containers and blobs.')
var storageBlobDataReader = '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

// ── Messaging Roles ────────────────────────────────────────────────────────

@export()
@description('Azure Service Bus Data Owner — Full access to Azure Service Bus resources.')
var serviceBusDataOwner = '/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419'

@export()
@description('Azure Service Bus Data Sender — Send access to Azure Service Bus resources.')
var serviceBusDataSender = '/providers/Microsoft.Authorization/roleDefinitions/69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'

@export()
@description('Azure Service Bus Data Receiver — Receive access to Azure Service Bus resources.')
var serviceBusDataReceiver = '/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

@export()
@description('Azure Event Hubs Data Owner — Full access to Azure Event Hubs resources.')
var eventHubsDataOwner = '/providers/Microsoft.Authorization/roleDefinitions/f526a384-b230-433a-b45c-95f59c4a2dec'

// ── API Management Roles ───────────────────────────────────────────────────

@export()
@description('API Management Service Contributor — Can manage service and the APIs.')
var apiManagementServiceContributor = '/providers/Microsoft.Authorization/roleDefinitions/312a565d-c81f-4fd8-895a-4e21e48d571c'

// ── Key Vault Roles ────────────────────────────────────────────────────────

@export()
@description('Key Vault Secrets User — Read secret contents.')
var keyVaultSecretsUser = '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'

@export()
@description('Key Vault Secrets Officer — Perform any action on the secrets of a key vault.')
var keyVaultSecretsOfficer = '/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

@export()
@description('Key Vault Contributor — Manage key vaults, but not access to the secrets, keys, or certificates within.')
var keyVaultContributor = '/providers/Microsoft.Authorization/roleDefinitions/f25e0fa2-a7c8-4377-a976-54943a77a395'

// ── General Roles ──────────────────────────────────────────────────────────

@export()
@description('Contributor — Full management access (no RBAC assignment).')
var contributor = '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

@export()
@description('Reader — View all resources.')
var reader = '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

// ── Database Roles ─────────────────────────────────────────────────────────

@export()
@description('SQL Server Contributor — Manage SQL servers and databases (not access).')
var sqlServerContributor = '/providers/Microsoft.Authorization/roleDefinitions/6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437'

@export()
@description('Cosmos DB Account Reader — Read Azure Cosmos DB account data.')
var cosmosDbAccountReader = '/providers/Microsoft.Authorization/roleDefinitions/fbdf93bf-df7d-467e-a4d2-9458aa1360c8'

// ── Convenience Map ────────────────────────────────────────────────────────

@export()
@description('All role definition IDs in a single object for easy lookup by property name.')
var roles = {
  // Storage
  storageBlobDataContributor: storageBlobDataContributor
  storageFileDataSmbShareContributor: storageFileDataSmbShareContributor
  storageAccountContributor: storageAccountContributor
  storageBlobDataReader: storageBlobDataReader

  // Messaging
  serviceBusDataOwner: serviceBusDataOwner
  serviceBusDataSender: serviceBusDataSender
  serviceBusDataReceiver: serviceBusDataReceiver
  eventHubsDataOwner: eventHubsDataOwner

  // API Management
  apiManagementServiceContributor: apiManagementServiceContributor

  // Key Vault
  keyVaultSecretsUser: keyVaultSecretsUser
  keyVaultSecretsOfficer: keyVaultSecretsOfficer
  keyVaultContributor: keyVaultContributor

  // General
  contributor: contributor
  reader: reader

  // Database
  sqlServerContributor: sqlServerContributor
  cosmosDbAccountReader: cosmosDbAccountReader
}
