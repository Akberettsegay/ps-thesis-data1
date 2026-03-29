#region file function
function OpenFile {
    $Status.Text = "Выберите файл"
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "All Files (*.*)|*.*"
    $OpenFileDialog.InitialDirectory = ".\"
    $OpenFileDialog.Title = "Выберите файл"
    $OpenFileDialog.ShowDialog() # открыть файл
    $path_save = $OpenFileDialog.FileNames # забрать путь к файлу
    $Status.Text = "Выбран файл: $path_save"
}

function SaveFile {
    $Status.Text = "Сохранение файла"
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Filter = "All Files (*.txt)|*.txt"
    $SaveFileDialog.FileName = "test" # предустановленное имя файла
    $SaveFileDialog.InitialDirectory = "$env:USERPROFILE\desktop\"
    $SaveFileDialog.Title = "Выберите файл"
    $SaveFileDialog.ShowDialog()
    $path_out = $SaveFileDialog.FileNames # забрать путь к файлу
    $Status.Text = "Файл сохранен: $path_out"
}
#endregion

#region favicon.cc
Add-Type -assembly System.Drawing # добавить сборку для подключения иконок

$bmp = New-Object System.Drawing.Bitmap(16, 16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.drawline([System.Drawing.Pens]::Black, 0, 0, 15, 0)
$g.drawline([System.Drawing.Pens]::Black, 15, 0, 15, 4)
$g.drawline([System.Drawing.Pens]::Black, 15, 4, 10, 4)
$g.drawline([System.Drawing.Pens]::Black, 10, 4, 10, 15)
$g.drawline([System.Drawing.Pens]::Black, 10, 15, 6, 15)
$g.drawline([System.Drawing.Pens]::Black, 6, 15, 6, 4)
$g.drawline([System.Drawing.Pens]::Black, 6, 4, 0, 4)
$g.drawline([System.Drawing.Pens]::Black, 0, 4, 0, 0)
$g.drawline([System.Drawing.Pens]::Blue, 1, 1, 14, 1)
$g.drawline([System.Drawing.Pens]::Blue, 1, 2, 14, 2)
$g.drawline([System.Drawing.Pens]::Blue, 1, 3, 14, 3)
$g.drawline([System.Drawing.Pens]::Blue, 7, 4, 7, 14)
$g.drawline([System.Drawing.Pens]::Blue, 8, 4, 8, 14)
$g.drawline([System.Drawing.Pens]::Blue, 9, 4, 9, 14)
$ico = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
#endregion

#region main_form
Add-Type -assembly System.Windows.Forms # подключить сборку формы .NET

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "WinForms Test Stend"
$main_form.Width = 1120 # ширина
$main_form.Height = 710 # высота
$main_form.AutoSize = $false

$main_form.StartPosition = "CenterScreen" # стартовая позиция расположения формы при открытии
#$main_form.ShowIcon = $False # скрыть иконку
#$main_form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Users\lifailon\desktop\favicon.cc.ico')
$main_form.Icon = $ico # назначить favicon для формы
$main_form.FormBorderStyle = "FixedSingle" # запретить растягивать

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Label"
$Label.Location = New-Object System.Drawing.Point(10, 30)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)

