Write-Host "`n⚠ Uninstalling PSX Profile..." -ForegroundColor Yellow

# Detect OS Paths
$IsRunningOnWindows = $PSVersionTable.OS -match "Windows"
if ($IsRunningOnWindows) {
    $DataDir = $env:LOCALAPPDATA
} else {
    # Unix Path
    $DataDir = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $env:HOME ".local/share" }
}

try {
    # 1. Remove Profile Script
    if (Test-Path $PROFILE) { 
        Remove-Item $PROFILE -Force
        Write-Host "✔ Profile script removed" -ForegroundColor Green 
    }

    # 2. Remove Logs
    $logFile = Join-Path $DataDir "PS7Logs"
    if (Test-Path $logFile) { 
        Remove-Item $logFile -Recurse -Force
        Write-Host "✔ Logs directory removed" -ForegroundColor Green 
    }

    # 3. Remove Theme
    $themeDir = Join-Path $DataDir "oh-my-posh-themes"
    $themeFile = Join-Path $themeDir "paradox.omp.json"
    
    if (Test-Path $themeFile) { 
        Remove-Item $themeFile -Force
        Write-Host "✔ Oh My Posh theme removed" -ForegroundColor Green 
    }
    
    # Optional: Remove theme folder if empty
    if ((Test-Path $themeDir) -and (Get-ChildItem $themeDir).Count -eq 0) {
        Remove-Item $themeDir -Force
    }

    Write-Host "✨ Uninstall complete. Restart PowerShell." -ForegroundColor Cyan
} catch {
    Write-Host "❌ Uninstall failed: $_" -ForegroundColor Red
}