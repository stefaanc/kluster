#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#

param(
    [switch]$Force
)

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
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
#    do_echo "openSSL.light"
#    choco upgrade openSSL.light -y
    do_echo "PuTTY"
    choco upgrade PuTTY -y
    do_echo "WinSCP"
    choco upgrade WinSCP -y
    do_echo "packer"
    choco upgrade packer -y
    do_echo "terraform"
    choco upgrade terraform -y
#    do_echo "terragrunt"
#    choco upgrade terragrunt -y
}
else {
    do_echo "chocolateygui"
    choco upgrade chocolateygui
    do_echo "wget"
    choco upgrade wget
    do_echo "cURL"
    choco upgrade cURL
#    do_echo "openSSL.light"
#    choco upgrade openSSL.light
    do_echo "PuTTY"
    choco upgrade PuTTY
    do_echo "WinSCP"
    choco upgrade WinSCP
    do_echo "packer"
    choco upgrade Packer
    do_echo "terraform"
    choco upgrade terraform
#    do_echo "terragrunt"
#    choco upgrade terragrunt
}

#
do_step "Install/upgrade powershell modules"

# we cannot install "VMware.PowerCLI" via chocolatey
# because we need the -AllowClobber option to ignore collisions with the hyper-v module
do_echo "VMware.PowerCLI"
$installed = Get-InstalledModule -Name VMware.powerCLI -ErrorAction 'Continue'
$found = Find-Module -Name VMware.powerCLI
if ( $installed -and ( $installed.Version.ToString() -ne $found.Version.ToString() ) ) {
    Uninstall-Module -Name VMware.powerCLI -Force
    $installed = $null
}
if ( !$installed ) {
    do_echo -Color Yellow ".   This may take a while, up to 15 minutes."
    if ( $Force ) {
        $job = Start-Job {
            Install-Module -Name VMware.powerCLI -Scope CurrentUser -AllowClobber -Force
        }
    }
    else {
        $job = Start-Job {
            Install-Module -Name VMware.powerCLI -Scope CurrentUser -AllowClobber
        }
    }
    do_cleanup '$job | Remove-Job'

    while ( ( $job.State -ne "Completed" ) -and ( $job.State -ne "Failed" ) ) {
        do_echo -Color Yellow ".   Waiting for the installation to complete..."
        Start-Sleep 60
    }

    try {
        Receive-Job -Job $job | do_echo
    }
    catch {
        do_exit $_.Exception.Message
    }
}

#
do_step "Generate PuTTY-keys"

if ( -not ( Test-Path -Path "$ROOT\.ssh" ) ) {
    New-Item -Type 'directory' -Path "$ROOT\.ssh"
}
if ( -not ( Test-Path -Path "$ROOT\.ssh\putty.pub" ) ) {

    do_echo ""
    do_echo "Please keep this PowerShell running"
    do_echo "Continue in the PuTTY Key Generator window, and close it when finished . . . "
    do_echo ""
    do_echo "- press the Generate button"
    do_echo "- move your cursor around until the green progress bar is complete"
    do_echo "- you can change the key comment.  A typical key comment would be your email address"
    do_echo "- DO NOT put in a key passphrase"
    do_echo "- press the Save public key button"
    do_echo "  - navigate to your $ROOT\.ssh folder"
    do_echo "  - save with name 'putty.pub'"
    do_echo "- press the Save private key button"
    do_echo "  - navigate to your $ROOT\.ssh folder"
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
