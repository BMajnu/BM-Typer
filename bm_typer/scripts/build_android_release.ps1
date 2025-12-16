# Build Android Release Script for TechZone IT
# Purpose: Build Android APK with manual Environment injection to prevent AOT crashes.

Write-Host "Initializing Visual Studio Environment for ANDROID..." -ForegroundColor Cyan

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

# 2. Inject ATL (Just in case)
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
Write-Host "Building Android Release APK..." -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons

if (Test-Path "build\app\outputs\apk\release\app-release.apk") {
    Write-Host "Android Build SUCCESS!" -ForegroundColor Green
    Write-Host "Output: build\app\outputs\apk\release\app-release.apk"
} else {
    Write-Error "Android Build FAILED."
    exit 1
}
