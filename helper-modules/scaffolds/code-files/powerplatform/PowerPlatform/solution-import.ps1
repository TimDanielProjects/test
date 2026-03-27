<#
.SYNOPSIS
    Imports managed Power Platform solutions to a target environment.

.DESCRIPTION
    This script imports one or more packed managed solution .zip files to a Power Platform environment.
    If a folder is provided, all .zip files are imported in alphabetical order.
    It applies environment-specific settings (connection references, environment variables)
    from JSON settings files.

.PARAMETER SolutionPath
    Path to a single solution .zip file or a folder containing multiple .zip files.

.PARAMETER EnvironmentUrl
    The URL of the target Power Platform environment (e.g., https://myorg-dev.crm4.dynamics.com).

.PARAMETER SettingsFile
    Path to a shared settings JSON file (used when no per-solution settings exist).

.PARAMETER SettingsFolder
    Path to a folder containing per-solution settings subfolders.
    Convention: {SettingsFolder}/{SolutionName}/{env}.json

.PARAMETER Environment
    Environment name (dev, test, prod) - used to find the correct settings file in SettingsFolder.

.PARAMETER Async
    Whether to import asynchronously (default: true).

.EXAMPLE
    .\solution-import.ps1 -SolutionPath "./packed/" -EnvironmentUrl "https://myorg-dev.crm4.dynamics.com" -SettingsFolder "./solution-settings" -Environment "dev"

.EXAMPLE
    .\solution-import.ps1 -SolutionPath "./Core.zip" -EnvironmentUrl "https://myorg-dev.crm4.dynamics.com" -SettingsFile "./solution-settings/dev.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SolutionPath,

    [Parameter(Mandatory = $true)]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory = $false)]
    [string]$SettingsFile = "",

    [Parameter(Mandatory = $false)]
    [string]$SettingsFolder = "",

    [Parameter(Mandatory = $false)]
    [string]$Environment = "",

    [Parameter(Mandatory = $false)]
    [bool]$Async = $true
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Power Platform Solution Import" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Determine solution files to import
if (Test-Path $SolutionPath -PathType Container) {
    # Folder provided - find all .zip files and sort alphabetically
    $solutionFiles = Get-ChildItem -Path $SolutionPath -Filter "*.zip" | Sort-Object Name
    if ($solutionFiles.Count -eq 0) {
        Write-Host "No .zip files found in: $SolutionPath" -ForegroundColor Red
        exit 1
    }
    Write-Host "Found $($solutionFiles.Count) solution(s) to import:" -ForegroundColor White
    $solutionFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
}
elseif (Test-Path $SolutionPath -PathType Leaf) {
    # Single file provided
    $solutionFiles = @(Get-Item $SolutionPath)
    Write-Host "Solution file: $SolutionPath" -ForegroundColor White
}
else {
    Write-Host "Solution path not found: $SolutionPath" -ForegroundColor Red
    exit 1
}

Write-Host "Target environment: $EnvironmentUrl" -ForegroundColor White

# Set the target environment
Write-Host ""
Write-Host "Setting target environment..." -ForegroundColor Yellow
pac auth create --environment $EnvironmentUrl

# Import each solution in order
foreach ($solutionFile in $solutionFiles) {
    $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($solutionFile.Name)

    Write-Host ""
    Write-Host "--------------------------------------------" -ForegroundColor Cyan
    Write-Host "Importing solution: $solutionName" -ForegroundColor Cyan
    Write-Host "--------------------------------------------" -ForegroundColor Cyan

    # Build import command
    $importArgs = @(
        "solution", "import",
        "--path", $solutionFile.FullName,
        "--activate-plugins", "true",
        "--force-overwrite", "true",
        "--publish-changes", "true"
    )

    if ($Async) {
        $importArgs += "--async"
        $importArgs += "--max-async-wait-in-min"
        $importArgs += "120"
    }

    # Resolve settings file
    $resolvedSettings = ""

    # Priority 1: Per-solution settings in SettingsFolder
    if ($SettingsFolder -and $Environment) {
        $perSolutionPath = Join-Path $SettingsFolder "$solutionName/$Environment.json"
        if (Test-Path $perSolutionPath) {
            $resolvedSettings = $perSolutionPath
            Write-Host "  Applying per-solution settings: $perSolutionPath" -ForegroundColor White
        }
    }

    # Priority 2: Shared settings file in SettingsFolder
    if (-not $resolvedSettings -and $SettingsFolder -and $Environment) {
        $sharedPath = Join-Path $SettingsFolder "$Environment.json"
        if (Test-Path $sharedPath) {
            $resolvedSettings = $sharedPath
            Write-Host "  Applying shared settings: $sharedPath" -ForegroundColor White
        }
    }

    # Priority 3: Explicit SettingsFile parameter
    if (-not $resolvedSettings -and $SettingsFile -and (Test-Path $SettingsFile)) {
        $resolvedSettings = $SettingsFile
        Write-Host "  Applying settings: $SettingsFile" -ForegroundColor White
    }

    if ($resolvedSettings) {
        $importArgs += "--settings-file"
        $importArgs += $resolvedSettings
    }
    else {
        Write-Host "  No settings file found - importing without settings override" -ForegroundColor Yellow
    }

    # Import
    Write-Host "  Importing..." -ForegroundColor Yellow
    try {
        & pac @importArgs
        Write-Host "  Solution '$solutionName' imported successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to import solution '$solutionName': $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "All solutions imported successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
