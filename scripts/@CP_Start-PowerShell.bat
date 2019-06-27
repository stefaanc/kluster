setlocal EnableDelayedExpansion

@echo off
rem   All commands have to be concatenated on a single line to be able to pass them to PowerShell.
rem   Hence following rules:
rem   - make sure every line starts with at least one space         ( this avoids the first character being escaped by the ^ of the previous line )
rem   - make sure every line ends with ^                            ( this skips the <CR><LF> and escapes the first character of the next line )
rem   - make sure every code line ends with ;^                      ( this replaces <CR><LF> with a ; and escapes the first character of the next line )
rem   - put comments between ^<# and #^>                            ( this escapes the < and > for CommandPrompt, and this makes them in-line comments for PowerShell )
rem   - make sure the last line is a line with at least one space   ( this avoids the first character of the next line being escaped by the ^ of the previous line )
@echo on

rem
rem Set command
rem

set CMD=^
  ~\Projects\kluster\.psprofile.ps1 ;^
  
rem
rem Execute command
rem

PowerShell -NoProfile -Command Start-Process -Verb RunAs PowerShell '-ExecutionPolicy Bypass -NoExit -Command !CMD!'
