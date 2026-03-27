# Function App Deployment Modules

This folder contains the unified Bicep module for deploying Azure Function Apps with conditional logging.

## FunctionApp_Core.bicep

Single module that handles all four logging combinations via boolean feature flags:

| `enableAppInsights` | `enableNodinite` | Behaviour |
|---------------------|------------------|-----------|
| `false` | `false` | No additional logging |
| `true` | `false` | Application Insights instrumentation keys added to app settings |
| `false` | `true` | Nodinite diagnostic settings (FunctionAppLogs → Event Hub) |
| `true` | `true` | Both Application Insights + Nodinite |

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | string | Yes | Azure region |
| `functionAppName` | string | Yes | Name of the Function App |
| `serverFarmResourceId` | string | Yes | Resource ID of the App Service Plan |
| `functionAppSettings` | object | Yes | Merged environment variables |
| `enableAppInsights` | bool | No | Enable Application Insights (default: false) |
| `applicationInsightResourceId` | string | No | App Insights resource ID (required when enableAppInsights is true) |
| `enableNodinite` | bool | No | Enable Nodinite diagnostic logging (default: false) |
| `sharedResources` | object | No | Shared resources for Event Hub info (required when enableNodinite is true) |

### Outputs

- `functionAppName` — The name of the deployed Function App
- `functionAppId` — The resource ID of the Function App
- `systemAssignedPrincipalId` — The principal ID of the system-assigned managed identity
- `defaultHostname` — The default hostname of the Function App

### Function App Configuration

The Function App is configured with:
- **.NET 9.0** runtime with isolated worker process
- **CORS enabled** for all origins
- **HTTPS only** with TLS 1.2 minimum
- **Always On** enabled
- **System-assigned managed identity**

## Usage

This module is called from the parent `FunctionApp.bicep` — do not reference it directly.
