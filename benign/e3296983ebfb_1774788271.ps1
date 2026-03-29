<#
.Synopsis
    MDT Custom CustomSettings.ini Generator
.DESCRIPTION
    Creates a task sequence specific CustomSettings.ini
.EXAMPLE
    MDT-GenerateTSini.ps1
.NOTES
    Created:	 2017-08-28
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
	3. Verify content of the resulting INI file and copy it into the Control folder
#>

cls

#---------------------------------------------------------------------------

# Adjust these variables if necessary 
$con_lis = @("AT","BE","CH","DE","ES","GR","HU","LU","NL","PL","PT","RU","SE","TR")
$src_xml = "\\MDT01\W10$\Control\Packages.xml" #package list
$w10_ver = "10.0.14393.0" # W10 build number, has to match target OS build
$w10_dir = "Windows 10 1607 Enterprise x64" #OS folder, required for .NET 3.5 sources
$w10_ts  = "10_1607" #Task Sequence ID

#---------------------------------------------------------------------------
$cur_date = Get-Date
$cab_array = @()
$lan_xml = [xml](Get-Content $src_xml)

#create custom package array
ForEach ($cab in $lan_xml.packages.package) 
    {
        $cab_array += @{
        name=$cab.Name.ToString()
        guid=$cab.guid.ToString()
        version=$cab.version.ToString()
    }
}

#This function generates LanguagePacks00x={guid} line
Function Gen-Content
    {
        $tmp = 'LanguagePacks00' + $counter + '=' + $tmp_filter.guid + "`r`n"
        $global:cs_file += $tmp
    }

#This function generates country specific list of language packs
Function Gen-LanList
    {
        $counter = 1
        ForEach ($lan in $tmp_lis) 
        {
            $global:cs_file += "`r`n;Language Pack `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*LanguagePack-Package ' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file += ";Basic `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*Basic-' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file += ";Text-to-speech `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*TextToSpeech-' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file += ";Speech recognition `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*-Speech-' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file += ";Optical character recognition `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*OCR-' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file += ";handwriting recognition `r`n"
            $tmp_filter = $cab_array | Where-Object {$_.name -like '*Handwriting-' + $lan + '*' -and $_.version -eq $w10_ver} 
            If ($tmp_filter.guid)
                {
                    Gen-Content
                    $counter++
                }
            $global:cs_file +=  "`r`n"
        }
    }

$global:cs_file = ';Last updated: ' + $cur_date + "`r`n`r`n"
$global:cs_file += '[Settings]
Priority=ComputerNameAlias, SetLocale, Default
Properties=OSDCountry

[ComputerNameAlias]
OSDCountry=#Left("%OSDComputerName%",2)#

; This section acts as a switch for language packs
[SetLocale]
Subsection=%OSDCountry%'
$global:cs_file += "`r`n`r`n"

ForEach ($country in $con_lis)
    {
        If ($country -eq "AT") 
            {
                $tmp_lis = @("de-de")
                $switch = '[' + $country + ']'
                #$switch = '[' + $lan.substring(3,2).toupper() + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "BE") 
            {
                $tmp_lis = @("de-de","fr-fr","nl-nl")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "CH") 
            {
                $tmp_lis = @("de-de","fr-fr","it-it")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "DE") 
            {
                $tmp_lis = @("de-de")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "ES") 
            {
                $tmp_lis = @("es-es")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "GR") 
            {
                $tmp_lis = @("el-gr")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "HU") 
            {
                $tmp_lis = @("hu-hu")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "LU") 
            {
                $tmp_lis = @("de-de","fr-fr")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "BE") 
            {
                $tmp_lis = @("de-de","fr-fr","nl-nl")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "NL") 
            {
                $tmp_lis = @("nl-nl")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "PL") 
            {
                $tmp_lis = @("pl-pl")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "PT") 
            {
                $tmp_lis = @("pt-pt")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "RU") 
            {
                $tmp_lis = @("ru-ru")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "SE") 
            {
                $tmp_lis = @("sv-se")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
        If ($country -eq "TR") 
            {
                $tmp_lis = @("tr-tr")
                $switch = '[' + $country + ']'
                $global:cs_file += $switch
                Gen-LanList
            }
    }

$global:cs_file += "[Default]
SkipCapture=YES

; NetFX 3.5 source path `r`n"

$global:cs_file += "WindowsSource=%DeployRoot%\Operating Systems\" + $w10_dir + "\sources\sxs" + "`r`n"

$global:cs_file +='
PrepareWinRE=YES
DisableTaskMgr=YES'

$global:cs_file | Out-File -FilePath $PSScriptRoot\CustomSettings_$w10_ts.ini -Encoding ascii -Force