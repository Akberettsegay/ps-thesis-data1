#region decode image
#$decode_image = [System.Convert]::FromBase64String("")
#endregion

#region forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -assembly System.Drawing
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "ConvertTo-Base64"
$main_form.Font = "Arial,16"
$main_form.ShowIcon = $False
$main_form.StartPosition = "CenterScreen"
$main_form.FormBorderStyle = "FixedSingle"
$main_form.Icon = $icon
# $main_form.Width = 1050
$main_form.Width = 600
$main_form.Height = 800

$open_file = New-Object System.Windows.Forms.Button
$open_file.Text = "Select file"
$open_file.BringToFront() # передний фон
$open_file.Location = New-Object System.Drawing.Point(20, 20)
$open_file.Size = New-Object System.Drawing.Size(200, 40)
$open_file.BackColor = "black"
$open_file.ForeColor = "silver"
$open_file.FlatStyle = "Flat"
$main_form.Controls.Add($open_file)

$open_file.add_click({
        $Status.Text = "Select file"
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        $OpenFileDialog.InitialDirectory = ".\"
        $OpenFileDialog.Title = "Select file"
        $OpenFileDialog.ShowDialog()
        $global:path_save = $OpenFileDialog.FileNames
        $status.Text = "Selected file: $path_save"
    })

$Convert = New-Object System.Windows.Forms.Button
$Convert.Text = "Convert"
$Convert.Location = New-Object System.Drawing.Point(20, 70)
$Convert.Size = New-Object System.Drawing.Size(200, 40)
$Convert.BackColor = "black"
$Convert.ForeColor = "silver"
$Convert.FlatStyle = "Flat"
$main_form.Controls.Add($Convert)

$Convert.add_click({
        $Convert.Enabled = $false
        $convert_out = [System.Convert]::ToBase64String((Get-Content $path_save -Encoding Byte))
        $outputBox.Text = $convert_out
        Set-Clipboard $convert_out
        $status.Text = "Content copied to clipboard"
        $Convert.Enabled = $true
    })

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 120)
$outputBox.Size = New-Object System.Drawing.Size(540, 550)
$outputBox.BackColor = "black"
$outputBox.ForeColor = "silver"
$outputBox.MultiLine = $True
$main_form.Controls.Add($outputBox)

$VScrollBar = New-Object System.Windows.Forms.VScrollBar
$outputBox.Scrollbars = "Vertical"

$Convert_text = New-Object System.Windows.Forms.Button
$Convert_text.Text = "Convert text"
$Convert_text.Location = New-Object System.Drawing.Point(20, 680)
$Convert_text.Size = New-Object System.Drawing.Size(260, 40)
$Convert_text.BackColor = "black"
$Convert_text.ForeColor = "silver"
$Convert_text.FlatStyle = "Flat"
$main_form.Controls.Add($Convert_text)

$Convert_text.add_click({
        $text = $outputBox.Text
        $byte = [System.Text.Encoding]::Unicode.GetBytes($text)
        $base64 = [System.Convert]::ToBase64String($byte)
        $outputBox.Text = $base64
    })

$Convert_decode = New-Object System.Windows.Forms.Button
$Convert_decode.Text = "Decode text"
$Convert_decode.Location = New-Object System.Drawing.Point(300, 680)
$Convert_decode.Size = New-Object System.Drawing.Size(260, 40)
$Convert_decode.BackColor = "black"
$Convert_decode.ForeColor = "silver"
$Convert_decode.FlatStyle = "Flat"
$main_form.Controls.Add($Convert_decode)

$Convert_decode.add_click({
        $text = $outputBox.Text
        $decode_base64 = [System.Convert]::FromBase64String($text)
        $decode_string = [System.Text.Encoding]::Unicode.GetString($decode_base64)
        $outputBox.Text = $decode_string
    })

$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$Status = New-Object System.Windows.Forms.ToolStripStatusLabel
$main_form.Controls.Add($statusStrip)
$StatusStrip.Items.Add($Status)
$Status.Text = "(c) Lifailon"

$PictureBox = New-Object System.Windows.Forms.PictureBox
# $PictureBox.Image = $decode_image # Присвоить фоновое изображение в формате Base64
$PictureBox.SendToBack() # задний фон
$PictureBox.BackColor = "Black"
$PictureBox.Location = "0,0"
$PictureBox.Size = "1200,800"
$PictureBox.SizeMode = "StretchImage"
$main_form.Controls.Add($PictureBox)

$main_form.ShowDialog()
#endregion