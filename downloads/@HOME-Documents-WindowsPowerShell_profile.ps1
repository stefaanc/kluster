if ( -not $HOME ) {
    Set-Variable HOME "$env:USERPROFILE" -Scope Global -Force
    ( Get-PSProvider 'FileSystem' ).Home = $HOME   # replace "~"
}

$global:ROOT = $null

#
# find the closest folder in the current path, that has a '.psprofile.ps1' file
if ( -not $ROOT ) {
    function FindRoot {
        $current = "$( Get-Location )"
        while ( -not $root -and $current.StartsWith("$HOME") ) {
            #
            # try current
            if ( Test-Path -Path "$current\.psprofile.ps1" ) {
                break
            }

            #
            # try parent
            $current = Split-Path -Path $current
        }
        if ( -not $current.StartsWith("$HOME") ) {
            $current = $null
        }
        return $current
    }

    $global:ROOT = "$( FindRoot )"

    if ( $ROOT ) {
       #
       # run '.psprofile.ps1'
       . "$ROOT\.psprofile.ps1"
       exit 0
    }
}

#
# find the default-project profile
if ( -not $ROOT ) {
    ~\Projects\.psprofile.ps1   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< you may have to change this
}

#
# run default-master profile
if ( -not $ROOT ) {
    $global:ROOT = $HOME
    $env:PATH = "$ROOT\Documents\WindowsPowerShell\scripts;$env:PATH"

    if ( -not ( Get-Location ).Path.StartsWith("$ROOT") ) {
        Set-Location "$ROOT"
    }

    Apply-PSConsoleSettings
}
