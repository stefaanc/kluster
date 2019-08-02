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
$env:PACKER_LOG = "0"

$e = [char]27
if ( ( $HOST.UI.RawUI.ForegroundColor -eq 'DarkYellow' ) -and ( $HOST.UI.RawUI.BackgroundColor -eq 'DarkMagenta' ) ) {
    # we are working with a legacy Powershell instance
    $env:PACKER_COMMON_COLORS = "$e[91m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    $env:PACKER_ESXI_COLORS   = "$e[37m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    $env:PACKER_HYPERV_COLORS = "$e[37m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    #                            normal,bright,green ,yellow,red   ,reset
}
else {
    # we are working with a modified Powershell instance
    # we assume a "Colorized" color-scheme is being used for the console
    $env:PACKER_COMMON_COLORS = "$e[94m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    $env:PACKER_ESXI_COLORS   = "$e[32m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    $env:PACKER_HYPERV_COLORS = "$e[34m,$e[36m,$e[92m,$e[93m,$e[91m,$e[0m"
    #                            normal,bright,green ,yellow,red   ,reset
}
