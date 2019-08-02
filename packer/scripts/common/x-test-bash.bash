#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use in packer:
#
#    "provisioners": [
#        {
#            "type": "file",
#            "source": "{{ user `packer` }}/scripts/common/uploads/",
#            "destination": "/tmp/"
#        },
#        {
#            "type": "shell",
#            "environment_vars": [
#                "STEPS_COLORS={{ user `packer_common_colors` }}"
#            ],
#            "remote_file": "_test.bash",
#            "script": "{{ user `packer` }}/scripts/common/_test.bash"
#        },
#        {
#            "type": "file",
#            "source": "/tmp/_test.log",
#            "destination": "{{ user `packer` }}/logs/{{ isotime \"20060102T150405.0000Z\" }}_x-test-bash.log",
#            "direction": "download"
#        }
#    ]
#

STEPS_LOG_FILE="/tmp/$( basename ${BASH_SOURCE[0]} .bash ).log"
STEPS_LOG_APPEND=""

. "/tmp/.steps.bash"

do_script

#
do_step "Test"

ip_addresses=$( \
    ifconfig \
    | grep '^\w' \
    | sed -e 's/:.*//' \
    | grep -v '^lo$' \
    | xargs -d '\n' -n1 ifconfig \
    | grep ' inet ' \
    | awk '{ print $2 }' \
)

do_echo "You can access 'nethserver' at:"
do_echo "- https://$( hostname ):980"
while read -r ip_address ; do 
    do_echo "- https://$ip_address:980"
done <<< "$ip_addresses"

#
do_exit 0
