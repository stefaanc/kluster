#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/psconsole
#
# use:
#
#     Apply-PSConsoleSettings.ps1 "$Project" [ -NoPrompt ]
#
# with:
#
#     $Project is the name to show in the window title.
#
#         for instance $Project = "KLUSTER"
#         will set the window title to "Windows PowerShell for KLUSTER"
#
#         for instance $Project = "" or $null
#         will set the window title to "Windows PowerShell"
#
#     -NoPrompt will not define a function to change the prompt
#
# requires:
#
#     $ROOT/.psconsole.json = {
#         "UserColorScheme": {...}
#         "AdminColorScheme": {...}
#         "LegacyColorScheme": {...}
#     }
#
# legacy Powershell color-scheme:
#
#     {
#         "LegacyColorScheme": {
#             "StreamOutputForegroundColor": "DarkYellow",
#             "StreamOutputBackgroundColor": "DarkMagenta",
#             "StreamErrorForegroundColor": "Red",
#             "StreamErrorBackgroundColor": "Black",
#             "StreamWarningForegroundColor": "Yellow",
#             "StreamWarningBackgroundColor": "Black",
#             "StreamDebugForegroundColor": "Yellow",
#             "StreamDebugBackgroundColor": "Black",
#             "StreamVerboseForegroundColor": "Yellow",
#             "StreamVerboseBackgroundColor": "Black",
#             "StreamProgressForegroundColor": "Yellow",
#             "StreamProgressBackgroundColor": "DarkCyan",
#             "SyntaxCommandForegroundColor": "Yellow",
#             "SyntaxCommandBackgroundColor": "DarkMagenta",
#             "SyntaxCommentForegroundColor": "DarkGreen",
#             "SyntaxCommentBackgroundColor": "DarkMagenta",
#             "SyntaxContinuationPromptForegroundColor": "DarkYellow",
#             "SyntaxContinuationPromptBackgroundColor": "DarkMagenta",
#             "SyntaxDefaultForegroundColor": "DarkYellow",
#             "SyntaxDefaultBackgroundColor": "DarkMagenta",
#             "SyntaxEmphasisForegroundColor": "Cyan",
#             "SyntaxEmphasisBackgroundColor": "DarkMagenta",
#             "SyntaxErrorForegroundColor": "Red",
#             "SyntaxErrorBackgroundColor": "DarkMagenta",
#             "SyntaxKeywordForegroundColor": "Green",
#             "SyntaxKeywordBackgroundColor": "DarkMagenta",
#             "SyntaxMemberForegroundColor": "White",
#             "SyntaxMemberBackgroundColor": "DarkMagenta",
#             "SyntaxNumberForegroundColor": "White",
#             "SyntaxNumberBackgroundColor": "DarkMagenta",
#             "SyntaxOperatorForegroundColor": "DarkGray",
#             "SyntaxOperatorBackgroundColor": "DarkMagenta",
#             "SyntaxParameterForegroundColor": "DarkGray",
#             "SyntaxParameterBackgroundColor": "DarkMagenta",
#             "SyntaxSelectionForegroundColor": "DarkMagenta",
#             "SyntaxSelectionBackgroundColor": "DarkYellow",
#             "SyntaxStringForegroundColor": "DarkBlue",
#             "SyntaxStringBackgroundColor": "DarkMagenta",
#             "SyntaxTypeForegroundColor": "Gray",
#             "SyntaxTypeBackgroundColor": "DarkMagenta",
#             "SyntaxVariableForegroundColor": "Green",
#             "SyntaxVariableBackgroundColor": "DarkMagenta",
#             "PromptForegroundColor": "DarkYellow",
#             "PromptBackgroundColor": "DarkMagenta"
#         }
#     }
#
#     Remark that changing 'StreamOutputForegroundColor' and 'StreamOutputBackgroundColor' doesn't persist
#     in late PowerShell 5.1 versions.  This is a bug in PSReadLine that is solved in PowerShell 6 version.
#     These values are better changed by changing the ConsoleColors of the PowerShell shortcut
#
#     Remark that, although PowerShell allows using HEX color-codes, or ANSI VT100 color-codes for some of these items,
#     This script is only able to understand the 16 PowerShell-colors
#
# colors:
#
#     Black                            # Colorized color-scheme: used as Screen Background
#     DarkBlue
#     DarkGreen
#     DarkCyan
#     DarkRed
#     DarkMagenta                      ##### Legacy Powershell color-scheme: used as Screen Background
#     DarkYellow                       ##### Legacy Powershell color-scheme: used as Screen Text
#     Gray       # i.e. 'DarkWhite'    # Colorized color-scheme: used as Normal Screen Text
#     DarkGray   # i.e. 'LightBlack'   # Colorized color-scheme: used as Dim Screen Text & Popup Text
#     Blue       # 'Orange' in Colorized color-scheme
#     Green
#     Cyan                             # Colorized color-scheme: used as Bright Screen Text
#     Red
#     Magenta    # 'Violet' in Colorized color-scheme
#     Yellow
#     White                            # Colorized color-scheme: used as Popup Background
#
#     Remark that these colors aren't necessarily in-line with their name.
#     The effective colors are set in the registry and the properties of the shortcut
#     to powershell.exe (ref: .https://devblogs.microsoft.com/commandline/understanding-windows-console-host-settings)
#     The boxes in the shortcut's properties (left-to-right) show the colors
#     corresponding to the above names (top-to-bottom)
#
param(
    [parameter(position=0)]$Project,
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'

if ( $HOST.Name -ne 'ConsoleHost' ) {
    Write-Warning "This only works in the console host, not the ISE."
    return
}

#
# set the colors for streams and tokens
function ApplyPSConsoleSettings {
    # we are using a function to avoid variables polluting the environment when sourcing this

    $e = [char]0x1b

    $VTForegroundColors = @{
        Black = "30"
        DarkBlue = "34"
        DarkGreen = "32"
        DarkCyan = "36"
        DarkRed = "31"
        DarkMagenta = "35"
        DarkYellow = "33"
        Gray = "37"
        DarkGray = "90"
        Blue = "94"
        Green = "92"
        Cyan = "96"
        Red = "91"
        Magenta = "95"
        Yellow = "93"
        White = "97"
    }

    $VTBackgroundColors = @{
        Black = "40"
        DarkBlue = "44"
        DarkGreen = "42"
        DarkCyan = "46"
        DarkRed = "41"
        DarkMagenta = "45"
        DarkYellow = "43"
        Gray = "47"
        DarkGray = "100"
        Blue = "104"
        Green = "102"
        Cyan = "106"
        Red = "101"
        Magenta = "105"
        Yellow = "103"
        White = "107"
    }

    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    #
    # pickup the console settings
    if ( $ROOT -eq $HOME ) {
        $PSConsoleSettings = $( Get-Content -Raw -Path "$HOME/Documents/WindowsPowershell/console.json" | ConvertFrom-Json )
    }
    else {
        $PSConsoleSettings = $( Get-Content -Raw -Path "$ROOT/.psconsole.json" | ConvertFrom-Json )
    }

    if ( ( $HOST.UI.RawUI.ForegroundColor -eq 'DarkYellow' ) -and ( $HOST.UI.RawUI.BackgroundColor -eq 'DarkMagenta' ) ) {
        # we are working with a legacy Powershell instance

        $CS = $PSConsoleSettings.LegacyColorScheme
    }
    else {
        # we are working with a modified Powershell instance
        # we assume a "Colorized" color-scheme is being used for the console

        if ( $IsAdmin ) {
            $CS = $PSConsoleSettings.AdminColorScheme
        }
        else {
            $CS = $PSConsoleSettings.UserColorScheme
        }
    }

    #
    # set the console title
    if ( "$Project" -ne "" ) {
        $HOST.UI.RawUI.WindowTitle = "Windows PowerShell for $Project"
    }
    else {
        $HOST.UI.RawUI.WindowTitle = "Windows PowerShell"
    }
    if ( $IsAdmin ) {
        $HOST.UI.RawUI.WindowTitle = "[Administrator] $( $HOST.UI.RawUI.WindowTitle )"
    }

    #
    # set the colors for the streams
    if ( $HOST.UI.RawUI.BackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
        $MustClearHost = $true
    }

    $HOST.UI.RawUI.ForegroundColor = $CS.StreamOutputForegroundColor
    $HOST.UI.RawUI.BackgroundColor = $CS.StreamOutputBackgroundColor
    $HOST.PrivateData.ErrorForegroundColor = $CS.StreamErrorForegroundColor
    $HOST.PrivateData.ErrorBackgroundColor = $CS.StreamErrorBackgroundColor
    $HOST.PrivateData.WarningForegroundColor = $CS.StreamWarningForegroundColor
    $HOST.PrivateData.WarningBackgroundColor = $CS.StreamWarningBackgroundColor
    $HOST.PrivateData.DebugForegroundColor = $CS.StreamDebugForegroundColor
    $HOST.PrivateData.DebugBackgroundColor = $CS.StreamDebugBackgroundColor
    $HOST.PrivateData.VerboseForegroundColor = $CS.StreamVerboseForegroundColor
    $HOST.PrivateData.VerboseBackgroundColor = $CS.StreamVerboseBackgroundColor
    $HOST.PrivateData.ProgressForegroundColor = $CS.StreamProgressForegroundColor
    $HOST.PrivateData.ProgressBackgroundColor = $CS.StreamProgressBackgroundColor

    #
    # set the colors for the syntax-highlighting
    if (Get-Module -ListAvailable -Name "PSReadline") {
        # PSReadline was introduced in PowerShell version 5

        if ( [System.Version](Get-Module PSReadline).Version -lt [System.Version]"2.0.0" ) {
            Set-PSReadLineOption -TokenKind 'Command' -ForegroundColor $CS.SyntaxCommandForegroundColor -BackgroundColor $CS.SyntaxCommandBackgroundColor
            Set-PSReadLineOption -TokenKind 'Comment' -ForegroundColor $CS.SyntaxCommentForegroundColor -BackgroundColor $CS.SyntaxCommentBackgroundColor
            Set-PSReadLineOption -ContinuationPromptForegroundColor $CS.SyntaxContinuationPromptForegroundColor -ContinuationPromptBackgroundColor $CS.SyntaxContinuationPromptBackgroundColor   # !!!
            # Set-PSReadLineOption -TokenKind 'Default' -ForegroundColor $CS.SyntaxDefaultForegroundColor -BackgroundColor $CS.SyntaxDefaultBackgroundColor
            Set-PSReadLineOption -TokenKind 'None' -ForegroundColor $CS.SyntaxDefaultForegroundColor -BackgroundColor $CS.SyntaxDefaultBackgroundColor
            Set-PSReadLineOption -EmphasisForegroundColor $CS.SyntaxEmphasisForegroundColor -EmphasisBackgroundColor $CS.SyntaxEmphasisBackgroundColor                                           # !!!
            Set-PSReadLineOption -ErrorForegroundColor $CS.SyntaxErrorForegroundColor -ErrorBackgroundColor $CS.SyntaxErrorBackgroundColor                                                       # !!!
            Set-PSReadLineOption -TokenKind 'Keyword' -ForegroundColor $CS.SyntaxKeywordForegroundColor -BackgroundColor $CS.SyntaxKeywordBackgroundColor
            Set-PSReadLineOption -TokenKind 'Member' -ForegroundColor $CS.SyntaxMemberForegroundColor -BackgroundColor $CS.SyntaxMemberBackgroundColor
            Set-PSReadLineOption -TokenKind 'Number' -ForegroundColor $CS.SyntaxNumberForegroundColor -BackgroundColor $CS.SyntaxNumberBackgroundColor
            Set-PSReadLineOption -TokenKind 'Operator' -ForegroundColor $CS.SyntaxOperatorForegroundColor -BackgroundColor $CS.SyntaxOperatorBackgroundColor
            Set-PSReadLineOption -TokenKind 'Parameter' -ForegroundColor $CS.SyntaxParameterForegroundColor -BackgroundColor $CS.SyntaxParameterBackgroundColor
            # Set-PSReadLineOption -TokenKind 'Selection' -ForegroundColor $CS.SyntaxSelectionForegroundColor -BackgroundColor $CS.SyntaxSelectionBackgroundColor
            Set-PSReadLineOption -TokenKind 'String' -ForegroundColor $CS.SyntaxStringForegroundColor -BackgroundColor $CS.SyntaxStringBackgroundColor
            Set-PSReadLineOption -TokenKind 'Type' -ForegroundColor $CS.SyntaxTypeForegroundColor -BackgroundColor $CS.SyntaxTypeBackgroundColor
            Set-PSReadLineOption -TokenKind 'Variable' -ForegroundColor $CS.SyntaxVariableForegroundColor -BackgroundColor $CS.SyntaxVariableBackgroundColor
        }
        else {
            # the PSReadLine version changed from Windows 10 build 1809 onward

            #
            # prepare VT code for syntax colors
            $VTCommand = "$e[$( $VTForegroundColors.$( $CS.SyntaxCommandForegroundColor ) )"
            if ( $CS.SyntaxCommandBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTCommand = $VTCommand + ";$( $VTBackgroundColors.$( $CS.SyntaxCommandBackgroundColor ) )"
            }
            $VTCommand = $VTCommand + "m"

            $VTComment = "$e[$( $VTForegroundColors.$( $CS.SyntaxCommentForegroundColor ) )"
            if ( $CS.SyntaxCommentBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTComment = $VTComment + ";$( $VTBackgroundColors.$( $CS.SyntaxCommentBackgroundColor ) )"
            }
            $VTComment = $VTComment + "m"

            $VTContinuationPrompt = "$e[$( $VTForegroundColors.$( $CS.SyntaxContinuationPromptForegroundColor ) )"
            if ( $CS.SyntaxContinuationPromptBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTContinuationPrompt = $VTContinuationPrompt + ";$( $VTBackgroundColors.$( $CS.SyntaxContinuationPromptBackgroundColor ) )"
            }
            $VTContinuationPrompt = $VTContinuationPrompt + "m"

            $VTDefault = "$e[$( $VTForegroundColors.$( $CS.SyntaxDefaultForegroundColor ) )"
            if ( $CS.SyntaxDefaultBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTDefault = $VTDefault + ";$( $VTBackgroundColors.$( $CS.SyntaxDefaultBackgroundColor ) )"
            }
            $VTDefault = $VTDefault + "m"

            $VTEmphasis = "$e[$( $VTForegroundColors.$( $CS.SyntaxEmphasisForegroundColor ) )"
            if ( $CS.SyntaxEmphasisBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTEmphasis = $VTEmphasis + ";$( $VTBackgroundColors.$( $CS.SyntaxEmphasisBackgroundColor ) )"
            }
            $VTEmphasis = $VTEmphasis + "m"

            $VTError = "$e[$( $VTForegroundColors.$( $CS.SyntaxErrorForegroundColor ) )"
            if ( $CS.SyntaxErrorBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTError = $VTError + ";$( $VTBackgroundColors.$( $CS.SyntaxErrorBackgroundColor ) )"
            }
            $VTError = $VTError + "m"

            $VTKeyword = "$e[$( $VTForegroundColors.$( $CS.SyntaxKeywordForegroundColor ) )"
            if ( $CS.SyntaxKeywordBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTKeyword = $VTKeyword + ";$( $VTBackgroundColors.$( $CS.SyntaxKeywordBackgroundColor ) )"
            }
            $VTKeyword = $VTKeyword + "m"

            $VTMember = "$e[$( $VTForegroundColors.$( $CS.SyntaxMemberForegroundColor ) )"
            if ( $CS.SyntaxMemberBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTMember = $VTMember + ";$( $VTBackgroundColors.$( $CS.SyntaxMemberBackgroundColor ) )"
            }
            $VTMember = $VTMember + "m"

            $VTNumber = "$e[$( $VTForegroundColors.$( $CS.SyntaxNumberForegroundColor ) )"
            if ( $CS.SyntaxNumberBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTNumber = $VTNumber + ";$( $VTBackgroundColors.$( $CS.SyntaxNumberBackgroundColor ) )"
            }
            $VTNumber = $VTNumber + "m"

            $VTOperator = "$e[$( $VTForegroundColors.$( $CS.SyntaxOperatorForegroundColor ) )"
            if ( $CS.SyntaxOperatorBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTOperator = $VTOperator + ";$( $VTBackgroundColors.$( $CS.SyntaxOperatorBackgroundColor ) )"
            }
            $VTOperator = $VTOperator + "m"

            $VTParameter = "$e[$( $VTForegroundColors.$( $CS.SyntaxParameterForegroundColor ) )"
            if ( $CS.SyntaxParameterBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTParameter = $VTParameter + ";$( $VTBackgroundColors.$( $CS.SyntaxParameterBackgroundColor ) )"
            }
            $VTParameter = $VTParameter + "m"

            $VTSelection = "$e[$( $VTForegroundColors.$( $CS.SyntaxSelectionForegroundColor ) )"
            if ( $CS.SyntaxSelectionBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTSelection = $VTSelection + ";$( $VTBackgroundColors.$( $CS.SyntaxSelectionBackgroundColor ) )"
            }
            $VTSelection = $VTSelection + "m"

            $VTString = "$e[$( $VTForegroundColors.$( $CS.SyntaxStringForegroundColor ) )"
            if ( $CS.SyntaxStringBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTString = $VTString + ";$( $VTBackgroundColors.$( $CS.SyntaxStringBackgroundColor ) )"
            }
            $VTString = $VTString + "m"

            $VTType = "$e[$( $VTForegroundColors.$( $CS.SyntaxTypeForegroundColor ) )"
            if ( $CS.SyntaxTypeBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTType = $VTType + ";$( $VTBackgroundColors.$( $CS.SyntaxTypeBackgroundColor ) )"
            }
            $VTType = $VTType + "m"

            $VTVariable = "$e[$( $VTForegroundColors.$( $CS.SyntaxVariableForegroundColor ) )"
            if ( $CS.SyntaxVariableBackgroundColor -ne $CS.StreamOutputBackgroundColor ) {
                $VTVariable = $VTVariable + ";$( $VTBackgroundColors.$( $CS.SyntaxVariableBackgroundColor ) )"
            }
            $VTVariable = $VTVariable + "m"

            #
            # change the background colors
            $PSReadlineOptions = @{
                Colors = @{
                    Command = $VTCommand
                    Comment = $VTComment
                    ContinuationPrompt = $VTContinuationPrompt
                    Default = $VTDefault
                    Emphasis = $VTEmphasis
                    Error = $VTError
                    Keyword = $VTKeyword
                    Member = $VTMember
                    Number = $VTNumber
                    Operator = $VTOperator
                    Parameter = $VTParameter
                    Selection = $VTSelection
                    String = $VTString
                    Type = $VTType
                    Variable = $VTVariable
                }
            }
            Set-PSReadlineOption @PSReadlineOptions
        }
    }

    #
    # set the colors for the prompt
    $global:PROMPT_FOREGROUNDCOLOR = $CS.PromptForegroundColor
    $global:PROMPT_BACKGROUNDCOLOR = $CS.PromptBackgroundColor

    if ( $IsAdmin ) {
        $global:PROMPT_ADMIN_FOREGROUNDCOLOR = $CS.StreamWarningForegroundColor
        $global:PROMPT_ADMIN_BACKGROUNDCOLOR = $CS.StreamWarningBackgroundColor
    }
    else {
        $global:PROMPT_ADMIN_FOREGROUNDCOLOR = $null
        $global:PROMPT_ADMIN_BACKGROUNDCOLOR = $null
    }

    #
    # clear host when UI background color changed
    if ( $MustClearHost ) {
        Clear-Host
    }
}
ApplyPSConsoleSettings

#
# set the colors for the prompt
if ( -not $NoPrompt ) {
    function global:Prompt {
        if ( "$PROMPT_ADMIN_FOREGROUNDCOLOR" -ne "" ) {
            Write-Host "[Administrator]" -NoNewline -ForegroundColor $PROMPT_ADMIN_FOREGROUNDCOLOR -BackgroundColor $PROMPT_ADMIN_BACKGROUNDCOLOR
            Write-Host " " -NoNewline
        }
        Write-Host "PS $( Get-Location )>" -NoNewline -ForegroundColor $PROMPT_FOREGROUNDCOLOR -BackgroundColor $PROMPT_BACKGROUNDCOLOR

        return " "
    }
}

exit 0
