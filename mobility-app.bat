@echo off
setlocal
cd /d "C:\Users\RAJAVEL\Desktop\mobility_project"
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\RAJAVEL\Desktop\mobility_project\run_mobility.ps1" %*
