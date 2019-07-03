#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/steps
#
# use:
#
# Set-PSConsoleColorScheme.ps1 psconsole-colorscheme.json
#
# default psconsole-settings:
#
# {
#     "ColorScheme": {
#         "ForegroundColor": "DarkYellow",
#         "BackgroundColor": "DarkMagenta",
#         "ErrorForegroundColor": "Red",
#         "ErrorBackgroundColor": "Black",
#         "WarningForegroundColor": "Yellow",
#         "WarningBackgroundColor": "Black",
#         "DebugForegroundColor": "Yellow",
#         "DebugBackgroundColor": "Black",
#         "VerboseForegroundColor": "Yellow",
#         "VerboseBackgroundColor": "Black",
#         "ProgressForegroundColor": "Yellow",
#         "ProgressBackgroundColor": "DarkCyan"
#     }
# }
#
# valid colors:
#
#    White
#    Red
#    Green
#    Blue
#    Cyan
#    Yellow
#    Magenta
#    Gray
#    DarkRed
#    DarkGreen
#    DarkBlue
#    DarkCyan
#    DarkYellow
#    DarkMagenta
#    DarkGray
#    Black
#
$PSColorSchemeJSON = $args[0]

$CS = ( Get-Content -Raw -Path $PSColorSchemeJSON | ConvertFrom-Json ).ColorScheme

if ( $host.name -eq 'ConsoleHost' ) {
    $host.ui.RawUI.ForegroundColor = $CS.ForegroundColor
    $host.ui.RawUI.BackgroundColor = $CS.BackgroundColor
    $host.PrivateData.ErrorForegroundColor = $CS.ErrorForegroundColor
    $host.PrivateData.ErrorBackgroundColor = $CS.ErrorBackgroundColor
    $host.PrivateData.WarningForegroundColor = $CS.WarningForegroundColor
    $host.PrivateData.WarningBackgroundColor = $CS.WarningBackgroundColor
    $host.PrivateData.DebugForegroundColor = $CS.DebugForegroundColor
    $host.PrivateData.DebugBackgroundColor = $CS.DebugBackgroundColor
    $host.PrivateData.VerboseForegroundColor = $CS.VerboseForegroundColor
    $host.PrivateData.VerboseBackgroundColor = $CS.VerboseBackgroundColor
    $host.PrivateData.ProgressForegroundColor = $CS.ProgressForegroundColor
    $host.PrivateData.ProgressBackgroundColor = $CS.ProgressBackgroundColor
    Clear-Host
}
else {
    Write-Warning "This only works in the console host, not the ISE."
}