$CheckBox = New-Object System.Windows.Forms.CheckBox
$CheckBox.Text = "CheckBox"
$CheckBox.AutoSize = $true
$CheckBox.Checked = $true
$CheckBox.Location = New-Object System.Drawing.Point(10, 50)
$main_form.Controls.Add($CheckBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "КНОПКА"
$button.Location = New-Object System.Drawing.Point(160, 35)
$button.FlatAppearance.BorderSize = 0
$button.FlatStyle = "Flat"
#$button.BackColor = "Tansparent"
#Checked Back Color = "Transparent"
#Mouse Down Back Color = "Transparent"
#Mouse Over Back Color = "Transparent"
$main_form.Controls.Add($button)

$RadioButton = New-Object System.Windows.Forms.RadioButton
$RadioButton.Location = New-Object System.Drawing.Point(160, 65)
$RadioButton.Text = "RadioButton-1"
$RadioButton.AutoSize = $true
$main_form.Controls.Add($RadioButton)

$RadioButton_2 = New-Object System.Windows.Forms.RadioButton
$RadioButton_2.Location = New-Object System.Drawing.Point(260, 65)
$RadioButton_2.Text = "RadioButton-2"
$RadioButton_2.AutoSize = $true
$RadioButton_2.Checked = $true
$main_form.Controls.Add($RadioButton_2)

$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.DataSource = @("ComboBox1", "ComboBox2", "ComboBox3")
$ComboBox.Location = New-Object System.Drawing.Point(10, 70)
$main_form.Controls.Add($ComboBox)

$CheckedListBox = New-Object System.Windows.Forms.CheckedListBox
$CheckedListBox.Items.ADD("CheckedListBox")
$CheckedListBox.Items.ADD("Items 2")
$CheckedListBox.Items.ADD("3")
$CheckedListBox.Location = New-Object System.Drawing.Point(10, 100)
$main_form.Controls.Add($CheckedListBox)

$GroupBox = New-Object System.Windows.Forms.GroupBox
$GroupBox.Text = "GroupBox"
$GroupBox.AutoSize = $true
$GroupBox.Location = New-Object System.Drawing.Point(160, 95)
$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "Кнопка 2"
$button2.Location = New-Object System.Drawing.Point(0, 30)
$GroupBox.Controls.Add($button2) # добавить на GroupBox
$CheckBox2 = New-Object System.Windows.Forms.CheckBox
$CheckBox2.Text = "CheckBox2"
$CheckBox2.AutoSize = $true
$CheckBox2.Checked = $true
$CheckBox2.Location = New-Object System.Drawing.Point(10, 60)
$GroupBox.Controls.Add($CheckBox2)
$main_form.Controls.Add($GroupBox) # добавить GroupBox на форму

$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(10, 210)
$ListBox.Items.Add('ListBox');
$ListBox.Items.Add('2');
$ListBox.Items.Add('3');
$main_form.Controls.add($ListBox)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(160, 210)
$TabPage1 = New-Object System.Windows.Forms.TabPage
$TabPage1.Text = 'TabPage1'
$TabControl.Controls.Add($TabPage1)

# Добавить Label на TabPage1
$TabLabel = New-Object System.Windows.Forms.Label
$TabLabel.Text = "TabControl"
$TabLabel.Location = New-Object System.Drawing.Point(60, 30)
$TabLabel.AutoSize = $true
$TabPage1.Controls.Add($TabLabel)

$TabPage2 = New-Object System.Windows.Forms.TabPage
$TabPage2.Text = 'TabPage2'
$TabControl.Controls.Add($TabPage2)

$main_form.Controls.add($TabControl)

$ListView = New-Object System.Windows.Forms.ListView
$ListViewItem1 = New-Object System.Windows.Forms.ListViewItem("--=1=--")
$ListViewItem2 = New-Object System.Windows.Forms.ListViewItem("--=2=--")
$ListViewItem3 = New-Object System.Windows.Forms.ListViewItem("--=3=--")
$ListViewItem4 = New-Object System.Windows.Forms.ListViewItem("--=4=--")
$ListView.Items.Add($ListViewItem1)
$ListView.Items.Add($ListViewItem2)
$ListView.Items.Add($ListViewItem3)
$ListView.Items.Add($ListViewItem4)
$ListView.Location = New-Object System.Drawing.Point(10, 320)
$main_form.Controls.add($ListView)

$TreeView = New-Object System.Windows.Forms.TreeView
$TreeViewNode = $TreeView.Nodes.Add("1")
$TreeViewNode.Nodes.Add("2")
$TreeView.Nodes.Add("3")
$TreeView.Location = New-Object System.Drawing.Point(160, 320)
$main_form.Controls.add($TreeView)

$DateTimePicker = New-Object System.Windows.Forms.DateTimePicker
$DateTimePicker.Location = New-Object System.Drawing.Point(10, 430)
$main_form.Controls.add($DateTimePicker)

$TrackBar = New-Object System.Windows.Forms.TrackBar
$TrackBar.Location = New-Object System.Drawing.Point(230, 430)
$TrackBar.Autosize = $true
$TrackBar.Value = 5
$main_form.Controls.add($TrackBar)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(10, 460)
$ProgressBar.Size = New-Object System.Drawing.Size(200, 24)
$ProgressBar.Value = 0
$main_form.Controls.add($ProgressBar)

# Скролл по горизонтали
$HScrollBar = New-Object System.Windows.Forms.HScrollBar
$HScrollBar.Size = New-Object System.Drawing.Size(170, 30)
$HScrollBar.Location = New-Object System.Drawing.Point(10, 490)
$main_form.Controls.add($HScrollBar)

# Скролл по вертикали
$VScrollBar = New-Object System.Windows.Forms.VScrollBar
$VScrollBar.Size = New-Object System.Drawing.Size(16, 176)
$VScrollBar.Location = New-Object System.Drawing.Point(380, 25)
$main_form.Controls.add($VScrollBar)

# ПКМ (Right Click Mouse)
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$ContextMenu.MenuItems.Add(
    "Copy", {
        $dgv_selected = @($DataGridView.SelectedCells.Value) # создать массив
        Set-Clipboard $dgv_selected # скопировать в буфер содержимое массива
    })
$main_form.ContextMenu = $ContextMenu
#endregion

#region binary data
$Formatter_binaryFomatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
$System_IO_MemoryStream = New-Object System.IO.MemoryStream (, [byte[]][System.Convert]::FromBase64String('
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
4P8B2nibrmILiXkAAAAASUVORK5CYIIL'))
#endregion

#region menu
# Создать меню
$Menu = New-Object System.Windows.Forms.MenuStrip
$Menu.BackColor = "white"
$main_form.MainMenuStrip = $Menu
$main_form.Controls.Add($Menu)

# Добавить вкладку
$menuItem_file = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file.Text = "File"
$menuItem_file.Image = $Formatter_binaryFomatter.Deserialize($System_IO_MemoryStream)
$Menu.Items.Add($menuItem_file)

# Добавить кнопки
$menuItem_file_open = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file_open.Text = "Открыть"
$menuItem_file_open.Add_Click({ OpenFile })
$menuItem_file.DropDownItems.Add($menuItem_file_open)

$menuItem_file_save = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file_save.Text = "Сохранить"
$menuItem_file_save.Add_Click({ SaveFile })
$menuItem_file.DropDownItems.Add($menuItem_file_save)

$menuItem_file_font = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file_font.Text = "Шрифт"
$menuItem_file_font.Add_Click({
        $FontDialog = New-Object System.Windows.Forms.FontDialog
        $FontDialog.ShowDialog()
        $font = $fontDialog.Font.Name
        $Status.Text = "Выбран шрифт: $font"
    })
$menuItem_file.DropDownItems.Add($menuItem_file_font)

$menuItem_file_exit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file_exit.Text = "Выход"
$menuItem_file_exit.Add_Click({ $main_form.Close() })
$menuItem_file.DropDownItems.Add($menuItem_file_exit)
#endregion

#region Associated Icon
$iconNP = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command notepad).Path) # создать иконку ассоциации

# Добавить вкладку
$menuItem_file = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem_file.Text = "Help"
$menuItem_file.Image = $iconNP
$Menu.Items.Add($menuItem_file)
#endregion

#region C# Dll Import
$dll_import = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
namespace System
{
public class IconExtractor
{
public static Icon Extract(string file, int number, bool largeIcon)
{
IntPtr large;
IntPtr small;
ExtractIconEx(file, number, out large, out small, 1);
try
{
return Icon.FromHandle(largeIcon ? large : small);
}
catch
{
return null;
}
}
[DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
}
}
"@
Add-Type -TypeDefinition $dll_import -ReferencedAssemblies System.Drawing
#endregion

#region menu-2
$mainToolStrip = New-Object System.Windows.Forms.ToolStrip
$mainToolStrip.Location = New-Object System.Drawing.Point(615, 25)
$mainToolStrip.ImageScalingSize = New-Object System.Drawing.Size(26, 32) # размер изображения
$mainToolStrip.Size = New-Object System.Drawing.Size(300, 32) # размер формы (для изображения меняется высота)
$mainToolStrip.AutoSize = $false
$mainToolStrip.Anchor = "Bottom" # None, Top, Bottom, Left, Right
$main_form.Controls.Add($mainToolStrip)

$toolStripOpen = New-Object System.Windows.Forms.ToolStripButton
$toolStripOpen.ToolTipText = "Open"
$toolStripOpen.Image = [System.IconExtractor]::Extract("shell32.dll", 22, $true) # 4-е изображение из 48
$toolStripOpen.Add_Click({ OpenFile })
$mainToolStrip.Items.Add($toolStripOpen)

$toolStripTextBox = New-Object System.Windows.Forms.ToolStripTextBox # ToolStripComboBox
$toolStripTextBox.Size = New-Object System.Drawing.Size(80)
$mainToolStrip.Items.Add($toolStripTextBox)
#endregion

#region status
$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$Status = New-Object System.Windows.Forms.ToolStripStatusLabel
$main_form.Controls.Add($statusStrip)
$StatusStrip.Items.Add($Status)
$Status.Text = "Статус"
#endregion

#region new
# UpDown
$NumericUpDown = New-Object System.Windows.Forms.NumericUpDown
$NumericUpDown.Location = New-Object System.Drawing.Point(420, 30)
$NumericUpDown.text = 1
$main_form.Controls.add($NumericUpDown)

$DomainUpDown = New-Object System.Windows.Forms.DomainUpDown
$DomainUpDown.Location = New-Object System.Drawing.Point(420, 55)
$DomainUpDown.Items.add("text")
$main_form.Controls.add($DomainUpDown)

$Calendar = New-Object System.Windows.Forms.MonthCalendar
$Calendar.Location = New-Object System.Drawing.Point(420, 80)
$main_form.Controls.add($Calendar)

$button.add_Click({
        if ($RadioButton.Checked -eq $true) { $Status.Text = "Выбран RadioButton-1" }
        if ($RadioButton.Checked -eq $true) { $ProgressBar.Value = 10 }
        if ($RadioButton_2.Checked -eq $true) { $Status.Text = "Выбран RadioButton-2" }
        if ($RadioButton_2.Checked -eq $true) { $ProgressBar.Value = 30 }
    })

$button2.add_Click({
        $Status.Text = "Нажата кнопка 2"
        $ProgressBar.Value = 100
    })

# Картинка на форме
$PictureBox = New-Object System.Windows.Forms.PictureBox
#$PictureBox.Load('D:\favico.jpg')
$PictureBox.Image = $iconNP.ToBitmap()
$PictureBox.Location = "550, 480"
$PictureBox.Size = "32, 32"
$PictureBox.SizeMode = "StretchImage"
$main_form.Controls.Add($PictureBox)

$iconFolder = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command explorer).Path)

