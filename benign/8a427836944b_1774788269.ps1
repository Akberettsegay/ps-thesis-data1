<#
.Synopsis
    TPM 1.2 -> TPM 2.0 Updater
.DESCRIPTION
    Verifies TPM mode and initiates TPM 1.2 -> TPM 2.0 discrete upgrade if necessary
.EXAMPLE
    VerifyTpmMode.ps1
.NOTES
    Created:	 2017-09-19
	Updated:	 2017-11-08
    Version:	 1.2
    Author - Anton Romanyuk
    Twitter: @admiraltolwyn
    Blog   : http://www.vacuumbreather.com
    Disclaimer:
    This script is provided 'AS IS' with no warranties, confers no rights and 
    is not supported by the author.
.LINK
    http://www.vacuumbreather.com
.NOTES
	1.1: Added support for detection and remediation of vulnerable TPM firmware on HP models
	1.2: Fixed inconsistencies in the logging messages
#>

# Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("LogPath")  
$logFile = "$logPath\$($myInvocation.MyCommand).log"
$Make = $TSenv.Value("Make")
 
# Start the logging 
Start-Transcript $logFile
Write-Host "$($myInvocation.MyCommand) - Logging to $logFile"

$NeedReboot = "NO"

# Credentials 
$DellPassword = "YourDellBiosPassword"
 
# Start Main Code Here
# https://stackoverflow.com/questions/8761888/capturing-standard-out-and-error-with-start-process
Function Execute-Command ($commandTitle, $commandPath, $commandArguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    [pscustomobject]@{
        commandTitle = $commandTitle
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode  
    }
}

Switch ($Make){
"HP"{
    Write-Host "$($myInvocation.MyCommand) - Detecting whether a platform supports HP discrete TPM mode switching in real time."
    Write-Host "$($myInvocation.MyCommand) - For HP platforms that support TPM mode changes, the output from powershell should include: ManufacturerVersion: 6.40, 6.41 or 6.43 (1.2 mode), or 7.40, 7.41, 7.60, 7.61 or 7.63 (2.0 mode)"
	Write-Host "$($myInvocation.MyCommand) - Checking if installed TPM firmware is affected by ADV170012. Vulnerable TPM versions: ManufacturerVersion: 6.40 or 6.41 (1.2 mode), or 7.40, 7.41, 7.60 or 7.61 (2.0 mode)"
    $tpm_mode = (Get-TPM).ManufacturerVersion
    Write-Host "$($myInvocation.MyCommand) - Following ManufacturerVersion detected: $tpm_mode"

    If ($tpm_mode -eq "6.40") {
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe."
        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode 1.2->2.0."
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM12_6.40.190.0_to_TPM20_7.41.2375.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
    If ($tpm_mode -eq "6.41") { 
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe."      
        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode 1.2->2.0."
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM12_6.41.197.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
	If ($tpm_mode -eq "6.43") { 
        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode 1.2->2.0."
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM12_6.43.243.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
	If ($tpm_mode -eq "7.40") { 
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe." 
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM20_7.40.2098.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
	If ($tpm_mode -eq "7.41") { 
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe." 
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM20_7.41.2375.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
	If ($tpm_mode -eq "7.60") { 
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe." 
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM20_7.60.2677.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
	If ($tpm_mode -eq "7.61") { 
		Write-Host "$($myInvocation.MyCommand) - This Infineon firmware version is not safe." 
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' -f"' + $PSScriptRoot + '\HP\TPM20_7.61.2785.0_to_TPM20_7.62.3126.0.BIN" -p"' + $PSScriptRoot + '\password.bin" -s'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\HP\TPMConfig64.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
}
"Dell Inc."{
    
    Write-Host "$($myInvocation.MyCommand) - Detecting whether a platform supports Dell discrete TPM mode switching in real time."
    Write-Host "$($myInvocation.MyCommand) - For Dell platforms that support TPM mode changes, the output from powershell should include: ManufacturerVersion: 5.81 (1.2 mode), or 1.3 (2.0 mode)"
    $tpm_mode = (Get-TPM).ManufacturerVersion
    Write-Host "$($myInvocation.MyCommand) - Following ManufacturerVersion detected: $tpm_mode"

    If ($tpm_mode -eq "5.81") {
        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode 1.2->2.0."
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning -OnlyForNextRestart

	    $cmdLine  = ' /s /p="' + $DellPassword + '" /l="c:\temp\TpmModeSwitch.log"'

        Write-Host "$($myInvocation.MyCommand) - Changing TPM Mode..."
	    $log_tmp = Execute-Command -commandTitle "Change TPM Mode" -commandPath  $PSScriptRoot\Dell\Updates\DellTpm2.0_Fw1.3.0.1.exe -commandArguments $cmdLine

        $NeedReboot = "YES"
	    Write-Host $log_tmp
    }
}
Default {
        Write-Host "$($myInvocation.MyCommand) - $Make is unsupported, exit" 
        Exit 0
    }
}

# Execute reboot if needed
If ($NeedReboot -eq "YES") {
    Write-Host "$($myInvocation.MyCommand) - A reboot is required. The installation will resume after restart."
    $TSenv.Value("NeedRebootTpmSwitch") = $NeedReboot
	Exit 0
}

# Stop logging 
Stop-Transcript