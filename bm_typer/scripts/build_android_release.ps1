# Build Android Release Script for TechZone IT
# Purpose: Build Android APK with manual Environment injection to prevent AOT crashes.

Write-Host "Initializing Visual Studio Environment for ANDROID..." -ForegroundColor Cyan

# 1. Activate the newest supported VS environment
$vsCandidates = @(
    "C:\Program Files\Microsoft Visual Studio\18\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Community"
)
$vsPath = $vsCandidates | Where-Object { Test-Path "$_\VC\Auxiliary\Build\vcvars64.bat" } | Select-Object -First 1

if (-not $vsPath) {
    Write-Error "Could not find a supported Visual Studio installation."
    exit 1
}

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
$flutterCandidates = @(
    "C:\src\flutter\bin\flutter.bat",
    "C:\src\flutter\bin\flutter"
)
$flutterCmd = $flutterCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $flutterCmd) {
    $flutterCmd = "flutter"
}

$flutterDir = Split-Path $flutterCmd -Parent
if ($flutterDir -and (Test-Path $flutterDir) -and ($env:Path -notmatch [Regex]::Escape($flutterDir))) {
    $env:Path = "$flutterDir;$env:Path"
}

& $flutterCmd clean
& $flutterCmd pub get
& $flutterCmd build apk --release --no-tree-shake-icons --target-platform android-arm64

if (Test-Path "build\app\outputs\apk\release\app-release.apk") {
    $versionLine = (Get-Content "pubspec.yaml" | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1)
    $version = if ($versionLine) { ($versionLine -replace '^version:\s*', '').Trim() } else { "1.0.0+1" }
    $safeVersion = $version -replace '\+', '-build-'
    $deliverableDir = Join-Path (Get-Location) "deliverables\android\$safeVersion"
    $sourceApk = Join-Path (Get-Location) "build\app\outputs\apk\release\app-release.apk"
    $renamedApk = Join-Path $deliverableDir "BM-Typer-v$safeVersion-release.apk"
    $checksumFile = Join-Path $deliverableDir "BM-Typer-v$safeVersion-release.apk.sha256"
    $buildInfoFile = Join-Path $deliverableDir "BUILD-INFO.txt"

    New-Item -ItemType Directory -Force -Path $deliverableDir | Out-Null
    Copy-Item $sourceApk $renamedApk -Force

    $hash = (Get-FileHash $renamedApk -Algorithm SHA256).Hash
    Set-Content -Path $checksumFile -Value "$hash *$(Split-Path $renamedApk -Leaf)"

    $buildInfo = @"
App: BM Typer
Platform: Android
Version: $version
Build Type: Release APK (ARM64)
Package ID: com.techzoneit.bm_typer
Generated At: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source APK: $sourceApk
Deliverable APK: $renamedApk
SHA256: $hash
"@
    Set-Content -Path $buildInfoFile -Value $buildInfo

    Write-Host "Android Build SUCCESS!" -ForegroundColor Green
    Write-Host "Output: $sourceApk"
    Write-Host "Deliverable: $renamedApk"
    Write-Host "Checksum: $checksumFile"
    Write-Host "Build Info: $buildInfoFile"
} else {
    Write-Error "Android Build FAILED."
    exit 1
}
