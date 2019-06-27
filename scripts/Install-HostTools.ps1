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
do_step "Install/upgrade chocolatey packages"

if ( $Force ) {
    do_echo "chocolateygui"
    choco upgrade chocolateygui -y
    do_echo "wget"
    choco upgrade wget -y
    do_echo "cURL"
    choco upgrade cURL -y
    do_echo "openSSL.light"
    choco upgrade openSSL.light -y
    do_echo "PuTTY"
    choco upgrade PuTTY -y
    do_echo "WinSCP"
    choco upgrade WinSCP -y
    do_echo "packer"
    choco upgrade packer -y
}
else {
    do_echo "chocolateygui"
    choco upgrade chocolateygui
    do_echo "wget"
    choco upgrade wget
    do_echo "cURL"
    choco upgrade cURL
    do_echo "openSSL.light"
    choco upgrade openSSL.light
    do_echo "PuTTY"
    choco upgrade PuTTY
    do_echo "WinSCP"
    choco upgrade WinSCP
    do_echo "packer"
    choco upgrade Packer
}

#
do_step "Install/upgrade powershell modules"

# we cannot install "vmware.PowerCLI" via chocolatey
# because we need the -AllowClobber option to ignore collisions with the hyper-v module
do_echo "vmware.PowerCLI"
$installed = Get-InstalledModule -Name vmware.powerCLI
$found = Find-Module -Name vmware.powerCLI
if ( $installed -and ( $installed.Version.ToString() -ne $found.Version.ToString() ) ) {
    Uninstall-Module -Name vmware.powerCLI
    $installed = $null
}
if ( !$installed ) {
    if ( $Force ) {
        Install-Module -Name vmware.powerCLI -AllowClobber -Force
    }
    else {
        Install-Module -Name vmware.powerCLI -AllowClobber
    }
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
do_exit 0