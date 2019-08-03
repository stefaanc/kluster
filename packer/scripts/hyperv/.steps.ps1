#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/steps
#

#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars')]       # !!! NEEDS WORK !!!
#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost')]   # !!! NEEDS WORK !!!

$e = [char]27
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

function ConvertColorToEsc {
    param(
        [Parameter(Position = 0, Mandatory = $true)][Alias("Color")][string]$ForegroundColor,
        [Parameter(Position = 1)][string]$BackgroundColor
    )

    $f = "$ForegroundColor".Substring(0,1)
    if ( $f -eq [char]27 ) {
        $c = "$ForegroundColor"
    }
    elseif ( $f -eq "#" ) {
        $c = "$e[38;2" +
            ";$( [Convert]::ToInt32("$ForegroundColor".Substring(1,2),16) )" +
            ";$( [Convert]::ToInt32("$ForegroundColor".Substring(3,2),16) )" +
            ";$( [Convert]::ToInt32("$ForegroundColor".Substring(5,2),16) )" +
            "m"
    }
    else {
        $c = "$e[$( $VTForegroundColors.$ForegroundColor )"
        if ( "$BackgroundColor" -ne "" ) {
            $c = $c + ";$( $VTBackgroundColors.$BackgroundColor )"
        }
        $c = $c + "m"
    }

    return $c
}

if ( !(Get-Variable -Name "STEPS_COLORS" -ErrorAction 'Ignore') ) {
    $STEPS_COLORS = $env:STEPS_COLORS
}
if ( "$STEPS_COLORS" -eq "" ) {
    #normal      ; bright       ; green        ; yellow       ; red          ; reset
    ${N}="$e[33m"; ${B}="$e[96m"; ${G}="$e[92m"; ${Y}="$e[93m"; ${R}="$e[91m"; ${X}="$e[0m"
}
else {
    $COLORS = "$STEPS_COLORS".Split(",")
    ${N}=ConvertColorToEsc $COLORS[0]
    ${B}=ConvertColorToEsc $COLORS[1]
    ${G}=ConvertColorToEsc $COLORS[2]
    ${Y}=ConvertColorToEsc $COLORS[3]
    ${R}=ConvertColorToEsc $COLORS[4]
    ${X}="$e[0m"
}

if ( "$STEPS_STAGE" -eq "" ) {
    # Write-Host "${N}##### this is first call to '.steps.ps1'${X}"   # for debugging#

    $STEPS_STAGE = "init"
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    $STEPS_CLEANUP = ""

    $STEPS_SCRIPT = $script:MyInvocation.PSCommandPath
    if ( !(Get-Variable -Name "STEPS_PARAMS" -ErrorAction 'Ignore') ) {
        $STEPS_PARAMS = @( Get-PSCallStack )[1].InvocationInfo.BoundParameters
    }
    if ( !(Get-Variable -Name "STEPS_LOG_FILE" -ErrorAction 'Ignore') ) {
        $STEPS_LOG_FILE = $env:STEPS_LOG_FILE
    }
    if ( !(Get-Variable -Name "STEPS_LOG_APPEND" -ErrorAction 'Ignore') ) {
        $STEPS_LOG_APPEND = $env:STEPS_LOG_APPEND
    }

    $ErrorActionPreference='Stop'
    if ( "$STEPS_LOG_FILE" -eq "" ) {
        $InformationPreference='SilentlyContinue'
    }
    else {
        $InformationPreference='Continue'
    }
}
elseif ( "$STEPS_STAGE" -eq "init" ) {
    # Write-Host "${N}##### this is second call to '.steps.ps1'${X}${X}"   # for debugging

    $STEPS_STAGE = "root"
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    # don't define '$STEPS_CLEANUP' - this would override the value when 'do_cleanup' is called before 'do_script'

    $STEPS_INDENT = ""
    $STEPS_PREVIOUS_INDENT = $STEPS_INDENT

    # Don't re-initialize '.steps.ps1'
    return
}
else {
    # Write-Host "${N}##### this is following call to '.steps.ps1'${X}"   # for debugging

    $STEPS_STAGE = "branch"
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    $STEPS_CLEANUP = ""

    Write-Information "${N}${STEPS_INDENT}${X}"   # add a blank line to start a new scope

    $STEPS_PREVIOUS_INDENT = $STEPS_INDENT
    $STEPS_INDENT = ".   $STEPS_INDENT"

    # Don't re-initialize '.steps.ps1'
    return
}

