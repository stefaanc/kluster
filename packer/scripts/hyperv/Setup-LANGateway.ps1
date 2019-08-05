#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use in powershell:
#
#    Setup-LANSwitch [ "$SWITCH_LAN" [ "$IP_ADDRESS_HOST" [ "$IP_PREFIX" ]]]
#
# use in packer:
#
#    "provisioners": [
#        {
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "-NoProfile", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "TEMPLATE_DIRECTORY={{ user `root` }}/{{ user `datastore` }}/{{ user `template_directory` }}",
#                "VM_ROOT={{ user `root` }}/{{ user `datastore` }}",
#                "VM_NAME={{ user `vm_name` }}",
#                "IP_ADDRESS_LAN={{ user `ip_address_lan` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_hyperv_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/hyperv/Setup-LANGateway.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$TEMPLATE_DIRECTORY = "$env:TEMPLATE_DIRECTORY",
    [string]$VM_ROOT = "$env:VM_ROOT",
    [string]$VM_NAME = "$env:VM_NAME",
    [string]$IP_ADDRESS_LAN_GATEWAY = "$env:IP_ADDRESS_LAN_GATEWAY",
    [string]$LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [string]$TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
)
if ( "$TEMPLATE_DIRECTORY" -eq "" ) { $TEMPLATE_DIRECTORY = "$ROOT\datastore\templates\nethserver7" }
if ( "$VM_ROOT" -eq "" ) { $VM_ROOT = "$ROOT\datastore" }
if ( "$VM_NAME" -eq "" ) { $VM_NAME = "gateway-hyv" }
if ( "$IP_ADDRESS_LAN_GATEWAY" -eq "" ) { $IP_ADDRESS_IP_GATEWAY = "192.168.0.17" }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-langateway.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name Hyper-V -Prefix hyv   # covers naming conflicts when using hyper-v and vmware at the same time
$TEARDOWN = ""

#
do_step "Import VM `"$VM_NAME`" if it does not exist yet"

if ( -not ( Get-hyvVM -Name "$VM_NAME" -ErrorAction Ignore ) ) {
    $VM_DIRECTORY = "$VM_ROOT\$VM_NAME"
    $GUID = ( Get-ChildItem "$TEMPLATE_DIRECTORY\Virtual Machines\*.vmcx" ).Name.split(".")[0]
    Remove-Item -Recurse "$VM_DIRECTORY" -ErrorAction Ignore
    Import-VM -Path "$TEMPLATE_DIRECTORY\Virtual Machines\$GUID.vmcx" -Copy -VirtualMachinePath "$VM_DIRECTORY" -VhdDestinationPath "$VM_DIRECTORY\Virtual Hard Disks"
    do_echo "VM `"$VM_NAME`" imported."

    # Prepare tear-down script
    $TEARDOWN_ENTRY = @"
do_step "Remove VM ```"$VM_NAME```" if it exists"
if ( Get-hyvVM -Name "$VM_NAME" -ErrorAction Ignore ) {
    Remove-hyvVM -Name "$VM_NAME" -Force
    do_echo "VM ```"$VM_NAME```" removed."
}
Remove-Item -Recurse "$VM_DIRECTORY" -ErrorAction Ignore

"@
    $TEARDOWN = $TEARDOWN_ENTRY + $TEARDOWN
}

#
do_step "Start VM `"$VM_NAME`" if it is not running yet"

if ( ( Get-hyvVM -Name "$VM_NAME" ).State -ne 'Running' ) {
    Start-hyvVM -Name "$VM_NAME"
    do_echo "VM `"$VM_NAME`" started."

    # Prepare tear-down script
    $TEARDOWN_ENTRY = @"
do_step "Stop VM ```"$VM_NAME```" if it is running"
if ( ( Get-hyvVM -Name "$VM_NAME" -ErrorAction Ignore ) -and ( ( Get-hyvVM -Name "$VM_NAME" ).State -eq 'Running' ) ) {
    Stop-hyvVM -Name "$VM_NAME" -Force
    do_echo "VM ```"$VM_NAME```" stopped."
}

"@
    $TEARDOWN = $TEARDOWN_ENTRY + $TEARDOWN
}

#
do_step "Wait for VM `"$VM_NAME`" to become reachable"

do {
    sleep 5
    do_echo "Waiting for the VM to become reachable..."
    ping $IP_ADDRESS_LAN_GATEWAY
} until ( "$LASTEXITCODE" -eq "0" )

#
if ( "$TEARDOWN_SCRIPT" -ne "" ) {
    do_step "Update tear-down script"

    $TEARDOWN = $TEARDOWN + "`r`n" + ( Get-Content -Raw $TEARDOWN_SCRIPT )
    $TEARDOWN | Out-File -FilePath "$TEARDOWN_SCRIPT" -Force
}

#
do_exit 0