$panel = New-Object System.Windows.Forms.Panel # создать панель, используется для группировки
$panel.Location = New-Object System.Drawing.Point(420, 260) # удобно перемещать панель со всеми элементами внутри
$panel.BackgroundImage = $iconFolder # фоновое изображение на форме панели
$panel.BackgroundImageLayout = "zoom" # подогнать под размер формы с сохранение пропорций (none, stretch - растянуть)
$main_form.Controls.Add($panel)

# Динамическое добавление элемента
$button3 = New-Object System.Windows.Forms.Button
$button3.ForeColor = "Green"
$button3.Text = "Add +"
$button3.Location = New-Object System.Drawing.Point(5, 5) # расположение на панели
$panel.Controls.Add($button3) # добавить на панель

$button3.add_Click({
        $global:button_temp = New-Object System.Windows.Forms.Button # добавить в виде глобальной переменной
        $button_temp.Text = "Temp"
        $button_temp.Location = New-Object System.Drawing.Point(5, 65)
        $panel.Controls.Add($button_temp)
    })

$button4 = New-Object System.Windows.Forms.Button
$button4.ForeColor = "Red"
$button4.Text = "Remove -"
$button4.Location = New-Object System.Drawing.Point(5, 35)
$panel.Controls.Add($button4)

$button4.add_Click({
        $panel.Controls.Remove($button_temp) # удаление кнопки
    })

