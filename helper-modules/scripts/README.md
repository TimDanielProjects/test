# Deployment Scripts

Bash scripts used by CI/CD pipelines for Azure resource provisioning.

> **Migrated from `generic-script-files/`** — these scripts are now co-located
> within `helper-modules/` for a single-source-of-truth approach. Copies
> also exist in `template-deployment-modules/Scripts/` for Azure DevOps pipeline
> usage.

## Scripts

| Script | Purpose |
|--------|---------|
| `CheckForKeyVault.sh` | Checks for / creates a Key Vault in the given resource group |
| `CheckForResourceGroup.sh` | Checks for / creates an Azure resource group |
| `CheckForStorageAccount.sh` | Checks for / creates a Storage Account |
| `RegisterResourceProviders.sh` | Registers required Azure resource providers for integration services |
| `SetRBACRole.sh` | Assigns Storage Blob Data Contributor role to a given service principal |
