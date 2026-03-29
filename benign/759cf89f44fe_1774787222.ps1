$esxi = "vcsa.domain.local"
$user = "administrator@vsphere.local"
$pass = Get-Content "$home\Documents\vcsa_password.txt" | ConvertTo-SecureString
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Connect-VIServer $esxi -User $Cred.Username -Password $Cred.GetNetworkCredential().password

$Date = (Get-Date -Format "MM/dd/yyyy")
$Date += " 12:00 AM"
$log = Get-VIEvent -Start $Date -MaxSamples 10000 | `
    Where-Object { $_.FullFormattedMessage -match "reconfigure" } | `
    Select-Object UserName, CreatedTime, @{Label = "Message"; Expression = { $_.FullFormattedMessage -replace "(\n) | (\s{2,25})" } } | `
    Sort-Object CreatedTime
foreach ($l in $log) {
    write-host
    write-host $l.UserName
    write-host $l.CreatedTime
    write-host $l.Message
}

pause