# Kluster

**A package to deploy and configure highly-scalable production-grade apps using kubernetes (OKV) on a bare-metal platform (KVM).**

Objectives of the project:

- design a platform using OKV and KVM
- learn and apply the technology and techniques to install, develop, test, maintain and operate
- all installed packages must be free, unless there is no viable alternative (hence the KVM virtualization platform)
- security is a major concern (hence the OKV distribution/flavour of kubernetes)
- the end goal is a platform that is ready for highly-scalable production-grade apps
- everything can be installed and managed from a Windows 10 laptop
- a Windows 10 laptop with Hyper-V and (optionally) a vmware ESXi server can be used as a small development and test environment
- a Windows 10 laptop with Hyper-V and (optionally) a vmware ESXi server can be used as a portable demo environment


This is a project that is continuously updated and possibly changing direction, as we learn, and as new technology and techniques become available.  Backward compatibility is not a major concern at this moment.


## Before You Start

### Setup your profile for PowerShell

1. by default, the "kluster" project is expected to be in the `~\Projects\kluster` folder.  

   - if you put it somewhere else, for instance `~\xyz\kluster`, edit the `~\xyz\kluster\.psprofile.ps1` file
     - change the `$ROOT = "$HOME\Projects\kluster"` line to `$ROOT = "$HOME\xyz\kluster"`


2. navigate to your `~\Documents\WindowsPowerShell` folder

   - if there is no `profile.ps1` file
     - copy the `~\Projects\kluster\downloads\profile.ps` file  

   - if there is a `profile.ps1` file
     - either add (some of) the content of `~\Project\kluster\downloads\profile.ps` to the original file
     - or rename the original file and copy the `~\Projects\kluster\downloads\profile.ps` file  

   - if you are using a different root folder for the "kluster" project (see 1.), edit the `~\Documents\WindowsPowerShell\profile.ps1` file
     - change the `. ~\Projects\kluster\.psprofile.ps1` line to `. ~\xyz\kluster\.psprofile.ps1`


3. open a PowerShell terminal

   - if you get a warning that you cannot execute scripts
     - either execute `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
     - or run `@@CP_Start-PowerShell.bat` in your `$ROOT\scripts` folder to open a PowerShell terminal


4. verify that executing `echo $env:USERPROFILE` gives you your home-directory

   - we have seen this go wrong, but the remedy depends on your environment.  It is important that this gets sorted before you continue.


### Generate root-certificates for the kluster domain
   
> :warning:  
> Re-generating root certificates will invalidate all already existing kluster-certificates.

1. open a PowerShell terminal

2. execute `Generate-RootCACertificates.ps1 $IP_DOMAIN`, for instance

   ```powershell
   Generate-RootCACertificates.ps1 "kluster.local"
   ```

   - you will be asked to allow the script to import a root-CA certificate for the IP-domain - click `Yes`
   - the generated certificates can be found in `$ROOT\.pki\kluster.local`


### Setup Hyper-V on your laptop

1. there is plenty of information on the web about this, for instance: https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v 

2. optionally install [Windows Admin Center](https://docs.microsoft.com/en-us/windows-server/manage/windows-admin-center/overview) for a modern web-based GUI to manage your Windows 10 machine and Hyper-V


### Setup an ESXi server (optional)

1. browse to the VMware website and select `Free Product Downloads` on the `Downloads`-tab: https://my.vmware.com/en/web/vmware/evalcenter?p=free-esxi6

2. you can get a free license when you create an account

3. download the vSphere Hypervisor and install it

4. [configure ESXi server](./documents/configure-esxi-server.md)


### Prepare the kluster environment

1. navigate to your `$ROOT\scripts` folder and run `@@CP_Prepare-KlusterEnvironment.bat`

