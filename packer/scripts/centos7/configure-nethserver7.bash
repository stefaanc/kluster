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
#            "type": "shell",
#            "environment_vars": [
#                "ADAPTER_WAN_DEVICE=eth0",
#                "ADAPTER_LAN_DEVICE=eth1",
#                "IP_DOMAIN={{ user `ip_domain` }}",
#                "IP_ADDRESS_GATEWAY={{ user `ip_address_gateway` }}",
#                "IP_PREFIX={{ user `ip_prefix` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/centos7/configure-nethserver7.bash"
#            ]
#        }
#    ]
#

echo ""
echo "#"
echo "# Give 'red' role to WAN network"
echo "#"

db networks setprop "$ADAPTER_WAN_DEVICE" role red
signal-event interface-update

echo ""
echo "#"
echo "# Setup DCHP for LAN network"
echo "#"

IPBASE=$( echo "$IP_ADDRESS_GATEWAY" | sed -e 's/\.[0-9]*$//' )
db dhcp set "$ADAPTER_LAN_DEVICE" range status enabled DhcpDomain "$IP_DOMAIN" DhcpRangeStart "$IPBASE.2" DhcpRangeEnd "$IPBASE.199" DhcpLeaseTime 86400

#
# Update HTTPS certificates
#

#db configuration setprop pki CrtFile /path/to/your/server.crt
#db configuration setprop pki KeyFile /path/to/your/server.key
#signal-event certificate-update
