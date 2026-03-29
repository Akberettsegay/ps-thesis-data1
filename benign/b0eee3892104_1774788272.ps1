<#

************************************************************************************************************************

Created:    2017-11-06
Version:    1.0

Authors - Michael Niehaus, Anton Romanyuk (modifications for WIM servicing & removal of capabilities)

Purpose:   Removes some or all of the in-box apps and capabilities from a Windows 10
           WIM file. By default it will remove all apps and capabilities, but you can
           provide separate RemoveApps.xml & RemoveCapabilities.xml files with a list 
           of apps / capabilities that you want to remove. If those files don't exist, 
           the script will recreate them in the script folder, so you can run the script
           once, grab the files, make whatever changes you want, then put the files 
           alongside the script and it will remove only the apps and capabilities you 
           specified.

Additional Info:
           The script will mount install.wim to a temporary directory C:\temp\Mount,
           uninstall apps & capabilities, commit changes to install.wim and perform 
           cleanup activities.

************************************************************************************************************************

#>

cls

# ---------------------------------------------------------------------------
# Global variables
# ---------------------------------------------------------------------------

$MountFolder = "Mount"
$MountPath = "C:\temp\"
$MountFull = $MountPath + $MountFolder
$WimPath = "C:\temp\W10\sources\install.wim"
$WimIndex = "3" #NOTE: pre-1709: 1 = Enterprise, 1709: 3 = Enterprise

# ---------------------------------------------------------------------------
# Get-AppList:  Return the list of apps to be removed
# ---------------------------------------------------------------------------

function Get-AppList
{
  begin
  {
    # Look for a config file.
    $configFile = "$PSScriptRoot\RemoveApps.xml"
    if (Test-Path -Path $configFile)
    {
      # Read the list
      $list = Get-Content $configFile
    }
    else
    {
      # No list? Build one with all apps.
      Write-Output "Building list of provisioned apps"
      $list = @()        
      Get-AppxProvisionedPackage -Path $MountFull | % { $list += $_.DisplayName }

      # Write the list to the $PSScriptRoot path"
      $list | Set-Content $configFile
      Write-Output "Wrote list of apps to $PSScriptRoot\RemoveApps.xml, you can edit and use the list for future script executions"
    }

    Write-Host "Apps selected for removal: " $list.Count
  }

  process
  {
    $list
  }

}

# ---------------------------------------------------------------------------
# Get-CapabilityList:  Return the list of capabilities to be removed
# ---------------------------------------------------------------------------

function Get-CapabilityList
{
  begin
  {
    # Look for a config file.
    $configFile = "$PSScriptRoot\RemoveCapabilities.xml"
    if (Test-Path -Path $configFile)
    {
      # Read the list
      $list = Get-Content $configFile
    }
    else
    {
      # No list? Build one with all capabilities.
      Write-Output "Building list of provisioned capabilities"
      $list = @()        
      Get-WindowsCapability -Path $MountFull | % { $list += $_.Name }

      # Write the list to the $PSScriptRoot path"
      $list | Set-Content $configFile
      Write-Output "Wrote list of capabilities to $PSScriptRoot\RemoveCapabilities.xml, you can edit and use the list for future script executions"
    }

    Write-Host "Capabilities selected for removal:" $list.Count
  }

  process
  {
    $list
  }

}

# ---------------------------------------------------------------------------
# Remove-App:  Remove the specified app
# ---------------------------------------------------------------------------

function Remove-App
{
  [CmdletBinding()]
  param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string] $appName
  )

  begin
  {
      $script:Provisioned = Get-AppxProvisionedPackage -Path $MountFull
  }

  process
  {
    $app = $_

    # Remove the provisioned package
    Write-Output "Removing provisioned package $_"
    $current = $script:Provisioned | ? { $_.DisplayName -eq $app }
    if ($current)
    {
        $a = Remove-AppxProvisionedPackage -Path $MountFull -PackageName $current.PackageName
    }
    else
    {
         Write-Warning "Unable to find provisioned package $_"
    }
  }
}

# ---------------------------------------------------------------------------
# Remove-Capabilities:  Remove the specified capability
# ---------------------------------------------------------------------------

function Remove-Capability
{
  [CmdletBinding()]
  param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string] $CapabilityName
  )

  # Remove the capability
  Write-Output "Removing provisioned capability $CapabilityName"

  Try
  {
    Remove-WindowsCapability -Path $MountFull -Name $CapabilityName
  }
  Catch
  {
    Write-Warning "Unable to remove capability $CapabilityName"
  }
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

New-Item -Path $MountPath -Name $MountFolder -ItemType Directory -Force | Out-Null

Write-Host "$($myInvocation.MyCommand) - Mounting WIM" -ForegroundColor Green
Mount-WindowsImage -Path $MountFull -ImagePath $WimPath -Index $WimIndex -Optimize

Write-Host "$($myInvocation.MyCommand) - Removing apps" -ForegroundColor Green
Get-AppList | Remove-App

Write-Host "$($myInvocation.MyCommand) - Removing capabilities" -ForegroundColor Green
Get-CapabilityList | Remove-Capability

Write-Host "$($myInvocation.MyCommand) - Committing changes and dismounting WIM" -ForegroundColor Yellow
Dismount-WindowsImage -Path $MountFull -Save