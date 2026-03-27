# APIM Policy Files

XML policy files used by Bicep modules for Azure API Management configuration.

## Files

| File | Description |
|------|-------------|
| `allOperations.policy.xml` | Default all-operations policy — removes subscription key header |
| `allApiPolicy.xml` | All-API policy that includes the Nodinite logging fragment |
| `genericNodiniteLoggingPolicyFragment.xml` | Reusable APIM policy fragment for Nodinite logging via blob storage |

## Usage

These files are loaded at deployment time using Bicep's `loadTextContent()`:

```bicep
value: loadTextContent('../policies/allApiPolicy.xml')
```

Referenced by:
- `LoggingSettings/NodiniteSettings.bicep` — deploys the Nodinite policy fragment and all-API policy
- Generated API templates — loads `allOperations.policy.xml` for default operation policies

> **Migration note:** These files were previously in a separate `generic-policy-files/` repository.
> They are now co-located with the Bicep modules that consume them, eliminating the fragile
> cross-repository `loadTextContent` path dependency.