$LinkLabel = New-Object System.Windows.Forms.LinkLabel # создать текст ссылки
$LinkLabel.Text = "Ссылка"
$LinkLabel.LinkColor = "green"
$LinkLabel.ActiveLinkColor = "red"
$LinkLabel.LinkBehavior = "HoverUnderline" # подчеркивается при наведении
$LinkLabel.Location = New-Object System.Drawing.Point(420, 370)
$LinkLabel.add_LinkClicked({ # событие нажатия
        Start-Process ("https://metanit.com/sharp/windowsforms/4.2.php")
    })
$main_form.Controls.Add($LinkLabel)

$auto_text = @("Text", "TextBox")

# Пароль
$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Multiline = $true # перенос по строкам, нужно применять для раскрытия пароля
$TextBox.WordWrap = $true
$TextBox.PasswordChar = "*"
$TextBox.Location = New-Object System.Drawing.Point(420, 400)
$main_form.Controls.Add($TextBox)

$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider # добавить статус ошибки

$button5 = New-Object System.Windows.Forms.Button
$button5.Text = "Раскрыть"
$button5.Location = New-Object System.Drawing.Point(420, 430)
$main_form.Controls.Add($button5)

$button5.add_Click({
        $TextBox.UseSystemPasswordChar = $true
        $ErrorProvider.SetError($button5, "Пароль раскрыт") # ошибка
    })

