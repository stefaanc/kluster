#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#

#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars')]       # !!! NEEDS WORK !!!
#[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost')]   # !!! NEEDS WORK !!!

if ( !(Get-Variable -Name "STEPS_COLORS" -ErrorAction 'Ignore') ) {
    $STEPS_COLORS = $env:STEPS_COLORS
}
if ( "$STEPS_COLORS" -eq "" ) {
    $e = [char]27
    ${N}="$e[38;5;45m"; ${G}="$e[92m"; ${Y}="$e[93m"; ${R}="$e[91m"; ${X}="$e[0m"
    #     normal      ;       green  ;       yellow ;       red    ;       reset
}
else {
    $COLORS = "$STEPS_COLORS".Split(",")
    ${N}=$COLORS[0]; ${G}=$COLORS[1]; ${Y}=$COLORS[2]; ${R}=$COLORS[3]; ${X}=$COLORS[4];
    #    normal      ;    green  ;         yellow ;         red    ;         reset
}

if ( "$STEPS_STAGE" -eq "" ) {
    # Write-Host "${N}##### this is first call to '.steps.ps1'${X}"   # for debugging#

    $STEPS_STAGE = "init"
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    $STEPS_SCRIPT = $script:MyInvocation.PSCommandPath
    if ( !(Get-Variable -Name "STEPS_LOG_FILE" -ErrorAction 'Ignore') ) {
        $STEPS_LOG_FILE = $env:STEPS_LOG_FILE
    }
    if ( !(Get-Variable -Name "STEPS_LOG_APPEND" -ErrorAction 'Ignore') ) {
        $STEPS_LOG_APPEND = $env:STEPS_LOG_APPEND
    }
    $STEPS_LOG_APPEND = "$STEPS_LOG_APPEND".ToLower()

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

    $STEPS_INDENT = ""
    $STEPS_PREVIOUS_INDENT = $STEPS_INDENT

    # Don't re-initialize '.steps.ps1'
    return
}
else {
    # Write-Host "${N}##### this is following call to '.steps.ps1'${X}"   # for debugging

    $STEPS_STAGE = "branch"
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

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
    $global:LASTEXITLINENO=-1
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
            & "$STEPS_SCRIPT"
        }
        elseif ( ( "$STEPS_LOG_APPEND" -eq "" ) -or ( "$STEPS_LOG_APPEND" -eq "false" ) ) {
            & "$STEPS_SCRIPT" "$STEPS_LOG_FILE" 5>&1 4>&1 3>&1 2>&1 > "$STEPS_LOG_FILE"
        }
        else {
            & "$STEPS_SCRIPT" "$STEPS_LOG_FILE" "$STEPS_LOG_APPEND" 5>&1 4>&1 3>&1 2>&1 >> "$STEPS_LOG_FILE"
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
        if ( $log -ne "" ) {
            $log = $STEPS_LOG_FILE.Replace("/", "\")
            if ( ( "$STEPS_LOG_APPEND" -eq "" ) -or ( "$STEPS_LOG_APPEND" -eq "false" ) ) {
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
    param (
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
    param (
        [string]$message
    )
    # Write-Host "${N}##### do_echo${X}"   # for debugging

    Write-Information "${Y}${STEPS_INDENT}.   $message${X}"

    Write-Output ".   $message"
}

function do_reset {
    # Write-Host "${N}##### do_reset${X}"   # for debugging
    cmd /c "exit 0"
    $Error.Clear()
}

function do_exit {
    param (
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
    $exitstatus = $?   # do this first so it is not overwritten
    $exitcode = $LASTEXITCODE   # remark: this may be an old exitcode when not all exitcodes are caught
    # Write-Host "${N}##### do_catch_exit${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging

    if ( ( "$exitcode" -eq "0" ) -and ( "$exitstatus" -eq "True" ) ) {
        return
    }
    else {
        $global:LASTEXITSCRIPT = $MyInvocation.ScriptName
        $command_start = $MyInvocation.OffsetInLine
        $command_length = $MyInvocation.PositionMessage.Split("`n")[-1].Replace('+', '').Replace(' ', '').Length
        $global:LASTEXITCOMMAND = $MyInvocation.Line.Substring($command_start - 1, $command_length)
        $global:LASTEXITLINENO = $MyInvocation.ScriptLineNumber
        $global:LASTEXITCHARNO = $MyInvocation.OffsetInLine
        $global:LASTEXITMESSAGE = "caught exitcode $exitcode"

        if ( "$exitstatus" -eq "0" ) {   # -and ( "$exitstatus" -ne "True" )
            $exitcode = -99999
            cmd /c "exit -99999"   # set correct $LASTEXITCODE
        }

        throw $LASTEXITMESSAGE
    }
}

function do_check_exit {
    if ( !$? ) { exit $LASTEXITCODE }
}

function do_trap {
    # Write-Host "${N}##### do_trap${X}"   # for debugging
    # Write-Host "${N}##### `$STEPS_STAGE -eq '$STEPS_STAGE'${X}"   # for debugging
    # Write-Host "${N}##### `$LASTEXITTRAPPED -eq $LASTEXITTRAPPED${X}"   # for debugging

    if ( ! $LASTEXITTRAPPED ) {
        if ( $LASTEXITLINENO -ne -1 ) {
            # thrown by 'do_exit' or 'do_catch_exit'
            $exitcode = $LASTEXITCODE

            $script = $LASTEXITSCRIPT
            $command = $LASTEXITCOMMAND
            $lineno = $LASTEXITLINENO
            $charno = $LASTEXITCHARNO
            $message = $LASTEXITMESSAGE
        }
        else {
            # thrown directly
            $exitcode = $LASTEXITCODE   # remark: this may be an old exitcode when not all exitcodes are caught
            if ( "$exitcode" -eq "0" ) {
                # thrown without exitcode
                $exitcode = 99999
                cmd /c "exit $exitcode"   # set correct $LASTEXITCODE
            }

            $script = $Error[0].InvocationInfo.ScriptName
            $command_start = $Error[0].InvocationInfo.OffsetInLine
            $command_length = $Error[0].InvocationInfo.PositionMessage.Split("`n")[-1].Replace('+', '').Replace(' ', '').Length
            $command = $Error[0].InvocationInfo.Line.Substring($command_start - 1, $command_length)
            $lineno = $Error[0].InvocationInfo.ScriptLineNumber
            $charno = $Error[0].InvocationInfo.OffsetInLine
            $message = $Error[0].Exception.Message

            if ( "$message" -eq "" ) {
                # thrown without a message
                $message = "<no message>"
            }
        }

        $text = "ERROR: $exitcode, line: $lineno, char: $charno, cmd: '$( $command.Replace("'", "`'") )' > `"$( $message.Replace('"', '`"') )`""

        Write-Information "${R}${STEPS_INDENT}$text${X}"
        Write-Information "${N}${STEPS_PREVIOUS_INDENT}${X}"

        Write-Output ""
        Write-Output "#"
        Write-Output "# $text"
        Write-Output "#"
        Write-Output ""

        if ( $LASTEXITLINENO -eq -1 ) { # there typically is no error record when thrown by 'do_exit' or 'do_catch_exit'
            Write-Output $Error[0]
        }

        $global:LASTEXITTRAPPED = $true
    }

    throw $Error[0].Exception   # propagate exception
}
