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
#                "VM_NAME={{ user `vm_name` }}",
#                "ADAPTER_LAN_DEVICE=eth1",
#                "ADAPTER_LAN_MAC=00:00:02:00:01:01",
#                "IP_DOMAIN={{ user `ip_domain` }}",
#                "IP_ADDRESS_GATEWAY={{ user `ip_address_gateway` }}",
#                "IP_PREFIX={{ user `ip_prefix` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/centos7/configure-gateway.bash"
#            ]
#        }
#    ]
#

# reference: https://www.itzgeek.com/how-tos/linux/centos-how-tos/change-hostname-in-centos-7-rhel-7.html
echo ""
echo "#"
echo "# Set hostname"
echo "#"

hostnamectl set-hostname "$VM_NAME.$IP_DOMAIN"

# reference: https://www.altaro.com/hyper-v/ubuntu-linux-server-hyper-v-guest
echo ""
echo "#"
echo "# Reset SSH server certificates"
echo "#"

rm /etc/ssh/ssh_host_*
ssh-keygen -A

echo ""
echo "#"
echo "# Configure LAN adapter"
echo "#"

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-"$ADAPTER_LAN_DEVICE"
DEVICE=$ADAPTER_LAN_DEVICE
HWADDR=$ADAPTER_LAN_MAC
TYPE=Ethernet
BOOTPROTO=none
IPADDR=$IP_ADDRESS_GATEWAY
PREFIX=$IP_PREFIX
ONBOOT=yes
EOF
ifup $ADAPTER_LAN_DEVICE