function do_exec {   # called from 1st 'do_script'
    # Write-Host "${N}##### do_exec${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    $global:LASTSTEP = 0

    $global:LASTEXITSCRIPT=""
    $global:LASTEXITCOMMAND=""
    $global:LASTEXITLINENO=""
    $global:LASTEXITCHARNO=""
    $global:LASTEXITMESSAGE=""
    $global:LASTEXITTRAPPED=""

    #Set-Alias 'echo' 'do_echo'                                                 # !!! NEEDS WORK !!!
    #Set-Alias 'exit' 'do_exit'                                                 # !!! NEEDS WORK !!!

    #
    # clear $LASTEXITCODE
    #

    cmd /c "exit 0"

    #
    # restart script with proper redirection
    #

    try {
        # Write-Host "${N}##### do_exec - try${X}"   # for debugging
        if ( "$STEPS_LOG_FILE" -eq "" ) {
            & "$STEPS_SCRIPT" @STEPS_PARAMS
        }
        else {
            $logpath = Split-Path -Path "$STEPS_LOG_FILE"
            if ( $logpath -and !$( Test-Path -Path "$logpath" ) ) {
                New-Item -ItemType directory -Path "$logpath" | Out-Null
            }

            if ( !$STEPS_LOG_APPEND ) {
                & "$STEPS_SCRIPT" @STEPS_PARAMS 5>&1 4>&1 3>&1 2>&1 > "$STEPS_LOG_FILE"
            }
            else {
                & "$STEPS_SCRIPT" @STEPS_PARAMS 5>&1 4>&1 3>&1 2>&1 >> "$STEPS_LOG_FILE"
            }
        }
    }
    catch {
        # Write-Host "${N}##### do_exec - catch${X}"   # for debugging
        exit $LASTEXITCODE   # don't propagate exception
    }

    # Write-Host "${N}##### do_exec - break${X}"   # for debugging
    exit 0
}

