Write-Host "`n🔄 Updating PSX Profile..." -ForegroundColor Cyan

# Detect OS
$IsRunningOnWindows = $PSVersionTable.OS -match "Windows"
$IsRunningOnMacOS   = $PSVersionTable.OS -match "Darwin"

# Determine which file to fetch
$FileName = if ($IsRunningOnWindows) { 
    "Microsoft.PowerShell_profile.windows.ps1" 
} elseif ($IsRunningOnMacOS) { 
    "Microsoft.PowerShell_profile.macos.ps1" 
} else { 
    "Microsoft.PowerShell_profile.linux.ps1" 
}

$RepoUrl = "https://raw.githubusercontent.com/Mahmoud-walid/psx-profile/main/profiles/$FileName"

try {
    Write-Host "⬇ Fetching latest version of $FileName..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $RepoUrl -OutFile $PROFILE -UseBasicParsing
    
    # Reload Profile
    . $PROFILE
    Write-Host "✔ PSX Profile updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Update failed: $_" -ForegroundColor Red
}