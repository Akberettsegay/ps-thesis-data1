# ================================
#      PSX-PROFILE INSTALLER
# ================================

Write-Host "`n🚀 Starting PSX Profile Installation..." -ForegroundColor Cyan

# 1️⃣ Detect OS and Variables
$IsRunningOnWindows = $PSVersionTable.OS -match "Windows"
$IsRunningOnMacOS   = $PSVersionTable.OS -match "Darwin"

# Base GitHub URL for the profiles folder
$RepoBase = "https://raw.githubusercontent.com/Mahmoud-walid/psx-profile/main/profiles"

if ($IsRunningOnWindows) {
    Write-Host "🪟 Detected OS: Windows" -ForegroundColor Yellow
    $ProfileScript = "Microsoft.PowerShell_profile.windows.ps1"
    $ThemeBaseDir  = "$env:LOCALAPPDATA\oh-my-posh-themes"
    
    # Check Admin (Windows Specific)
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) { Write-Warning "For best results (installing fonts/winget), run as Administrator." }

} else {
    # Linux & macOS Shared Logic for Paths
    $PlatformName = if ($IsRunningOnMacOS) { "macOS" } else { "Linux" }
    Write-Host "🍎/🐧 Detected OS: $PlatformName" -ForegroundColor Yellow
    
    $ProfileScript = if ($IsRunningOnMacOS) { "Microsoft.PowerShell_profile.macos.ps1" } else { "Microsoft.PowerShell_profile.linux.ps1" }
    
    # XDG Standard or Fallback
    $DataHome = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $env:HOME ".local/share" }
    $ThemeBaseDir = Join-Path $DataHome "oh-my-posh-themes"
}

# 2️⃣ Define Target Profile Path
$TargetProfile = $PROFILE.CurrentUserAllHosts
if (-not $TargetProfile) {
    if ($IsRunningOnWindows) {
        $TargetProfile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
    } else {
        $ConfigHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:HOME ".config" }
        $TargetProfile = Join-Path $ConfigHome "powershell/Microsoft.PowerShell_profile.ps1"
    }
}

# Ensure Profile Directory Exists
$profileDir = Split-Path $TargetProfile
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }

# 3️⃣ Install Oh My Posh
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "➡ Installing Oh My Posh..." -ForegroundColor Yellow
    
    if ($IsRunningOnWindows -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    } elseif ($IsRunningOnMacOS -and (Get-Command brew -ErrorAction SilentlyContinue)) {
        brew install jandedobbeleer/oh-my-posh/oh-my-posh
    } else {
        # Universal Fallback (Linux/Mac/Windows without winget)
        try {
            if ($IsRunningOnWindows) {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                Invoke-Expression (Invoke-RestMethod -Uri 'https://ohmyposh.dev/install.ps1')
            } else {
                # Linux/Mac manual install script
                curl -s https://ohmyposh.dev/install.sh | bash -s
            }
        } catch {
            Write-Warning "Failed to auto-install Oh My Posh. Please install it manually."
        }
    }
}

# 4️⃣ Download Theme
if (-not (Test-Path $ThemeBaseDir)) { New-Item -ItemType Directory -Force -Path $ThemeBaseDir | Out-Null }
$ThemeDest = Join-Path $ThemeBaseDir "paradox.omp.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json" -OutFile $ThemeDest -UseBasicParsing

# 5️⃣ Download Specific Profile
$SourceUrl = "$RepoBase/$ProfileScript"
Write-Host "➡ Downloading Profile Script ($ProfileScript) to: $TargetProfile" -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $SourceUrl -OutFile $TargetProfile -UseBasicParsing
    Write-Host "`n🎉 Installation Complete!" -ForegroundColor Green
    Write-Host "👉 Please restart your terminal or run: . `"$TargetProfile`"" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to download profile from $SourceUrl"
}