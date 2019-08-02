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
#            "environment_vars": [
#                "ADAPTER_WAN_DEVICE=eth0",
#                "ADAPTER_LAN_DEVICE=eth1",
#                "IP_DOMAIN={{ user `ip_domain` }}",
#                "IP_ADDRESS_GATEWAY={{ user `ip_address_gateway` }}",
#                "IP_PREFIX={{ user `ip_prefix` }}",
#                "STEPS_COLORS={{ user `packer_common_colors` }}"
#            ],
#            "remote_file": "configure-nethserver7.bash",
#            "script": "{{ user `packer` }}/scripts/common/configure-nethserver7.bash"
#        },
#        {
#            "type": "file",
#            "source": "/tmp/configure-nethserver7.log",
#            "destination": "{{ user `packer` }}/logs/{{ isotime \"20060102T150405.0000Z\" }}_configure-nethserver7.log
#        }
#    ]
#

STEPS_LOG_FILE="/tmp/$( basename ${BASH_SOURCE[0]} .bash ).log"
STEPS_LOG_APPEND=""

. "/tmp/.steps.bash"

do_script

#
do_step "Give 'red' role to WAN network"

db networks setprop "$ADAPTER_WAN_DEVICE" role red
signal-event interface-update

#
do_step "Setup DCHP for LAN network"

IPBASE=$( echo "$IP_ADDRESS_GATEWAY" | sed -e 's/\.[0-9]*$//' )
db dhcp set "$ADAPTER_LAN_DEVICE" range status enabled DhcpDomain "$IP_DOMAIN" DhcpRangeStart "$IPBASE.2" DhcpRangeEnd "$IPBASE.199" DhcpLeaseTime 86400

#
#do_step "Update HTTPS certificates"

#db configuration setprop pki CrtFile /path/to/your/server.crt
#db configuration setprop pki KeyFile /path/to/your/server.key
#signal-event certificate-update

#
do_exit 0
