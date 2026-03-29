<#
.Synopsis
    TPM auto provisioning enabler
.DESCRIPTION
    Used to enable Windows 10 TPM autoprovisioning
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
 
# Start Main Code Here
Switch ($Make){
"Dell Inc."{
	    Write-Host "$($myInvocation.MyCommand) - Enable the TPM auto-own behavior."
        Enable-TpmAutoProvisioning
		$NeedReboot = "YES"
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