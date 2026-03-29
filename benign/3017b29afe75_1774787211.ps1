#region change properties
#$all_users = Get-ADUser -filter * -Properties DisplayName | select -ExpandProperty DisplayName # sn,Description
$gusers = Get-ADUser -filter * -Properties sn
$users = @()
foreach ($u in $gusers) {
    $UserFamily = $u | Select-Object -ExpandProperty sn
    $UserName = $u | Select-Object -ExpandProperty givenName
    $users += $UserFamily + " " + $UserName
}
$all_users = $users[1..3000] -notlike " "
#endregion

$result = @()
$count_users = $all_users.Count
$result += "Количество пользователей в домене: $count_users"
Write-Host $result
$start_time = Get-Date

foreach ($usr in $all_users) {
    $mass = @()
    foreach ($n in $all_users) {
        if ($usr -eq $n) { $mass += $n }
    }
    if ($mass.count -gt 1) {
        $c = ($mass.count) - 1
        $cname = "$usr (повторений: $c)"
        Write-Host "Найден повторяющийся пользователь: $cname"
        $result += $cname
    }
}
$result = $result | Select-Object -Unique

$end_time = Get-Date
Write-Host "Сканирование завершено"
$time = $end_time - $start_time
$min = $time.minutes
$sec = $time.seconds
$time = "$min" + " минут " + "$sec" + " секунд"
$counts_dubl = ($result.Count) - 1
$result += "Количество повторящихся пользователей: $counts_dubl"
$result += "Время сканирования: $time"
$result += "Дата сканирования: $end_time"
$result > "$home/desktop/ADUser-Result.txt"