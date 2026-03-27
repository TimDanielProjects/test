# API Repository

This repository contains an API Management API definition deployed via Bicep.

## Structure

```
├── Deployment/
│   ├── Bicep/              # Infrastructure as Code (Bicep)
│   │   ├── Main.bicep      # API definition and deployment
│   │   └── bicepconfig.json
│   ├── Pipeline/           # CI/CD pipeline definitions
│   │   ├── Pipeline.yml    # Pipeline entry point
│   │   ├── Build.yml       # Build stage (copies Bicep + policies)
│   │   └── Release.yml     # Release stage (deploys to shared RG)
│   └── Policies/           # APIM operation policy files
│       └── myOperation.policy.xml
└── README.md
```

## Getting Started

1. Update `Main.bicep` with your API definition (display name, operations, backend URL)
2. Add operation-specific policy XML files in `Deployment/Policies/`
3. The pipeline deploys the API to the shared APIM instance

## CI/CD

The pipeline deploys to the shared resource group containing the APIM instance.
