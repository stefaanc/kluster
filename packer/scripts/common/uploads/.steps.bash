#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/steps
#

set -eu -o pipefail -o errtrace

trap 'do_exit 99999 $? "$LINENO"' ERR
trap 'do_trap' EXIT

. "$( dirname ${BASH_SOURCE[0]} )/.globals.bash"

declare -A VTForegroundColors=(
    ["Black"]="30"
    ["DarkBlue"]="34"
    ["DarkGreen"]="32"
    ["DarkCyan"]="36"
    ["DarkRed"]="31"
    ["DarkMagenta"]="35"
    ["DarkYellow"]="33"
    ["Gray"]="37"
    ["DarkGray"]="90"
    ["Blue"]="94"
    ["Green"]="92"
    ["Cyan"]="96"
    ["Red"]="91"
    ["Magenta"]="95"
    ["Yellow"]="93"
    ["White"]="97"
)
declare -A VTBackgroundColors=(
    ["Black"]="40"
    ["DarkBlue"]="44"
    ["DarkGreen"]="42"
    ["DarkCyan"]="46"
    ["DarkRed"]="41"
    ["DarkMagenta"]="45"
    ["DarkYellow"]="43"
    ["Gray"]="47"
    ["DarkGray"]="100"
    ["Blue"]="104"
    ["Green"]="102"
    ["Cyan"]="106"
    ["Red"]="101"
    ["Magenta"]="105"
    ["Yellow"]="103"
    ["White"]="107"
)

