#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
$STEPS_LOG_FILE = "$ROOT\logs\prepare-klusterenvironment_$( Get-Date -Format yyyyMMddTHHmmssffffZ ).log"

. "$(Split-Path -Path $script:MyInvocation.MyCommand.Path)/.steps.ps1"
trap { do_trap }

do_script

#
& Install-Chocolatey
& Install-HostTools -Force

#
do_exit 0