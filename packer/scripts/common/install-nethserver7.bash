#!/bin/bash
#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    "provisioners": [
#        {
#            "type": "file",
#            "source": "{{ user `packer` }}/scripts/common/uploads/",
#            "destination": "/tmp/"
#        },
#        {
#            "type": "shell",
#            "expect_disconnect": true,
#            "environment_vars": [
#                "STEPS_COLORS={{ user `packer_common_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/common/install-nethserver7.bash",
#                "{{ user `packer` }}/scripts/common/recover-install-nethserver7.bash"
#            ]
#        },
#        {
#            "type": "file",
#            "source": "/tmp/install-nethserver7.log",
#            "destination": "{{ user `packer` }}/logs/{{ isotime \"20060102T150405.0000Z\" }}_install-nethserver7.log",
#            "direction": "download"
#        }
#    ]
#

STEPS_LOG_FILE="/tmp/$( basename ${BASH_SOURCE[0]} .bash ).log"
STEPS_LOG_APPEND=""

. "/tmp/.steps.bash"

do_script

#
do_step "Install nethserver7"

do_echo "The installation will take a while."
if [[ "$( virt-what )" = "hyperv" ]] ; then
    # 'eth0' is dropped during nethserver installation, so connection to packer is lost
    do_echo "At the end, we will briefly loose contact with the virtual machine." 
    do_echo "Please wait for the machine to reboot and the connection to recover."
fi

# capture the IP-addresses of the interfaces before we loose 'eth0' (see hyperv-issue below)
ip_addresses=$( \
    ifconfig \
    | grep '^\w' \
    | sed -e 's/:.*//' \
    | grep -v '^lo$' \
    | xargs -d '\n' -n1 ifconfig \
    | grep ' inet ' \
    | awk '{ print $2 }' \
)

yum -y install http://mirror.nethserver.org/nethserver/nethserver-release-7.rpm

nethserver-install &
PID=$!
while [[ -d /proc/$PID ]] ; do
    do_echo "Waiting for installation to complete..."
    sleep 15
done
if [[ "$( virt-what )" = "hyperv" ]] ; then
    # 'eth0' is dropped during nethserver installation, so connection to packer is NOW lost
    # saving the remaining '111'-output to file, so we can recover it later
    exec 111> /tmp/recover_111.txt
    ### reference: https://community.nethserver.org/t/issues-with-7-6-and-hyperv-16/11502/30
    # wait 1 second to finish the script, then reboot to recover 'eth0'
    do_cleanup 'sleep 1 && shutdown -r now &'
fi
wait $PID   # trigger trap if exitcode not 0

#
do_echo "You can access 'nethserver' at:"
do_echo "- https://$( hostname ):980"
while read -r ip_address ; do 
    do_echo "- https://$ip_address:980"
done <<< "$ip_addresses"

#
do_exit 0
