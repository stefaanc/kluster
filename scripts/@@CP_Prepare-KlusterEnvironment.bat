PowerShell -NoProfile -Command Start-Process -Verb RunAs powershell.exe '-ExecutionPolicy Bypass -NoExit -Command ". @PS_Prepare-KlusterEnvironment.ps1; Wait-Key; exit 0"'
