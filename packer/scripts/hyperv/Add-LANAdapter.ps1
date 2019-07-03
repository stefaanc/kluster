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
#                "VM_NAME={{ user `vm_name` }}",
#                "SWITCH_LAN={{ user `switch_lan` }}",
#                "ADAPTER_LAN_MAC=00:00:02:00:01:01",
#                "LOG_DIRECTORY={{ user `packer` }}/logs"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/hyperv/Add-LANAdapter.ps1"
#            ]
#        }
#    ]
#
param(
    [parameter(position=0)] $VM_NAME = "$env:VM_NAME",
    [parameter(position=1)] $SWITCH_LAN = "$env:SWITCH_LAN",
    [parameter(position=2)] $ADAPTER_LAN_MAC = "$env:ADAPTER_LAN_MAC",
    [parameter(position=3)] $LOG_DIRECTORY = "$env:LOG_DIRECTORY"
)
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$PACKER_ROOT\logs" }

# save params for second '.steps' pass
$STEPS_PARAMS = @{
    VM_NAME = $VM_NAME
    SWITCH_LAN = $SWITCH_LAN
    ADAPTER_LAN_MAC = $ADAPTER_LAN_MAC
    LOG_DIRECTORY = $LOG_DIRECTORY
}

$STEPS_LOG_FILE = "$LOG_DIRECTORY\add_lanadapter_$( Get-Date -Format yyyyMMddTHHmmssffffZ ).log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name Hyper-V -Prefix hyv   # covers naming conflicts when using hyper-v and vmware at the same time

#
if ( ( Get-hyvVM -VMName "$env:VM_NAME" ).Generation -eq 1 ) {
    do_step "Stop generation 1 VM, not needed for generation 2 VM"

    Stop-hyvVM -VMName "$env:VM_NAME"
}

#
do_step "Add adapter for LAN switch `"$env:SWITCH_LAN`" to VM `"$env:VM_NAME`""

Add-VMNetworkAdapter -VMName "$env:VM_NAME" -SwitchName "$env:SWITCH_LAN" -StaticMacAddress "$env:ADAPTER_LAN_MAC"

#
if ( ( Get-hyvVM -VMName "$env:VM_NAME" ).Generation -eq 1 ) {
    do_step "Start generation 1 VM, not needed for generation 2 VM"

    Start-hyvVM -VMName "$env:VM_NAME"
}

#
do_exit 0
