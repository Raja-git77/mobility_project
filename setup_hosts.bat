@echo off
title Mobility App - Hosts & Port 80 Proxy Setup
echo ==============================================================
echo    MOBILITY APP - WINDOWS HOSTS & PORT 80 PROXY CONFIGURATION
echo ==============================================================
echo.

:: 1. Add hosts entry for mobility and mobility.app
echo [*] Checking Windows hosts file...
findstr /i "127.0.0.1 mobility" "%windir%\system32\drivers\etc\hosts" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [+] Host mapping already present in hosts file.
) else (
    echo [+] Appending mobility mappings to hosts file...
    echo. >> "%windir%\system32\drivers\etc\hosts"
    echo # Mobility App local domain mapping >> "%windir%\system32\drivers\etc\hosts"
    echo 127.0.0.1 mobility >> "%windir%\system32\drivers\etc\hosts"
    echo 127.0.0.1 mobility.app >> "%windir%\system32\drivers\etc\hosts"
    echo [+] Hosts file updated!
)

:: 2. Port forwarding 80 -> 8000
echo [*] Configuring netsh port forwarding (Port 80 -^> Port 8000)...
netsh interface portproxy delete v4tov4 listenport=80 listenaddress=127.0.0.1 >nul 2>&1
netsh interface portproxy add v4tov4 listenport=80 listenaddress=127.0.0.1 connectport=8000 connectaddress=127.0.0.1
echo [+] Port 80 forwarding configured!

echo.
echo ==============================================================
echo [+] Success! You can now type http://mobility in Chrome!
echo ==============================================================
echo.
pause
