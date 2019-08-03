# docs

- better syntax highlighting

# laptop

- create ssh key and convert to putty ppk, instead of creating putty key

# hyperv

- Import-Module -Name hyper-v -Prefix hyv  
  Get-Command get-*vm -All  
  Get-hyvVM
-

# vmware

- !!! GB keyboard for VM console !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
- Import-Module -Name vmware.vimautomation.core -Prefix vmw  
  Get-Command get-*vm -All  
  Connect-VIServer -Server holmecroft-vm1 -Protocol https -User 'root' -Password 'xyz'  
  Get-vmwVM  
-

# kvm

- !!! waiting for installation


# packer

-

# centos7

- !!! ssh certificate
- !!! cleanup: https://vmexpo.wordpress.com/2016/06/16/virtual-machine-template-guidelines-for-vmware-redhatcentos-linux-7-x/
- !!! i8042 & PCI not supported on hyperv generation 2


# nethserver7

- !!! ssh certificate
- !!! static MAC on WAN
- !!! https certificate
  db configuration setprop pki CommonName $CN


# terraform

- Set-VM -Name $VMName -AutomaticStopAction ShutDown, or makestep if time diff over a certain amount
- $VMNetworkAdapter = Get-VMNetworkAdapter -VMName $VMName
  Set-VMNetworkAdapter -VMNetworkAdapter $VMNetworkAdapter -StaticMACAddress ($VMNetworkAdapter.MACAddress)

