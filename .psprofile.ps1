$ROOT = "$HOME\Projects\kluster"

$env:ROOT = "$ROOT"
$env:PATH = "$env:PATH;$ROOT\scripts"

if ( -not (Get-Location).Path.StartsWith("$ROOT") ) {
    Set-Location "$ROOT"
}

Apply-PSConsoleSettings $ROOT\.psconsole.json

$e = [char]27
$env:STEPS_COLORS = "$e[38;5;45m,$e[92m,$e[93m,$e[91m,$e[0m"
#                    normal     ,green ,yellow,red   ,reset

$env:PACKER_ROOT = "$ROOT/packer".Replace("\", "/")
$env:PACKER_NO_COLOR = "true"
$env:PACKER_CACHE_DIR = "$env:PACKER_ROOT/packer_cache"
$env:PACKER_LOG_PATH = "$env:PACKER_ROOT/_packer.log"
$env:PACKER_LOG = "0"
