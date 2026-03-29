#region ico
# $ico_main = [System.Convert]::FromBase64String("")
# $ico_settings = [System.Convert]::FromBase64String("")
# $ico_refresh = [System.Convert]::FromBase64String("")
# $ico_stop = [System.Convert]::FromBase64String("")

$path = "$home\documents\dns-list.txt"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#endregion

function dns-list {
    $menu.Items.Clear()
    if (!(Test-Path $path)) {
        New-Item -Path $path -ItemType "File" -Value "6
1.1.1.1
8.8.8.8
9.9.9.9
77.88.8.8
77.88.8.7" | Out-Null
    }
    $global:list = Get-Content $path
    $global:interface = $list[0]
    $list_count = ($list.count) - 1
    if (!!($list_count -gt 15)) { $list_count = 15 }
    foreach ($r in 1..$list_count) {
        $menu.Items.Add($list[$r]) | Out-Null
    }
    checked-dns

    #region add-click-dns
    if ($list[1] -ne $null) {
        $menu.Items[0].add_Click({
                checked-false; $menu.Items[0].Checked = $true; $global:ip = $list[1]; change-ip; checked-interface
            })
    }

    if ($list[2] -ne $null) {
        $menu.Items[1].add_Click({
                checked-false; $menu.Items[1].Checked = $true; $global:ip = $list[2]; change-ip; checked-interface
            })
    }

    if ($list[3] -ne $null) {
        $menu.Items[2].add_Click({
                checked-false; $menu.Items[2].Checked = $true; $global:ip = $list[3]; change-ip; checked-interface
            })
    }

    if ($list[4] -ne $null) {
        $menu.Items[3].add_Click({
                checked-false; $menu.Items[3].Checked = $true; $global:ip = $list[4]; change-ip; checked-interface
            })
    }

    if ($list[5] -ne $null) {
        $menu.Items[4].add_Click({
                checked-false; $menu.Items[4].Checked = $true; $global:ip = $list[5]; change-ip; checked-interface
            })
    }

    if ($list[6] -ne $null) {
        $menu.Items[5].add_Click({
                checked-false; $menu.Items[5].Checked = $true; $global:ip = $list[6]; change-ip; checked-interface
            })
    }

    if ($list[7] -ne $null) {
        $menu.Items[6].add_Click({
                checked-false; $menu.Items[6].Checked = $true; $global:ip = $list[7]; change-ip; checked-interface
            })
    }

    if ($list[8] -ne $null) {
        $menu.Items[7].add_Click({
                checked-false; $menu.Items[7].Checked = $true; $global:ip = $list[8]; change-ip; checked-interface
            })
    }

    if ($list[9] -ne $null) {
        $menu.Items[8].add_Click({
                checked-false; $menu.Items[8].Checked = $true; $global:ip = $list[9]; change-ip; checked-interface
            })
    }

    if ($list[10] -ne $null) {
        $menu.Items[9].add_Click({
                checked-false; $menu.Items[9].Checked = $true; $global:ip = $list[10]; change-ip; checked-interface
            })
    }

    if ($list[11] -ne $null) {
        $menu.Items[10].add_Click({
                checked-false; $menu.Items[10].Checked = $true; $global:ip = $list[11]; change-ip; checked-interface
            })
    }

    if ($list[12] -ne $null) {
        $menu.Items[11].add_Click({
                checked-false; $menu.Items[11].Checked = $true; $global:ip = $list[12]; change-ip; checked-interface
            })
    }

    if ($list[13] -ne $null) {
        $menu.Items[12].add_Click({
                checked-false; $menu.Items[12].Checked = $true; $global:ip = $list[13]; change-ip; checked-interface
            })
    }

    if ($list[14] -ne $null) {
        $menu.Items[13].add_Click({
                checked-false; $menu.Items[13].Checked = $true; $global:ip = $list[14]; change-ip; checked-interface
            })
    }

    if ($list[15] -ne $null) {
        $menu.Items[14].add_Click({
                checked-false; $menu.Items[14].Checked = $true; $global:ip = $list[15]; change-ip; checked-interface
            })
    }
    #endregion

    $menu_change = $menu.Items.Add("Change")
    # $menu_change.Image = $ico_settings
    $menu_change.add_Click({
            ii $path
        })

    $menu_update = $menu.Items.Add("Update")
    # $menu_update.Image = $ico_refresh
    $menu_update.add_Click({
            dns-list
        })

    $fip_all = Get-NetIPConfiguration
    foreach ($f in $fip_all) {
        $fip = $f.IPv4Address.IPAddress
        $fin = $f.IPv4Address.InterfaceIndex
        $menu.Items.Add($fip)
    }

    # Инициализация номеров добавленных Items
    $num_all = $menu.AccessibilityObject.accChildCount # фиксируем общее кол-во Items
    $fip_count = ($fip_all.Count) - 1 # фиксируем кол-во добавленных Items Interface -1 (range посчитает +1)
    $num_start = ($num_all - $fip_count) - 1 # получаем начальный номер Items -1 (читаем переменные с 0)
    $num_end = ($num_all) - 1 # получаем конечный номер Items -1 (порядок сдвинулся на старте)
    $num_mass = $num_start..$num_end # создаем массив
    ###

    # Сопостовление номера Item и значения Index
    $Collections = New-Object System.Collections.Generic.List[System.Object]
    foreach ($num in $num_mass) {
        $ip_temp = $menu.Items[$num].Text # читаем текст переменной
        $index_temp = ($fip_all | where { $_.IPv4Address.IPAddress -like $ip_temp }).InterfaceIndex # инициализируем Index по IP
        $Collections.Add([PSCustomObject]@{Item = $num; Index = $index_temp })
    }
    ###

    #region add-click-ip
    if ($fip_all[0] -ne $null) {
        $item = $Collections[0].Item
        $menu.Items[$item].add_Click({
                $index = $Collections[0].Index
                $list[0] = $index
                $list > $path
                dns-list
            })
    }

    if ($fip_all[1] -ne $null) {
        $item = $Collections[1].Item
        $menu.Items[$item].add_Click({
                $index = $Collections[1].Index
                $list[0] = $index
                $list > $path
                dns-list
            })
    }

    if ($fip_all[2] -ne $null) {
        $item = $Collections[2].Item
        $menu.Items[$item].add_Click({
                $index = $Collections[2].Index
                $list[0] = $index
                $list > $path
                dns-list
            })
    }

    if ($fip_all[3] -ne $null) {
        $item = $Collections[3].Item
        $menu.Items[$item].add_Click({
                $index = $Collections[3].Index
                $list[0] = $index
                $list > $path
                dns-list
            })
    }

    if ($fip_all[4] -ne $null) {
        $item = $Collections[4].Item
        $menu.Items[$item].add_Click({
                $index = $Collections[4].Index
                $list[0] = $index
                $list > $path
                dns-list
            })
    }
    #endregion

    checked-interface

    $menu_exit = $menu.Items.Add("Exit")
    # $menu_exit.Image = $ico_stop
    $menu_exit.add_Click({
            $NotifyIcon.dispose()
            $App.ExitThread()
        })
}

