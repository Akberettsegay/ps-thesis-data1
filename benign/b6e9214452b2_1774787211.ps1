$group_name = "RDGW_Admins"
$mailFrom = "Report@$env:userdnsdomain"
$mailTo = "support@mail.ru"
$mailSrv = "mail.mail.ru"
$file_name = "$group_name.txt"
$path = "$env:userprofile\Documents\$file_name"

function ad-group {
    Get-ADGroupMember -Identity $group_name | select -ExpandProperty Name
}

function compare-group {
    Compare-Object -ReferenceObject (ad-group) -DifferenceObject $check_file | select -ExpandProperty InputObject
}

if ((Test-Path $path) -eq $false) {
    New-Item -Path $path;
    ad-group > $path
}

$check_file = Get-Content $path
$count = ((ad-group).Count) - ($check_file.Count)
if ($count -notmatch "-") {
    $count = $count -replace "^", "+"
}

if (compare-group) {
    $change = compare-group
    $change = $change -join "; "

    #Send-MailMessage -From "$mailFrom" -To "$mailTo" -Subject "В группе $group_name есть изменени" -Body "
    #$count пользователь(я):
    #$change" –SmtpServer "$mailSrv" -Encoding 'UTF8'

    Add-Type -AssemblyName System.Windows.Forms
    $NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $NotifyIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command netplwiz).Path)
    $NotifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
    $NotifyIcon.BalloonTipTitle = "В группе $group_name есть изменения"
    $NotifyIcon.BalloonTipText = "
$count пользователь(я):
$change"
    $NotifyIcon.Visible = $true
    $NotifyIcon.ShowBalloonTip(10000)
}