# ────────────────────────────────
# 📁 Setup PS7 Logging (LocalAppData)
# ────────────────────────────────

if (-not $env:LOCALAPPDATA -or $env:LOCALAPPDATA -eq "") {
    return  # Host did double-load profile → ignore duplicate
}

$logFolder = Join-Path $env:LOCALAPPDATA "PS7Logs"

# Create folder if missing
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

$Global:PS7_LogFile = Join-Path $logFolder "ps7_open_logs.json"

# Create file if missing
if (-not (Test-Path $Global:PS7_LogFile)) {
    "[]" | Out-File -FilePath $Global:PS7_LogFile -Encoding utf8 -Force
}

# ────────────────────────────────
# 📝 Logging Function
# ────────────────────────────────
function Write-PS7OpenLog {
    if (-not $Global:PS7_LogFile) { return }

    try {
        $isAdmin = (
            [Security.Principal.WindowsPrincipal](
                [Security.Principal.WindowsIdentity]::GetCurrent()
            )
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        switch -Wildcard ($Host.Name) {
            "*Windows Terminal*" { $hostLabel = "WindowsTerminal" }
            "*Visual Studio*"    { $hostLabel = "VSCode" }
            "*ConsoleHost*"      { $hostLabel = "ConsoleHost" }
            default              { $hostLabel = "Unknown" }
        }

        $logs = @()
        $raw = Get-Content $Global:PS7_LogFile -Raw
        
        if ($raw.Trim() -ne "") {
            try { $logs = @($raw | ConvertFrom-Json) }
            catch { $logs = @() }
        }

        $logs += [PSCustomObject]@{
            Timestamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            User       = $env:USERNAME
            Host       = $hostLabel
            Admin      = $isAdmin
            Path       = (Get-Location).Path
            SessionID  = $PID
            Machine    = $env:COMPUTERNAME
        }

        $logs | ConvertTo-Json -Depth 5 |
            Out-File -FilePath $Global:PS7_LogFile -Encoding utf8 -Force
    }
    catch { Write-Host "⚠ Failed to write PS7 log: $_" -ForegroundColor DarkYellow }
}

Write-PS7OpenLog

# ────────────────────────────────
# 📝 Get PS7 Open Logs Function
# ────────────────────────────────
function Get-PowerShell7-Open-Logs {
    param(
        [Alias("d")][switch]$Delete
    )

    if (-not $Global:PS7_LogFile -or -not (Test-Path $Global:PS7_LogFile)) {
        Write-Host "⚠ Log file not found." -ForegroundColor DarkYellow
        return
    }

    if ($Delete) {
        "[]" | Out-File -FilePath $Global:PS7_LogFile -Encoding utf8 -Force
        Write-Host "🗑 All logs deleted successfully." -ForegroundColor Yellow
        return
    }

    $logs = @()
    try {
        $raw = Get-Content -Path $Global:PS7_LogFile -Raw
        if ($raw.Trim() -eq "") { $raw = "[]" }
        $logs = $raw | ConvertFrom-Json
    } catch {
        Write-Host "⚠ Failed to read logs." -ForegroundColor Red
        return
    }

    if ($logs.Count -eq 0) {
        Write-Host "⚠ No logs found." -ForegroundColor DarkYellow
        return
    }

    $header = "{0,-20} {1,-10} {2,-15} {3,-6} {4,-30} {5,-8} {6,-15}" -f `
        "Timestamp","User","Host","Admin","Path","Session","Machine"
    Write-Host $header -ForegroundColor Cyan
    Write-Host ("─" * 120) -ForegroundColor DarkGray

    foreach ($log in $logs) {
        $line = "{0,-20} {1,-10} {2,-15} {3,-6} {4,-30} {5,-8} {6,-15}" -f `
            $log.Timestamp, $log.User, $log.Host, $log.Admin, $log.Path, $log.SessionID, $log.Machine

        if ($log.Admin) { $color = "Red" }
        elseif ($log.Host -eq "Unknown") { $color = "Yellow" }
        else { $color = "Green" }

        Write-Host $line -ForegroundColor $color
    }

    Write-Host ""  
}

# ────────────────────────────────
# 📁 Folder Tree Function
# ────────────────────────────────

function Show-FolderTree {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, HelpMessage="Path of the folder to display")]
        [string]$Path = (Get-Location),

        [Parameter(HelpMessage="Folders to ignore, separated by comma")]
        [string[]]$IgnoreFolders = @('node_modules'),

        [Parameter(HelpMessage="Show help message")]
        [switch]$Help,

        [string]$Indent = "",
        [bool]$IsLast = $true
    )

    if ($Help) {
        Write-Host "Usage: Show-FolderTree [-Path <folderPath>] [-IgnoreFolders <folders>] [-Help]" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  Show-FolderTree"
        Write-Host "  Show-FolderTree -Path C:\MyProject"
        Write-Host "  Show-FolderTree -IgnoreFolders node_modules,.git"
        return
    }

    # Fetch items excluding ignored folders
    $items = Get-ChildItem -LiteralPath $Path -Force | Where-Object {
        -not ($IgnoreFolders -contains $_.Name)
    }

    $count = $items.Count
    $i = 0

    foreach ($item in $items) {
        $i++
        $isLastItem = $i -eq $count

        $branch = if ($isLastItem) { "└─" } else { "├─" }

        if ($item.PSIsContainer) {
            Write-Host "$Indent$branch $($item.Name)" -ForegroundColor Cyan
            $newIndent = $Indent + ($isLastItem ? "   " : "│  ")
            Show-FolderTree -Path $item.FullName -Indent $newIndent -IgnoreFolders $IgnoreFolders
        }
        else {
            Write-Host "$Indent$branch $($item.Name)" -ForegroundColor Gray
        }
    }
}

