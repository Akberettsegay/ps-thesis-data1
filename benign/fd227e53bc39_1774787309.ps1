#requires -version 2
<#
.SYNOPSIS
  Add FSRM Quota with a .CSV file

.DESCRIPTION
  Add FSRM Quota with a .CSV file who define a path an a quota template to apply on it

.INPUTS
 .CSV file selected by user during the script

.OUTPUTS
  Create transcript log file similar to $ScriptDir\[SCRIPTNAME]_[YYYY_MM_DD]_[HHhMMmSSs].log

.NOTES
  Version:        2.0
  Author:         ALBERT Jean-Marc
  Creation Date:  16/06/2015
  Purpose/Change: 2015.06.16 - ALBERT Jean-Marc - Initial script development
				  2015.06.22 - ALBERT Jean-Marc - Replace .CSV fixed name per file dialog selection
                                                  
  
.EXAMPLE
  <None>
#>
 
#---------------------------------------------------------[Initialisations]--------------------------------------------------------
 
#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Import-Module ActiveDirectoryImport-Module ISE

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "2.0"

#Write script directory path on "ScriptDir" variable
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Log file creation, similar to $ScriptDir\[SCRIPTNAME]_[YYYY_MM_DD].log
$ActualDate = Get-Date -uformat %Y_%m_%d
$ScriptLogFile = "$ScriptDir\$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition))" + "_" + $ActualDate + ".log"

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Stop-TranscriptOnLog
 {   
 	Stop-Transcript
   <# On met dans le transcript les retour à la ligne nécessaire à notepad #>
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
                Write-Error "Canceled operation"
		          [System.Windows.Forms.MessageBox]::Show("Script is not able to continue. Operation stopped." , "Operation canceled" , 0, [Windows.Forms.MessageBoxIcon]::Error)
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
Select on this window the CSV file who contains directory and quota parameters.
Its content must be similar to:
  
FullPath		Template		(Required line)
E:\Directory1	Users 1GO
E:\Directory2	Users 2GO
", "Folders & Quota parameters list", 0, [Windows.Forms.MessageBoxIcon]::Question)

$CSVInputFile = Select-FileDialog -Title "Select CSV file" -Filter "CSV File (*.csv) |*.csv"

# Import list of mailbox who need to create online archive
$csvValues = Import-Csv $CSVInputFile -Delimiter ';'


 # Set FSRM Quota Template with a loop
	foreach ($line in $csvValues) {
		$SharingSpace = $line.FullPath
		$Template = $line.Template
		New-FsrmQuota -Path $SharingSpace -Template $Template
	
}


# Stop the log transcript
    Stop-TranscriptOnLog