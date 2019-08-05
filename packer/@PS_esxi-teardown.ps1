#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/kluster
#

$ErrorActionPreference='Stop'

packer build -color=false -on-error=ask -timestamp-ui -force -var-file $env:PACKER_ROOT/esxi-variables.json $env:PACKER_ROOT/esxi-9-teardown.json
