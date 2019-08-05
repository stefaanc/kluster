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
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "SWITCH_WAN={{ user `switch_wan` }}",
#                "NETWORK_WAN={{ user `network_wan` }}",
#                "NETWORK_WAN_NIC={{ user `network_wan_nic` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_esxi_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/esxi/Setup-WANSwitch.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$REMOTE_HOST = "$env:REMOTE_HOST",
    [string]$REMOTE_USERNAME = "$env:REMOTE_USERNAME",
    [string]$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD",
    [string]$SWITCH_WAN = "$env:SWITCH_WAN",
    [string]$NETWORK_WAN = "$env:NETWORK_WAN",
    [string]$NETWORK_WAN_NIC = "$env:NETWORK_WAN_NIC",
    [string]$LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [string]$TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
)
if ( "$SWITCH_WAN" -eq "" ) { $SWITCH_LAN = "vSwitch0" }
if ( "$SWITCH_WAN" -eq "" ) { $SWITCH_LAN = "vSwitch0" }
if ( "$SWITCH_WAN" -eq "" ) { $SWITCH_LAN = "vSwitch0" }
if ( "$NETWORK_LAN" -eq "" ) { $NETWORK_LAN = "WAN Network" }
if ( "$NETWORK_LAN_NIC" -eq "" ) { $NETWORK_LAN_NIC = "vmnic0" }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-wanswitch.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name VMware.VimAutomation.Core -Prefix vmw   # covers naming conflicts when using hyper-v and vmware at the same time
Connect-VIServer -Server "$REMOTE_HOST" -User "$REMOTE_USERNAME" -Password "$REMOTE_PASSWORD"
$TEARDOWN = ""

#
do_step "Create WAN switch `"$SWITCH_WAN`" if it does not exist yet"

if ( -not (Get-VirtualSwitch -VMHost "$REMOTE_HOST" -Name "$SWITCH_WAN" -ErrorAction Ignore) ) {
    $CMD =          "esxcli network vswitch standard add --vswitch-name='$SWITCH_WAN'"
#    $CMD = $CMD + "; esxcli network vswitch standard uplink add --vswitch-name='$SWITCH_WAN' --uplink-name='$NETWORK_WAN_NIC'"
    $ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "Switch `"$SWITCH_WAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove WAN switch ```"$SWITCH_WAN```" if it exists"
if ( Get-VirtualSwitch -VMHost "$REMOTE_HOST" -Name "$SWITCH_WAN" -ErrorAction Ignore ) {
    `$CMD = "esxcli network vswitch standard remove --vswitch-name='$SWITCH_WAN'"
    `$ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
    do_echo "Switch ```"$SWITCH_WAN```" removed."
}

"@
        $TEARDOWN = ($TEARDOWN_ENTRY + $TEARDOWN)
    }
}

#
do_step "Create WAN port group `"$NETWORK_WAN`" if it does not exist yet"

if ( -not (Get-VirtualPortGroup -VMHost "$REMOTE_HOST" -Name "$NETWORK_WAN" -ErrorAction Ignore) ) {
    $CMD = "esxcli network vswitch standard portgroup add --vswitch-name='$SWITCH_WAN' --portgroup-name='$NETWORK_WAN'"
    $ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "WAN port group `"$NETWORK_WAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove WAN port group ```"$NETWORK_WAN```" if it exists"
if ( Get-VirtualPortGroup -VMHost "$REMOTE_HOST" -Name "$NETWORK_WAN" -ErrorAction Ignore ) {
    `$CMD = "esxcli network vswitch standard portgroup remove --vswitch-name='$SWITCH_WAN' --portgroup-name='$NETWORK_WAN'"
    `$ErrorActionPreference = 'Continue'
    plink -no-antispoof -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
    do_echo "WAN port group ```"$NETWORK_WAN```" removed."
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
