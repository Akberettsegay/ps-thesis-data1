$Nic = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "ipenabled = 'true'"
$Nic.SetTcpipNetbios(2)