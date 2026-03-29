$Configuration=New-PesterConfiguration

#$Configuration.filter.Tag=('')

$Configuration.Output.Verbosity=('Detailed')

Invoke-Pester -Configuration $Configuration