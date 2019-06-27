#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#

. .steps.ps1
trap { do_trap }

#do_script
do_script

#
& Install-Chocolatey
& Install-HostTools -Force

#
Wait-Key

#
do_exit 0