# Текст с масками
$TextBox2 = New-Object System.Windows.Forms.MaskedTextBox
$TextBox2.Mask = "8(" + "000" + ")" + "-" + "000" + "-" + "0000"
# 9 - позволяет вводить цифры и пробелы
# # - позволяет вводить цифры, пробелы и знаки '+' и '-'
# L - позволяет вводить только буквенные символы
# A - позволяет вводить буквенные и цифровые символы
$TextBox2.Location = New-Object System.Drawing.Point(420, 460)
$main_form.Controls.Add($TextBox2)

$CheckBox3 = New-Object System.Windows.Forms.CheckBox
$CheckBox3.Text = "CheckBox3"
$CheckBox3.AutoSize = $true
$CheckBox3.Checked = $true
$CheckBox3.CheckState = "Indeterminate" # флажок не определен - отмечен, но находится в неактивном состоянии
$CheckBox3.AutoCheck = $false # невозможно снять или активировать галочку (можно отключать когда функции будут недоступны)
# при изменении состояния флажка он генерирует событие CheckedChanged
$CheckBox3.Location = New-Object System.Drawing.Point(420, 490)
$main_form.Controls.Add($CheckBox3)

# Разделитель (горизонтальная линия)
$outputBox1 = New-Object System.Windows.Forms.TextBox
$outputBox1.Location = New-Object System.Drawing.Point(0, 530)
$outputBox1.Size = New-Object System.Drawing.Size(600, 1)
$outputBox1.BackColor = "Black"
$outputBox1.MultiLine = $True
$main_form.Controls.Add($outputBox1)
#endregion

#region password
Add-Type -AssemblyName System.Web

$button_gen = New-Object System.Windows.Forms.Button
$button_gen.Text = "Сгенерировать пароль"
$button_gen.BackColor = "orange"
$button_gen.Location = New-Object System.Drawing.Point(20, 540)
$button_gen.Size = New-Object System.Drawing.Size(150, 40)
$main_form.Controls.Add($button_gen)

$button_gen.add_Click({
        $pass = [System.Web.Security.Membership]::GeneratePassword(10, 2)
        $outputBox2.Text = $pass
    })

$outputBox2 = New-Object System.Windows.Forms.TextBox
$outputBox2.Location = New-Object System.Drawing.Point(21, 585)
$outputBox2.Size = New-Object System.Drawing.Size(150, 30)
$outputBox2.Font = "Arial,14"
$outputBox2.MultiLine = $True
$main_form.Controls.Add($outputBox2)
#endregion

#region translit
function translit {
    param([string]$inString) # параметр принимает только текст
    $Translit = @{ # создать массив
        [char]'а' = "a"
        [char]'А' = "A"
        [char]'б' = "b"
        [char]'Б' = "B"
        [char]'в' = "v"
        [char]'В' = "V"
        [char]'г' = "g"
        [char]'Г' = "G"
        [char]'д' = "d"
        [char]'Д' = "D"
        [char]'е' = "e"
        [char]'Е' = "E"
        [char]'ё' = "yo"
        [char]'Ё' = "Yo"
        [char]'ж' = "zh"
        [char]'Ж' = "Zh"
        [char]'з' = "z"
        [char]'З' = "Z"
        [char]'и' = "i"
        [char]'И' = "I"
        [char]'й' = "j"
        [char]'Й' = "J"
        [char]'к' = "k"
        [char]'К' = "K"
        [char]'л' = "l"
        [char]'Л' = "L"
        [char]'м' = "m"
        [char]'М' = "M"
        [char]'н' = "n"
        [char]'Н' = "N"
        [char]'о' = "o"
        [char]'О' = "O"
        [char]'п' = "p"
        [char]'П' = "P"
        [char]'р' = "r"
        [char]'Р' = "R"
        [char]'с' = "s"
        [char]'С' = "S"
        [char]'т' = "t"
        [char]'Т' = "T"
        [char]'у' = "u"
        [char]'У' = "U"
        [char]'ф' = "f"
        [char]'Ф' = "F"
        [char]'х' = "h"
        [char]'Х' = "H"
        [char]'ц' = "c"
        [char]'Ц' = "C"
        [char]'ч' = "ch"
        [char]'Ч' = "Ch"
        [char]'ш' = "sh"
        [char]'Ш' = "Sh"
        [char]'щ' = "sch"
        [char]'Щ' = "Sch"
        [char]'ъ' = ""
        [char]'Ъ' = ""
        [char]'ы' = "y"
        [char]'Ы' = "Y"
        [char]'ь' = ""
        [char]'Ь' = ""
        [char]'э' = "e"
        [char]'Э' = "E"
        [char]'ю' = "yu"
        [char]'Ю' = "Yu"
        [char]'я' = "ya"
        [char]'Я' = "Ya"
    }
    $outCHR = "" # создать пустую переменную типа String (строка), не массив!
    foreach ($CHR in $inCHR = $inString.ToCharArray()) { # передать в цикл переменную и разбить на массив из букв
        if ($Translit[$CHR] -cne $Null ) # если буква с учетом ригистра присутствует в массиве $Translit
        { $outCHR += $Translit[$CHR] } # заменить на переменную из массива $Translit и добавить букву в переменную вывода
        else
        { $outCHR += $CHR } # если буква отсутствует в массиве $Translit, добавить минуя массив преобразования
    }
    $global:translit_out = $outCHR
}

