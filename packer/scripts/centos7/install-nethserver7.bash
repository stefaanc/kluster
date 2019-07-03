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
#            "expect_disconnect": true,
#            "scripts": [
#                "{{ user `packer` }}/scripts/centos7/install-nethserver7.bash"
#            ]
#        }
#    ]
#

echo ""
echo "#"
echo "# Install nethserver7"
echo "#"

yum -y install http://mirror.nethserver.org/nethserver/nethserver-release-7.rpm
nethserver-install
if [ $(virt-what) == "hyperv" ] ; then
    shutdown -r now   # solving hyperv-issue with eth0 being dropped after install
fi
