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
#            "execute_command": ["PowerShell", "{{.Vars}}{{.Script}}; exit $LASTEXITCODE"],
#            "env_var_format": "$env:%s=\"%s\"; ",
#            "tempfile_extension": ".ps1",
#            "environment_vars": [
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "REMOTE_DATASTORE={{ user `remote_datastore` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_DIRECTORY={{ user `packer` }}",
#                "STEPS_COLORS={{ user `packer_hyperv_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/esxi/Teardown.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$REMOTE_HOST = "$env:REMOTE_HOST",
    [string]$REMOTE_USERNAME = "$env:REMOTE_USERNAME",
    [string]$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD",
    [string]$REMOTE_DATASTORE = "$env:REMOTE_DATASTORE",
    [string]$LOG_DIRECTORY = "$env:LOG_DIRECTORY",
    [string]$TEARDOWN_DIRECTORY = "$env:TEARDOWN_DIRECTORY"
)
if ( "$REMOTE_DATASTORE" -eq "" ) { $REMOTE_DATASTORE = "datastore1" }
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }
if ( "$TEARDOWN_DIRECTORY" -eq "" ) { $TEARDOWN_DIRECTORY = "$env:PACKER_ROOT" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_teardown.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

Import-Module -Name VMware.VimAutomation.Core -Prefix vmw   # covers naming conflicts when using hyper-v and vmware at the same time
Connect-VIServer -Server "$REMOTE_HOST" -User "$REMOTE_USERNAME" -Password "$REMOTE_PASSWORD"

#
if ( Test-Path -Path "$TEARDOWN_DIRECTORY/_esxi-teardown-4.ps1" ) { . "$TEARDOWN_DIRECTORY/_esxi-teardown-4.ps1" }
if ( Test-Path -Path "$TEARDOWN_DIRECTORY/_esxi-teardown-1.ps1" ) { . "$TEARDOWN_DIRECTORY/_esxi-teardown-1.ps1" }

#
do_exit 0
