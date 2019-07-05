Set-Variable HOME "$env:USERPROFILE" -Scope Global -Force
( Get-PSProvider 'FileSystem' ).Home = $HOME   # replace "~"

$ROOT = "$HOME\Projects\kluster"
$PATH = "$ROOT\scripts;$env:PATH"

$env:HOME = $HOME
$env:ROOT = $ROOT
$env:PATH = $PATH

if ( -not ( Get-Location ).Path.StartsWith("$ROOT") ) {
    Set-Location "$ROOT"
}

. Apply-PSConsoleSettings "KLUSTER"

$env:PACKER_ROOT = "$ROOT/packer".Replace("\", "/")
$env:PACKER_NO_COLOR = "true"
$env:PACKER_CACHE_DIR = "$env:PACKER_ROOT/packer_cache"
$env:PACKER_LOG_PATH = "$env:PACKER_ROOT/logs/_packer.log"
$env:PACKER_LOG = "0"
