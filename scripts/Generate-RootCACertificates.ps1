#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#
# use:
#
#    Generate-RootCACertificates [ "$IP_DOMAIN" ]
#
param(
    [parameter(position=0)] $IP_DOMAIN = "$env:IP_DOMAIN"
)
if ( "$IP_DOMAIN" -eq "" ) { $IP_DOMAIN = "kluster.local" }

# save params for second '.steps' pass
$STEPS_PARAMS = @{
    IP_DOMAIN = $IP_DOMAIN
}

$STEPS_LOG_FILE = "$ROOT\logs\generate-rootcacertificates_$( Get-Date -Format yyyyMMddTHHmmssffffZ ).log"
$STEPS_LOG_APPEND = $false

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )/.steps.ps1"
trap { do_trap }

do_script

#
# workaround for issue with openssl finding the .rnd file
$SAVED_LOCATION = ( Get-Location ).Path
Set-Location "$HOME"

#
do_step "Create folder for certificates"

$PATH = "$ROOT\.pki\$IP_DOMAIN"
if ( -not ( Test-Path -Path "$PATH" ) ) {
    New-Item -ItemType "directory" -Path "$PATH"
}

#
do_step "Initialise openSSL"

if ( -not ( Test-Path -Path "$HOME\.rnd" ) ) {
    $ErrorActionPreference = 'Continue'
    openssl genrsa -writerand "$HOME\.rnd" 2048 | Out-Null; do_catch_exit -IgnoreExitStatus
    $ErrorActionPreference = 'Stop'
}

#
do_step "Generate a private key for 'ca@$IP_DOMAIN'"

$ErrorActionPreference = 'Continue'
openssl genrsa -passout pass:x -out "$PATH\ca@$IP_DOMAIN.key" 2048; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'

#
do_step "Generate a certificate for 'ca@$IP_DOMAIN'"

New-Item -ItemType "file" -Path "$PATH" -Name "ca.ext" -Force -Value @"
basicConstraints       = critical,CA:true
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,cRLSign,digitalSignature,keyCertSign,keyEncipherment
"@

openssl req -new -sha256 -nodes -key "$PATH\ca@$IP_DOMAIN.key" -subj "/CN=ca@$IP_DOMAIN" -out "$PATH\ca.csr"; do_catch_exit
$ErrorActionPreference = 'Continue'
openssl x509 -req -in "$PATH\ca.csr" -signkey "$PATH\ca@$IP_DOMAIN.key" -days 3652 -extfile "$PATH\ca.ext" -CAcreateserial -out "$PATH\ca@$IP_DOMAIN.crt"; do_catch_exit -IgnoreExitStatus
$ErrorActionPreference = 'Stop'
Remove-Item -Force "$PATH\ca.csr"

#
do_step "Generate a certificate for 'ca@$IP_DOMAIN' in the browser"

openssl pkcs12 -export -cacerts -passout pass:klusklus -in "$PATH\ca@$IP_DOMAIN.crt" -inkey "$PATH\ca@$IP_DOMAIN.key" -name "ca@$IP_DOMAIN" -out "$PATH\ca@$IP_DOMAIN.p12"; do_catch_exit

#
do_step "Delete old certificate for 'ca@$IP_DOMAIN' in the browser"

$Certs = Get-ChildItem Cert:"CurrentUser\AuthRoot" | Where-Object { $_.Subject -match "$IP_DOMAIN" }
if ( "$Certs" ) {
    $Certs | Format-Table FriendlyName, Subject | Out-String | do_echo
    $Certs | Remove-Item
}
# automatically cloned when created, but not automatically deleted
Get-ChildItem Cert:"CurrentUser\Root" | Where-Object { $_.Subject -match "$IP_DOMAIN" } | Remove-Item

#
do_step "Import new certificate for 'ca@$IP_DOMAIN' in the browser"

CertUtil -f -user -p klusklus -importPFX AuthRoot "$PATH\ca@$IP_DOMAIN.p12"
$Certs = Get-ChildItem Cert:"CurrentUser\AuthRoot" | Where-Object { $_.Subject -match "$IP_DOMAIN" }
$Certs | Format-Table FriendlyName, Subject | Out-String | do_echo

#
# workaround for issue with openssl finding the .rnd file
Set-Location "$SAVED_LOCATION"

#
do_exit 0