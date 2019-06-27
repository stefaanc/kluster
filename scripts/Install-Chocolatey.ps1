#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#

. .steps.ps1
trap { do_trap }

do_script

#
do_step "Install Chocolatey"

if ( -not (Test-Path -Path "$HOMEDRIVE/ProgramData/chocolatey") ) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

#
do_exit 0