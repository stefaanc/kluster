#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/psconsole
#
# use:
#
#     Set-PSConsoleWindowSize "$Path" -Width 120 -Height 50 -ScreenBufferHeight 8000
#
param(
    [Parameter(Mandatory=$true, Position=0)][string]$Path,
    [Parameter(Position=1)][Alias("Width")][int]$X = 120,
    [Parameter(Position=2)][Alias("Height")][int]$Y = 50,
    [Parameter(Position=3)][Alias("ScreenBufferHeight")][int]$ScreenBufferY = 8000
)

$ErrorActionPreference = 'Stop'

if ( -not ( $Path -match "^.*(\.lnk)$" ) ) {
    $Path = "$Path`.lnk"
}

$lnk = Get-Shortcut.ps1 $Path

$lnk.SetScreenBufferSize($X, $ScreenBufferY)
$lnk.SetWindowSize($X, $Y)

$lnk.Save()

exit 0
