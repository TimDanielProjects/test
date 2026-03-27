# Power Platform Solutions

This folder contains unpacked Power Platform solution sources. Each subfolder is one solution.

## Structure

```
solutions/
├── Core/                    (Foundation: Dataverse tables, security roles, env variables)
│   └── src/
│       └── Other/
│           ├── Solution.xml
│           └── Customizations.xml
├── Apps/                    (Canvas apps, model-driven apps)
│   └── src/
│       └── ...
├── Automation/              (Power Automate cloud flows)
│   └── src/
│       └── ...
└── README.md
```

## Getting Started

1. **Clone an existing solution** from your Power Platform environment:
   ```bash
   pac solution clone --name YourSolutionName --output-directory ./Core/src
   ```

2. **Or initialise a new solution**:
   ```bash
   pac solution init --publisher-name YourPublisher --publisher-prefix cr --outputDirectory ./Core/src
   ```

3. Add more solution folders as needed (e.g., `Apps/`, `Automation/`, `Analytics/`).

## Multi-Solution Guidance

| Solution | Purpose | Typical Contents |
|----------|---------|-----------------|
| **Core** | Foundation layer | Dataverse tables, security roles, environment variables, shared components |
| **Apps** | User interfaces | Canvas apps, model-driven apps, custom pages |
| **Automation** | Process automation | Power Automate cloud flows, business rules |
| **Analytics** | Reporting | Power BI embedded dashboards, Dataverse views |

### Dependency Order

Solutions are **imported in alphabetical order** by folder name. Use numeric prefixes if you need explicit ordering:
```
solutions/
├── 01-Core/
├── 02-Apps/
├── 03-Automation/
```

Or configure the `solutionOrder` parameter in the pipeline to set explicit ordering.

## Working with Solutions

- **Export**: `pac solution export --name YourSolution --path ./solution.zip`
- **Unpack**: `pac solution unpack --zipfile ./solution.zip --folder ./Core/src`
- **Pack**: `pac solution pack --folder ./Core/src --zipfile ./Core.zip --processCanvasApps`
- **Import**: `pac solution import --path ./Core.zip`

## Best Practices

- Always use **solution-aware** development
- Use **environment variables** for environment-specific configuration
- Use **connection references** instead of direct connections
- Keep solution components under a **single publisher** for ALM
- Put shared tables/components in the **Core** solution and reference them from other solutions
