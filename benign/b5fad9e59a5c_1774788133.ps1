#requires -version 3.0
#requires -modules activedirectory
#Requires -RunAsAdministrator
<#
	.SYNOPSIS
		Configure an Active Directory Domain.
	.DESCRIPTION
		Configure an Active Directory Domain. Including AD Recyle Bin, preparation for MS Managed Service acounts, GPO Central Store, FGPP and a lot more.
        This script also creates an sample OU structure.
	.EXAMPLE  
        Configure-AD.ps1
	.INPUTS
		Keine.
	.OUTPUTS
		Keine.
    .PARAMETER 
	.NOTES
		Author     : Fabian Niesen
		Filename   : 
		Requires   : PowerShell Version 3.0
		
		Version    : 0.1
		History    : 0.2   FN  31.08.2022  Add some autodetection, Change Logging
                     0.1   FN  26.11.2015  initial version
                    

    .LINK
https://github.com/InfrastructureHeroes/Scipts/

    .COPYRIGHT
Copyright (c) Fabian Niesen if not stated otherwise. All rights reserved. Licensed under the MIT license.
        
#>
Param(
	[Parameter(Mandatory=$false, Position=1 , ValueFromPipeline=$True)]
	[String]$DOM =(Get-ADDomain).Forest,
	[Parameter(Mandatory=$false, Position=2, ValueFromPipeline=$True)]
	[String]$NETBIOS ="DEMO",
	[Parameter(Mandatory=$false, Position=3, ValueFromPipeline=$True)]
	[String]$SMADMINPW ="Chang3M3!",
	[Parameter(Mandatory=$false, Position=4, ValueFromPipeline=$True)]
	[String]$LDAPDOM = (Get-ADDomain).DistinguishedName,
	[Parameter(Mandatory=$false, Position=5, ValueFromPipeline=$True)]
	[String]$IPSubnet = $null
)


$ErrorActionPreference = "SilentlyContinue"
$script:BuildVer = "0.2"
$script:ProgramFiles = $env:ProgramFiles
$script:ParentFolder = $PSScriptRoot | Split-Path -Parent
$script:ScriptName = $myInvocation.MyCommand.Name
$script:ScriptName = $scriptName.Substring(0, $scriptName.Length - 4)
$LogName = $script:ScriptName
$Logpath = "C:\Windows\Logs" + "\" + $LogName
$LogFile = $Logpath +"\" + (Get-Date -UFormat "%Y%m%d-%H%M")+ "_"+$script:ScriptName + ".log"
# End of declaration - do not edit below this Point!
####################################################
#region Logfiles
<#
.COPYRIGHT for this region
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project https://github.com/gregnottage/IntuneScripts for license information.

.Notes
Removed EventLog Handling and smaller changes by Fabian Niesen
#>
Function Start-Log {
    param (
        [string]$FilePath,

        [Parameter(HelpMessage = 'Deletes existing file if used with the -DeleteExistingFile switch')]
        [switch]$DeleteExistingFile
    )
	
    Try {
        If (!(Test-Path $FilePath)) {
            ## Create the log file
            New-Item $FilePath -Type File -Force | Out-Null
        }
            
        If ($DeleteExistingFile) {
            Remove-Item $FilePath -Force
        }
			
        ## Set the global variable to be used as the FilePath for all subsequent Write-Log
        ## calls in this session
        $script:ScriptLogFilePath = $FilePath
    }
    Catch {
        Write-Error $_.Exception.Message
    }
}

####################################################

Function Write-Log {
    #Write-Log -Message 'warning' -LogLevel 2
    #Write-Log -Message 'Error' -LogLevel 3
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
			
        [Parameter()]
        [ValidateSet(1, 2, 3)]
        [int]$LogLevel = 1,

        [Parameter(HelpMessage = 'Outputs message to Event Log,when used with -WriteEventLog')]
        [switch]$WriteEventLog
    )
    Write-Host $Message
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath
}
#endregion Logfiles
####################################################


