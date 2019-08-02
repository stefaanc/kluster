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
#    "post-processors": [
#        {
#            "type": "shell-local",
#            "execute_command": ["PowerShell", "-NoProfile", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "SWITCH_LAN={{ user `switch_lan` }}",
#                "IP_ADDRESS_HOST={{ user `ip_address_host` }}",
#                "IP_PREFIX={{ user `ip_prefix` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_hyperv_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `root` }}/scripts/Setup-LANSwitch.ps1"
#            ]
#        }
#    ]
#
param(
    [parameter(position=0)] $SWITCH_LAN = "$env:SWITCH_LAN",
    [parameter(position=1)] $IP_ADDRESS_HOST = "$env:IP_ADDRESS_HOST",
    [parameter(position=2)] $IP_PREFIX = "$env:IP_PREFIX",
    [parameter(position=3)] $LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [parameter(position=4)] $TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
)
if ( "$SWITCH_LAN" -eq "" ) { $SWITCH_LAN = "Virtual Switch Internal" }
if ( "$IP_ADDRESS_HOST" -eq "" ) { $IP_ADDRESS_HOST = "192.168.0.254" }
if ( "$IP_PREFIX" -eq "" ) { $IP_PREFIX = "24" }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$ROOT\logs" }

# save params for second '.steps' pass
$STEPS_PARAMS = @{
    SWITCH_LAN = $SWITCH_LAN
    IP_ADDRESS_HOST = $IP_ADDRESS_HOST
    IP_PREFIX = $IP_PREFIX
    LOG_DIRECTORY = $LOG_DIRECTORY
    TEARDOWN_SCRIPT = $TEARDOWN_SCRIPT
}


$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_setup-lanswitch.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name Hyper-V -Prefix hyv   # covers naming conflicts when using hyper-v and vmware at the same time
$TEARDOWN = ""

#
do_step "Create LAN switch `"$SWITCH_LAN`" if it does not exist yet"

if ( -not ( Get-VMSwitch -Name "$SWITCH_LAN" -ErrorAction Ignore ) ) {
    New-VMSwitch -SwitchName "$SWITCH_LAN" -SwitchType Internal
    New-NetIPAddress -IPAddress "$IP_ADDRESS_HOST" -PrefixLength "$IP_PREFIX" -SkipAsSource $true -InterfaceAlias "vEthernet ($SWITCH_LAN)"
    do_echo "Switch `"$SWITCH_LAN`" created."

    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove LAN switch ```"$SWITCH_LAN```" if it exists"
if ( Get-VMSwitch -Name "$SWITCH_LAN" -ErrorAction Ignore ) {
    Remove-VMSwitch -Name "$SWITCH_LAN" -Force
    do_echo "Switch ```"$SWITCH_LAN```" removed."
}

"@
        $TEARDOWN = $TEARDOWN_ENTRY + $TEARDOWN
    }
}

#
do_step "Set 'Private' network category"

While ( ( Get-NetConnectionProfile -InterfaceAlias "vEthernet ($SWITCH_LAN)").NetworkCategory -ne "Private" ) {
    try {
        # 'Set-NetConnectionProfile' cmdlet doesn't seem to pickup "$ErrorActionPreference = 'Stop'",
        # and instead may hang (f.i. when using a non-existing interface-alias), so set error-action explicitly
        Set-NetConnectionProfile -InterfaceAlias "vEthernet ($SWITCH_LAN)" -NetworkCategory Private -ErrorAction 'Stop'
    }
    catch {
        # We observed that this sometimes fails because the network is marked "Identifying",
        # but it succeeds after some time
        if ( $Error[0].Exception.Message -like "*'Identifying...'*" ) {
            do_echo "Waiting for network identification to complete..."
            Start-Sleep 5
        }
        else {
            throw $Error[0]
        }
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
