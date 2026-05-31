# Run Windows Debug Script for BM Typer
# Purpose: Start `flutter run -d windows` from a normal PowerShell shell by
# importing the Visual Studio developer environment first.

Write-Host "Initializing Visual Studio Environment for DEBUG..." -ForegroundColor Cyan

$vsCandidates = @(
    "C:\Program Files\Microsoft Visual Studio\18\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Community"
)

$vsPath = $vsCandidates |
    Where-Object { Test-Path "$_\VC\Auxiliary\Build\vcvars64.bat" } |
    Select-Object -First 1

if (-not $vsPath) {
    Write-Error "Could not find a supported Visual Studio installation."
    exit 1
}

$vcvars = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"

cmd /c "call `"$vcvars`" && set" | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

$msvcRoot = "$vsPath\VC\Tools\MSVC"
$latestVersion = Get-ChildItem $msvcRoot |
    Sort-Object Name -Descending |
    Select-Object -First 1 -ExpandProperty Name

$atlInclude = "$msvcRoot\$latestVersion\atlmfc\include"
$atlLib = "$msvcRoot\$latestVersion\atlmfc\lib\x64"

$env:INCLUDE += ";$atlInclude"
$env:LIB += ";$atlLib"

Write-Host "Running Flutter Windows debug app..." -ForegroundColor Cyan
flutter run -d windows
