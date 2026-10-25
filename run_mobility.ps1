# ==============================================================================
# Mobility Platform — Automated Real-Time Launcher
# Trigger: "mobility app"
# ==============================================================================

$projectDir = "C:\Users\RAJAVEL\Desktop\mobility_project"
$localUrl = "http://127.0.0.1:8000"
$liveGhUrl = "https://raja-git77.github.io/mobility_project/"
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

Set-Location -Path $projectDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  MOBILITY PLATFORM -- REAL-TIME AUTONOMOUS LAUNCHER " -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "[*] Project Directory: $projectDir" -ForegroundColor Gray

# 1. Check if backend server is already responding
$isRunning = $false
try {
    $resp = Invoke-RestMethod -Uri "$localUrl/api/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
    if ($resp.status -eq "online") {
        $isRunning = $true
        Write-Host "[+] Local Server already running on $localUrl (DB: $($resp.db))" -ForegroundColor Green
    }
} catch {
    $isRunning = $false
}

# 2. Start backend server if not running
if (-not $isRunning) {
    $portConn = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
    if ($portConn) {
        Write-Host "[*] Freeing port 8000..." -ForegroundColor Yellow
        $portConn | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Milliseconds 500
    }

    Write-Host "[*] Starting real-time server (app.py) with Live-Reload / HMR..." -ForegroundColor Cyan
    $env:FLASK_DEBUG = "1"
    Start-Process -FilePath "python" -ArgumentList "app.py" -WorkingDirectory $projectDir -WindowStyle Normal

    # Wait for server health check
    $healthy = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 600
        try {
            $resp = Invoke-RestMethod -Uri "$localUrl/api/health" -Method Get -TimeoutSec 1 -ErrorAction Stop
            if ($resp.status -eq "online") {
                $healthy = $true
                break
            }
        } catch {}
    }

    if ($healthy) {
        Write-Host "[+] Local Server is ONLINE at $localUrl!" -ForegroundColor Green
    } else {
        Write-Host "[!] Local Server starting up in background..." -ForegroundColor Yellow
    }
}

# 3. Check and start Cloudflare Tunnel (Public HTTPS for remote strangers)
$tunnelProc = Get-Process cloudflared -ErrorAction SilentlyContinue
$publicUrl = ""
if (Test-Path "$projectDir\tunnel_url.txt") {
    $publicUrl = (Get-Content "$projectDir\tunnel_url.txt" -Raw).Trim()
}

if (-not $tunnelProc -or [string]::IsNullOrWhiteSpace($publicUrl)) {
    Write-Host "[*] Starting Cloudflare HTTPS Quick Tunnel..." -ForegroundColor Cyan
    Start-Process -FilePath "$projectDir\cloudflared.exe" -ArgumentList "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8000" -RedirectStandardError "$projectDir\cf_tunnel.log" -WindowStyle Hidden

    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 800
        if (Test-Path "$projectDir\cf_tunnel.log") {
            $match = Select-String -Path "$projectDir\cf_tunnel.log" -Pattern "https://[a-zA-Z0-9-]+\.trycloudflare\.com"
            if ($match) {
                $publicUrl = $match.Matches[0].Value
                Set-Content -Path "$projectDir\tunnel_url.txt" -Value $publicUrl
                $json = @{ api_url = $publicUrl; updated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"); status = "online" } | ConvertTo-Json
                Set-Content -Path "$projectDir\api_config.json" -Value $json
                Set-Content -Path "$projectDir\web\api_config.json" -Value $json
                Set-Content -Path "$projectDir\build\web\api_config.json" -Value $json
                Write-Host "[+] Public Tunnel Active: $publicUrl" -ForegroundColor Green
                break
            }
        }
    }
} else {
    Write-Host "[+] Public Tunnel already active: $publicUrl" -ForegroundColor Green
}

# 4. Register Chrome Omnibox Keywords
try {
    python add_chrome_keyword.py | Out-Null
} catch {}

# 5. Launch Google Chrome with Mobility Auto-Redirect Extension
Write-Host "[*] Launching Google Chrome with Auto-Redirect Extension..." -ForegroundColor Cyan
$extPath = "$projectDir\chrome_redirect_ext"
$chromeArgs = "--load-extension=`"$extPath`" `"$localUrl`""
if (Test-Path $chromePath) {
    Start-Process -FilePath $chromePath -ArgumentList $chromeArgs
} else {
    Start-Process "chrome" -ArgumentList $chromeArgs -ErrorAction SilentlyContinue
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Mobility Platform is LIVE & ACCESSIBLE EVERYWHERE! " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  1. Local Real-Time URL:   $localUrl" -ForegroundColor White
Write-Host "  2. Public Live Tunnel:    $publicUrl" -ForegroundColor White
Write-Host "  3. 24/7 GitHub Pages:     $liveGhUrl" -ForegroundColor White
Write-Host "  4. Chrome Omnibox:        Type 'mobility app' in Chrome" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan

# 6. Display Terminal QR Code for Instant Mobile Scanning
try {
    python -c "import sys, qrcode; sys.stdout.reconfigure(encoding='utf-8'); qr = qrcode.QRCode(border=1); qr.add_data('$liveGhUrl'); qr.print_ascii(invert=True)"
} catch {}
