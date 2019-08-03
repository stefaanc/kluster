#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    Generate-ServerCertificatesESXI "$IP_ADDRESS" [ "$SERVER_NAME" [ "$IP_DOMAIN" ]]
#
param(
    [string]$IP_ADDRESS = "$env:IP_ADDRESS",
    [string]$SERVER_NAME = "$env:SERVER_NAME",
    [string]$IP_DOMAIN = "$env:IP_DOMAIN"
)

$STEPS_LOG_FILE = "$ROOT\logs\generate-servercertificatesesxi_$( Get-Date -Format yyyyMMddTHHmmss.ffffZ ).log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

if ( "$IP_ADDRESS" -eq "" ) { throw "Cannot execute script: no IP address specified" }
if ( "$SERVER_NAME" -eq "" ) { $SERVER_NAME = "esxiserver" }
if ( "$IP_DOMAIN" -eq "" ) { $IP_DOMAIN = "kluster.local" }
#
# workaround for issue with openssl finding the .rnd file
Push-Location
do_cleanup 'Pop-Location'

Set-Location "$HOME"

#
do_step "Create folder for certificates"

$SERVER_DOMAIN="$SERVER_NAME.$IP_DOMAIN"
$PATH="$ROOT/.pki/$SERVER_DOMAIN"
if ( -not ( Test-Path -Path "$PATH" ) ) {
    New-Item -ItemType "directory" -Path "$PATH"
}

#
do_step "Generate rootCA certificates if they don't exist"

$CA_PATH="$ROOT/.pki/$IP_DOMAIN"
if ( -not ( Test-Path -Path "$CA_PATH" ) ) {
    & Generate-RootCACertificates "$IP_DOMAIN"
}

#
do_step "Generate server certificates"

& Generate-ServerCertificates "$IP_ADDRESS" "$SERVER_NAME" "$IP_DOMAIN"

#
do_step "Prepare certificates for ESXi server"

$PATH="$ROOT/.pki/$SERVER_DOMAIN"
( Get-Content -Raw "$PATH/server@$SERVER_DOMAIN.key" ).Replace("`r`n", "`n") | Set-Content -NoNewLine "$PATH/rui.key"
( Get-Content -Raw "$PATH/server@$SERVER_DOMAIN.crt" ).Replace("`r`n", "`n") | Set-Content -NoNewLine "$PATH/rui.crt"

do_echo ""
do_echo -Color "Yelllow" "To install certs on ESXi server:"
do_echo -Color "Yelllow" "- put ESXi server in maintenance mode (esxcli system maintenanceMode set --enable true)"
do_echo -Color "Yelllow" "- using winscp, rename old rui.key and rui.crt in /etc/vmware/ssl/ to rui.key.bak and rui.crt.bak"
do_echo -Color "Yelllow" "- using winscp, upload new rui.key and rui.crt to /etc/vmware/ssl/"
do_echo -Color "Yelllow" "- put ESXi server out of maintenance mode (esxcli system maintenanceMode set --enable false)"
do_echo -Color "Yelllow" "- reboot ESXi server"
do_echo ""

#
do_exit 0
