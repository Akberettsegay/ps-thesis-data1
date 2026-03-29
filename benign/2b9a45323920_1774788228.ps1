Describe "🚀 PS7 Logging Tests" {

    BeforeAll {
        Write-Host "`n✨ Setting up Test Environment..." -ForegroundColor Cyan
        
        # 1. Setup Paths
        $CurrentDir = $PSScriptRoot
        if ([string]::IsNullOrEmpty($CurrentDir)) { $CurrentDir = Get-Location }

        $script:testEnvPath = Join-Path $CurrentDir "test-output-env"
        $ProjectRoot = Split-Path -Parent $CurrentDir
        
        # 2. Determine Correct Profile File based on OS
        $IsRunningOnWindows = $PSVersionTable.OS -match "Windows"
        $IsRunningOnMacOS   = $PSVersionTable.OS -match "Darwin"
        
        if ($IsRunningOnWindows) {
            $ProfileName = "Microsoft.PowerShell_profile.windows.ps1"
        } elseif ($IsRunningOnMacOS) {
            $ProfileName = "Microsoft.PowerShell_profile.macos.ps1"
        } else {
            $ProfileName = "Microsoft.PowerShell_profile.linux.ps1"
        }

        # Point to the new profiles folder
        $script:ProfilePath = Join-Path $ProjectRoot "profiles/$ProfileName"
        
        Write-Host "📂 Loading Profile: $ProfileName" -ForegroundColor Gray

        # 3. Create Test Environment
        $script:OriginalAppData = $env:LOCALAPPDATA
        if (Test-Path $script:testEnvPath) { Remove-Item $script:testEnvPath -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $script:testEnvPath -Force | Out-Null
        
        # Mocking Paths
        $env:LOCALAPPDATA = $script:testEnvPath
        # For Unix profiles using XDG/HOME
        $env:XDG_DATA_HOME = $script:testEnvPath
        $env:HOME = $script:testEnvPath 

        # =========================================================
        # 🛡️ CI FIXES
        # =========================================================
        function Global:oh-my-posh { return "Write-Host 'Oh-My-Posh Mocked'" }
        $Global:PSX_Name = "" 
        function Global:Clear-Host { }
        # =========================================================

        # 4. Load Profile
        if (Test-Path $script:ProfilePath) {
            . $script:ProfilePath
        } else {
            Throw "Could not find profile file at: $script:ProfilePath"
        }

        # Determine Log Path based on OS logic in profile
        if ($IsRunningOnWindows) {
            $script:TestLogFile = Join-Path $script:testEnvPath "PS7Logs\ps7_open_logs.json"
        } else {
            # Linux profile uses XDG_DATA_HOME/PS7Logs
            $script:TestLogFile = Join-Path $script:testEnvPath "PS7Logs/ps7_open_logs.json"
        }
    }

    It "📝 Should create log file automatically on load" {
        $exists = Test-Path $script:TestLogFile
        if ($exists) { Write-Host "   ✅ File found at: $script:TestLogFile" -ForegroundColor DarkGray }
        $exists | Should -Be $true
    }

    It "➕ Should contain the initial log entry" {
        if (-not (Test-Path $script:TestLogFile)) { Throw "Log file missing" }
        
        $content = Get-Content $script:TestLogFile -Raw 
        if ([string]::IsNullOrWhiteSpace($content)) { $content = "[]" }
        
        $json = $content | ConvertFrom-Json
        $json.Count | Should -BeGreaterThan 0
    }

    It "🔍 Get-PowerShell7-Open-Logs should run without error" {
        { Get-PowerShell7-Open-Logs } | Should -Not -Throw
    }

    It "🗑 Should delete logs when using -Delete switch" {
        Get-PowerShell7-Open-Logs -Delete
        
        $content = Get-Content $script:TestLogFile -Raw
        if ([string]::IsNullOrWhiteSpace($content)) { $content = "[]" }
        $json = $content | ConvertFrom-Json
        
        $json.Count | Should -Be 0
    }

    AfterAll {
        if ($script:OriginalAppData) { $env:LOCALAPPDATA = $script:OriginalAppData }
        
        if ($script:testEnvPath -and (Test-Path $script:testEnvPath)) { 
            Remove-Item $script:testEnvPath -Recurse -Force -ErrorAction SilentlyContinue 
        }
        
        Write-Host "`n🎉 Test Environment Cleaned up." -ForegroundColor Magenta
    }
}