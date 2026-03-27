# Power Platform Repository

This repository contains a Power Platform solution with supporting Azure infrastructure (Key Vault, optional APIM custom connectors) deployed via Bicep and Power Platform CLI.

## Structure

```
├── Deployment/
│   ├── Bicep/                          # Azure infrastructure
│   │   ├── Main.bicep
│   │   └── bicepconfig.json
│   ├── Pipeline/                       # CI/CD pipeline definitions
│   │   ├── Pipeline.yml
│   │   ├── Build.yml
│   │   └── Release.yml
│   └── PowerPlatform/                  # PP-specific deployment scripts
│       ├── environment-setup.ps1       # Create PP environments via PAC CLI
│       ├── solution-import.ps1         # Import managed solutions
│       └── solution-settings/          # Per-environment settings
│           ├── dev.json
│           ├── test.json
│           └── prod.json
├── solutions/                          # Unpacked Power Platform solutions
│   └── README.md
└── README.md
```

## Supported Application Types

| Type | Managed via |
|------|------------|
| Canvas App | Power Platform solution |
| Model-Driven App | Power Platform solution |
| Power Automate | Power Platform solution |
| Power BI | Power Platform solution |
| Power Pages | Power Platform solution |
| Copilot Studio | Power Platform solution |
| Custom Connector | Power Platform solution + APIM |

## Getting Started

1. Set up your Power Platform environments: `.\Deployment\PowerPlatform\environment-setup.ps1`
2. Create your solution in the Power Platform maker portal
3. Clone the solution: `pac solution clone --name YourSolution --output-directory ./solutions/Core/src`
4. Update environment-specific settings in `solution-settings/`

## CI/CD

The pipeline:
1. Deploys Azure infrastructure (Key Vault secrets, optional resources) via Bicep
2. Packs Power Platform solutions from `solutions/` directory
3. Imports managed solutions to the target environment with settings overrides
