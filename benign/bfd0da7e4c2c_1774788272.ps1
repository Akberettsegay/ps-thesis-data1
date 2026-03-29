<#
.Synopsis
    MDT Language Packs Importer
.DESCRIPTION
    Imports Windows 10 language packs and features on demand into the MDT workbench
.EXAMPLE
    MDT-ImportLanguagePacks.ps1
.NOTES
    Created:	 2017-08-24
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
	1. Modify parameters to match your deployment share
	2. Run the script
#>

cls

#---------------------------------------------------------------------------

# Adjust these variables if necessary 
# IMPORTANT: use UNC path for src_dir, otherwise MDT might not be able to import packages
# NOTE: Adjust $w10_build variable accordingly

$mdt_root = "\\MDT01\W10$\" #UNC or local
$mdt_drive = "DS005"
$w10_build = "1607"
$w10_rel = "Windows 10 " + $w10_build + " x64"
$lan_lis = @("de-de","fr-fr","es-es","el-gr","hu-hu","it-it","nl-nl","pl-pl","pt-pt","ru-ru","sv-se","tr-tr")
$src_dir = "\\MDT01\C$\Import\LANGUAGE_PACKS\MultiLang_Feat_on_Demand_" + $w10_build
$mdt_path = $mdt_drive + ":\Packages\Language Packs\" 

#---------------------------------------------------------------------------

#Import MDT PS1 module and map deployment share
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name $mdt_drive -PSProvider MDTProvider -Root $mdt_root

# create W10 MDT rel language pack folder if it doesn't exist, supress all errors
Write-Host "Creating MDT language code subfolder: " $mdt_dir -ForegroundColor Green
New-Item -path $mdt_path -enable "True" -Name $w10_rel -Comments "" -ItemType "Folder" 2>$null

ForEach ($lan in $lan_lis) {

        #Construct full path for each language package
        $sub_dir = $src_dir + "\" + $lan
        $mdt_dir = $mdt_path + "\" + $w10_rel + "\" + $lan

        # create W10 MDT language specific folder if it doesn't exist, supress all errors
        Write-Host "Creating MDT language code subfolder:" $mdt_dir -ForegroundColor Green
        New-Item -path ($mdt_path + "\" + $w10_rel) -enable "True" -Name $lan -Comments "" -ItemType "Folder" 2>$null

        # Create subfolders
        Write-Host "Creating language code subfolder:" $sub_dir -ForegroundColor Green
        New-Item -ItemType Directory -Force -Path $sub_dir

        #Find language packages and copy them to subfolders
        Write-Host "Copying" $lan "source files to " $sub_dir -ForegroundColor Green
        Get-ChildItem $src_dir  -force | Where-Object {$_.name -like '*-' + $lan + '*' -or $_.name -like '*_' + $lan + '.cab'} |Copy-Item -Destination $sub_dir -Force #-Verbose
        
        #Remove Retail-Demo package
        Write-Host "Removing" $lan "RetailDemo package file..." -ForegroundColor Green
        Get-ChildItem $sub_dir  -force | Where-Object {$_.name -like '*RetailDemo*'} | Remove-Item -Force
        
        #Import language packages into MDT
        Write-Host "Importing" $lan "language package files into MDT..." -ForegroundColor Green
        import-mdtpackage -path $mdt_dir -SourcePath $sub_dir #-Verbose
}