$outputBox3 = New-Object System.Windows.Forms.TextBox
$outputBox3.Location = New-Object System.Drawing.Point(280, 545)
$outputBox3.Size = New-Object System.Drawing.Size(220, 30)
$outputBox3.Font = "Arial,14"
$outputBox3.MultiLine = $True
$main_form.Controls.Add($outputBox3)

$button_trans = New-Object System.Windows.Forms.Button
$button_trans.Text = "        Транслит"
$button_trans.Image = $iconNP # наложить иконку
$button_trans.ImageAlign = "MiddleLeft" # расположение изображения слева
$button_trans.Font = "Arial,12"
$button_trans.Location = New-Object System.Drawing.Point(330, 580)
$button_trans.Size = New-Object System.Drawing.Size(120, 40)
$main_form.Controls.Add($button_trans)

$button_trans.add_Click({
        $name = $outputBox3.text # зрабрать имя
        translit $name # выполнить функцию с подстановкой параметра имени
        $translit_name = $translit_out
        $outputBox3.text = $translit_name # перезаписать текст формы ввода на вывод
    })
#endregion

#region DGV-ping
$DataGridView = New-Object System.Windows.Forms.DataGridView
$DataGridView.Location = New-Object System.Drawing.Point(620, 115)
$DataGridView.Size = New-Object System.Drawing.Size(400, 200)
$DataGridView.AutoSizeColumnsMode = "Fill" # ширина столбцов подбирается таким образом, чтобы суммарная ширина всех столбцов в точности заполняла отображаемую область элемента управления, а прокрутка по горизонтали требовалась только для того, чтобы не допускать уменьшения ширины столбцов ниже значений свойства MinimumWidth. Относительная ширина столбцов определяется относительными значениями свойства FillWeight.
# AllCells # Ширина столбцов изменяется так, чтобы вместить содержимое всех ячеек столбцов, включая ячейки заголовков.
# AllCellsExceptHeader # Ширина столбцов изменяется так, чтобы вместить содержимое всех ячеек столбцов, исключая ячейки заголовков.
# ColumnHeader # Ширина столбцов изменяется так, чтобы вместить содержимое ячеек заголовков столбцов.
# DisplayedCells # Ширина столбцов изменяется так, чтобы вместить содержимое всех ячеек столбцов, которые находятся в строках, отображающихся на экране в настоящий момент, включая ячейки заголовков.
# DisplayedCellsExceptHeader # Ширина столбцов изменяется так, чтобы вместить содержимое всех ячеек столбцов, которые находятся в строках, отображающихся на экране в настоящий момент, исключая ячейки заголовков.
$DataGridView.AutoSize = $false
$DataGridView.MultiSelect = $true # разрешить выбор нескольких ячеек
$DataGridView.ReadOnly = $true # запретить редактирование
$DataGridView.TabIndex = 0
$main_form.Controls.Add($DataGridView)