ConvertColorToEsc () {
    local foregroundcolor=$( echo -e "$1" )
    if [[ $# -gt 1 ]] ; then
        local backgroundcolor=$( echo -e "$2" )
    else
        local backgroundcolor=""
    fi

    local f=${foregroundcolor:0:1}
    if [[ "$f" = $'\e' ]] ; then
        local c="$foregroundcolor"
    elif [[ "$f" = "#" ]] ; then
        local red=$(( 16#$( echo "${foregroundcolor:1:2}" | tr a-z A-Z ) ))
        local green=$(( 16#$( echo "${foregroundcolor:3:2}" | tr a-z A-Z ) ))
        local blue=$(( 16#$( echo "${foregroundcolor:5:2}" | tr a-z A-Z ) ))
        local c="\e[38;2;${red};${green};${blue}m"
    else
        local c="\e[${VTForegroundColors[$foregroundcolor]}"
        if [[ "$backgroundcolor" != "" ]] ; then
            local c="${c};${VTBackgroundColors[$backgroundcolor]}"
        fi
        local c="${c}m"
    fi

    echo "$c"
}

STEPS_CLEANUP=""

set +u   # disable checking for undefined vars
export STEPS_COLORS="$STEPS_COLORS"
set -u
if [[ "$STEPS_COLORS" = "" ]] ; then
    export N="\e[37m"; export B="\e[96m"; export G="\e[92m"; export Y="\e[93m"; export R="\e[91m"; export X="\e[0m"
    #         normal ;           bright ;           green  ;           yellow ;           red    ;           reset
else
    OLDIFS=$IFS; IFS=',' 
    read -ra colors <<< "$STEPS_COLORS"
    IFS=$OLDIFS
    export N=$( ConvertColorToEsc ${colors[0]} )
    export B=$( ConvertColorToEsc ${colors[1]} )
    export G=$( ConvertColorToEsc ${colors[2]} )
    export Y=$( ConvertColorToEsc ${colors[3]} )
    export R=$( ConvertColorToEsc ${colors[4]} )
    export X="\e[0m"
fi

set +u   # disable checking for undefined vars
export STEPS_STAGE="$STEPS_STAGE"
set -u
if [[ "$STEPS_STAGE" = "" ]] ; then
    #echo "##### this is first call to '.steps.bash'" #>&111   # for debugging#

    export STEPS_STAGE="root"
    #echo "##### [[ \$STEPS_STAGE = '$STEPS_STAGE' ]]" #>&111   # for debugging

    export STEPS_INDENT=""
    export STEPS_PREVIOUS_INDENT=$STEPS_INDENT

    global LASTSTEP=0

    global LASTEXITCODE=0
    global LASTEXITSCRIPT=""
    global LASTEXITCOMMAND=""
    global LASTEXITLINENO=""
    global LASTEXITMESSAGE=""
    global LASTEXITTRAPPED=""

    set +u   # disable checking for undefined vars
    export STEPS_LOG_FILE="$STEPS_LOG_FILE"
    set -u
    if [[ "$STEPS_LOG_FILE" = "" ]] ; then
        exec 111>/dev/null 2> >( tee "./_stderr.log" )
    else
        logpath="$( dirname $STEPS_LOG_FILE )"
        if [[ $logpath ]] ; then
            mkdir -p $logpath
        fi

        set +u   # disable checking for undefined vars
        export STEPS_LOG_APPEND="$STEPS_LOG_APPEND"
        set -u
        if [[ "$STEPS_LOG_APPEND" = "" ]] || [[ "$STEPS_LOG_APPEND" = "false" ]] ; then
            exec 111>&1 1> $STEPS_LOG_FILE 2> >( tee "./_stderr.log" )
        else
            exec 111>&1 1>> $STEPS_LOG_FILE 2> >( tee "./_stderr.log" )
        fi
    fi
else
    #echo "##### this is following call to '.steps.ps1'" #>&111   # for debugging

    export STEPS_STAGE="branch"
    #echo "##### [[ \$STEPS_STAGE = '$STEPS_STAGE' ]]" #>&111   # for debugging

    echo -e "${N}${STEPS_INDENT}${X}" >&111   # add a blank line to start a new scope

    export STEPS_PREVIOUS_INDENT=$STEPS_INDENT
    export STEPS_INDENT=".   $STEPS_INDENT"
fi

do_script () {
    #echo '##### do_script' #>&111     # for debugging
    local script="Script: ${BASH_SOURCE[1]}"
    local line="$( printf '%.0s=' `seq 1 $( expr length "$script" )` )"
    local hostname="@ Host: $HOSTNAME"
    local log="$STEPS_LOG_FILE"
    if [[ "$log" != "" ]] ; then 
        if [[ "$STEPS_LOG_APPEND" = "" ]] || [[ "$STEPS_LOG_APPEND" = "false" ]] ; then 
            local log="> Log:  $log"
        else 
            local log=">> Log: $log"
        fi
    fi

    echo -e "${N}${STEPS_INDENT}$line${X}" >&111
    echo -e "${N}${STEPS_INDENT}$script${X}" >&111
    echo -e "${N}${STEPS_INDENT}$line${X}" >&111
    if [[ $STEPS_STAGE = "root" ]] ; then
        echo -e "${N}${STEPS_INDENT}$hostname${X}" >&111
        if [[ $log != "" ]] ; then 
            echo -e "${N}$log${X}" >&111
        fi
    fi
    echo -e "${N}${STEPS_INDENT}${X}" >&111

    echo ""
    echo "#"
    echo "# $line"
    echo "# $script"
    echo "# $line"
    if [[ $STEPS_STAGE = "root" ]] ; then
        echo "#"
        echo "# $hostname"
        if [[ $log != "" ]] ; then 
            echo "# $log"
        fi
    fi
    echo "#"
    echo ""
}

do_step () {
    local description="$1"
    #echo '##### do_step' #>&111     # for debugging

    global LASTSTEP=$(( LASTSTEP + 1 ))
    if [[ $description != "trap" ]] && [[ $description != "exit" ]] ; then
        echo -e "${N}${STEPS_INDENT}$description${X}" >&111

        echo ""
        echo "#"
        echo "# $description"
        echo "#"
        echo ""
    fi
}

do_echo () {
    local message=${@:-$(</dev/stdin)}
    #echo '##### do_echo' #>&111     # for debugging

    local foregroundcolor=${B}
    local backgroundcolor=""
    if [[ $# -gt 1 ]] ; then
        while [[ $1 ]] ; do
            case "$1" in
                -c | --color | --foregroundcolor)
                    local foregroundcolor=$2; shift ;;
                --backgroundcolor)
                    local backgroundcolor=$2; shift ;;
                *)
                    local message=$@; break ;;
            esac
            shift
        done
    fi

    local color=$( ConvertColorToEsc $foregroundcolor $backgroundcolor )

    OLDIFS=$IFS; IFS=$'\n'
    while read -r line ; do
        echo -e "${color}${STEPS_INDENT}.   $line${X}" >&111
        echo "# $line"
    done <<< "$message"
    IFS=$OLDIFS
}

do_reset () {
    #echo '##### do_reset' #>&111     # for debugging
    global LASTEXITCODE=0
    global LASTEXITSCRIPT=""
    global LASTEXITCOMMAND=""
    global LASTEXITLINENO=""
    global LASTEXITMESSAGE=""
    global LASTEXITTRAPPED=""
}

do_cleanup () {
    #echo '##### do_cleanup' #>&111     # for debugging
    STEPS_CLEANUP=$1
}

do_exit () {
    local exitcode=$1
    local command="$BASH_COMMAND"   # capture command here so not overwritten by the code in this function
    #echo '##### do_exit' >&111     # for debugging

    if [[ $exitcode != 99999 ]] ; then 
        # called directly
        #echo "##### 1" #>&111     # for debugging
        global LASTEXITSCRIPT="${BASH_SOURCE[1]}"
        local lineno="${BASH_LINENO[1]}"   # this always will be '0' when trapped in 'main'
        if [[ $lineno = "0" ]] ; then local lineno="--" ; fi
        global LASTEXITLINENO=$lineno
        if [[ ( $# -gt 1 ) && ( "$2" != "" ) ]] ; then
            global LASTEXITCOMMAND="do_exit $exitcode \"$2\""
            global LASTEXITMESSAGE="$2"
        else
            global LASTEXITCOMMAND="do_exit $exitcode"
            global LASTEXITMESSAGE="exited with exitcode $exitcode"
        fi
    elif [[ "$( tail -n 1 "./_stderr.log" 2>/bin/null | grep ': line [0-9]*: ' )" != "" ]] ; then 
        # called via ERR trap, with error-message
        #echo '##### 2' #>&111     # for debugging
        local exitcode=$2   # replace 99999 with trapped errorcode
        global LASTEXITSCRIPT="$( tail -n 1 "./_stderr.log" | sed -e 's|: .*||' )"
        global LASTEXITLINENO="$( tail -n 1 "./_stderr.log" | sed -e 's|.*: line ||' -e 's|: .*||' )"
        global LASTEXITCOMMAND="$command"
        global LASTEXITMESSAGE="$( tail -n 1 "./_stderr.log" | sed -e 's|.* line [0-9]*: ||' )"
    else 
        # called via ERR trap, without error-message (f.i. 'exit' command)
        #echo '##### 3' #>&111     # for debugging
        local exitcode=$2   # replace '99999' with trapped errorcode
        local index=1
        while [[ "true" ]] ; do
            local script="${BASH_SOURCE[$index]}"
            local basename="$(basename "$script")"
            if [[ ( "$basename" != ".steps.bash" ) && ( "$basename" != ".globals.bash" ) ]] ; then
                break
            fi
            local index=$(( index + 1 ))
        done
        global LASTEXITSCRIPT="$script"
        local lineno="${BASH_LINENO[$index]}"   # this always will be '0' when trapped in 'main'
        if [[ $lineno = "0" ]] ; then local lineno="$3" ; fi
        if [[ $lineno = "" ]] ; then local lineno="--" ; fi
        global LASTEXITLINENO=$lineno
        global LASTEXITCOMMAND="$command"
        global LASTEXITMESSAGE="exited with exitcode $exitcode"
    fi

    global LASTEXITCODE=$exitcode

    #echo "##### [[ \$LASTEXITCODE = $LASTEXITCODE ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITSCRIPT = $LASTEXITSCRIPT ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITLINENO = $LASTEXITLINENO ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITCOMMAND = $LASTEXITCOMMAND ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITMESSAGE = $LASTEXITMESSAGE ]]" #>&111     # for debugging

    exit $exitcode
}

do_trap () {
    local exitcode=$?
    local command="$BASH_COMMAND"   # capture command here so not overwritten by the code in this function
    #echo '##### do_trap' >&111     # for debugging

    if [[ "$LASTEXITTRAPPED" = "" ]] ; then
        if [[ "$LASTEXITLINENO" != "" ]] ; then 
            # called via EXIT trap for 'do_exit'
            #echo '##### 1' #>&111     # for debugging
            :   # noop
        elif [[ "$( tail -n 1 "./_stderr.log" 2>/bin/null | grep ': line [0-9]*: ' )" != "" ]] ; then 
            # called via direct EXIT trap, with error-message
            #echo '##### 2' #>&111     # for debugging
            global LASTEXITSCRIPT="$( tail -n 1 "./_stderr.log" | sed -e 's|: .*||' )"
            global LASTEXITCOMMAND="$command"
            global LASTEXITLINENO="$( tail -n 1 "./_stderr.log" | sed -e 's|.*: line ||' -e 's|: .*||' )"
            global LASTEXITMESSAGE="$( tail -n 1 "./_stderr.log" | sed -e 's|.*: line [0-9]*: ||' )"
        else 
            # called via direct EXIT trap, without error-message
            #echo '##### 3' #>&111     # for debugging
            global LASTEXITSCRIPT="${BASH_SOURCE[1]}"
            global LASTEXITCOMMAND="$command"
            local lineno="${BASH_LINENO[1]}"   # this always will be '0' when trapped in 'main'
            if [[ "$lineno" = "0" ]] ; then local lineno="--" ; fi
            global LASTEXITLINENO=$lineno
            global LASTEXITMESSAGE="exited with exitcode $exitcode"
        fi

        if [[ "$STEPS_CLEANUP" != "" ]] ; then
            eval "$STEPS_CLEANUP"
        fi

        if [[ $exitcode = 0 ]] ; then
            echo -e "${G}${STEPS_INDENT}OK${X}" >&111
            echo -e "${G}${STEPS_PREVIOUS_INDENT}${X}" >&111

            echo ""
            echo "# $( printf '%.0s=' `seq 1 30` )"
            echo ""
        else
            local text="ERROR: $exitcode, script: $LASTEXITSCRIPT, line: $LASTEXITLINENO, cmd: '$LASTEXITCOMMAND' > \"$LASTEXITMESSAGE\""

            echo -e "${R}${STEPS_INDENT}$text${X}" >&111
            echo -e "${G}${STEPS_PREVIOUS_INDENT}${X}" >&111

            echo ""
            echo "#"
            echo "# $text"
            echo "#"
            echo ""

            global LASTEXITTRAPPED="X"
        fi

        rm -f "./_stderr.log" # cleanup 'tee'd file

        global LASTEXITCODE=$exitcode
    else
        if [[ "$STEPS_CLEANUP" != "" ]] ; then
            eval "$STEPS_CLEANUP"
        fi
    fi

    #echo "##### [[ \$LASTEXITCODE = $LASTEXITCODE ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITSCRIPT = $LASTEXITSCRIPT ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITLINENO = $LASTEXITLINENO ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITCOMMAND = $LASTEXITCOMMAND ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITMESSAGE = $LASTEXITMESSAGE ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITTRAPPED = $LASTEXITTRAPPED ]]" #>&111     # for debugging

    exit $exitcode
}
