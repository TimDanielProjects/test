# Logic App Standard Deployment Modules

This folder contains Bicep modules for deploying Azure Logic App Standard with different logging configurations. The main `LogicAppStandard.bicep` file calls the unified core module with feature flags.

## Module Files

### LogicAppStandard_Core.bicep (Unified)

Single module that handles all logging combinations via feature flags:

- **No logging** — `enableAppInsights: false` + `enableNodinite: false`
- **Application Insights only** — `enableAppInsights: true` + `enableNodinite: false`
- **Nodinite only** — `enableAppInsights: false` + `enableNodinite: true`
- **Both providers** — `enableAppInsights: true` + `enableNodinite: true`

When Application Insights is enabled, the module adds `APPINSIGHTS_INSTRUMENTATIONKEY` and
`APPLICATIONINSIGHTS_CONNECTION_STRING` to the app settings. When Nodinite is enabled, a
`Microsoft.Insights/diagnosticSettings` resource is conditionally deployed to route
`WorkflowRuntime` logs to Event Hub.

### Azure Arc Support

All logging combinations support Azure Arc (Kubernetes) hosting via:
- `isArcEnabled`: Changes the Logic App kind to include `kubernetes`
- `customLocationResourceId`: Sets the Custom Location for Arc deployment

## Usage

This module is called from the parent `LogicAppStandard.bicep` file, which converts the
string-based `NodiniteLoggingEnabled` / `ApplicationInsightsLoggingEnabled` parameters
into boolean feature flags.

## Outputs

The module returns the following outputs:
- `logicAppName`: The name of the deployed Logic App
- `logicAppId`: The resource ID of the Logic App
- `systemAssignedPrincipalId`: The principal ID of the system-assigned managed identity
- `logicAppUrl`: The default URL of the Logic App

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | string | Yes | Azure region for deployment |
| `logicAppName` | string | Yes | Name of the Logic App to create |
| `serverFarmResourceId` | string | Yes | Resource ID of the App Service Plan |
| `logicAppSettings` | object | Yes | Merged environment variables (base + custom) |
| `enableAppInsights` | bool | No | Enable Application Insights logging (default: false) |
| `applicationInsightResourceId` | string | No | Resource ID of App Insights (required when enabled) |
| `enableNodinite` | bool | No | Enable Nodinite diagnostic logging (default: false) |
| `sharedResources` | object | No | Shared resources with Event Hub info (required when Nodinite enabled) |
| `isArcEnabled` | bool | No | Enable Azure Arc hosting (default: false) |
| `customLocationResourceId` | string | No | Custom Location resource ID for Arc (default: '') |

## Required Storage Account

The parent `LogicAppStandard.bicep` file requires a `storageAccount` parameter with:
- `resourceId`: The Azure resource ID of the storage account
- `name`: The name of the storage account

This storage account is used for:
- Logic App runtime files and secrets
- Workflow state and execution data
- Content share for the Logic App
