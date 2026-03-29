<#
.Synopsis
    TPM auto provisioning disabler
.DESCRIPTION
    Used to disable Windows 10 TPM autoprovisioning
.EXAMPLE
    EnableTPMAutoProvisioning.ps1
.NOTES
    Created:	 2017-09-19
    Version:	 1.0
    Author - Anton Romanyuk
    Twitter: @admiraltolwyn
    Blog   : http://www.vacuumbreather.com
    Disclaimer:
    This script is provided 'AS IS' with no warranties, confers no rights and 
    is not supported by the author.
.LINK
    http://www.vacuumbreather.com
.NOTES

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
 
# Start Main Code Here
Switch ($Make){
"Dell Inc."{
    
    Write-Host "$($myInvocation.MyCommand) - Detecting whether a platform supports Dell discrete TPM mode switching in real time."
    Write-Host "$($myInvocation.MyCommand) - For Dell platforms that support TPM mode changes, the output from powershell should include: ManufacturerVersion: 5.81 (1.2 mode), or 1.3 (2.0 mode)"
    $tpm_mode = (Get-TPM).ManufacturerVersion
    Write-Host "$($myInvocation.MyCommand) - Following ManufacturerVersion detected: $tpm_mode"

    If ($tpm_mode -eq "5.81") {
	    Write-Host "$($myInvocation.MyCommand) - Pause the TPM auto-own behavior temporarily."
        Disable-TpmAutoProvisioning
		$NeedReboot = "YES"
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