#region functions
function checked-interface {
    foreach ($num in 0..30) {
        $interface_ip = (Get-NetIPConfiguration -InterfaceIndex $interface).IPv4Address | select -ExpandProperty IPAddress
        if ($menu.Items[$num].Text -eq $interface_ip) {
            $menu.Items[$num].Checked = $true
        }
    }
}

function checked-dns {
    $dns = (Get-NetIPConfiguration -InterfaceIndex $interface).DNSServer | select -ExpandProperty ServerAddresses
    foreach ($num in 0..14) {
        if ($menu.Items[$num].Text -eq $dns) {
            $menu.Items[$num].Checked = $true
        }
    }
}

function checked-false {
    foreach ($num in 0..14) {
        if (!!($menu.Items[$num])) {
            $menu.Items[$num].Checked = $false
        }
    }
}

function change-ip {
    Write-Host $ip
    Set-DNSClientServerAddress -InterfaceIndex $interface -ServerAddresses $ip
}
#endregion

#region main
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon

$MouseDoubleClick = [System.Windows.Forms.MouseEventHandler] {
    $idns = (Get-NetIPConfiguration -InterfaceIndex $interface).DNSServer | select -ExpandProperty ServerAddresses
    $iip = (Get-NetIPConfiguration -InterfaceIndex $interface).IPv4Address | select -ExpandProperty IPAddress
    $igw = (Get-NetIPConfiguration -InterfaceIndex $interface).IPv4DefaultGateway | select -ExpandProperty NextHop
    $NotifyIcon.BalloonTipTitle = "Interface configuration"
    $NotifyIcon.BalloonTipText = "IP: $iip
GW: $igw
DNS: $idns"
    $NotifyIcon.ShowBalloonTip($Duration)
}
$NotifyIcon.add_MouseDoubleClick($MouseDoubleClick)

# $NotifyIcon.Icon = $ico_main
$NotifyIcon.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$NotifyIcon.ContextMenuStrip = $menu
dns-list

$App = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($App)
#endregion