#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#

if [[ -f "/tmp/recover_111.txt" ]] ; then
    cat "/tmp/recover_111.txt"

    exitcode=$( tail -n 2 "/tmp/recover_111.txt" | grep "ERROR:" | sed -e "s|^.*ERROR:\s*||" -e "s|,.*$||" )
    if [[ "$exitcode" != "" ]] ; then
        exit $exitcode
    fi

    rm -f "/tmp/recover_111.txt"
fi

exit 0
