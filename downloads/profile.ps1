if ( -not $HOME ) {
    Set-Variable HOME "$env:USERPROFILE" -Scope Global -Force
    ( Get-PSProvider 'FileSystem' ).Home = $HOME   # replace "~"
}

#
# find the closest folder in the current path, that has a '.psprofile.ps1' file
if ( -not $ROOT ) {
    function FindRoot {
        $root = $null
        $current = "$( Get-Location )"
        while ( -not $root -and $current.StartsWith("$HOME") ) {
            #
            # try current
            if ( Test-Path -Path "$current\.psprofile.ps1" ) {
                $root = $current
                break
            }

            #
            # try parent
            $current = Split-Path -Path $current
        }
        return $root
    }

    $ROOT = "$( FindRoot )"
}

#
# run '.psprofile.ps1'
if ( $ROOT ) {
    . "$ROOT\.psprofile.ps1"
}
else {
    . ~\Projects\.psprofile.ps1
}
