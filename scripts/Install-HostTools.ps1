#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
param(
    [switch]$Force
)

. .steps.ps1
trap { do_trap }

do_script

#
do_step "Install/upgrade packages"

if ( $Force ) {
    choco upgrade chocolateygui -y
    choco upgrade wget -y
    choco upgrade cURL -y
    choco upgrade openSSL.light -y
    choco upgrade PuTTY -y
    choco upgrade WinSCP -y
    choco upgrade Packer -y
}
else {
    choco upgrade chocolateygui
    choco upgrade wget
    choco upgrade cURL
    choco upgrade openSSL.light
    choco upgrade PuTTY
    choco upgrade WinSCP
    choco upgrade Packer
}

#
do_step "Generate PuTTY-keys"

if ( -not (Test-Path -Path "$ROOT\.certs\putty.pub") ) {
    mkdir "$HOME\kluster\.certs"

    do_echo ""
    do_echo "Please keep this PowerShell running"
    do_echo "Continue in the PuTTY Key Generator window, and close it when finished . . . "
    do_echo ""
    do_echo "- press the Generate button"
    do_echo "- move your cursor around until the green progress bar is complete"
    do_echo "- you can change the key comment.  A typical key comment would be your email address"
    do_echo "- DO NOT put in a key passphrase"
    do_echo "- press the Save public key button"
    do_echo "  - navigate to your $HOME\kluster\.certs folder"
    do_echo "  - save with name 'putty.pub'"
    do_echo "- press the Save private key button"
    do_echo "  - navigate to your $HOME\kluster\.certs folder"
    do_echo "  - save with name 'putty.ppk'"
    do_echo "- you can now close the PuTTY Key Generator window"
    do_echo ""

    puttygen | Out-Default
}

#
do_step "Set 'ShutdownTimeout'-property for Hyper-V"

if ( Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" ) {
    Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name ShutdownTimeout -Value 3000
}

#
do_step "Install vmware.PowerCLI module for PowerShell"

Install-Module -Name vmware.powerCLI -AllowClobber

#
do_exit 0