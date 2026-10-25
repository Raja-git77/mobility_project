@echo off
title Mobility Platform Server and Tunnel
cd /d "C:\Users\RAJAVEL\Desktop\mobility_project"

echo ===================================================
echo   MOBILITY PLATFORM - PERSISTENT SERVER & TUNNEL
echo ===================================================

echo [*] Cleaning old processes on port 8080...
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

del /f /q "C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_err.txt" 2>nul
del /f /q "C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_url.txt" 2>nul

echo [*] Starting Python multi-threaded server on 0.0.0.0:8080...
start "MobilityServer" python "C:\Users\RAJAVEL\Desktop\mobility_project\mobility_app\serve_mobile.py"

timeout /t 2 /nobreak >nul

echo [*] Starting Cloudflare Tunnel in separate persistent process...
start "CloudflareTunnel" cmd /c "npx --yes cloudflared tunnel --protocol http2 --url http://127.0.0.1:8080 2> C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_err.txt"

echo [*] Extracting tunnel URL...
powershell -Command "for ($i=0; $i -lt 15; $i++) { Start-Sleep -Seconds 2; if (Test-Path 'C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_err.txt') { $m = Select-String -Path 'C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_err.txt' -Pattern 'https://[a-zA-Z0-9-]+\.trycloudflare\.com'; if ($m) { $u = $m.Matches[0].Value; Set-Content -Path 'C:\Users\RAJAVEL\Desktop\mobility_project\tunnel_url.txt' -Value $u; Write-Host '[+] Live Public URL:' $u; break; } } }"

echo.
echo ===================================================
echo [*] Mobility Platform is LIVE! Keep this window open.
echo ===================================================
pause
