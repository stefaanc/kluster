$ErrorActionPreference='Stop'

packer build -on-error=ask -timestamp-ui -var-file $env:PACKER_ROOT/esxi-variables.json -force $env:PACKER_ROOT/esxi-1-setup.json
packer build -on-error=ask -timestamp-ui -var-file $env:PACKER_ROOT/esxi-variables.json -force $env:PACKER_ROOT/esxi-2-centos7.json
packer build -on-error=ask -timestamp-ui -var-file $env:PACKER_ROOT/esxi-variables.json -force $env:PACKER_ROOT/esxi-3-nethserver7.json
packer build -on-error=ask -timestamp-ui -var-file $env:PACKER_ROOT/esxi-variables.json -force $env:PACKER_ROOT/esxi-4-setup.json

echo ""
Read-Host -Prompt "Press <Enter> to tear down, <Ctrl-C> to leave without tearing down ..."

packer build -on-error=ask -timestamp-ui -var-file $env:PACKER_ROOT/esxi-variables.json -force $env:PACKER_ROOT/esxi-9-teardown.json