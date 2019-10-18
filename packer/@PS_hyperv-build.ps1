#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#

$ErrorActionPreference='Stop'

New-Item -ItemType Directory -Path $env:PACKER_ROOT\logs -Force

packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/hyperv-variables.json $env:PACKER_ROOT/hyperv-1-setup.json
packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/hyperv-variables.json $env:PACKER_ROOT/hyperv-2-centos7.json
packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/hyperv-variables.json $env:PACKER_ROOT/hyperv-3-nethserver7.json
packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/hyperv-variables.json $env:PACKER_ROOT/hyperv-4-setup.json

Write-Output ""
Read-Host -Prompt "Press <Enter> to tear down, <Ctrl-C> to leave without tearing down ..."

packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/hyperv-variables.json $env:PACKER_ROOT/hyperv-9-teardown.json
