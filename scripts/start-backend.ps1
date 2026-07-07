# Demarre le backend GWANG MEU dans WSL Ubuntu (processus detache).
#
# POURQUOI WSL : sur ce poste, la JVM Windows ne peut ouvrir aucun Selector NIO
# ("Unable to establish loopback connection" — verifie via jshell), Tomcat ne
# peut donc pas demarrer nativement. La JVM Linux de WSL n'a pas ce probleme.
#
# Prerequis (une fois) :
#   - wsl --install -d Ubuntu --no-launch
#   - wsl -d Ubuntu -u root -- apt-get install -y openjdk-21-jre-headless redis-server
#   - /etc/wsl.conf : [network] generateResolvConf=false, et /etc/resolv.conf statique
#     (nameserver 1.1.1.1) — le DNS auto de WSL est instable sur ce poste.
#   - mvn package -DskipTests dans backend/
#
# Ce script : synchronise jar + env dans WSL puis lance /opt/start-gw.sh
# (redis local + export env + java) ancre a un wsl.exe detache.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$staging = "$env:TEMP\gw"
New-Item -ItemType Directory -Force $staging | Out-Null

# -- Env : .env racine + overrides pooler de backend/prod.md + ajustements locaux --
$lines = @()
Get-Content "$root\.env" | ForEach-Object { if ($_ -match '^[A-Z_0-9]+=') { $lines += $_ } }
$prod = Get-Content "$root\backend\prod.md" -Raw
foreach ($k in 'SUPABASE_DB_URL', 'SUPABASE_DB_USER', 'SUPABASE_DB_PASSWORD', 'SUPABASE_SERVICE_KEY', 'JWT_SECRET') {
    if ($prod -match "(?m)^$k=(.+)$") { $lines += "$k=$($matches[1].Trim())" }
}
$lines += 'REDIS_URL=redis://localhost:6379'          # Upstash supprime -> redis local WSL
$lines += 'APP_URL=http://localhost:8080'
$lines += 'LANDING_URL=http://localhost:3000'
$lines += 'SPRING_FLYWAY_VALIDATE_ON_MIGRATE=false'   # V6 corrigee apres application
$lines += 'MANAGEMENT_HEALTH_NEO4J_ENABLED=false'     # AuraDB en pause (lecture PG-first)
$lines += 'MANAGEMENT_HEALTH_MAIL_ENABLED=false'      # Resend sans cle (optionnel)
# Dedup : la DERNIERE occurrence gagne
$seen = @{}; $final = @()
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    $k = $lines[$i].Split('=')[0]
    if (-not $seen.ContainsKey($k)) { $seen[$k] = $true; $final = , $lines[$i] + $final }
}
[System.IO.File]::WriteAllLines("$staging\gw.env", $final)

# -- Jar + lanceur --
$jar = Get-ChildItem "$root\backend\target\gwangmeu-backend-*.jar" | Select-Object -First 1
Copy-Item $jar.FullName "$staging\app.jar" -Force
@'
#!/bin/bash
service redis-server start >/dev/null 2>&1 || true
while IFS= read -r line; do
  case "$line" in
    ""|\#*) ;;
    *) export "$line" ;;
  esac
done < /opt/gw.env
exec java -Dfile.encoding=UTF-8 -jar /opt/app.jar
'@ -replace "`r", '' | Set-Content "$staging\start-gw.sh" -NoNewline -Encoding ascii

# -- Synchronisation dans WSL puis lancement ancre --
$winStaging = $staging -replace '\\', '/'
wsl.exe -d Ubuntu -u root -- bash -c "D=`$(wslpath '$winStaging'); cp `"`$D/app.jar`" /opt/app.jar; cp `"`$D/gw.env`" /opt/gw.env; cp `"`$D/start-gw.sh`" /opt/start-gw.sh; sed -i 's/\r`$//' /opt/gw.env /opt/start-gw.sh; chmod +x /opt/start-gw.sh; pkill java 2>/dev/null; true"
Start-Process wsl.exe -ArgumentList '-d', 'Ubuntu', '-u', 'root', '--', '/opt/start-gw.sh' `
    -WindowStyle Hidden `
    -RedirectStandardOutput "$env:TEMP\gwangmeu-wsl.log" `
    -RedirectStandardError "$env:TEMP\gwangmeu-wsl.err.log"

Write-Host 'Backend lance dans WSL. Sante : http://localhost:8080/actuator/health'
Write-Host "Log : $env:TEMP\gwangmeu-wsl.log"
