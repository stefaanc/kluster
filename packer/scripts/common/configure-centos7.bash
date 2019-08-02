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
#            "remote_file": "configure-centos7.bash",
#            "script": "{{ user `packer` }}/scripts/common/configure-centos7.bash"
#        },
#        {
#            "type": "file",
#            "source": "/tmp/configure-centos7.log",
#            "destination": "{{ user `packer` }}/logs/{{ isotime \"20060102T150405.0000Z\" }}_configure-centos7.log",
#            "direction": "download"
#        }
#    ]
#

### reference: https://docs.microsoft.com/en-gb/windows-server/virtualization/hyper-v/supported-centos-and-red-hat-enterprise-linux-virtual-machines-on-hyper-v
### reference: https://docs.microsoft.com/en-gb/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v
### reference: https://www.altaro.com/hyper-v/centos-linux-hyper-v
### reference: https://vmexpo.wordpress.com/2016/06/16/virtual-machine-template-guidelines-for-vmware-redhatcentos-linux-7-x/
### remark that essentials are done in kickstart's '%post'

STEPS_LOG_FILE="/tmp/$( basename ${BASH_SOURCE[0]} .bash ).log"
STEPS_LOG_APPEND=""

. "/tmp/.steps.bash"

do_script

#
do_step "Setup 'cron' jobs"

cat <<EOF > /var/spool/cron/root
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
MAILTO=root

@reboot chronyc makestep                               ### https://www.systutorials.com/docs/linux/man/1-chronyc/
@reboot echo 'noop' > /sys/block/sda/queue/scheduler   ### https://access.redhat.com/solutions/5427
EOF
chmod 600 /var/spool/cron/root

#
do_step "Change minimum UID and GID for non-system users"
### reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-managing_users_and_groups

sed -i 's/^UID_MIN.*/UID_MIN                  5000/' /etc/login.defs
sed -i 's/^GID_MIN.*/GID_MIN                  5000/' /etc/login.defs

#
do_step "Enable 'epel' repository for 'yum' (needed fot bash-completion-extras)"
### reference: https://www.tecmint.com/how-to-enable-epel-repository-for-rhel-centos-6-5/

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#
do_step "Update/upgrade installed packages"

do_echo "The update/upgrade will take a while."
yum -y install deltarpm
yum -y update && yum -y upgrade &
PID=$!
while [[ -d /proc/$PID ]] ; do
    do_echo "Waiting for update/upgrade to complete..."
    sleep 15
done
wait $PID   # trigger trap if exitcode not 0

#
do_step "Install packages"

do_echo "net-tools"
yum -y install net-tools                ### for old-style tools like 'ifconfig'
do_echo "bind-utils"
yum -y install bind-utils               ### for old=style tools like 'nslookup'
do_echo "wget"
yum -y install wget
do_echo "nano"
yum -y install nano
do_echo "mailx"
yum -y install mailx
do_echo "bash-completion"
yum -y install bash-completion
do_echo "bash-completion-extras"
yum -y install bash-completion-extras   ### requires epel repository

#
do_step "Clean-up 'yum'"
yum clean all

#
do_exit 0
