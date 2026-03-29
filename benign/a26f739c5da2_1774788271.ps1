<#
.Synopsis
    MDT Driver Importer 1.0
.DESCRIPTION
    Imports driver repository into the MDT workbench
.EXAMPLE
    MDT-ImportDrivers.ps1
.NOTES
    Created:	 2016-08-16
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
	1. Copy files to the staging folder
	2. Modify parameters to match the deployment share
	3. Run the script
#>

cls

#---------------------------------------------------------------------------

# Adjust these variables if necessary 
$stage_dir = "C:\Import\DRIVERS\"
$mdt_root = "\\MDT01\W10$" #UNC or local
$vendors = @("HP", "Dell Inc.")
$os_name = "Windows 10 x64"

#---------------------------------------------------------------------------

$mdt_drive = "DS005"

# import MDT PS module and connect to the deployment share
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1" 2>$null
New-PSDrive -Name $mdt_drive -PSProvider MDTProvider -Root $mdt_root

# Main

ForEach ($vendor in $vendors) {
	# check if vendor folder exists
    If ($vendor) {
		Write-Host "Found following vendor: " $vendor
		
		# query vendor folder for any model subfolders
        $tmp_dir = $stage_dir + $vendor
        $src_dir = Get-ChildItem $tmp_dir -Recurse -Directory -Depth 0

        ForEach ($dir in $src_dir) {
        
			# for example: C:\PreStaging\Drivers\Dell Inc.\Latitude 5570
            $tmp_drv_dir = $tmp_dir + "\" + $dir.Name
			# get all driver categories for a specific model
            $drv_dirs = Get-ChildItem $tmp_drv_dir -Recurse -Directory -Depth 0
			
			# for example: DS001:\Out-of-Box Drivers\Windows 10 x64\Dell Inc.
            $mdt_driver_root = $mdt_drive + ":\Out-of-Box Drivers\" + $os_name + "\" + $vendor
			# for example: DS001:\Out-of-Box Drivers\Windows 10 x64\Dell Inc.\Latitude E5570
            $mdt_path = $mdt_driver_root + "\" + $dir.Name

            # create model folder if it doesn't exist, supress all errors
            New-Item -path $mdt_driver_root -enable "True" -Name $dir.Name -Comments "" -ItemType "Folder" 2>$null

            ForEach ($drv_dir in $drv_dirs) {

				# construct full driver path
				# for example: DS001:\Windows 10 x64\Dell Inc.\Latitude E5570\audio
                $mdt_dir = $mdt_path + "\" + $drv_dir

				# Delete MDT driver folder located in %Make%\%Model%\ and create it from scratch
				# for example: DS001:\Out-of-Box Drivers\Windows 10 x64\Dell Inc.\Latitude E5570\audio
				# This is necessary to ensure we start with a clean slate
				Write-Host "Performing " $mdt_dir " driver cleanup." -ForegroundColor Magenta
                Write-Host "Removing MDT folder: " $mdt_dir -ForegroundColor Cyan
                Remove-Item $mdt_dir -Force -Recurse 2>$null
				Write-Host "Creating MDT folder: " $mdt_dir -ForegroundColor Cyan
                New-Item -path $mdt_path -enable "True" -Name $drv_dir -Comments "" -ItemType "Folder" | Out-Null
                
				# construct full path to the staging folder containing driver package
				# for example: C:\PreStaging\Drivers\Dell Inc.\Latitude 5570\audio
                $drv_path =  $tmp_drv_dir + "\" + $drv_dir
                
				# import driver package
				Write-Host "Importing driver package: " $mdt_dir -ForegroundColor Cyan
                import-mdtdriver -path $mdt_dir -SourcePath $drv_path #-Verbose
            }  
        }
    }
}