<#
.SYNOPSIS
Builds and packages the Turing Lab Windows release.

.DESCRIPTION
Runs the Flutter Windows Release build and packages the complete runnable
bundle as an Inno Setup installer in build/windows/installer.

.PARAMETER FlutterBin
Path to flutter.bat or flutter.exe. Defaults to TURING_LAB_FLUTTER_BIN, then
the flutter command available on PATH.

.PARAMETER InnoSetupCompiler
Path to ISCC.exe. Defaults to TURING_LAB_INNO_SETUP_COMPILER, then ISCC on PATH
or the standard Inno Setup 6 installation directories.

.EXAMPLE
.\windows\scripts\archive_windows.ps1
#>

[CmdletBinding()]
param(
    [string]$FlutterBin = $env:TURING_LAB_FLUTTER_BIN,
    [string]$InnoSetupCompiler = $env:TURING_LAB_INNO_SETUP_COMPILER,
    [string]$MinFlutterVersion = "3.27.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$windowsBuildRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $repoRoot "build\windows")
)
$bundleSource = Join-Path $windowsBuildRoot "x64\runner\Release"
$installerOutputDir = Join-Path $windowsBuildRoot "installer"
$installerScript = Join-Path $scriptDir "turing_lab.iss"
$setupIconPath = Join-Path $repoRoot "windows\runner\resources\app_icon.ico"
$executableName = "turing_lab.exe"

function Assert-ManagedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$AllowedRoot
    )

    $canonicalPath = [System.IO.Path]::GetFullPath($Path)
    $canonicalRoot = [System.IO.Path]::GetFullPath($AllowedRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $rootPrefix = $canonicalRoot + [System.IO.Path]::DirectorySeparatorChar

    if (
        $canonicalPath -ne $canonicalRoot -and
        -not $canonicalPath.StartsWith(
            $rootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "Refusing to use path '$canonicalPath'. Expected it under '$canonicalRoot'."
    }
}

function Resolve-FlutterCommand {
    if (-not [string]::IsNullOrWhiteSpace($FlutterBin)) {
        $configuredFlutter = Get-Command $FlutterBin -ErrorAction SilentlyContinue
        if ($null -eq $configuredFlutter) {
            throw "Flutter was not found at '$FlutterBin'."
        }
        return $configuredFlutter.Source
    }

    $pathFlutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $pathFlutter) {
        throw "Flutter was not found on PATH. Set TURING_LAB_FLUTTER_BIN to flutter.bat."
    }

    return $pathFlutter.Source
}

function Resolve-InnoSetupCommand {
    if (-not [string]::IsNullOrWhiteSpace($InnoSetupCompiler)) {
        $configuredCompiler = Get-Command $InnoSetupCompiler -ErrorAction SilentlyContinue
        if ($null -eq $configuredCompiler) {
            throw "Inno Setup compiler was not found at '$InnoSetupCompiler'."
        }
        return $configuredCompiler.Source
    }

    $pathCompiler = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($null -ne $pathCompiler) {
        return $pathCompiler.Source
    }

    $compilerCandidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    )
    foreach ($candidate in $compilerCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw "Inno Setup 6 was not found. Install it or set TURING_LAB_INNO_SETUP_COMPILER to ISCC.exe."
}

function Resolve-VCRuntimeDirectory {
    $vswherePath = Join-Path ${env:ProgramFiles(x86)} `
        "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path -LiteralPath $vswherePath -PathType Leaf)) {
        throw "Visual Studio Installer's vswhere.exe was not found."
    }

    $visualStudioPath = & $vswherePath -latest -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($visualStudioPath)) {
        throw "A Visual Studio installation with the C++ desktop tools was not found."
    }

    $redistRoot = Join-Path $visualStudioPath "VC\Redist\MSVC"
    $redistVersions = Get-ChildItem -LiteralPath $redistRoot -Directory `
        -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "^[0-9]+(?:\.[0-9]+)+$"
        } | Sort-Object { [System.Version]$_.Name } -Descending

    foreach ($redistVersion in $redistVersions) {
        $runtimeDirectories = Get-ChildItem `
            -LiteralPath (Join-Path $redistVersion.FullName "x64") `
            -Directory -Filter "Microsoft.VC*.CRT" -ErrorAction SilentlyContinue
        foreach ($runtimeDirectory in $runtimeDirectories) {
            $requiredRuntimeFiles = @(
                "msvcp140.dll",
                "vcruntime140.dll",
                "vcruntime140_1.dll"
            )
            $missingRuntimeFile = $requiredRuntimeFiles | Where-Object {
                -not (Test-Path -LiteralPath (Join-Path $runtimeDirectory.FullName $_) -PathType Leaf)
            }
            if ($null -eq $missingRuntimeFile) {
                return $runtimeDirectory.FullName
            }
        }
    }

    throw "The x64 Visual C++ runtime files required for app-local deployment were not found."
}

