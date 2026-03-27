# .SYNOPSIS
#     Creates and configures Power Platform environments for the solution.
#
# .DESCRIPTION
#     This script creates Power Platform environments (dev, test, prod) using the Power Platform CLI.
#     It configures the environment settings and creates the necessary app registrations for CI/CD.
#
# .PARAMETER EnvironmentName
#     The name of the Power Platform environment to create.
#
# .PARAMETER EnvironmentType
#     The type of environment: Sandbox, Production, Developer, or Trial.
#
# .PARAMETER Region
#     The region for the Power Platform environment (e.g., europe, unitedstates).
#
# .PARAMETER OrganisationSuffix
#     The organisation suffix used in naming conventions.
#
# .PARAMETER IntegrationId
#     The integration/solution identifier.
#
# .EXAMPLE
#     .\environment-setup.ps1 -EnvironmentName "myapp-dev" -EnvironmentType "Sandbox" -Region "europe"

param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Sandbox", "Production", "Developer", "Trial")]
    [string]$EnvironmentType = "Sandbox",

    [Parameter(Mandatory = $false)]
    [string]$Region = "europe",

    [Parameter(Mandatory = $false)]
    [string]$OrganisationSuffix = "",

    [Parameter(Mandatory = $false)]
    [string]$IntegrationId = ""
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Power Platform Environment Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verify PAC CLI is installed
try {
    $pacVersion = pac --version
    Write-Host "Power Platform CLI version: $pacVersion" -ForegroundColor Green
}
catch {
    Write-Host "Power Platform CLI (pac) is not installed." -ForegroundColor Red
    Write-Host "Install with: dotnet tool install --global Microsoft.PowerApps.CLI.Tool" -ForegroundColor Yellow
    exit 1
}

# Check if authenticated
Write-Host "Checking authentication..." -ForegroundColor Yellow
try {
    $authList = pac auth list
    if ($authList -match "No profiles") {
        Write-Host "No authentication profiles found. Please run: pac auth create" -ForegroundColor Red
        exit 1
    }
    Write-Host "Authentication verified." -ForegroundColor Green
}
catch {
    Write-Host "Failed to check authentication: $_" -ForegroundColor Red
    exit 1
}

# Build environment display name
$envDisplayName = if ($OrganisationSuffix -and $IntegrationId) {
    "$OrganisationSuffix-$IntegrationId-$EnvironmentName"
} else {
    $EnvironmentName
}

# Create the environment
Write-Host ""
Write-Host "Creating Power Platform environment..." -ForegroundColor Yellow
Write-Host "  Name: $envDisplayName" -ForegroundColor White
Write-Host "  Type: $EnvironmentType" -ForegroundColor White
Write-Host "  Region: $Region" -ForegroundColor White

try {
    pac admin create `
        --name "$envDisplayName" `
        --type $EnvironmentType `
        --region $Region `
        --currency USD `
        --language 1033

    Write-Host "Environment '$envDisplayName' created successfully!" -ForegroundColor Green
}
catch {
    if ($_.Exception.Message -match "already exists") {
        Write-Host "Environment '$envDisplayName' already exists - skipping creation." -ForegroundColor Yellow
    }
    else {
        Write-Host "Failed to create environment: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Environment setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to https://make.powerapps.com and select the new environment" -ForegroundColor White
Write-Host "  2. Create your solution in the maker portal" -ForegroundColor White
Write-Host "  3. Clone the solution: pac solution clone --name YourSolution" -ForegroundColor White
