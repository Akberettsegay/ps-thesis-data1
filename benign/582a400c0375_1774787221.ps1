Import-Module "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitMain.ps1"
$AppName = "Notepad++"
$UninstallerPath = "C:\Program Files\Notepad++\uninstall.exe"
If (-not (Test-Path $UninstallerPath)) {
    Write-Host "Деинсталлятор Notepad++ не найден: $UninstallerPath"
    Exit-Script -ExitCode 1
}
Function Uninstall-Application {
    Show-InstallationWelcome -CloseApps "iexplore" -CheckDiskSpace -PersistPrompt
    Execute-Process -Path $UninstallerPath -Parameters "/S" -WindowStyle Hidden -IgnoreExitCodes "3010"
    Show-InstallationPrompt -Message "Программа $AppName удалена." -ButtonRightText "Закрыть" -Icon Information -NoWait
    Exit-Script -ExitCode $AppDependentExitCode
}
Uninstall-Application