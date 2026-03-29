# PS7 Auto Test Runner (Watch Mode)
$ErrorActionPreference = "Stop"

$testFolder = Join-Path $PSScriptRoot "test"

# Function to run tests (approved verb)
function Invoke-Tests {
    Write-Host "`n🧪 Running all PS7 tests in $testFolder..." -ForegroundColor Cyan

    try {
        $result = Invoke-Pester -Path $testFolder -PassThru -OutputFormat NUnitXml
        Write-Host "`n🎉 All tests completed!" -ForegroundColor Green
        Write-Host "✅ Total Tests: $($result.TestResult.Count)"
        Write-Host "✅ Passed: $($result.PassedCount)"
        Write-Host "❌ Failed: $($result.FailedCount)"
        Write-Host "⚠️ Skipped: $($result.SkippedCount)"
    }
    catch {
        Write-Host "❌ Error running tests: $_" -ForegroundColor Red
    }
}

# Separator helper
function Write-Separator {
    param(
        [string]$Char = "─",
        [int]$Length = 60
    )
    Write-Host ($Char * $Length) -ForegroundColor DarkGray
}

# Watcher Setup
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $PSScriptRoot
$watcher.Filter = "*.ps1"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher Changed -Action {
    Write-Host "`n🔄 File changed! Running tests..." -ForegroundColor Yellow
    Write-Separator
    Invoke-Tests
}

# Initial run
Write-Host "`n👀 Starting PS7 Test Watcher..." -ForegroundColor Cyan
Write-Separator
Invoke-Tests
Write-Host "`n👀 Watching for changes in .ps1 files. Press Ctrl+C to stop." -ForegroundColor Cyan

# Keep script alive
while ($true) { Start-Sleep -Seconds 5 }