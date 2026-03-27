# Network Repository

This repository contains the network infrastructure (VNet, NSGs, subnets) deployed via Bicep.

## Structure

```
├── Deployment/
│   ├── Bicep/              # Infrastructure as Code (Bicep)
│   │   ├── Main.bicep      # VNet, NSGs, and subnet definitions
│   │   └── bicepconfig.json
│   └── Pipeline/           # CI/CD pipeline definitions
│       ├── Pipeline.yml    # Pipeline entry point
│       ├── Build.yml       # Build stage
│       └── Release.yml     # Release stage
└── README.md
```

## Getting Started

1. Update subnet address prefixes in the pipeline variables
2. Adjust NSG rules as needed for your environment
3. Deploy via the pipeline

## Subnet Layout

| Subnet | Default Prefix | Purpose |
|--------|---------------|---------|
| snet-apim | 10.0.0.0/24 | API Management |
| snet-logicapp | 10.0.1.0/24 | Logic Apps (delegated) |
| snet-functionapp | 10.0.2.0/24 | Function Apps (delegated) |
| snet-privateendpoints | 10.0.3.0/24 | Private Endpoints |
| snet-default | 10.0.4.0/24 | General purpose |
