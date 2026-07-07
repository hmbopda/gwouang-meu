# Expose le backend local sur une URL publique temporaire (trycloudflare.com).
# ATTENTION : l'URL change a chaque lancement -> reconstruire le frontend
# (API_BASE_URL dans frontend/.env) si elle a change.
$ErrorActionPreference = 'Stop'
$log = "$env:TEMP\gwangmeu-tunnel.log"
Write-Host "Demarrage du tunnel - log : $log"

Start-Process -FilePath 'cloudflared' `
    -ArgumentList 'tunnel', '--url', 'http://localhost:8080' `
    -WindowStyle Hidden `
    -RedirectStandardOutput "$env:TEMP\gwangmeu-tunnel.out.log" `
    -RedirectStandardError $log

Start-Sleep -Seconds 8
$url = (Select-String -Path $log -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -AllMatches |
    ForEach-Object { $_.Matches } | Select-Object -First 1).Value
Write-Host "URL publique du backend : $url"
