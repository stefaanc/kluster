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
$packer_theme_hyperv = "$ROOT\colors\psconsole-colorized-dark-blue.json"
$packer_theme_esxi = "$ROOT\colors\psconsole-colorized-dark-magenta.json"
$packer_theme_common = "$ROOT\colors\psconsole-colorized-dark-cyan.json"

$psprofile = "$PSScriptRoot\..\.psprofile.ps1"

#
do_step "Create shortcuts for powershell"

do_echo "@CP_Start-PowerShellUser"
New-Shortcut "$ROOT\scripts\@CP_Start-PowerShellUser" -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -NoExit -Command `"$psprofile`""
Set-ShortcutColors "$ROOT\scripts\@CP_Start-PowerShellUser" -Theme "$powershell_theme"
Set-ShortcutWindowSize "$ROOT\scripts\@CP_Start-PowerShellUser" -Width 120 -Height 50 -ScreenBufferHeight 8000

do_echo "@CP_Start-PowerShellAdmin"
New-Shortcut "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -NoExit -Command `"$psprofile`""
Set-ShortcutColors "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Theme "$powershell_theme"
Set-ShortcutWindowSize "$ROOT\scripts\@CP_Start-PowerShellAdmin" -Width 120 -Height 50 -ScreenBufferHeight 8000

#
do_step "Create shortcuts for scripts"

Get-ChildItem -Path "$ROOT\scripts\@PS_*.ps1" | ForEach-Object -Process {
    $name = $( Split-Path $_ -Leaf ).Split(".")[0].Substring(4)

    if ( -not ( Test-Path "$ROOT\scripts\@CP_$name.bat") ) {
        do_echo "@CP_$name"
        New-Shortcut "$ROOT\scripts\@CP_$name" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -Command `"$psprofile; $ROOT\scripts\@PS_$name.ps1`"; Wait-Key; exit 0"
        Set-ShortcutColors "$ROOT\scripts\@CP_$name" -Theme "$powershell_theme"
        Set-ShortcutWindowSize "$ROOT\scripts\@CP_$name" -Width 150 -Height 50 -ScreenBufferHeight 8000
    }
}

#
do_step "Create shortcuts for packer"

Get-ChildItem -Path "$ROOT\packer\@PS_*.ps1" | ForEach-Object -Process {
    $name = $( Split-Path $_ -Leaf ).Split(".")[0].Substring(4)

    if ( $name.StartsWith("hyperv_") ) {
        $theme = $packer_theme_hyperv
    }
    elseif ( $name.StartsWith("esxi_") ) {
        $theme = $packer_theme_esxi
    }
    else {
        $theme = $packer_theme_common
    }

    do_echo "@CP_$name"
    New-Shortcut "$ROOT\packer\@CP_$name" -Admin -TargetPath "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -Command `"$psprofile; $ROOT\packer\@PS_$name.ps1`"; Wait-Key; exit 0"
    Set-ShortcutColors "$ROOT\packer\@CP_$name" -Theme "$theme"
    Set-ShortcutWindowSize "$ROOT\packer\@CP_$name" -Width 150 -Height 50 -ScreenBufferHeight 8000
}

#
do_step "Copy shortcuts for packer to scripts folder"

do_echo "@CP_Build-TemplatesHyperV"
Copy-Item -Force "$ROOT\packer\@CP_hyperv-build.lnk" "$ROOT\scripts\@CP_Build-TemplatesHyperV.lnk"

#
do_exit 0