If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole( [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  Write-Warning "You need Admin Permissions to run this script!"| Out-file $ErrorLog -Append
    break
}

  Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
  Import-Module ADDSDeployment
  Write-Log -Message  "Prepare Managed Service Accounts"
  Add-KdsRootKey -EffectiveImmediately
  
  Write-Log -Message  "Erstelle Central GPO Store"
  Copy-Item -Path C:\Windows\PolicyDefinitions -Destination C:\Windows\Sysvol\domain\Policies -Recurse

  Write-Log -Message  "Disable NetBios over TCPIP"
  $nic = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'"
  $nic.SetTcpipNetbios(2)

  Write-Log -Message  "Konfiguriere AD-Papierkorb"
  $ADPK = "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,"+$LDAPDOM
  Enable-ADOptionalFeature -Identity $ADPK -Scope ForestOrConfigurationSet -Target $DOM -Confirm $false

  Write-Log -Message  "Vorbereitung für GMSA"
  Add-KdsRootKey -EffectiveImmediately

  Write-Log -Message  "Erzeuge OU Struktur"
  New-ADOrganizationalUnit -Name Benutzer -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Computer -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Server -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name NeueBenutzer -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name NeueComputer -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Benutzer -Path $("OU=Benutzer,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Kontakte -Path $("OU=Benutzer,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Gruppen -Path $("OU=Benutzer,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Services -Path $LDAPDOM -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name EXC -Path $("OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Rechtegruppen -Path $("OU=EXC,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Verteilergruppen -Path $("OU=EXC,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Server -Path $("OU=EXC,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name FIL -Path $("OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Gruppen -Path $("OU=FIL,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Server -Path $("OU=FIL,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name UPD -Path $("OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Server -Path $("OU=UPD,OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true
  New-ADOrganizationalUnit -Name Server -Path $("OU=Services,"+$LDAPDOM) -ProtectedFromAccidentalDeletion $true

  Write-Log -Message  "Konfiguriere Umlenkung für neue Computer und Bentzer"
  redirusr $("OU=NeueBenutzer,"+$LDAPDOM)
  redircmp $("OU=NeueComputer,"+$LDAPDOM)
  
  # ADFGPP
  Write-Log -Message  "Erstelle FineGrained Password Policy"
  New-ADGroup -Name "Dienstekonten" -SamAccountName "Dienstekonten" -groupScope Global -GroupCategory Security -Path $("CN=Users,"+$LDAPDOM) -Description "Securitygroup for DienstekontenPSO"
  New-ADGroup -Name "Adminkonten" -SamAccountName "Adminkonten" -groupScope Global -GroupCategory Security -Path $("CN=Users,"+$LDAPDOM) -Description "Securitygroup for AdminkontenPSO"
  New-ADFineGrainedPasswordPolicy -Name "DienstekontenPSO" -Precedence 200 -ComplexityEnabled $true -Description "Passwortrichtlinie für Dienstekonten" -MaxPasswordAge "90.00:00:00" -MinPasswordAge "1.00:00:00" -MinPasswordLength 16 -PasswordHistoryCount 24
  New-ADFineGrainedPasswordPolicy -Name "AdminkontenPSO" -Precedence 100 -ComplexityEnabled $true -Description "Passwortrichtlinie für Administrative Konten" -MaxPasswordAge "90.00:00:00" -MinPasswordAge "1.00:00:00" -MinPasswordLength 20 -PasswordHistoryCount 24
  Add-ADFineGrainedPasswordPolicySubject DienstekontenPSO -Subjects Dienstekonten
  Add-ADFineGrainedPasswordPolicySubject AdminkontenPSO -Subjects Adminkonten
  
  #Write-Log -Message  "Anlegen der AD Site"
  #IF ($IPSubnet -ne $null) { New-ADReplicationSubnet -Name $IPSubnet }