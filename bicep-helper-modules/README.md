# Bicep Helper Modules

Reusable Bicep modules for deploying Azure infrastructure. Each module wraps [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) with opinionated defaults, typed parameters with full IntelliSense, and consistent `@description` decorators.

## Quick Start

Reference a module from your Bicep file using a relative path:

```bicep
module storageAccount '../../../bicep-helper-modules/StorageAccount.bicep' = {
  name: 'StorageAccount-${dateTime}'
  params: {
    storageAccountParams: {
      name: 'mystorageaccount'
    }
  }
}
```

All modules follow a consistent pattern:
- **`@description`** on every parameter and output for full IntelliSense support
- **Typed object parameters** with per-property descriptions
- **Sensible defaults** — only provide what you need to override
- **`dateTime`** and **`location`** optional on every module

---

## Module Catalog

### Compute

| Module | File | Description |
|--------|------|-------------|
| App Service Plan | `appServicePlan.bicep` | Deploys a server farm for hosting Function Apps and Logic Apps |
| Function App | `FunctionApp.bicep` | Function App with conditional Nodinite/App Insights logging |
| Logic App Standard | `LogicAppStandard.bicep` | Logic App (Standard) with conditional logging |
| Container App Environment | `ContainerAppEnvironment.bicep` | Managed environment for Container Apps |
| Container App | `ContainerApp.bicep` | Container App with ingress, scaling, and registry auth |

### Database

| Module | File | Description |
|--------|------|-------------|
| SQL Server | `SqlServer.bicep` | SQL logical server with optional databases and Entra admin |
| Cosmos DB | `CosmosDB.bicep` | Cosmos DB account with SQL databases and containers |
| Redis Cache | `RedisCache.bicep` | Azure Cache for Redis |

### Integration

| Module | File | Description |
|--------|------|-------------|
| API Management | `APIM.bicep` | APIM instance with optional products |
| APIM Settings | `APIM_Settings.bicep` | Product-level config on existing APIM |
| Data Factory | `DataFactory.bicep` | Azure Data Factory instance |
| API (Full) | `API_Modules/API.bicep` | Complete APIM API: version set, product, backends, named values, operations |

### Messaging

| Module | File | Description |
|--------|------|-------------|
| Event Hub Namespace | `EventHubNamespace.bicep` | Event Hub Namespace |
| Service Bus Namespace | `ServiceBusNamespace.bicep` | Service Bus Namespace with optional queues/topics |

### Monitoring

| Module | File | Description |
|--------|------|-------------|
| Application Insights | `ApplicationInsights.bicep` | App Insights backed by Log Analytics |
| Log Analytics Workspace | `LogAnalyticsWorkspace.bicep` | Log Analytics Workspace |
| Nodinite Storage Account | `NodiniteStorageAccount.bicep` | Storage account for Nodinite log persistence |

### Networking

| Module | File | Description |
|--------|------|-------------|
| Virtual Network | `VirtualNetwork.bicep` | VNet with subnets, delegations, service endpoints |
| Network Security Group | `NetworkSecurityGroup.bicep` | NSG with configurable security rules |
| Private Endpoint | `PrivateEndpoint.bicep` | Private Endpoint for secure PaaS connectivity |

### Security

| Module | File | Description |
|--------|------|-------------|
| Key Vault | `KeyVault.bicep` | Key Vault with RBAC auth and optional secret seeding |
| Managed Identity | `ManagedIdentity.bicep` | User-assigned managed identity |
| RBAC | `AccessControlWithRBAC/RBAC.bicep` | Role assignments on Storage, Service Bus, APIM, Key Vault, Cosmos DB, Event Hub, SQL Server, Redis, Data Factory, Web Apps, Container Apps |

### Storage

| Module | File | Description |
|--------|------|-------------|
| Storage Account | `StorageAccount.bicep` | Storage Account with optional blob containers |

---

## Logging Sub-Modules

These are called internally by `FunctionApp.bicep` and `LogicAppStandard.bicep` based on logging flags:

| Variant | Function App | Logic App |
|---------|-------------|-----------|
| Both providers | `FunctionApp_Modules/FunctionApp_BothLogging.bicep` | `LogicApp_Modules/LogicAppStandard_Core.bicep` |
| App Insights only | `FunctionApp_Modules/FunctionApp_AppInsightsOnly.bicep` | `LogicApp_Modules/LogicAppStandard_Core.bicep` |
| Nodinite only | `FunctionApp_Modules/FunctionApp_NodiniteOnly.bicep` | `LogicApp_Modules/LogicAppStandard_Core.bicep` |
| No logging | `FunctionApp_Modules/FunctionApp_NoLogging.bicep` | `LogicApp_Modules/LogicAppStandard_Core.bicep` |

> **Note:** The Logic App logging variants have been consolidated into a single unified module
> (`LogicAppStandard_Core.bicep`) that handles all combinations via `enableAppInsights` and
> `enableNodinite` feature flags.

## Shared Logging Settings

| Module | File | Description |
|--------|------|-------------|
| Nodinite Settings | `LoggingSettings/NodiniteSettings.bicep` | Full Nodinite infra: Event Hub, storage, managed identity, RBAC, APIM policy |
| App Insights Settings | `LoggingSettings/applicationInsightsSettings.bicep` | Log Analytics + App Insights + APIM logger + diagnostic settings |
| All Resources Log Settings | `LoggingSettings/AllResourcesLogSettings.bicep` | Per-resource Nodinite/App Insights logging config |

## Data Factory Sub-Modules

Template stubs in `DataFactoryResources/` for common Data Factory resources:

| Module | File |
|--------|------|
| Custom Connector | `DataFactoryResources/CustomConnector.bicep` |
| Linked Service | `DataFactoryResources/LinkedService.bicep` |
| Managed VNet | `DataFactoryResources/ManagedVirtualNetwork.bicep` |
| Pipeline | `DataFactoryResources/pipelines.bicep` |

---

## Module Catalog (for tooling)

A machine-readable `module-catalog.json` is provided at the repo root for use by the dynamic parameter-setting app. It contains every module's ID, file path, category, parameter definitions, and output names.

---

## Prerequisites

- [Azure Verified Modules](https://github.com/Azure/bicep-registry-modules) cloned as a sibling directory (`../bicep-registry-modules/`)
- Azure CLI or Azure PowerShell for deployment
- Bicep CLI v0.25+ (for nullable type support)

## Conventions

- All parameter descriptions use `Required.` or `Optional.` prefix for clarity
- Typed objects are preferred over loose `string`/`object` params
- Nullable (`?`) is used for optional typed properties
- `@allowed` decorators are used where a fixed set of values applies
- Section separators (`// ====...`) divide Parameters, Resources/Modules, and Outputs