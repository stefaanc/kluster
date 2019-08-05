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
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "-NoProfile", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "SWITCH_LAN={{ user `switch_lan` }}",
#                "NETWORK_LAN={{ user `network_lan` }}"
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_esxi_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/esxi/Setup-LANSwitch.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$REMOTE_HOST = "$env:REMOTE_HOST",
    [string]$REMOTE_USERNAME = "$env:REMOTE_USERNAME",
    [string]$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD",
    [string]$SWITCH_LAN = "$env:SWITCH_LAN",
    [string]$NETWORK_LAN = "$env:NETWORK_LAN",
    [string]$LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [string]$TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
)
if ( "$SWITCH_LAN" -eq "" ) { $SWITCH_LAN = "vSwitch1" }
if ( "$NETWORK_LAN" -eq "" ) { $NETWORK_LAN = "NAT Network" }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-lanswitch.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name VMware.VimAutomation.Core -Prefix vmw   # covers naming conflicts when using hyper-v and vmware at the same time
Connect-VIServer -Server "$REMOTE_HOST" -User "$REMOTE_USERNAME" -Password "$REMOTE_PASSWORD"
$TEARDOWN = ""

#
do_step "Create LAN switch `"$SWITCH_LAN`" if it does not exist yet"

if ( -not (Get-VirtualSwitch -VMHost "$REMOTE_HOST" -Name "$SWITCH_LAN" -ErrorAction Ignore) ) {
    $CMD = "esxcli network vswitch standard add --vswitch-name='$SWITCH_LAN'"
    $ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "Switch `"$SWITCH_LAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove LAN switch ```"$SWITCH_LAN```" if it exists"
if ( Get-VirtualSwitch -VMHost "$REMOTE_HOST" -Name "$SWITCH_LAN" -ErrorAction Ignore ) {
    `$CMD = "esxcli network vswitch standard remove --vswitch-name='$SWITCH_LAN'"
    `$ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
    do_echo "Switch ```"$SWITCH_LAN```" removed."
}

"@
        $TEARDOWN = ($TEARDOWN_ENTRY + $TEARDOWN)
    }
}

#
do_step "Create LAN port group `"$NETWORK_LAN`" if it does not exist yet"

if ( -not (Get-VirtualPortGroup -VMHost "$REMOTE_HOST" -Name "$NETWORK_LAN" -ErrorAction Ignore) ) {
    $CMD = "esxcli network vswitch standard portgroup add --vswitch-name='$SWITCH_LAN' --portgroup-name='$NETWORK_LAN'"
    $ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "LAN port group `"$NETWORK_LAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove LAN port group ```"$NETWORK_LAN```" if it exists"
if ( Get-VirtualPortGroup -VMHost "$REMOTE_HOST" -Name "$NETWORK_LAN" -ErrorAction Ignore ) {
    `$CMD = "esxcli network vswitch standard portgroup remove --vswitch-name='$SWITCH_LAN' --portgroup-name='$NETWORK_LAN'"
    `$ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
    do_echo "LAN port group ```"$NETWORK_LAN```" removed."
}

"@
        $TEARDOWN = ($TEARDOWN_ENTRY + $TEARDOWN)
    }
}

#
if ( "$TEARDOWN_SCRIPT" -ne "" ) {
    do_step "Update tear-down script"

    $TEARDOWN = $TEARDOWN + "`r`n" + ( Get-Content -Raw $TEARDOWN_SCRIPT )
    $TEARDOWN | Out-File -FilePath "$TEARDOWN_SCRIPT" -Force
}

#
do_exit 0
