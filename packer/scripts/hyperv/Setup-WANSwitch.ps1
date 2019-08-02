#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use in powershell:
#
#    Setup-WANSwitch [ "$SWITCH_WAN" [ "$NETWORK_WAN_NIC" ]]
#
# use in packer:
#
#    "post-processors": [
#        {
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "-NoProfile", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "SWITCH_WAN={{ user `switch_wan` }}",
#                "NETWORK_WAN_NIC"={{ user `network_wan_nic` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_hyperv_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `root` }}/scripts/Setup-WANSwitch.ps1"
#            ]
#        }
#    ]
#
param(
    [parameter(position=0)] $SWITCH_WAN = "$env:SWITCH_WAN",
    [parameter(position=1)] $NETWORK_WAN_NIC = "$env:NETWORK_WAN_NIC",
    [parameter(position=2)] $LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [parameter(position=3)] $TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
)
if ( "$SWITCH_WAN" -eq "" ) { $SWITCH_WAN = "Virtual Switch External" }
if ( "$NETWORK_WAN_NIC" -eq "" ) { $NETWORK_WAN_NIC = ( Get-NetAdapterHardwareInfo )[0].InterfaceDescription }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-wanswitch.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name Hyper-V -Prefix hyv   # covers naming conflicts when using hyper-v and vmware at the same time
$TEARDOWN = ""

#
do_step "Create WAN switch `"$SWITCH_WAN`" if it does not exist yet"

if ( -not ( Get-VMSwitch -Name "$SWITCH_WAN" -ErrorAction Ignore ) ) {
    New-VMSwitch -SwitchName "$SWITCH_WAN" -NetAdapterInterfaceDescription "$NETWORK_WAN_NIC"
    do_echo "Switch `"$SWITCH_WAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove WAN switch ```"$SWITCH_WAN```" if it exists"
if ( Get-VMSwitch -Name "$SWITCH_WAN" -ErrorAction Ignore ) {
    Remove-VMSwitch -Name "$SWITCH_WAN" -Force
    do_echo "Switch ```"$SWITCH_WAN```" removed."
}

"@
        $TEARDOWN = $TEARDOWN_ENTRY + $TEARDOWN
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
