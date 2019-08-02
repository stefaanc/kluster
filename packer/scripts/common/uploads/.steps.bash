#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/steps
#

set -eu -o pipefail -o errtrace

. "$( dirname ${BASH_SOURCE[0]} )/.globals.bash"

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
    export N=${colors[0]}; export B=${colors[1]}; export G=${colors[2]}; export Y=${colors[3]}; export R=${colors[4]}; export X=${colors[5]};
    #        normal    ;            bright    ;            green     ;            yellow    ;            red       ;            reset
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
        if [[ "$STEPS_LOG_APPEND" = "" ]] ; then
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
        if [[ "$STEPS_LOG_APPEND" = "" ]] ; then 
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

do_reset () {
    #echo '##### do_reset' #>&111     # for debugging
    global LASTEXITCODE=0
    global LASTEXITSCRIPT=""
    global LASTEXITCOMMAND=""
    global LASTEXITLINENO=""
    global LASTEXITMESSAGE=""
    global LASTEXITTRAPPED=""
}

do_echo () {
    message=${1:-$(</dev/stdin)}
    #echo '##### do_echo' #>&111     # for debugging

    OLDIFS=$IFS; IFS=$'\n'
    while read -r line ; do
        echo -e "${B}${STEPS_INDENT}.   $line${X}" >&111
        echo "# $line"
    done <<< "$message"
    IFS=$OLDIFS
}

do_exit () {
    local exitcode=$1
    local command="$BASH_COMMAND"   # capture command here so not overwritten by the code in this function
    #echo '##### do_exit' #>&111     # for debugging

    if [[ $exitcode != 99999 ]] ; then 
        # called directly
        #echo "##### 1" #>&111     # for debugging
        global LASTEXITSCRIPT="${BASH_SOURCE[1]}"
        local lineno="${BASH_LINENO[1]}"   # this always will be '0' when trapped in 'main'
        if [[ $lineno = "0" ]] ; then local lineno="--" ; fi
        global LASTEXITLINENO=$lineno
        global LASTEXITCOMMAND="do_exit $exitcode"
        global LASTEXITMESSAGE="exited with exitcode $exitcode"
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
    #echo '##### do_trap' #>&111     # for debugging

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
    fi

    #echo "##### [[ \$LASTEXITCODE = $LASTEXITCODE ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITSCRIPT = $LASTEXITSCRIPT ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITLINENO = $LASTEXITLINENO ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITCOMMAND = $LASTEXITCOMMAND ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITMESSAGE = $LASTEXITMESSAGE ]]" #>&111     # for debugging
    #echo "##### [[ \$LASTEXITTRAPPED = $LASTEXITTRAPPED ]]" #>&111     # for debugging

    exit $exitcode
}

trap 'do_exit 99999 $? "$LINENO"' ERR
trap 'do_trap' EXIT