#####
# DataGridView.ForeColor # цвет шрифта ячеек таблицы
# DataGridView.GridColor # цвет линий таблицы
# DataGridView.DefaultCellStyle # цвет и другие настройки вида ячеек таблицы. Настройки стилей строк, столбцов и ячеек переопределяют данное свойство.
# DataGridView.RowsDefaultCellStyle # цвет строк, переопределяет значения DataGridView.DefaultCellStyle.
# DataGridView.AlternatingRowsDefaultCellStyle # цвет нечетных строк таблицы. Переопределяет все стили, кроме DataGridViewRow.DefaultCellStyle и DataGridViewCell.Style
# DataGridViewColumn.DefaultCellStyle # цвет ячеек столбца. Переопределяется всеми стилями, кроме DataGridView.DefaultCellStyle.
# DataGridViewRow.DefaultCellStyle # цвет строки, хранит свои настройки независимо от родительского DataGridView. Переопределяет все стили, кроме DataGridViewCell.Style
# DataGridViewCell.Style # цвет ячейки, переопределяет все стили.
# DataGridView.ColumnHeadersDefaultCellStyle # цвет заголовков столбцов, при DataGridView.EnableHeadersVisualStyles = false.
# DataGridView.RowHeadersDefaultCellStyle # цвет заголовков строк, при DataGridView.EnableHeadersVisualStyles = false.
# AutoSizeMode - подгонка ширины столбца по его содержимому;
# ColumnType # определяет внешний вид ячеек столбца (какой объект для отображения информации находится в ячейках столбца);
# DataPropertyName # имя, отображающего в столбце поля;
# Frozen # фиксация столбца (столбец не передвигается при прокручивании таблицы);
# HeaderText # текст заголовка столбца;
# Width # ширина поля;
# MaxInputLength # максимально вводимая длина текста;
# MinimumWidth # минимальная ширина столбца;
# ReadOnly # блокировка столбца для редактирования данных;
# Resizable # разрешает менять ширину столбца;
# SortMode # сортировка данных в таблице по этому столбцу;
# ToolTipText # всплывающая подсказка для столбца;
# Visible # делает столбец невидимым.

# Сортировка:
# DataGridView.Sort(<Имя столбца>, <Порядок сортировки>) # где DataGridView - это имя объекта, <Имя столбца> - это имя столбца (свойство Name ) по которому происходит сортировка записей в таблице, параметр <Порядок сортировки> определяет порядок сортировки и может принимать два значения:
# System.ComponentModel.ListSortDirection.Ascending # сортировка по возрастанию;
# System.ComponentModel.ListSortDirection.Descending # сортировка по убыванию.
#####

$button_add = New-Object System.Windows.Forms.Button
$button_add.Text = "Ping"
$button_add.Location = New-Object System.Drawing.Point(620, 80)
$main_form.Controls.Add($button_add)

$button_add.Add_Click({
        $button_add.Enabled = $false

        ### DataGridViewCheckBoxColumn
        $CheckBoxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
        $CheckBoxColumn.Name = "CheckBox"
        $DataGridView.ReadOnly = $false # разрешить редактирование, что бы можно было отмечать CheckBox
        ###

        $DataGridView.DataSource = $null # очистить источник из кнопки 2
        $DataGridView.ColumnCount = 2 # создать кол-во столбцов
        $DataGridView.Columns[0].Name = "Name" # добавить 1-й столбец и дать ему имя
        $DataGridView.Columns[1].Name = "Status" # 2-й

        $DataGridView.Columns.Add($CheckBoxColumn) # добавить стобец с CheckBoxColumn

        $list_srv = @("google.com", "github.com", "cloud.delprof.ru", "pbx.delprof.ru", "vks.delprof.ru")

        $ping_out = foreach ($srv in $list_srv) {
            $status_ping = ping -n 1 -w 50 $srv
            if ($status_ping -match "ttl") {
                $DataGridView.Rows.Add("$srv", "Available") # заполнить строки (Rows) значениями через запятую в 1-й и 2-й столбец
            }
            else {
                $DataGridView.Rows.Add("$srv", "Not available")
            }
        }

        ### Красим:
        $DataGridView.Rows | ForEach-Object {
            if ($_.Cells["Status"].Value -eq "Available") {
                # если в клетке столбца Status значение (Value) = Available
                $_.Cells[1] | % { $_.Style.BackColor = "lightgreen" } # то покрасить 2-ю клетку
            }
            elseif ($_.Cells["Status"].Value -eq "Not available") {
                $_.Cells[1] | % { $_.Style.BackColor = "pink" }
            } }

        $button_add.Enabled = $true
    })
#endregion

#region DGV-proc
$button_add_2 = New-Object System.Windows.Forms.Button
$button_add_2.Text = "Process"
$button_add_2.Location = New-Object System.Drawing.Point(700, 80)
$main_form.Controls.Add($button_add_2)

