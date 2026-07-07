# Demarre le backend GWANG MEU en processus detache (survit a la fermeture du terminal).
# Prerequis : backend/target/gwangmeu-backend-*.jar (mvn package -DskipTests)
# Config : racine .env + overrides pooler depuis backend/prod.md (non versionne).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# -- Variables d'environnement depuis .env --
Get-Content "$root\.env" | ForEach-Object {
    if ($_ -match '^([A-Z_0-9]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

# -- Overrides pooler Supabase (IPv4) depuis backend/prod.md --
$prod = Get-Content "$root\backend\prod.md" -Raw
foreach ($k in 'SUPABASE_DB_URL', 'SUPABASE_DB_USER', 'SUPABASE_DB_PASSWORD') {
    if ($prod -match "(?m)^$k=(.+)$") {
        [System.Environment]::SetEnvironmentVariable($k, $matches[1].Trim(), 'Process')
    }
}

$env:APP_URL = 'http://localhost:8080'
$env:LANDING_URL = 'http://localhost:3000'
# V6 corrigee apres application -> checksum divergent, validation assouplie
$env:SPRING_FLYWAY_VALIDATE_ON_MIGRATE = 'false'

$jar = Get-ChildItem "$root\backend\target\gwangmeu-backend-*.jar" | Select-Object -First 1
$log = "$env:TEMP\gwangmeu-backend.log"
Write-Host "Demarrage du backend ($($jar.Name)) - log : $log"

Start-Process -FilePath 'java' `
    -ArgumentList '-Dfile.encoding=UTF-8', '-jar', $jar.FullName `
    -WindowStyle Hidden `
    -RedirectStandardOutput $log `
    -RedirectStandardError "$env:TEMP\gwangmeu-backend.err.log"

Write-Host 'Backend lance. Sante : http://localhost:8080/actuator/health'
