#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https:\\github.com\stefaanc\kluster
#

. "$( Split-Path -Path $script:MyInvocation.MyCommand.Path )\.steps.ps1"
trap { do_trap }

do_script

$powershell_theme = "$ROOT\colors\psconsole-powershell-dark.json"

$psprofile = "$PSScriptRoot\..\.psprofile.ps1"

#
do_step "Create shortcut 'scripts\@CP_Start-PowerShellUser'"

New-Shortcut "$ROOT\scripts\@CP_Start-PowerShellUser" -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -NoExit -Command `"$psprofile`""
Set-PSConsoleColors "$ROOT\scripts\@CP_Start-PowerShellUser" -Theme "$powershell_theme"
Set-PSConsoleWindowSize "$ROOT\scripts\@CP_Start-PowerShellUser" -Width 120 -Height 50 -ScreenBufferHeight 8000

#
do_step "Create shortcut 'scripts\@CP_Start-PowerShellAdmin'"

New-Shortcut "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -NoExit -Command `"$psprofile`""
Set-PSConsoleColors "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Theme "$powershell_theme"
Set-PSConsoleWindowSize "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Width 120 -Height 50 -ScreenBufferHeight 8000

#
do_step "Create shortcut 'packer\@CP_hyperv-build'"

New-Shortcut "$ROOT\packer\@CP_hyperv-build" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -Command `"$psprofile; $ROOT\packer\@PS_hyperv-build.ps1`"; Wait-Key; exit 0"
Set-PSConsoleColors "$ROOT\packer\@CP_hyperv-build" -Theme "$ROOT\colors\psconsole-colorized-light-azure.json"
Set-PSConsoleWindowSize "$ROOT\packer\@CP_hyperv-build" -Width 150 -Height 50 -ScreenBufferHeight 8000

#
do_step "Create shortcut 'packer\@CP_hyperv-setup'"

New-Shortcut "$ROOT\packer\@CP_hyperv-setup" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -Command `"$psprofile; $ROOT\packer\@PS_hyperv-setup.ps1`"; Wait-Key; exit 0"
Set-PSConsoleColors "$ROOT\packer\@CP_hyperv-setup" -Theme "$ROOT\colors\psconsole-colorized-light-azure.json"
Set-PSConsoleWindowSize "$ROOT\packer\@CP_hyperv-setup" -Width 150 -Height 50 -ScreenBufferHeight 8000

#
do_step "Create shortcut 'packer\@CP_hyperv-teardown'"

New-Shortcut "$ROOT\packer\@CP_hyperv-teardown" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -Command `"$psprofile; $ROOT\packer\@PS_hyperv-teardown.ps1`"; Wait-Key; exit 0"
Set-PSConsoleColors "$ROOT\packer\@CP_hyperv-teardown" -Theme "$ROOT\colors\psconsole-colorized-light-azure.json"
Set-PSConsoleWindowSize "$ROOT\packer\@CP_hyperv-teardown" -Width 150 -Height 50 -ScreenBufferHeight 8000

#
do_exit 0