function do_script {
    if ( $STEPS_STAGE -eq "init" ) {
        do_exec
    }
    else {
        # Write-Host "${N}##### do_script${X}"   # for debugging
        $script = "Script: $( $script:MyInvocation.MyCommand.Path )"
        $line = "=" * $script.Length
        $hostname = "@ Host: $env:COMPUTERNAME"
        if ( "$STEPS_LOG_FILE" -ne "" ) {
            $log = "$STEPS_LOG_FILE".Replace("/", "\")
            if ( !$STEPS_LOG_APPEND ) {
                $log = "> Log:  $log"
            }
            else {
                $log = ">> Log: $log"
            }
        }

        Write-Information "${N}${STEPS_INDENT}$line${X}"
        Write-Information "${N}${STEPS_INDENT}$script${X}"
        Write-Information "${N}${STEPS_INDENT}$line${X}"
        if ( $STEPS_STAGE -eq "root" ) {
            Write-Information "${N}${STEPS_INDENT}$hostname${X}"
            if ( $log -ne "" ) {
                Write-Information "${N}${STEPS_INDENT}$log${X}"
            }
        }
        Write-Information "${N}${STEPS_INDENT}${X}"

        Write-Output ""
        Write-Output "#"
        Write-Output "# $line"
        Write-Output "# $script"
        Write-Output "# $line"
        if ( $STEPS_STAGE -eq "root" ) {
            Write-Output "#"
            Write-Output "# $hostname"
            if ( $log -ne "" ) {
                Write-Output "# $log"
            }
        }
        Write-Output "#"
        Write-Output ""
    }
}

function do_step {
    param(
        [string]$description
    )
    # Write-Host "${N}##### do_step${X}"   # for debugging

    $global:LASTSTEP = [int]$LASTSTEP + 1
    if (( $description -ne "trap" ) -and ( $description -ne "exit" )) {
        Write-Information "${N}${STEPS_INDENT}$description${X}"

        Write-Output ""
        Write-Output "#"
        Write-Output "# $description"
        Write-Output "#"
        Write-Output ""
    }
}

function do_echo {
    param(
        [Alias("Color","c")][string]$ForegroundColor = ${B},
        [string]$BackgroundColor,
        [Parameter(Position = 0, ValueFromPipeline = $true)][string]$message
    )
    # Write-Host "${N}##### do_echo${X}"   # for debugging

    begin {
        $Color = ConvertColorToEsc $ForegroundColor $BackgroundColor
    }
    process {
        "$message".Replace("`r`n", "`n").Split("`n") | foreach-object {
            $line = "$_".TrimEnd()
            Write-Information "${Color}${STEPS_INDENT}.   $line${X}"
            Write-Output "# $line"
        }
    }
}

function do_reset {
    # Write-Host "${N}##### do_reset${X}"   # for debugging
    cmd /c "exit 0"   # reset $?, reset $LASTEXITCODE
    $global:LASTEXITSCRIPT=""
    $global:LASTEXITCOMMAND=""
    $global:LASTEXITLINENO=""
    $global:LASTEXITCHARNO=""
    $global:LASTEXITMESSAGE=""
    $global:LASTEXITTRAPPED=""
    $Error.Clear()
}

function do_cleanup {
    param(
        [string]$code
    )
    # Write-Host "${N}##### do_cleanup${X}"   # for debugging
    $script:STEPS_CLEANUP = "$code"
}

function do_exit {
    param(
        [int]$exitcode,
        [string]$message
    )
    # Write-Host "${N}##### do_exit${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    if ( $exitcode -eq 0 ) {
        Write-Information "${G}${STEPS_INDENT}OK${X}"
        Write-Information "${N}${STEPS_PREVIOUS_INDENT}${X}"

        Write-Output ""
        Write-Output "# $( "=" * 30 )"
        Write-Output ""

        if ( "$STEPS_CLEANUP" -ne "" ) {
            Invoke-Expression "$STEPS_CLEANUP"
        }

        exit 0
    }
    else {
        $global:LASTEXITSCRIPT = $MyInvocation.ScriptName
        $command_start = $MyInvocation.OffsetInLine
        $command_length = $MyInvocation.PositionMessage.Split("`n")[-1].Replace('+', '').Replace(' ', '').Length
        $global:LASTEXITCOMMAND = $MyInvocation.Line.Substring($command_start - 1, $command_length)
        $global:LASTEXITLINENO = $MyInvocation.ScriptLineNumber
        $global:LASTEXITCHARNO = $MyInvocation.OffsetInLine
        if ( "$message" -ne "" ) {
            $global:LASTEXITMESSAGE = $message
        }
        else {
            $global:LASTEXITMESSAGE = "exited with exitcode $exitcode"
        }

        cmd /c "exit $exitcode"   # set correct $LASTEXITCODE

        throw $LASTEXITMESSAGE
    }
}

