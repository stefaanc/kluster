Set-Variable HOME "$env:USERPROFILE" -Scope Global -Force
( Get-PSProvider 'FileSystem' ).Home = $HOME   # replace "~"

$global:ROOT = "$HOME\Projects\kluster"
$env:PATH = "$ROOT\scripts;$env:PATH"

if ( -not ( Get-Location ).Path.StartsWith("$ROOT") ) {
    Set-Location "$ROOT"
}

Apply-PSConsoleSettings "KLUSTER"

#
# for packer
$env:HOME = "$HOME"
$env:ROOT = "$ROOT"

$env:PACKER_ROOT = "$ROOT/packer".Replace("\", "/")
$env:PACKER_NO_COLOR = "true"
$env:PACKER_CACHE_DIR = "$env:PACKER_ROOT/packer_cache"
$env:PACKER_LOG_PATH = "$env:PACKER_ROOT/logs/_packer.log"
$env:PACKER_LOG = "1"

if ( ( $HOST.UI.RawUI.ForegroundColor -eq 'DarkYellow' ) -and ( $HOST.UI.RawUI.BackgroundColor -eq 'DarkMagenta' ) ) {
    # we are working with a legacy Powershell instance
    $env:PACKER_COMMON_COLORS = "DarkRed,DarkCyan,Green,Yellow,Red"
    $env:PACKER_ESXI_COLORS   = "DarkGray,DarkCyan,Green,Yellow,Red"
    $env:PACKER_HYPERV_COLORS = "DarkGray,DarkCyan,Green,Yellow,Red"
    $env:PACKER_KVM_COLORS    = "DarkGray,DarkCyan,Green,Yellow,Red"
    #                            normal,bright,green,yellow,red
}
else {
    # we are working with a modified Powershell instance
    # we assume a "Colorized" color-scheme is being used for the console
    $env:PACKER_COMMON_COLORS = "Blue,DarkCyan,Green,Yellow,Red"
    $env:PACKER_ESXI_COLORS   = "DarkGreen,DarkCyan,Green,Yellow,Red"
    $env:PACKER_HYPERV_COLORS = "DarkBlue,DarkCyan,Green,Yellow,Red"
    $env:PACKER_KVM_COLORS    = "Magenta,DarkCyan,Green,Yellow,Red"
    #                            normal,bright,green,yellow,red
}

$env:TF_ROOT = "$ROOT/terraform".Replace("\", "/")
$env:TF_INPUT = "false"
$env:TF_LOG_PATH = "$env:TF_ROOT/logs/_terraform.log"
$env:TF_LOG = "TRACE"

$env:TF_VAR_root = "$ROOT"
$env:TF_VAR_terraform = "$env:TF_ROOT"
