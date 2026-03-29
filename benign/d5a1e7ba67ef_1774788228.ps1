# ================================
#      PowerShell 7 Updater
# ================================
$ErrorActionPreference = "Stop"

Write-Host "`n⚡ Checking for latest PowerShell 7 release..." -ForegroundColor Cyan

try {
    # Fetch latest release data from GitHub API
    $release = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
} catch {
    Write-Host "❌ Failed to fetch release info (Check Internet/Rate Limits)." -ForegroundColor Red
    exit 1
}

$assets = $release.assets
$tag = $release.tag_name

# 1️⃣ Detect OS (Standardized Names)
$IsRunningOnWindows = $PSVersionTable.OS -match "Windows"
$IsRunningOnMacOS   = $PSVersionTable.OS -match "Darwin"
$IsRunningOnLinux   = $PSVersionTable.Platform -eq "Unix" -and -not $IsRunningOnMacOS

# 2️⃣ Detect Architecture (Cross-Platform Safe)
# $env:PROCESSOR_ARCHITECTURE isn't always reliable on Linux/Mac, so we use .NET
$arch = "x64" # Default
if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
    $arch = "arm64"
}

$downloadUrl = $null
$packageName = $null

# 3️⃣ Select Correct Asset
if ($IsRunningOnWindows) {
    Write-Host "🪟 Detected OS: Windows ($arch)" -ForegroundColor Yellow
    $asset = $assets | Where-Object { $_.name -match "win-$arch\.msi$" } | Select-Object -First 1
    if ($asset) {
        $downloadUrl = $asset.browser_download_url
        $packageName = $asset.name
    }
}
elseif ($IsRunningOnMacOS) {
    Write-Host "🍎 Detected OS: macOS ($arch)" -ForegroundColor Yellow
    $asset = $assets | Where-Object { $_.name -match "osx-$arch\.pkg$" } | Select-Object -First 1
    if ($asset) {
        $downloadUrl = $asset.browser_download_url
        $packageName = $asset.name
    }
}
elseif ($IsRunningOnLinux) {
    Write-Host "🐧 Detected OS: Linux ($arch)" -ForegroundColor Yellow
    
    # Detect Distro Type
    if (Test-Path "/etc/debian_version") {
        $asset = $assets | Where-Object { $_.name -match "linux-$arch\.deb$" } | Select-Object -First 1
    } elseif (Test-Path "/etc/redhat-release") {
        $asset = $assets | Where-Object { $_.name -match "linux-$arch\.rpm$" } | Select-Object -First 1
    }
    
    if ($asset) {
        $downloadUrl = $asset.browser_download_url
        $packageName = $asset.name
    }
}

if (-not $downloadUrl) {
    Write-Host "❌ Could not find a matching PowerShell package for your OS/Arch." -ForegroundColor Red
    exit 1
}

# 4️⃣ Download
$tempDir = [System.IO.Path]::GetTempPath()
$savePath = Join-Path $tempDir $packageName

Write-Host "⬇ Downloading $packageName..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $savePath -UseBasicParsing

# 5️⃣ Install
Write-Host "📦 Installing..." -ForegroundColor Cyan

try {
    if ($IsRunningOnWindows) {
        Start-Process msiexec.exe -ArgumentList "/i `"$savePath`" /qn /norestart" -Wait
    } elseif ($IsRunningOnMacOS) {
        sudo installer -pkg $savePath -target /
    } elseif ($IsRunningOnLinux) {
        if ($packageName -match "\.deb$") {
            sudo dpkg -i $savePath
            sudo apt-get install -f -y
        } elseif ($packageName -match "\.rpm$") {
            sudo rpm -Uvh $savePath
        }
    }
    Write-Host "✔ Update Complete: $tag" -ForegroundColor Green
    Write-Host "🚀 Please restart your terminal to use the new version." -ForegroundColor Cyan
} catch {
    Write-Host "❌ Installation failed: $_" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path $savePath) { Remove-Item $savePath -Force -ErrorAction SilentlyContinue }
}