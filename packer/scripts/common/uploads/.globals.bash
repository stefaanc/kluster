#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/globals
#

restore_nounset="$( shopt -po nounset )"; set +u
if [[ "$GLOBALS_INJECT" = "" ]] ; then 
    # make sure vars are not undefined, in case 'set +u' is set when calling the functions
    GLOBALS_INJECT=""
    LASTEXITCODE=0
fi
eval "$restore_nounset"

global () {
    # format the command to be able to safely eval it
    # and safely send it over the inject-stream
    local name="$( echo "$1" | sed -e 's/=.*$//' )"
    local value="$( echo "$1" | sed -e 's/^[^=]*=//' )"
    local command="$( printf '%q=%q' "$name" "$value" )"

    #echo "#>> \$command=$command"   # for debugging

    # define global variable in this environment
    # and make it available to future child-shells
    eval "export $command"

    if [[ "$GLOBALS_INJECT" != "" ]] ; then
        #echo "#>> \$GLOBALS_INJECT=$GLOBALS_INJECT"   # for debugging
        #echo "#>> \$inject=$command"   # for debugging

        # inject global variable into the environment of the calling script,
        # by sending it to the inject-stream of the calling script
        eval "echo \"$command\" >&${GLOBALS_INJECT}"
    fi
}

call () {
    {
        local injects="$( 
            # setup an inject-stream, redirecting it to the injects-variable,
            # and make the inject-stream available to future child-shells
            exec {GLOBALS_INJECT}>&1
            export GLOBALS_INJECT

            # call the requested command,
            # redirecting its standard output to the alternative-output-stream,
            # to avoid this output ends up in the injects-variable
            {
                local exitcode=0
                bash "$@" || local exitcode=$?   # '||' avoids exiting because of 'errexit' shell attribute
            } 1>&${altout}

            # add the exit-code from the called command to the injects-variable
            echo "LASTEXITCODE=$exitcode"
        )"
    } {altout}>&1 # fold alternative-output-stream back into standard-output-stream

    #echo "#>> \$injects=$injects"   # for debugging

    while read line ; do
        # create/update the global variable with the value from the injects-item
        global "$line"
    done <<< "$injects"

    if [[ ( "$LASTEXITCODE" != "0" ) && ( "$( shopt -po errexit | grep '+o' )" = "" ) ]] ; then
        # exitcode is not 0 and 'errexit' shell attribute is set
        exit $LASTEXITCODE       # sets '$?' and exits calling script
    else
        # exitcode is 0 or 'errexit' shell attribute is not set
        ( exit $LASTEXITCODE )   # sets '$?' without exiting calling script
    fi
}
