# Build Windows Release Script for TechZone IT
# Purpose: Clean build for Release mode with manual Environment injection.

Write-Host "Initializing Visual Studio Environment for RELEASE..." -ForegroundColor Cyan

# 1. Activate standard VS environment
$vsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community"
$vcvars = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"

if (Test-Path $vcvars) {
    cmd /c "call `"$vcvars`" && set" | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
} else {
    Write-Error "Could not find vcvars64.bat"
    exit 1
}

# 2. Inject ATL
$msvcRoot = "$vsPath\VC\Tools\MSVC"
$latestVersion = Get-ChildItem $msvcRoot | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name
$atlInclude = "$msvcRoot\$latestVersion\atlmfc\include"
$atlLib = "$msvcRoot\$latestVersion\atlmfc\lib\x64"

$env:INCLUDE += ";$atlInclude"
$env:LIB += ";$atlLib"

# 3. Inject NuGet
if ($env:Path -notmatch "C:\\Tools") {
    $env:Path += ";C:\Tools"
}

# 4. Build Release
Write-Host "Building Windows Release..." -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build windows --release

if (Test-Path "build\windows\x64\runner\Release\bm_typer.exe") {
    Write-Host "Release Build SUCCESS!" -ForegroundColor Green
    Write-Host "Output: build\windows\x64\runner\Release\bm_typer.exe"
} else {
    Write-Error "Release Build FAILED."
    exit 1
}
