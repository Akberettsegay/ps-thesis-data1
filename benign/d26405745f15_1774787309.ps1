#requires -version 2
<#
.SYNOPSIS
  Enable Mailbox online archive (with quota) for a list (.CSV file) of mailbox

.DESCRIPTION
  Enable Mailbox online archive (and set quota and quota alert) for a list (.CSV file) of mailbox.
  All modifications and a listing of actives archives were put on the log file.

.INPUTS
  .CSV file selected by user during the script

.OUTPUTS
   Create transcript log file similar to $ScriptDir\[SCRIPTNAME]_[YYYY_MM_DD]_[HHhMMmSSs].log
     
   
.NOTES
  Version:        3.0
  Author:         ALBERT Jean-Marc
  Creation Date:  24/06/2015
  Purpose/Change: 1.0 - 2015.06.24 - ALBERT Jean-Marc - Initial script development
                  2.0 - 2015.06.24 - ALBERT Jean-Marc - Add .CSV file selection
                                                        Add parts 'Show actives archives on local server',
                                                        'MessageBox who inform of the end of the process'
                                                        and 'Open the log file'
                  3.0 - 2015.06.24 - ALBERT Jean-Marc - Add possibility to start a connection with Exchange Management Shell (unactive for now)
                                                             
.EXAMPLE
  Start 'Exchange Management Shell' and execute .\[SCRIPTNAME].ps1

#>
 

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"

# Avoid error when the script is launch with "Run with Powershell"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "3.0"

#Write script directory path on "ScriptDir" variable
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#Log file creation, similar to $ScriptDir\[SCRIPTNAME]_[YYYY_MM_DD].log
$SystemTime = Get-Date -uformat %Hh%Mm%Ss
$SystemDate = Get-Date -uformat %Y.%m.%d
$ScriptLogFile = "$ScriptDir\$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition))" + "_" + $SystemDate + "_" + $SystemTime + ".log"

#Declare archive database who create future online archives
$ArchiveDatabase = "DATABASE_ARCHIVE_PX_1"
$ArchiveQuota = '1GB'
$ArchiveWarningQuota = '800MB' 

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Stop-TranscriptOnLog
 {   
 	Stop-Transcript
    # Add EOL required for Notepad.exe application usage
    [string]::Join("`r`n",(Get-Content $ScriptLogFile)) | Out-File $ScriptLogFile
 }
 
 function Select-FileDialog
    {
     param([string]$Title,[string]$Filter="All files *.*|*.*")
	    [System.Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' ) | Out-Null
	    $fileDialogBox = New-Object Windows.Forms.OpenFileDialog
	    $fileDialogBox.ShowHelp = $false
	    $fileDialogBox.initialDirectory = $ScriptDir
	    $fileDialogBox.filter = $Filter
        $fileDialogBox.Title = $Title
	    $Show = $fileDialogBox.ShowDialog( )

    If ($Show -eq "OK")
        {
         Return $fileDialogBox.FileName
        }
    Else
        {
         Add-Content $ScriptLogFile -Value "Operation canceled by user at $SystemDate $SystemTime"
		 [System.Windows.Forms.MessageBox]::Show("The script can't continue. Operation stopped at $SystemDate $SystemTime." , "Operation canceled" , 0, [Windows.Forms.MessageBoxIcon]::Error)
         Stop-TranscriptOnLog
		 Exit
        }
    }

#------------------------------------------------------------[Actions]-------------------------------------------------------------
 # Start of log completion
   Start-Transcript $ScriptLogFile | Out-Null

 # Import CSV file
   [System.Windows.Forms.MessageBox]::Show(
"
Select on this window the CSV file who contains mailbox list.
Its content must be similar to:
  
PrimarySmtpAddress        (Required line)
mailaddress1@domain.com (Replace it)
mailaddress2@domain.com (Replace it)
mailaddress3@domain.com (Replace it)
mailaddress4@domain.com (Replace it)
" , "Mailbox list for Online Archive activation" , 0, [Windows.Forms.MessageBoxIcon]::Question)

   $CSVInputFile = Select-FileDialog -Titre "Select CSV file" -Filter "Fichier CSV (*.csv) |*.csv"

 # Import list of mailbox who need to create online archive   
   $CSVUsersToActiveOnlineArchive = Import-Csv $CSVInputFile -Delimiter ';'
 
 # Loop for activate online archive and enter performed tasks on log file
   ForEach ($line in $CSVUsersToActiveOnlineArchive){
       $PrimarySmtpAddress = $line.PrimarySmtpAddress
       Enable-Mailbox $PrimarySmtpAddress -Archive -ArchiveDatabase $ArchiveDatabase
       Set-Mailbox $PrimarySmtpAddress -ArchiveQuota $ArchiveQuota -ArchiveWarningQuota $ArchiveWarningQuota
       Write-Output "Online archive activated for $PrimarySmtpAddress with a $ArchiveQuota Quota and a warning at $ArchiveWarningQuota utilization"
                                                    }
 
 # Show actives archives on local server
  Write-Output "Actives archives on all servers:"
  Get-Mailbox -Archive | FT Name,Alias,ServerName -AutoSize

 
 # MessageBox who inform of the end of the process
   [System.Windows.Forms.MessageBox]::Show(
"Activation and set of quota for online archives process is done.
The log file will be opened when click on 'OK' button
Please, check the log file for further informations
" , "End of the online archive process" , 0, [Windows.Forms.MessageBoxIcon]::Information)

 # Close the Exchange Powershell Session
   #Remove-PSSession $ExchangePSSession
 
 # Stop the log transcript
   Stop-TranscriptOnLog

 # Open the log file
   Invoke-Item $ScriptLogFile