#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#

Write-Host ""
Write-Host -NoNewLine 'Press any key to continue . . . '
$HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
Write-Host ""

exit 0