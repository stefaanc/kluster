## Setup PowerShell

#### Setup the PowerShell profiles

> :information_source:  
> The following is based on [the project profiles described in the github PSCONSOLE repository](https://github.com/stefaanc/psconsole#project-profiles).  You can find more explanation on the what/why/how there.

1. copy `~\Projects\kluster\downloads\@HOME-Projects_.psprofile.ps1` to your `~\Projects` folder.  This allows you to select a "default" project amongst all projects in this folder.  Make sure only one project is uncommented.

   - rename this file to `.psprofile.json`
   - if you are using a different root folder for the "kluster" project, change the `. ~\Projects\kluster\.psprofile.ps1` line to `. ~\xyz\kluster\.psprofile.ps1`.
   - update this file with links to your projects

2. copy `~\Projects\kluster\downloads\@HOME-Documents-WindowsPowerShell_profile.ps1` to your `~\Documents\WindowsPowerShell` folder

   - either rename this file to `profile.ps` or add (some of) the content of this file your `profile.ps`
   - if you are using a different root folder for the "kluster" project, change the `. ~\Projects\.psprofile.ps1` line to `. ~\xyz\.psprofile.ps1`.

3. copy `~\Projects\kluster\downloads\@HOME-Documents-WindowsPowerShell_console.json` to your `~\Documents\WindowsPowerShell` folder

   - rename this file to `console.json`

4. copy `~\Projects\kluster\downloads\@HOME-Documents-WindowsPowerShell-Scripts_Apply-PSConsoleSettings.ps1` to the `Scripts` folder (create it if it doesn't exist) under your `~\Documents\WindowsPowerShell` folder

   - rename this file to `Apply-PSConsoleSettings.ps1`

5. open a PowerShell terminal

   - if you get a warning that you cannot execute scripts, execute `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
   - alternatively, you can also use the `@CP_Start-PowerShellUser` or `@CP_Start-PowerShellAdmin` shortcuts that are created in the `~\Projects\kluster\scripts` folder after [preparing the kluster environment](/#prepare-the-kluster-environment).

6. verify that executing `echo $env:USERPROFILE` in a PowerShell terminal gives you your home-directory

   - we have seen this go wrong, but the remedy depends on your environment.  It is important that this gets sorted before you continue.

#### Install the `PSReadLine` module

> :information_source:  
> The following is taken from [the github PSCONSOLE repository](https://github.com/stefaanc/psconsole#the-colors-of-the-console).

From Windows 10 build 1809 onward, the `PSReadline` module was upgraded from version 1.2 to a 2.0.0-beta version.  This beta version causes a lot of issues that cannot be worked around.  To make the "kluster"-scripts work, you **MUST** downgrade the `PSReadLine` module to version 1.2

1. check if you have version 2.0.0

   ```powershell
   Get-Module PSReadLine
   ```

   gives

   ```text
   ModuleType Version    Name           ExportedCommands
   ---------- -------    ----           ----------------
   Script     2.0.0      PSReadLine     {Get-PSReadlineKeyHandler, Get-PSReadlineOption, Remove-PS...
   ```

2. run PowerShell as administrator, and execute

   ```powershell
   Install-Module -Name PSReadLine -RequireVersion 1.2 -SkipPublisherCheck
   ```

3. delete `C:\Program Files\WindowsPowerShell\Modules\PSReadline\2.0.0`

4. check if the module is installed

   ```powershell
   Get-InstalledModule PSReadLine
   ```

   gives

   ```text
   Version           Name           Repository           Description
   -------           ----           ----------           -----------
   1.2               PSReadLine     PSGallery            Great command line editing in the Powe...
   ```
