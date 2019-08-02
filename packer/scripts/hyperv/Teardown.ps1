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
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_DIRECTORY={{ user `packer` }}",
#                "STEPS_COLORS={{ user `packer_hyperv_colors` }}"
#            "scripts": [
#                "{{ user `packer` }}/scripts/hyperv/Teardown.ps1"
#        }
#    ]
#
param(
    [parameter(position=0)] $LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [parameter(position=1)] $TEARDOWN_DIRECTORY = "$env:TEARDOWN_DIRECTORY"
)
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$PACKER_ROOT\logs" }
if ( "$TEARDOWN_DIRECTORY" -eq "" ) { $TEARDOWN_DIRECTORY = "$PACKER_ROOT" }

# save params for second '.steps' pass
$STEPS_PARAMS = @{
    LOG_DIRECTORY = $LOG_DIRECTORY
    TEARDOWN_DIRECTORY = $TEARDOWN_DIRECTORY
}

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_teardown.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name Hyper-V -Prefix hyv   # covers naming conflicts when using hyper-v and vmware at the same time

#
if ( Test-Path -Path "$TEARDOWN_DIRECTORY/_hyperv-teardown-4.ps1" ) { . "$TEARDOWN_DIRECTORY/_hyperv-teardown-4.ps1" }
if ( Test-Path -Path "$TEARDOWN_DIRECTORY/_hyperv-teardown-1.ps1" ) { . "$TEARDOWN_DIRECTORY/_hyperv-teardown-1.ps1" }

#
do_exit 0