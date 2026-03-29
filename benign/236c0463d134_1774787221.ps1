$token_bot = "5517149522:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$id_chat = "-609777777"
$esxi = "vcsa.domain.local"
$user = "administrator@vsphere.local"
$pass = Get-Content "$home\Documents\vcsa_password.txt" | ConvertTo-SecureString
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Connect-VIServer $esxi -User $Cred.Username -Password $Cred.GetNetworkCredential().password

$stores = Get-Datastore
$proc = 30
foreach ($s in $stores) {
    $ds_name = $s.Name
    $vms = ((Get-Datastore $ds_name | get-vm).name) -join "; "
    $all = (($s.CapacityGB) -replace "\..+")
    $1_proc = $all / 100
    $free = ($s.FreeSpaceGB) -replace "\..+"
    $free_proc = ($free / $1_proc) -replace "\..+"
    if ($free_proc -lt $proc) {
        $out = "Хранилище <b>$ds_name</b> свободного места $free_proc % (доступно <b>$free GB</b> из $all GB).
Список VM подключенных к Datastore: $vms"
        $payload = @{
            "chat_id"    = $id_chat
            "text"       = $out
            "parse_mode" = "html"
        }
        Invoke-RestMethod -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $token_bot) -Method Post -ContentType "application/json;charset=utf-8" -Body (ConvertTo-Json -Compress -InputObject $payload) # or Invoke-WebRequest
    }
}