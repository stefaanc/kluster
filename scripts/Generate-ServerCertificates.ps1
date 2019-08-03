#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    Generate-ServerCertificates "$IP_ADDRESS" "$SERVER_NAME" [ "$IP_DOMAIN" ]
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
if ( "$SERVER_NAME" -eq "" ) { throw "Cannot execute script: no server name specified" }
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
basicConstraints       = critical,CA:false
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
do_exit 0
