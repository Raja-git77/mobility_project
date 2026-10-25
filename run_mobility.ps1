# ==============================================================================
# Mobility Platform — Automated Real-Time Launcher
# Trigger: "mobility app"
# ==============================================================================

$projectDir = "C:\Users\RAJAVEL\Desktop\mobility_project"
$url = "http://127.0.0.1:8000"
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

Set-Location -Path $projectDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  MOBILITY PLATFORM -- REAL-TIME ENVIRONMENT TRIGGER  " -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "[*] Project Directory: $projectDir" -ForegroundColor Gray

# 1. Check if server is already responding
$isRunning = $false
try {
    $resp = Invoke-RestMethod -Uri "$url/api/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
    if ($resp.status -eq "online") {
        $isRunning = $true
        Write-Host "[+] Server already running on $url (DB: $($resp.db))" -ForegroundColor Green
    }
} catch {
    $isRunning = $false
}

# 2. Start server if not running
if (-not $isRunning) {
    # Check if a defunct process is occupying port 8000 and clear it
    $portConn = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
    if ($portConn) {
        Write-Host "[*] Freeing up busy port 8000..." -ForegroundColor Yellow
        $portConn | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Milliseconds 500
    }

    Write-Host "[*] Starting real-time server (app.py) with Live-Reload / HMR..." -ForegroundColor Cyan
    $env:FLASK_DEBUG = "1"
    Start-Process -FilePath "python" -ArgumentList "app.py" -WorkingDirectory $projectDir -WindowStyle Normal

    # Wait for server to become healthy
    Write-Host "[*] Waiting for server health check..." -ForegroundColor Gray
    $healthy = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 600
        try {
            $resp = Invoke-RestMethod -Uri "$url/api/health" -Method Get -TimeoutSec 1 -ErrorAction Stop
            if ($resp.status -eq "online") {
                $healthy = $true
                break
            }
        } catch {}
    }

    if ($healthy) {
        Write-Host "[+] Server is ONLINE & HEALTHY at $url!" -ForegroundColor Green
    } else {
        Write-Host "[!] Server started, continuing to launch browser..." -ForegroundColor Yellow
    }
}

# 3. Launch Google Chrome
Write-Host "[*] Launching Google Chrome at $url..." -ForegroundColor Cyan
if (Test-Path $chromePath) {
    Start-Process -FilePath $chromePath -ArgumentList "$url"
} else {
    Start-Process "chrome" -ArgumentList "$url" -ErrorAction SilentlyContinue
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Mobility Platform is LIVE in Google Chrome!        " -ForegroundColor Green
Write-Host "  URL: $url                                          " -ForegroundColor White
Write-Host "  Flutter App: $url/flutter                          " -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Cyan
