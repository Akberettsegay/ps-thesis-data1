Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Command msconfig.exe).Path
$NotifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$NotifyIcon.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip

$MouseDoubleClick = [System.Windows.Forms.MouseEventHandler] {
    $NotifyIcon.BalloonTipTitle = "Start"
    $NotifyIcon.BalloonTipText = "MouseDoubleClick"
    $NotifyIcon.ShowBalloonTip($Duration)
}
$NotifyIcon.add_MouseDoubleClick($MouseDoubleClick)

$menu_serv = $menu.Items.Add("Services")
$menu_serv.add_Click({
        Get-Service | Out-GridView
    })

$menu_proc = $menu.Items.Add("Process")
$menu_proc.add_Click({
        Get-Process | Out-GridView
    })

$menu_exit = $menu.Items.Add("Exit")
$menu_exit.add_Click({
        $NotifyIcon.dispose()
        $App.ExitThread()
    })

$NotifyIcon.ContextMenuStrip = $menu

$App = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($App)