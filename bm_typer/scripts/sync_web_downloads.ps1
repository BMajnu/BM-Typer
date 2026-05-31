$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceInstaller = Join-Path $projectRoot 'installers\BMTyper_Setup_NSIS_v1.0.0.exe'
$targetDir = Join-Path $projectRoot 'web\downloads'
$targetInstaller = Join-Path $targetDir 'BM-Typer-Setup.exe'

if (-not (Test-Path $sourceInstaller)) {
    throw "Source installer not found: $sourceInstaller"
}

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Copy-Item -LiteralPath $sourceInstaller -Destination $targetInstaller -Force

Write-Host "Windows installer synced to $targetInstaller"