function do_catch_exit {
    param(
        [switch]$IgnoreExitStatus,
        [switch]$IgnoreExitCode,
        [string]$IgnoreExitCodes
    )
    $exitstatus = $?   # do this first so it is not overwritten
    $exitcode = $LASTEXITCODE   # remark: this may be an old exitcode when not all exitcodes are caught
    # Write-Host "${N}##### do_catch_exit${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    if ( ( ( "$exitcode" -eq "0" ) -or $IgnoreExitCode ) -and ( ( "$exitstatus" -eq "True" ) -or $IgnoreExitStatus ) ) {
        if ( "$exitstatus" -ne "0" ) {
            $global:LASTIGNOREDEXITCODE = $exitcode
            cmd /c "exit 0"   # reset $LASTEXITCODE
        }

        return
    }
    else {
        $script = $MyInvocation.ScriptName
        $command_start = $MyInvocation.OffsetInLine
        $command_length = $MyInvocation.PositionMessage.Split("`n")[-1].Replace('+', '').Replace(' ', '').Length
        $command = $MyInvocation.Line.Substring($command_start - 1, $command_length)
        $lineno = $MyInvocation.ScriptLineNumber
        $charno = $MyInvocation.OffsetInLine

        if ( ( $IgnoreExitCodes -and ( " $( "$IgnoreExitCodes".Replace(",", " ") ) " -like "* $exitcode *" ) ) -and ( ( "$exitstatus" -eq "True" ) -or $IgnoreExitStatus ) ) {
            $message = "ignored exitcode $exitcode"
            $text = "EXITCODE: $exitcode, line: $lineno, char: $charno, cmd: '$( "$command".Replace("'", "`'") )' > `"$( "$message".Replace('"', '`"') )`""
            do_echo "$text"

            $global:LASTIGNOREDEXITCODE = $exitcode
            cmd /c "exit 0"   # reset $LASTEXITCODE

            return
        }
        else {
            $global:LASTEXITSCRIPT = $script
            $global:LASTEXITCOMMAND = $command
            $global:LASTEXITLINENO = $lineno
            $global:LASTEXITCHARNO = $charno
            if ( "$exitcode" -eq "0" ) {   # -and ( "$exitstatus" -eq "False" )
                $exitcode = 255
                cmd /c "exit $exitcode"   # set correct $LASTEXITCODE

                $global:LASTEXITMESSAGE = "caught execution status $false, with exitcode 0"
            }
            else {
                $global:LASTEXITMESSAGE = "caught exitcode $exitcode"
            }

            throw $LASTEXITMESSAGE
        }
    }
}

function do_continue {
    # Write-Host "${N}##### do_continue${X}"   # for debugging
    cmd /c "exit 0"   # reset $?, reset $LASTEXITCODE
}

function do_trap {
    # Write-Host "${N}##### do_trap${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging
    # Write-Host "${N}##### `$LASTEXITTRAPPED -eq $LASTEXITTRAPPED${X}"   # for debugging

    if ( ! $LASTEXITTRAPPED ) {
        if ( "$LASTEXITLINENO" -ne "" ) {
            # thrown by 'do_exit' or 'do_catch_exit'

            $script = $LASTEXITSCRIPT
            $command = $LASTEXITCOMMAND
            $lineno = $LASTEXITLINENO
            $charno = $LASTEXITCHARNO
            $message = $LASTEXITMESSAGE

            $exitcode = $LASTEXITCODE
        }
        else {
            # thrown directly

            $script = $Error[0].InvocationInfo.ScriptName
            $command_start = $Error[0].InvocationInfo.OffsetInLine
            $command_length = $Error[0].InvocationInfo.PositionMessage.Split("`n")[-1].Replace('+', '').Replace(' ', '').Length
            $command = $Error[0].InvocationInfo.Line.Substring($command_start - 1, $command_length)
            $lineno = $Error[0].InvocationInfo.ScriptLineNumber
            $charno = $Error[0].InvocationInfo.OffsetInLine
            $message = $Error[0].Exception.Message

            $exitcode = $LASTEXITCODE   # remark: this may be an old exitcode when not all exitcodes are caught
            if ( ( "$exitcode" -eq "0" ) -or ( "$exitcode" -eq "" ) ){
                # thrown without exitcode
                $exitcode = 99999
                cmd /c "exit $exitcode"   # set correct $LASTEXITCODE
            }

            if ( "$message" -eq "" ) {
                # thrown without a message
                $message = "<no message>"
            }
        }

        if ( "$STEPS_CLEANUP" -ne "" ) {
            Invoke-Expression "$STEPS_CLEANUP"
        }

        $text = "ERROR: $exitcode, script: $script, line: $lineno, char: $charno, cmd: '$( "$command".Replace("'", "`'") )' > `"$( "$message".Replace('"', '`"') )`""

        Write-Information "${R}${STEPS_INDENT}$text${X}"
        Write-Information "${N}${STEPS_PREVIOUS_INDENT}${X}"

        Write-Output ""
        Write-Output "#"
        Write-Output "# $text"
        Write-Output "#"
        Write-Output ""

        if ( "$LASTEXITLINENO" -eq "" ) { # there typically is no error record when thrown by 'do_exit' or 'do_catch_exit'
            Write-Output $Error[0]
        }

        $global:LASTEXITTRAPPED = $true
    }
    else {
        if ( "$STEPS_CLEANUP" -ne "" ) {
            Invoke-Expression "$STEPS_CLEANUP"
        }
    }

    throw $Error[0].Exception   # propagate exception
}
