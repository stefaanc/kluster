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
#                "UPLOADS_DIRECTORY={{ user `packer` }}/scripts/esxi/uploads",
#                "REMOTE_HOST={{ user `remote_host` }}",
#                "REMOTE_USERNAME={{ user `remote_username` }}",
#                "REMOTE_PASSWORD={{ user `remote_password` }}",
#                "REMOTE_DATASTORE={{ user `remote_datastore` }}",
#                "LOG_DIRECTORY={{ user `packer` }}/logs",
#                "TEARDOWN_SCRIPT={{ user `packer` }}/{{ user `teardown_script` }}",
#                "STEPS_COLORS={{ user `packer_esxi_colors` }}"
#            ],
#            "scripts": [
#                "{{ user `packer` }}/scripts/esxi/Upload-ESXiScripts.ps1"
#            ]
#        }
#    ]
#
param(
    [string]$UPLOADS_DIRECTORY = "$env:UPLOADS_DIRECTORY"
)
if ( "$UPLOADS_DIRECTORY" -eq "" ) { $UPLOADS_DIRECTORY = "$env:PACKER_ROOT\scripts\esxi\uploads" }

$REMOTE_HOST = "$env:REMOTE_HOST"
$REMOTE_USERNAME = "$env:REMOTE_USERNAME"
$REMOTE_PASSWORD = "$env:REMOTE_PASSWORD"
$REMOTE_DATASTORE = "$env:REMOTE_DATASTORE"
$LOG_DIRECTORY = "$env:LOG_DIRECTORY"
$TEARDOWN_SCRIPT = "$env:TEARDOWN_SCRIPT"
if ( "$LOG_DIRECTORY" -eq "" ) { $LOG_DIRECTORY = "$env:PACKER_ROOT\logs" }

$STEPS_LOG_FILE = "$LOG_DIRECTORY\$( Get-Date -Format yyyyMMddTHHmmss.ffffZ )_upload-esxiscripts.log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

$TEARDOWN = ""

#
do_step "Check if ESXi scripts exist on `"$REMOTE_HOST`""

$CMD = "test -d '/vmfs/volumes/$REMOTE_DATASTORE/scripts' && echo 'true' || echo 'false'"
$ErrorActionPreference = 'Continue'
$has_scripts = ConvertFrom-JSON "$( plink -batch -pw "$REMOTE_PASSWORD" "${REMOTE_USERNAME}@${REMOTE_HOST}" "$CMD" 2> $null; do_catch_exit -IgnoreExitStatus )"
$ErrorActionPreference = 'Stop'
if ( "$has_scripts" -eq "" ) {
    throw "Failed to connect to '${REMOTE_USERNAME}@${REMOTE_HOST}'"
}

#
do_step "Upload ESXi scripts to `"$REMOTE_HOST`""

$ErrorActionPreference = 'Continue'
pscp -r -pw "$REMOTE_PASSWORD" "$UPLOADS_DIRECTORY\scripts" "${REMOTE_USERNAME}@${REMOTE_HOST}:/vmfs/volumes/$REMOTE_DATASTORE"; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'
do_echo "ESXi scripts uploaded."

if ( -not $has_scripts ) {
    if ( "$TEARDOWN_SCRIPT" -ne "" ) {
        $TEARDOWN_ENTRY = @"
do_step "Remove ESXi scripts from ```"$REMOTE_HOST```" if they exist"
`$CMD = "if [[ -d '/vmfs/volumes/$REMOTE_DATASTORE/scripts' ]] ; then rm -rf '/vmfs/volumes/$REMOTE_DATASTORE/scripts' ; fi"
`$ErrorActionPreference = 'Continue'
plink -batch -pw "`$REMOTE_PASSWORD" "`${REMOTE_USERNAME}@`${REMOTE_HOST}" "`$CMD"; do_catch_exit -IgnoreExitStatus
`$ErrorActionPreference = 'Stop'
do_echo "ESXi scripts removed."

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
