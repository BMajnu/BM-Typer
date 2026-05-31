# Build Workaround Script for TechZone IT
# Purpose: Manually set up C++ environment because vswhere.exe is failing to detect VS 2022.

Write-Host "Initializing Visual Studio Environment..." -ForegroundColor Cyan

# 1. Activate standard VS environment
$vsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community"
$vcvars = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"

if (Test-Path $vcvars) {
    # Call vcvars64.bat and capture environment
    cmd /c "call `"$vcvars`" && set" | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
} else {
    Write-Error "Could not find vcvars64.bat at $vcvars"
    exit 1
}

# 2. Manually inject ATL paths (since vcvars might miss them if detection is broken)
# Dynamic version finding
$msvcRoot = "$vsPath\VC\Tools\MSVC"
$latestVersion = Get-ChildItem $msvcRoot | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name
$atlInclude = "$msvcRoot\$latestVersion\atlmfc\include"
$atlLib = "$msvcRoot\$latestVersion\atlmfc\lib\x64"

if (Test-Path $atlInclude) {
    Write-Host "Found ATL Include: $atlInclude" -ForegroundColor Green
    $env:INCLUDE += ";$atlInclude"
} else {
    Write-Warning "ATL Include path not found: $atlInclude"
}

if (Test-Path $atlLib) {
     Write-Host "Found ATL Lib: $atlLib" -ForegroundColor Green
    $env:LIB += ";$atlLib"
} else {
    Write-Warning "ATL Lib path not found: $atlLib"
}

# 3. Ensure NuGet is in PATH
if ($env:Path -notmatch "C:\\Tools") {
    $env:Path += ";C:\Tools"
}

# 4. Run Flutter Build
Write-Host "Starting Flutter Build..." -ForegroundColor Cyan
flutter clean
flutter pub get
flutter run -d windows
