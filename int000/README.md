# Integration Repository

This repository contains an Azure integration project with Logic Apps Standard and Azure Functions.

## Structure

```
├── Deployment/
│   ├── Bicep/              # Infrastructure as Code (Bicep)
│   │   ├── Main.bicep      # Main deployment template
│   │   ├── Setup.bicep     # Pre-deployment setup (storage, Key Vault)
│   │   └── bicepconfig.json
│   └── Pipeline/           # CI/CD pipeline definitions
│       ├── Pipeline.yml    # Pipeline entry point
│       ├── Build.yml       # Build stage
│       └── Release.yml     # Release stage
├── LogicAppWorkspace/
│   ├── Function/           # Azure Functions (.NET 8 isolated)
│   │   ├── Function.cs     # Template function with Nodinite logging
│   │   ├── Program.cs      # Host builder and DI configuration
│   │   └── Function.csproj
│   └── LogicApp/           # Logic App Standard workflows
│       ├── host.json       # Extension bundle configuration
│       ├── connections.json # Connection definitions (APIM, Blob, ServiceBus, etc.)
│       ├── parameters.json # Workflow parameters
│       ├── Artifacts/Maps/ # XSLT transformation maps
│       └── wf-example/     # Example stateful workflow
└── README.md
```

## Getting Started

1. Open the solution in Visual Studio
2. Configure `local.settings.json` for local development
3. Run the Function project for custom code
4. Use VS Code with the Logic Apps extension for workflow design

## CI/CD

The pipeline deploys:
1. **Bicep** infrastructure (Storage, Logic App, Function App, RBAC)
2. **Logic App** workflows (zip deploy)
3. **Function App** package (zip deploy)
