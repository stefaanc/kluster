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
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "REMOTE_DATASTORE={{ user `remote_datastore` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "STEPS_COLORS={{ user `packer_esxi_colors` }}"
#            ],
#            "inline": [
#                "{{ user `packer` }}/scripts/esxi/Run-ESXiScript.ps1 -Command \"delete-vm.sh '{{ user `remote_datastore` }}' '{{ user `vm_name` }}'\""
#            ]
#        }
#    ]
#
param(
    [string]$COMMAND = "$env:COMMAND"
)

$REMOTE_HOST = "$env:REMOTE_HOST"
$REMOTE_USERNAME = "$env:REMOTE_USERNAME"
$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD"
$REMOTE_DATASTORE = "$env:REMOTE_DATASTORE"
$LOG_DIRECTORY = "$env:LOG_DIRECTORY"
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_run-esxiscript.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

#
do_step "Execute remote command: `"$COMMAND`""

$ErrorActionPreference = 'Continue'
plink -batch -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" ". /vmfs/volumes/$env:REMOTE_DATASTORE/scripts/$COMMAND"; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'

#
do_exit 0