# ────────────────────────────────
# 💻 Fancy PowerShell Welcome Banner
# ────────────────────────────────
Clear-Host

$line = "═" * 60
Write-Host ""
Write-Host "╔$line╗" -ForegroundColor DarkCyan
Write-Host "║" -NoNewline
Write-Host " 🚀 Welcome back, $($env:USERNAME)! 🚀 " -ForegroundColor Cyan -NoNewline
Write-Host "║"
Write-Host "╚$line╝" -ForegroundColor DarkCyan
Write-Host ""

Start-Sleep -Milliseconds 200

# Default dynamic banner name (unless changed via psx -n)
if (-not (Get-Variable PSX_Name -Scope Global -ErrorAction SilentlyContinue)) {
    $Global:PSX_Name = "psx-profile"
}
$name = $Global:PSX_Name

$colors = "Red","DarkRed","Yellow","Green","Cyan","Blue","Magenta","DarkMagenta","DarkYellow","Gray","White"
$banner = @()
for ($i=0; $i -lt $name.Length; $i++) {
    $color = $colors[$i % $colors.Count]
    $banner += @{ text = $name[$i]; color = $color }
}

# Print animated banner based on dynamic name
foreach ($part in $banner) {
    Write-Host -NoNewline $part.text -ForegroundColor $part.color
    Start-Sleep -Milliseconds ([Math]::Max(20, 60 - ($name.Length * 2)))
}
Write-Host ""   # Move to next line after banner


Write-Host ""
Write-Host ("═" * 60) -ForegroundColor DarkGray
Write-Host ("🕒 " + (Get-Date).ToString("dddd, MMMM dd yyyy HH:mm:ss")) -ForegroundColor DarkCyan
Write-Host ("📂 Current Directory: " + (Get-Location)) -ForegroundColor Gray
Write-Host ("═" * 60) -ForegroundColor DarkGray
Write-Host ""

$logs = @()
if (Test-Path $Global:PS7_LogFile) {
    $raw = Get-Content $Global:PS7_LogFile -Raw
    if ($raw.Trim() -ne "") {
        try { $logs = @($raw | ConvertFrom-Json) } catch {}
    }
}

Write-Host ("📊 Total PS7 Sessions Logged: " + $logs.Count) -ForegroundColor Cyan
$lastLogs = $logs | Select-Object -Last 3
foreach ($log in $lastLogs) {
    if ($log.Admin) { $color = "Red" }
    elseif ($log.Host -eq "Unknown") { $color = "Yellow" }
    else { $color = "Green" }
    Write-Host "[$($log.Timestamp)] User: $($log.User) | Host: $($log.Host) | Admin: $($log.Admin)" -ForegroundColor $color
}
Write-Host ""

# ──────────────────────────────
# 🔧 Aliases
# ──────────────────────────────
Set-Alias pwsh-logs Get-PowerShell7-Open-Logs

# ──────────────────────────────
# 🔧 Load Oh My Posh Prompt
# ──────────────────────────────
$env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\oh-my-posh-themes"
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

