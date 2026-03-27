# Shared Infrastructure

This repository deploys the shared (hub) resources used by all integration projects.

## Structure

```
├── Deployment/
│   ├── Bicep/
│   │   ├── Main.bicep          # Main deployment template (all shared resources)
│   │   ├── Setup.bicep         # Pre-deployment setup (Resource Group, Storage Account, Key Vault)
│   │   └── bicepconfig.json
│   └── Pipeline/
│       ├── Pipeline.yml        # Pipeline entry point
│       ├── Build.yml           # Build stage
│       └── Release.yml         # Release stage (setup + deploy per environment)
└── README.md
```

## What Gets Deployed

The shared resource group follows the naming pattern:
```
{organisation}-int-shared-rg-{region}-{environment}
```

Typical resources include:
- **API Management** – Central API gateway for all integrations
- **Service Bus Namespace** – Enterprise messaging
- **Event Hub Namespace** – Event streaming
- **Key Vault** – Centralised secret management
- **Application Insights** – Monitoring and telemetry
- **Log Analytics Workspace** – Log aggregation
- **App Service Plan** – Shared compute for Logic Apps
- **Storage Account** – Shared blob storage

The exact set depends on the resources selected during project creation.

## Pipeline

The release pipeline runs two stages per environment:

1. **Setup** – Ensures the Resource Group, Storage Account, and Key Vault exist before the main deployment. Assigns RBAC roles required by the deployment service principal.
2. **Deploy** – Deploys `Main.bicep` with all shared resources.

## Prerequisites

The Azure DevOps service connection (app registration) needs the following roles on the target subscription:

| Role | Purpose |
|------|---------|
| **Contributor** | Create and manage resources |
| **User Access Administrator** *or* **Role Based Access Control Administrator** | Assign RBAC roles to managed identities |
| **Storage Blob Data Contributor** | Access the shared storage account |

## CI/CD

1. Push changes to trigger the pipeline
2. The build stage packages Bicep templates into an artifact
3. The release stage deploys per environment (dev → test → prod)
