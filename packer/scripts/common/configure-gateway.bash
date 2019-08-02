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
#                "VM_NAME={{ user `vm_name` }}",
#                "ADAPTER_LAN_DEVICE=eth1",
#                "ADAPTER_LAN_MAC=00:00:02:00:01:01",
#                "IP_DOMAIN={{ user `ip_domain` }}",
#                "IP_ADDRESS_GATEWAY={{ user `ip_address_gateway` }}",
#                "IP_PREFIX={{ user `ip_prefix` }}",
#                "STEPS_COLORS={{ user `packer_common_colors` }}"
#            ],
#            "remote_file": "configure-gateway.bash",
#            "script": "{{ user `packer` }}/scripts/common/configure-gateway.bash"
#        },
#        {
#            "type": "file",
#            "source": "/tmp/configure-gateway.log",
#            "destination": "{{ user `packer` }}/logs/{{ isotime \"20060102T150405.0000Z\" }}_configure-gateway.log",
#            "direction": "download"
#        }
#    ]
#

STEPS_LOG_FILE="/tmp/$( basename ${BASH_SOURCE[0]} .bash ).log"
STEPS_LOG_APPEND=""

. "/tmp/.steps.bash"

do_script

#
do_step "Set hostname"
### reference: https://www.itzgeek.com/how-tos/linux/centos-how-tos/change-hostname-in-centos-7-rhel-7.html

hostnamectl set-hostname "$VM_NAME.$IP_DOMAIN"

#
do_step "Reset SSH server certificates"
### reference: https://www.altaro.com/hyper-v/ubuntu-linux-server-hyper-v-guest

rm /etc/ssh/ssh_host_*
ssh-keygen -A

#
do_step "Configure LAN adapter"

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

#
do_exit 0
