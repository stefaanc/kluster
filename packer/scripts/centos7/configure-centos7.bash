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
#            "environment_vars": [],
#            "scripts": [
#                "{{ user `packer` }}/scripts/centos7/configure-centos7.bash"
#            ]
#        }
#    ]
#

### reference: https://docs.microsoft.com/en-gb/windows-server/virtualization/hyper-v/supported-centos-and-red-hat-enterprise-linux-virtual-machines-on-hyper-v
### reference: https://docs.microsoft.com/en-gb/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v
### reference: https://www.altaro.com/hyper-v/centos-linux-hyper-v
### reference: https://vmexpo.wordpress.com/2016/06/16/virtual-machine-template-guidelines-for-vmware-redhatcentos-linux-7-x/
### remark that essentials are done in kickstart's '%post'

echo ""
echo "#"
echo "# setup cron jobs"
echo "#"

cat <<EOF > /var/spool/cron/root
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
MAILTO=root

@reboot chronyc makestep                               ### https://www.systutorials.com/docs/linux/man/1-chronyc/
@reboot echo 'noop' > /sys/block/sda/queue/scheduler   ### https://access.redhat.com/solutions/5427
EOF
chmod 600 /var/spool/cron/root

### reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-managing_users_and_groups
echo ""
echo "#"
echo "# change minimum uid and gid for non-system users"
echo "#"

sed -i 's/^UID_MIN.*/UID_MIN                  5000/' /etc/login.defs
sed -i 's/^GID_MIN.*/GID_MIN                  5000/' /etc/login.defs

### reference: https://www.tecmint.com/how-to-enable-epel-repository-for-rhel-centos-6-5/
echo ""
echo "#"
echo "# enable epel repository for yum (needed fot bash-completion-extras)"
echo "#"

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo ""
echo "#"
echo "# yum update/upgrade"
echo "#"

yum -y install deltarpm
yum -y update
yum -y upgrade

echo ""
echo "#"
echo "# install net-tools, bind-utils, wget, nano, mailx, bash-completion"
echo "#"

yum -y install net-tools                ### for old-style tools like 'ifconfig'
yum -y install bind-utils               ### for old=style tools like 'nslookup'
yum -y install wget
yum -y install nano
yum -y install mailx
yum -y install bash-completion
yum -y install bash-completion-extras   ### requires epel repository
yum clean all