$button_add_2.Add_Click({
        $DataGridView.ColumnCount = $null # удалить стобцы из кнопки 1
        $global:services = Get-Service | select name, status # создать массив
        $list = New-Object System.collections.ArrayList # объект листа
        $list.AddRange($services) # заполнить объект
        $DataGridView.DataSource = $list # указать источник для таблицы
    })
#endregion

#region Watermark
$watermark = "Server name"

$TextBox_Enter = {
    if ($TextBox_W.Text -like $watermark) {
        $TextBox_W.Text = ""
        $TextBox_W.ForeColor = [System.Drawing.SystemColors]::WindowText
    } }

$TextBox_Leave = {
    if ($TextBox_W.Text -like "") {
        $TextBox_W.Text = $watermark
        $TextBox_W.ForeColor = [System.Drawing.Color]::LightGray
    } }

$TextBox_W = New-Object System.Windows.Forms.TextBox
$TextBox_W.Location = New-Object System.Drawing.Point(780, 80)
$TextBox_W.Size = New-Object System.Drawing.Size(200, 30)
$TextBox_W.ForeColor = [System.Drawing.Color]::LightGray 
$TextBox_W.add_Enter($TextBox_Enter)
$TextBox_W.add_Leave($TextBox_Leave)
$TextBox_W.Text = $watermark
$main_form.Controls.Add($TextBox_W)
#endregion

#region Search
$TextBox_W.Add_TextChanged({
        $search_text = $TextBox_W.Text
        $search_services = @($services | Where { # создать массив, т.к. если найдено 1 значение, то его тип данных PSCustomObject вместо Object[] Array - массив
                $_.Name -match "$search_text" # для быстрой фильтрации (поиска), используется уже полученный массив
            })
        $list = New-Object System.collections.ArrayList
        $list.AddRange($search_services)
        $DataGridView.DataSource = $list
    })
#endregion

#region MouseDoubleClick
$ListBox_left = New-Object System.Windows.Forms.ListBox
$ListBox_left.Location = New-Object System.Drawing.Point(620, 330)
$ListBox_left.Size = New-Object System.Drawing.Size(190, 200)
$main_form.Controls.add($ListBox_left)

$ListBox_right = New-Object System.Windows.Forms.ListBox
$ListBox_right.Location = New-Object System.Drawing.Point(830, 330)
$ListBox_right.Size = New-Object System.Drawing.Size(190, 200)
$main_form.Controls.add($ListBox_right)

$form_Load = {
    $items = 1..10 | % { "Item $_" }
    $ListBox_left.Items.AddRange($items)
}

$ListBox_left_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler] {
    $ListBox_right.Items.Add($ListBox_left.SelectedItem)
    $ListBox_left.Items.Remove($ListBox_left.SelectedItem)
}

$ListBox_right_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler] {
    $ListBox_left.Items.Add($ListBox_right.SelectedItem)
    $ListBox_right.Items.Remove($ListBox_right.SelectedItem)
}

$ListBox_left.add_MouseDoubleClick($ListBox_left_MouseDoubleClick)
$ListBox_right.add_MouseDoubleClick($ListBox_right_MouseDoubleClick)

$main_form.add_Load($form_Load)
#endregion

#region PropertyGrid
$propertygrid = New-Object System.Windows.Forms.PropertyGrid
$propertygrid.Location = New-Object System.Drawing.Point(620, 540)
$propertygrid.Size = New-Object System.Drawing.Size(200, 100)
$propertygrid.Name = "PropertyGrid"
$propertygrid.TabIndex = 6
$main_form.Controls.Add($propertygrid)
#endregion

#region Beep
$Button_Beep = New-Object System.Windows.Forms.Button
$Button_Beep.Location = New-Object System.Drawing.Point(830, 540)
$Button_Beep.Text = "Beep"
$Button_Beep.AutoSize = $true
$main_form.Controls.Add($Button_Beep)

$Button_Beep.Add_Click({
        [console]::beep(440, 500)
        [console]::beep(440, 500)
        [console]::beep(440, 500)
        [console]::beep(349, 350)
        [console]::beep(523, 150)
        [console]::beep(440, 500)
        [console]::beep(349, 350)
        [console]::beep(523, 150)
        [console]::beep(440, 1000)
    })
#endregion

$main_form.ShowDialog()