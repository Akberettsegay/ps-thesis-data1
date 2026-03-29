function Decode-UnattendedPassword {
    param(
        [Parameter(Mandatory=$true)]
        $Path
    )
    
    $data = [io.file]::ReadAllText($Path)
    $regex = '(?smi)<AdministratorPassword>[\r\n\s]+<Value>([a-zA-Z0-9/\+=\-]+)</Value>'
    $val = $data | Select-String -Pattern $regex -AllMatches |
    %{ $_.Matches } | %{$_.Groups[1]} | %{
        $o = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($_.Value))
        $f = 'AdministratorPassword'
        Write-Host $($o.Substring(0, $o.Length-$f.Length))
    }
}