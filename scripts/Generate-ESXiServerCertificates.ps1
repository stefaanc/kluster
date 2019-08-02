#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    Generate-ESXIServerCertificates "$IP_ADDRESS" [ "$SERVER_NAME" [ "$IP_DOMAIN" ]]
#
param(
    [parameter(mandatory, position=0)] $IP_ADDRESS = "$env:IP_ADDRESS",
    [parameter(position=1)] $SERVER_NAME = "$env:SERVER_NAME",
    [parameter(position=2)] $IP_DOMAIN = "$env:IP_DOMAIN"
)
if ( "$SERVER_NAME" -eq "" ) { $SERVER_NAME = "esxiserver" }
if ( "$IP_DOMAIN" -eq "" ) { $IP_DOMAIN = "kluster.local" }

# save params for second '.steps' pass
$STEPS_PARAMS = @{
    IP_DOMAIN = $IP_DOMAIN
    IP_ADDRESS = $IP_ADDRESS
    SERVER_NAME = $SERVER_NAME
}

$STEPS_LOG_FILE = "$ROOT\logs\generate-esxiservercertificates_$( Get-Date -Format yyyyMMddTHHmmss.ffffZ ).log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

#
# workaround for issue with openssl finding the .rnd file
Set-Location "$HOME"

#
do_step "Create folder for certificates"

$SERVER_DOMAIN="$SERVER_NAME.$IP_DOMAIN"
$PATH="$ROOT/.pki/$SERVER_DOMAIN"
if ( -not ( Test-Path -Path "$PATH" ) ) {
    New-Item -ItemType "directory" -Path "$PATH"
}

#
do_step "Check/create rootCA certificates"

$CA_PATH="$ROOT/.pki/$IP_DOMAIN"
if ( -not ( Test-Path -Path "$CA_PATH" ) ) {
    Generate-RootCACertificates "$IP_DOMAIN"
}

#
do_step "Generate a private key for 'ca@$SERVER_DOMAIN'"

$ErrorActionPreference = 'Continue'
openssl genrsa -passout pass:x -out "$PATH/ca@$SERVER_DOMAIN.key" 2048; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'

#
do_step "Generate a certificate for 'ca@$SERVER_DOMAIN'"

New-Item -Type File -Path "$PATH" -Name ca.ext -Force -Value @"
basicConstraints       = critical,CA:true,pathlen:0
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,cRLSign,digitalSignature,keyCertSign,keyEncipherment
"@

openssl req -new -sha256 -nodes -key "$PATH/ca@$SERVER_DOMAIN.key" -subj "/CN=ca@$SERVER_DOMAIN" -out "$PATH/ca.csr"; do_catch_exit
$ErrorActionPreference = 'Continue'
openssl x509 -req -in "$PATH/ca.csr" -CA "$CA_PATH/ca@$IP_DOMAIN.crt" -CAkey "$CA_PATH/ca@$IP_DOMAIN.key" -days 3652 -extfile "$PATH/ca.ext" -CAcreateserial -out "$PATH/ca@$SERVER_DOMAIN.crt"; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'
Remove-Item -Force "$PATH/ca.csr"

#
do_step "Generate a certificate-bundle for 'ca@$SERVER_DOMAIN'"

( Get-Content -Raw "$PATH/ca@$SERVER_DOMAIN.crt" ) + ( Get-Content -Raw "$CA_PATH/ca@$IP_DOMAIN.crt" ) | Set-Content "$PATH/ca@$SERVER_DOMAIN.crt.bundle"

#
do_step "Generate a certificate for 'ca@$SERVER_DOMAIN' in the browser"

openssl pkcs12 -export -cacerts -passout pass:esxiesxi -in "$PATH/ca@$SERVER_DOMAIN.crt" -inkey "$PATH/ca@$SERVER_DOMAIN.key" -name "ca@$SERVER_DOMAIN" -out "$PATH/ca@$SERVER_DOMAIN.p12"; do_catch_exit

#
do_step "Delete old certificate for 'ca@$SERVER_DOMAIN' in the browser"

$Certs = Get-ChildItem Cert:"CurrentUser\CA" | Where-Object { $_.Subject -match "ca@$SERVER_DOMAIN" }
if ( "$Certs" ) {
    $Certs | Format-Table FriendlyName, Subject | Out-String | do_echo
    $Certs | Remove-Item
}

#
do_step "Import new certificate for 'ca@$SERVER_DOMAIN' in the browser"

CertUtil -f -user -p esxiesxi -importPFX CA "$PATH/ca@$SERVER_DOMAIN.p12"
$Certs = Get-ChildItem Cert:"CurrentUser\CA" | Where-Object { $_.Subject -match "ca@$SERVER_DOMAIN" }
$Certs | Format-Table FriendlyName, Subject | Out-String | do_echo

################################################################################

#
do_step "Generate a private key for 'server@$SERVER_DOMAIN'"

$ErrorActionPreference = 'Continue'
openssl genrsa -passout pass:x -out "$PATH/server@$SERVER_DOMAIN.key" 2048; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'

#
do_step "Generate a certificate for 'server@$SERVER_DOMAIN'"

New-Item -Type File -Path "$PATH" -Name server.ext -Force -Value @"
basicConstraints       = critical,CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,digitalSignature,keyEncipherment
subjectAltName         = DNS:$SERVER_NAME,DNS:$SERVER_DOMAIN,IP:$IP_ADDRESS
"@

openssl req -new -sha256 -nodes -key "$PATH/server@$SERVER_DOMAIN.key" -subj "/CN=$SERVER_NAME/O=$IP_DOMAIN" -out "$PATH/server.csr"; do_catch_exit
$ErrorActionPreference = 'Continue'
openssl x509 -req -in "$PATH/server.csr" -CA "$PATH/ca@$SERVER_DOMAIN.crt" -CAkey "$PATH/ca@$SERVER_DOMAIN.key" -days 3652 -extfile "$PATH/server.ext" -CAcreateserial -out "$PATH/server@$SERVER_DOMAIN.crt"; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'
Remove-Item -Force "$PATH/server.csr"

#
do_step "Prepare certificates for ESXi server"

( Get-Content -Raw "$PATH/server@$SERVER_DOMAIN.key" ).Replace("`r`n", "`n") | Set-Content -NoNewLine "$PATH/rui.key"
( Get-Content -Raw "$PATH/server@$SERVER_DOMAIN.crt" ).Replace("`r`n", "`n") | Set-Content -NoNewLine "$PATH/rui.crt"

do_echo ""
do_echo "To install certs on ESXi server:"
do_echo "- put ESXi server in maintenance mode (esxcli system maintenanceMode set --enable true)"
do_echo "- using winscp, rename old rui.key and rui.crt in /etc/vmware/ssl/ to rui.key.bak and rui.crt.bak"
do_echo "- using winscp, upload new rui.key and rui.crt to /etc/vmware/ssl/"
do_echo "- put ESXi server out of maintenance mode (esxcli system maintenanceMode set --enable false)"
do_echo "- reboot ESXi server"
do_echo ""

Set-Location "$PATH"

#
do_exit 0