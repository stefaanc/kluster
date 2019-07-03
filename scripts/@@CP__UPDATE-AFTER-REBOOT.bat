PowerShell -NoProfile -Command Start-Process -Verb RunAs PowerShell '-ExecutionPolicy Bypass -NoExit -Command ". @PS__UPDATE-AFTER-REBOOT.ps1; Wait-Key; exit 0"'
