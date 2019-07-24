PowerShell -NoProfile -Command Start-Process -Verb RunAs PowerShell '-ExecutionPolicy Bypass -NoProfile -NoExit -Command "%cd%\..\.psprofile.ps1; . @PS_Prepare-KlusterEnvironment.ps1; Wait-Key"'