# ──────────────────────────────
# 🔹 PSX Profile Core Command
# ──────────────────────────────
function psx {
    param(
        [Alias("h")][switch]$help,
        [Alias("v")][switch]$version,
        [Alias("u")][switch]$update,
        [Alias("r")][switch]$remove,
        [Alias("d")][switch]$clearlogs,
        [Alias("s")][switch]$status,
        [Alias("n")][string]$name,
        [Alias("p")][switch]$pwshupdate
    )

    if ($PSBoundParameters.ContainsKey("name")) {
        $Global:PSX_Name = $name
        Write-Host "✔ Banner name updated to: $name" -ForegroundColor Green
        return
    }

    $PSX_Version = "1.0.0"
    $PSX_LogFile = Join-Path $env:LOCALAPPDATA "PS7Logs\ps7_open_logs.json"
    $baseUrl = "https://raw.githubusercontent.com/Mahmoud-walid/psx-profile/main"
    $profileUrl = "$baseUrl/profiles/Microsoft.PowerShell_profile.windows.ps1"

    if ($pwshupdate) {
        $confirm = Read-Host "⚠ This will download and install the latest PowerShell 7. Continue? (Y/N)"
        if ($confirm -notmatch "^[Yy]$") {
            Write-Host "❌ Update cancelled." -ForegroundColor Yellow
            return
        }
        try {
            $IsWin = $PSVersionTable.OS -match "Windows"
            if ($IsWin) {
                Invoke-RestMethod "https://raw.githubusercontent.com/Mahmoud-walid/psx-profile/main/update-pwsh.ps1" | Invoke-Expression
            } else {
                pwsh -c "Invoke-RestMethod 'https://raw.githubusercontent.com/Mahmoud-walid/psx-profile/main/update-pwsh.ps1' | Invoke-Expression"
            }
        } catch {
            Write-Host "❌ PowerShell update failed: $_" -ForegroundColor Red
        }
        return
    }
    
    if ($help) {
        Write-Host "`n🌀 PSX Profile Command Help" -ForegroundColor Cyan
        Write-Host "Usage: psx [options]" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  -h, --help        Show this help message" -ForegroundColor Gray
        Write-Host "  -v, --version     Show current psx-profile version" -ForegroundColor Gray
        Write-Host "  -u, --update      Update psx-profile from GitHub" -ForegroundColor Gray
        Write-Host "  -r, --remove      Uninstall profile (profile, logs, theme)" -ForegroundColor Gray
        Write-Host "  -d, --clearlogs   Clear all PS7 session logs" -ForegroundColor Gray
        Write-Host "  -s, --status      Show profile status and last logs summary" -ForegroundColor Gray
        return
    }

    if ($version) { Write-Host "📌 psx-profile version: $PSX_Version" -ForegroundColor Cyan; return }
    if ($clearlogs) { 
        if (Test-Path $PSX_LogFile) { "[]" | Out-File -FilePath $PSX_LogFile -Encoding utf8 -Force; Write-Host "🗑 All PS7 logs cleared successfully." -ForegroundColor Yellow } 
        else { Write-Host "⚠ Log file not found." -ForegroundColor DarkYellow }; return 
    }

    if ($update) {
        Write-Host "🔄 Checking for updates..." -ForegroundColor Cyan
        try {
            $tmpFile = New-TemporaryFile
            Invoke-WebRequest -Uri $profileUrl -OutFile $tmpFile -UseBasicParsing
            $remoteContent = Get-Content $tmpFile -Raw
            Remove-Item $tmpFile -Force

            if ($remoteContent -match '\$PSX_Version\s*=\s*"([\d\.]+)"') {
                $remoteVersion = $Matches[1]
                if ($remoteVersion -ne $PSX_Version) {
                    Write-Host "⬆ New version detected: $remoteVersion. Updating..." -ForegroundColor Green
                    Invoke-WebRequest -Uri $profileUrl -OutFile $PROFILE -UseBasicParsing
                    . $PROFILE
                    Write-Host "✔ psx-profile updated to version $remoteVersion" -ForegroundColor Green
                } else { Write-Host "✅ psx-profile is already up to date." -ForegroundColor Cyan }
            } else { Write-Host "⚠ Could not detect remote version. Update skipped." -ForegroundColor DarkYellow }
        } catch { Write-Host "❌ Update failed: $_" -ForegroundColor Red }
        return
    }

    if ($remove) {
        Write-Host "⚠ You are about to uninstall psx-profile..." -ForegroundColor Yellow
        if (Test-Path $PROFILE) { Remove-Item $PROFILE -Force; Write-Host "✔ Profile removed." -ForegroundColor Green }
        if (Test-Path $PSX_LogFile) { Remove-Item $PSX_LogFile -Force; Write-Host "✔ Logs removed." -ForegroundColor Green }
        $themePath = "$env:LOCALAPPDATA\oh-my-posh-themes\paradox.omp.json"
        if (Test-Path $themePath) { Remove-Item $themePath -Force; Write-Host "✔ Oh My Posh theme removed." -ForegroundColor Green }
        Write-Host "✨ Uninstall complete. Restart PowerShell." -ForegroundColor Cyan
        return
    }

    if ($status -or (-not ($help -or $version -or $update -or $remove -or $clearlogs))) {
        Write-Host "🌀 psx-profile status:" -ForegroundColor Cyan
        Write-Host "Version: $PSX_Version" -ForegroundColor Cyan
        Write-Host "Profile Path: $PROFILE" -ForegroundColor Gray
        Write-Host "Logs Path: $PSX_LogFile" -ForegroundColor Gray

        $logs = @()
        if (Test-Path $PSX_LogFile) {
            $raw = Get-Content $PSX_LogFile -Raw
            if ($raw.Trim() -ne "") { try { $logs = @($raw | ConvertFrom-Json) } catch {} }
        }

        if ($logs.Count -gt 0) {
            Write-Host "`n📊 Last 3 PS7 sessions:" -ForegroundColor Cyan
            $lastLogs = $logs | Select-Object -Last 3
            foreach ($log in $lastLogs) {
                if ($log.Admin) { $color = "Red" }
                elseif ($log.Host -eq "Unknown") { $color = "Yellow" }
                else { $color = "Green" }
                Write-Host "[$($log.Timestamp)] User: $($log.User) | Host: $($log.Host) | Admin: $($log.Admin)" -ForegroundColor $color
            }
        } else { Write-Host "⚠ No logs found." -ForegroundColor DarkYellow }
        return
    }
}