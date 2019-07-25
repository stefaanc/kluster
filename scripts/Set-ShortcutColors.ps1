#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/psconsole
#
# use:
#
#     Set-ShortcutColors "$Path" [ -Theme "$Theme" ]
#
# with default $Theme = "$ROOT\colors\psconsole-powershell-legacy.json"
#
#     {
#         "console": {
#             "ScreenTextColor": 6,
#             "ScreenBackgroundColor": 5,
#             "PopupTextColor": 3,
#             "PopupBackgroundColor": 15,
#             "ConsoleColors": [
#                 "#000000",
#                 "#000080",
#                 "#008000",
#                 "#008080",
#                 "#800000",
#                 "#012456",
#                 "#eeedf0",
#                 "#c0c0c0",
#                 "#808080",
#                 "#0000ff",
#                 "#00ff00",
#                 "#00ffff",
#                 "#ff0000",
#                 "#ff00ff",
#                 "#ffff00",
#                 "#ffffff"
#             ]
#         }
#     }
#
param(
    [Parameter(Mandatory=$true, Position=0)][string]$Path,
    [Parameter(Position=1)][string]$Theme
)

$ErrorActionPreference = 'Stop'

if ( -not ( $Path -match "^.*(\.lnk)$" ) ) {
    $Path = "$Path`.lnk"
}

$lnk = Get-Shortcut.ps1 $Path
$colors = $( Get-Content -Raw -Path "$Theme" | ConvertFrom-Json )

$lnk.ScreenTextColor = $colors.console.ScreenTextColor
$lnk.ScreenBackgroundColor = $colors.console.ScreenBackgroundColor
$lnk.PopUpTextColor = $colors.console.PopUpTextColor
$lnk.PopUpBackgroundColor = $colors.console.PopUpBackgroundColor

$lnk.ConsoleColors[0] = $colors.console.ConsoleColors[0]
$lnk.ConsoleColors[1] = $colors.console.ConsoleColors[1]
$lnk.ConsoleColors[2] = $colors.console.ConsoleColors[2]
$lnk.ConsoleColors[3] = $colors.console.ConsoleColors[3]
$lnk.ConsoleColors[4] = $colors.console.ConsoleColors[4]
$lnk.ConsoleColors[5] = $colors.console.ConsoleColors[5]
$lnk.ConsoleColors[6] = $colors.console.ConsoleColors[6]
$lnk.ConsoleColors[7] = $colors.console.ConsoleColors[7]
$lnk.ConsoleColors[8] = $colors.console.ConsoleColors[8]
$lnk.ConsoleColors[9] = $colors.console.ConsoleColors[9]
$lnk.ConsoleColors[10] = $colors.console.ConsoleColors[10]
$lnk.ConsoleColors[11] = $colors.console.ConsoleColors[11]
$lnk.ConsoleColors[12] = $colors.console.ConsoleColors[12]
$lnk.ConsoleColors[13] = $colors.console.ConsoleColors[13]
$lnk.ConsoleColors[14] = $colors.console.ConsoleColors[14]
$lnk.ConsoleColors[15] = $colors.console.ConsoleColors[15]

$lnk.Save()

exit 0
