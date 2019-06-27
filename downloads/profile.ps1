Set-Variable HOME "$env:USERPROFILE" -Scope Global -Force
(Get-PSProvider 'FileSystem').Home = $HOME   # replace "~"

. ~\Projects\kluster\.psprofile.ps1