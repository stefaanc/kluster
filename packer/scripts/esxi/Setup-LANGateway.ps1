#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    "post-processors": [
#        {
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "-NoProfile", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "TEMPLATE_DIRECTORY={{ user `template_directory` }}",
#                "VM_NAME={{ user `vm_name` }}",
#                "IP_ADDRESS_LAN_GATEWAY={{ user `ip_address_lan_gateway` }}",
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "REMOTE_DATASTORE={{ user `remote_datastore` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_esxi_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/esxi/Setup-LANGateway.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$TEMPLATE_DIRECTORY = "$env:TEMPLATE_DIRECTORY",
    [string]$VM_NAME = "$env:VM_NAME",
    [string]$IP_ADDRESS_LAN_GATEWAY = "$env:IP_ADDRESS_LAN_GATEWAY"
)
if ( "$TEMPLATE_DIRECTORY" -eq "" ) { $TEMPLATE_DIRECTORY = "$ROOT\datastore\templates\nethserver7" }
if ( "$VM_NAME" -eq "" ) { $VM_NAME = "gateway-hyv" }

$REMOTE_HOST = "$env:REMOTE_HOST"
$REMOTE_USERNAME = "$env:REMOTE_USERNAME"
$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD"
$REMOTE_DATASTORE = "$env:REMOTE_DATASTORE"
$LOG_DIRECTORY = "$env:LOG_DIRECTORY"
$TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-langateway.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name VMware.VimAutomation.Core -Prefix vmw   # covers naming conflicts when using hyper-v and vmware at the same time
Connect-VIServer -Server "$env:REMOTE_HOST" -User "$env:REMOTE_USERNAME" -Password "$env:REMOTE_PASSWORD"
$TEARDOWN = ""

#
do_step "Import VM `"$VM_NAME`" if it does not exist yet"

if ( -not (Get-vmwVM -Name "$VM_NAME" -ErrorAction Ignore) ) {
    & "$env:PACKER_ROOT/scripts/esxi/Run-ESXIScript.ps1" "import-template.sh '$REMOTE_DATASTORE' '$TEMPLATE_DIRECTORY' '$VM_NAME'"
    $CMD = "vim-cmd solo/registervm '/vmfs/volumes/$REMOTE_DATASTORE/$VM_NAME/$VM_NAME.vmx'"
    $ErrorActionPreference = 'Continue'
    plink -batch -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "VM `"$VM_NAME`" imported."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove VM ```"$VM_NAME```" if it exists"
if (Get-vmwVM -Name "$VM_NAME" -ErrorAction Ignore) {
    `$VMID = (Get-vmwVM -Name "$VM_NAME").Id.Split('-')[-1]
    `$CMD = "vim-cmd vmsvc/unregister `$VMID"
    `$ErrorActionPreference = 'Continue'
    plink -batch -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
}
& "$env:PACKER_ROOT/scripts/esxi/Run-ESXIScript.ps1" "delete-vm.sh '$REMOTE_DATASTORE' '$VM_NAME'"
do_echo "VM ```"$VM_NAME```" removed."

"@
        $TEARDOWN = ($TEARDOWN_ENTRY + $TEARDOWN)
    }
}

#
do_step "Start VM `"$VM_NAME`" if it is not running yet"

if ( (Get-vmwVM -Name "$VM_NAME").PowerState -ne 'PoweredOn' ) {
    $VMID = (Get-vmwVM -Name "$env:VM_NAME").Id.Split('-')[-1]
    $CMD = "vim-cmd vmsvc/power.on $VMID"
    $ErrorActionPreference = 'Continue'
    plink -batch -pw "$env:REMOTE_PASSWORD" "${env:REMOTE_USERNAME}@${env:REMOTE_HOST}" "$CMD"; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
    do_echo "VM `"$VM_NAME`" started."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Stop VM ```"$VM_NAME```" if it is running"
if ( (Get-vmwVM -Name "$VM_NAME" -ErrorAction Ignore) -and ( (Get-vmwVM -Name "$VM_NAME").PowerState -eq 'PoweredOn' ) ) {
    `$VMID = (Get-vmwVM -Name "$env:VM_NAME").Id.Split('-')[-1]
    `$CMD = "vim-cmd vmsvc/power.off `$VMID"
    `$ErrorActionPreference = 'Continue'
    plink -batch -pw "`$env:REMOTE_PASSWORD" "`${env:REMOTE_USERNAME}@`${env:REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
    `$ErrorActionPreference = 'Stop'
    do_echo "VM ```"$VM_NAME```" stopped."
}

"@
        $TEARDOWN = ($TEARDOWN_ENTRY + $TEARDOWN)
    }
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
