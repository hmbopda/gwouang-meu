@echo off
echo ========================================
echo  GWANG MEU - Lancement en mode DEV
echo ========================================

:: ===== JAVA (chemin court sans caracteres speciaux) =====
set JAVA_HOME=C:\Users\HUGUES~1\JDKS~1\MS-170~1.17
set PATH=%JAVA_HOME%\bin;%PATH%

:: ===== MAVEN (chemin court sans caracteres speciaux) =====
set PATH=C:\Users\HUGUES~1\M2E4AB~1\wrapper\dists\APACHE~1.11-\6MQF5T~1\APACHE~1.11\bin;%PATH%

:: ===== SUPABASE =====
set SUPABASE_DB_URL=jdbc:postgresql://db.objlxdxzpqhrekpqxgab.supabase.co:5432/postgres
set SUPABASE_DB_USER=postgres
set SUPABASE_DB_PASSWORD=Gompemeu12042024@
set SUPABASE_JWT_ISSUER_URI=https://objlxdxzpqhrekpqxgab.supabase.co/auth/v1
set SUPABASE_JWKS_URI=https://objlxdxzpqhrekpqxgab.supabase.co/auth/v1/.well-known/jwks.json

:: ===== NEO4J =====
set NEO4J_URI=neo4j+s://83496284.databases.neo4j.io
set NEO4J_USERNAME=83496284
set NEO4J_PASSWORD=O-lqwBh94CmffVPOEhvXyfzDmw_NskS5b9sjqCGGAKk

:: ===== REDIS =====
set REDIS_URL=rediss://default:Af02AAIncDIyN2RkZjdiMWRjODE0OWQwYTUyODQ5ZmNlZDQ5MmFhZXAyNjQ4MjI@outgoing-condor-64822.upstash.io:6379

:: ===== SPRING =====
set SPRING_PROFILES_ACTIVE=dev

:: Verification Java
"%JAVA_HOME%\bin\java.exe" -version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: Java introuvable dans %JAVA_HOME%
    pause
    exit /b 1
)

echo Java    OK : %JAVA_HOME%
echo Profile    : %SPRING_PROFILES_ACTIVE%
echo.
echo Compilation et demarrage du backend...
echo.

cd /d "%~dp0backend"
mvn compile spring-boot:run

pause
