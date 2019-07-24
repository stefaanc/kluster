PowerShell -NoProfile -Command Start-Process -Verb RunAs PowerShell '-ExecutionPolicy Bypass -NoProfile -NoExit -Command "%cd%\..\.psprofile.ps1; . @PS__UPDATE-AFTER-REBOOT.ps1; Wait-Key; exit 0"'
