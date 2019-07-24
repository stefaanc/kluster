#
# Copyright (c) 2019 Stefaan Coussement
# MIT License
#
# more info: https://github.com/stefaanc/psconsole
# more info: https://github.com/stefaanc/ptsession
#
# use:
#
#     New-Shortcut "$Path" "$TargetPath" [ "$Arguments" ]
#
#     Remark that "$Path" has to be **full** path
#
# other optional parameters/switches:
#
#     -Desctription "$Description"
#     -HotKey "$HotKey"                       # f.i "ALT+CTRL+9", "SHIFT+F7"
#     -WorkingDirectory "$WorkingDirectory"
#     -WindowStyle $WindowStyle               # 1=normal (default), 3=maximized, 7=minimized
#     -IconLocation "$IconLocation"           # add ",99" to the path to get the 99th icon
#     -Admin or -RunAs
#
param(
    [Parameter(Mandatory=$True, Position=0)][string]$Path,
    [Parameter(Mandatory=$True, Position=1)][string]$TargetPath,
    [Parameter(Position=2)][string]$Arguments,
    [string]$Description,
    [string]$HotKey,
    [string]$WorkingDirectory,
    [int]$WindowStyle,
    [string]$IconLocation,
    [Alias("RunAs")][switch]$Admin
)

$ErrorActionPreference = 'Stop'

if ( -not ( $Path -match "^.*(\.lnk)$" ) ) {
    $Path = "$Path`.lnk"
}

if ( Test-Path -Path $Path ) {
    Remove-Item $Path
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($Path)
$shortcut.TargetPath = $TargetPath
$shortcut.Arguments = $Arguments
$shortcut.Description = $Description
$shortcut.HotKey = $HotKey
$shortcut.WorkingDirectory = $WorkingDirectory
$shortcut.WindowStyle = $WindowStyle
if ($Icon){
    $shortcut.IconLocation = $IconLocation
}
$shortcut.Save()

if ( $Admin ) {
    [System.IO.FileInfo]$Path = $Path
    $TempFileName = [System.IO.Path]::GetRandomFileName()
    $TempFile = [System.IO.FileInfo][System.IO.Path]::Combine($Path.Directory, $TempFileName)
    $Writer = New-Object System.IO.FileStream $TempFile, ([System.IO.FileMode]::Create)
    $Reader = $Path.OpenRead()
    While ($Reader.Position -lt $Reader.Length) {
        $Byte = $Reader.ReadByte()
        If ($Reader.Position -eq 22) {$Byte = 34}
        $Writer.WriteByte($Byte)
    }
    $Reader.Close()
    $Writer.Close()
    $Path.Delete()
    Rename-Item -Path $TempFile -NewName $Path.Name | Out-Null
}

exit 0