function Assert-SymlinkSupport {
    $checkDir = Join-Path $windowsBuildRoot (".symlink-check-" + [guid]::NewGuid().ToString("N"))
    Assert-ManagedPath -Path $checkDir -AllowedRoot $windowsBuildRoot

    $targetPath = Join-Path $checkDir "target.txt"
    $linkPath = Join-Path $checkDir "link.txt"
    New-Item -ItemType Directory -Path $checkDir -Force | Out-Null
    New-Item -ItemType File -Path $targetPath -Force | Out-Null

    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath `
            -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Flutter plugins require symbolic-link permission. Open 'ms-settings:developers', enable Developer Mode, and run this script again."
    }
    finally {
        Remove-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $checkDir -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-Flutter {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $script:flutterCommand @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter command failed with exit code ${LASTEXITCODE}: flutter $($Arguments -join ' ')"
    }
}

if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
    throw "This script must run on Windows."
}

Assert-ManagedPath -Path $installerOutputDir -AllowedRoot $windowsBuildRoot

if (-not (Test-Path -LiteralPath $installerScript -PathType Leaf)) {
    throw "Inno Setup script '$installerScript' was not found."
}
if (-not (Test-Path -LiteralPath $setupIconPath -PathType Leaf)) {
    throw "Installer icon '$setupIconPath' was not found."
}

$script:flutterCommand = Resolve-FlutterCommand
$innoSetupCommand = Resolve-InnoSetupCommand
$vcRuntimeDirectory = Resolve-VCRuntimeDirectory

Write-Host "==> Validating Flutter and Windows toolchain"
$flutterVersionOutput = & $script:flutterCommand --version 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Flutter did not respond successfully to '--version'."
}

$flutterVersionText = ($flutterVersionOutput | Out-String).Trim()
if ($flutterVersionText -notmatch "Flutter\s+([0-9]+(?:\.[0-9]+){2})") {
    throw "Could not determine the installed Flutter version."
}

$flutterVersion = [System.Version]$Matches[1]
$minimumVersion = [System.Version]$MinFlutterVersion
if ($flutterVersion -lt $minimumVersion) {
    throw "Flutter $MinFlutterVersion or newer is required, but $flutterVersion is installed."
}

Write-Host "Flutter $flutterVersion"
Write-Host "Inno Setup compiler: $innoSetupCommand"
Assert-SymlinkSupport
Invoke-Flutter -Arguments @("doctor", "-v")

Write-Host "==> flutter pub get"
Push-Location $repoRoot
try {
    Invoke-Flutter -Arguments @("pub", "get")

    Write-Host "==> Running flutter build windows --release"
    Invoke-Flutter -Arguments @("build", "windows", "--release")
}
finally {
    Pop-Location
}

$builtExecutable = Join-Path $bundleSource $executableName
$requiredBundlePaths = @(
    $builtExecutable,
    (Join-Path $bundleSource "flutter_windows.dll"),
    (Join-Path $bundleSource "data\flutter_assets"),
    (Join-Path $bundleSource "data\app.so")
)

foreach ($requiredPath in $requiredBundlePaths) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Windows Release bundle is incomplete. Missing '$requiredPath'."
    }
}

$pubspecVersionLine = Select-String -LiteralPath (Join-Path $repoRoot "pubspec.yaml") `
    -Pattern "^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$"
if ($null -eq $pubspecVersionLine) {
    throw "Could not parse the version from pubspec.yaml."
}
$appVersion = $pubspecVersionLine.Matches[0].Groups[1].Value
$appBuild = $pubspecVersionLine.Matches[0].Groups[2].Value
if ([string]::IsNullOrWhiteSpace($appBuild)) {
    $appBuild = "0"
}
$installerBaseName = "Turing-Lab-$appVersion-windows-x64-installer"
$installerPath = Join-Path $installerOutputDir "$installerBaseName.exe"
Assert-ManagedPath -Path $installerPath -AllowedRoot $windowsBuildRoot

Write-Host "==> Creating Windows installer"
New-Item -ItemType Directory -Path $installerOutputDir -Force | Out-Null
if (Test-Path -LiteralPath $installerPath) {
    Remove-Item -LiteralPath $installerPath -Force
}

$innoArguments = @(
    "/DBundleSource=$bundleSource",
    "/DOutputDir=$installerOutputDir",
    "/DOutputBaseFilename=$installerBaseName",
    "/DAppVersion=$appVersion",
    "/DAppBuild=$appBuild",
    "/DSetupIconFile=$setupIconPath",
    "/DVCRuntimeDir=$vcRuntimeDirectory",
    $installerScript
)
& $innoSetupCommand @innoArguments
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Windows installer '$installerPath' was not created."
}

Write-Host "Windows installer created at $installerPath"
