# Script ULTIME qui fait TOUT automatiquement

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOIEMENT AUTOMATIQUE COMPLET" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectName = "medusa-admin-final"
$projectPath = Join-Path $env:USERPROFILE "Downloads\$projectName"

# Nettoyage
Write-Host "[1/5] Nettoyage..." -ForegroundColor Yellow
if (Test-Path $projectPath) {
    Remove-Item -Path $projectPath -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      OK" -ForegroundColor Green

# Creer le projet avec create-medusa-app
Write-Host "[2/5] Creation du projet Medusa..." -ForegroundColor Yellow
Write-Host "      Cela peut prendre 3-5 minutes..." -ForegroundColor Gray
Write-Host "      Dossier: $projectPath" -ForegroundColor Gray

Push-Location (Join-Path $env:USERPROFILE "Downloads")

# Utiliser create-medusa-app avec des options non-interactives
$env:MEDUSA_TELEMETRY_DISABLED = "1"
$createCmd = "npx --yes create-medusa-app@latest $projectName --db-url `"postgres://localhost/test`" --skip-env --skip-db --skip-migrations --no-boilerplate"

Write-Host "      Execution de create-medusa-app..." -ForegroundColor Gray
Invoke-Expression $createCmd 2>&1 | Out-Null

if (-not (Test-Path $projectName)) {
    Write-Host "      ERREUR: Le projet n'a pas ete cree" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUTION MANUELLE:" -ForegroundColor Yellow
    Write-Host "1. Ouvrez un terminal PowerShell" -ForegroundColor White
    Write-Host "2. cd C:\Users\lecoa\Downloads" -ForegroundColor Green
    Write-Host "3. npx create-medusa-app@latest mon-projet" -ForegroundColor Green
    Write-Host "4. cd mon-projet" -ForegroundColor Green
    Write-Host "5. npx medusa build --admin-only" -ForegroundColor Green
    Write-Host "6. Deployez .medusa/admin sur Cloudflare Pages" -ForegroundColor White
    Pop-Location
    exit 1
}

Pop-Location
Push-Location $projectPath

Write-Host "      Projet cree!" -ForegroundColor Green

# Builder l'admin
Write-Host "[3/5] Build de l'admin..." -ForegroundColor Yellow
Write-Host "      Cela peut prendre 2-3 minutes..." -ForegroundColor Gray

try {
    npx medusa build --admin-only 2>&1 | Out-Null
    
    if (Test-Path ".medusa/admin") {
        Write-Host "      Build REUSSI!" -ForegroundColor Green
        
        # Creer _redirects
        $redirectsFile = Join-Path ".medusa/admin" "_redirects"
        Set-Content -Path $redirectsFile -Value "/* /index.html 200" -Encoding UTF8
        
        $adminPath = Resolve-Path ".medusa/admin"
    } else {
        throw "Build echoue"
    }
} catch {
    Write-Host "      ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Preparer wrangler
Write-Host "[4/5] Preparation de Wrangler..." -ForegroundColor Yellow
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    npm install -g wrangler 2>&1 | Out-Null
}
Write-Host "      OK" -ForegroundColor Green

# Ouvrir l'explorateur
Write-Host "[5/5] Ouverture de l'explorateur..." -ForegroundColor Yellow
Start-Process explorer.exe -ArgumentList $adminPath
Write-Host "      OK" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  TERMINE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Dossier admin: $adminPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "DEPLOIEMENT:" -ForegroundColor White
Write-Host ""
Write-Host "1. Interface Web:" -ForegroundColor Cyan
Write-Host "   https://dash.cloudflare.com > Pages > Create project" -ForegroundColor Green
Write-Host "   Upload: $adminPath" -ForegroundColor Green
Write-Host ""
Write-Host "2. Wrangler:" -ForegroundColor Cyan
Write-Host "   wrangler login" -ForegroundColor Green
Write-Host "   wrangler pages deploy `"$adminPath`"" -ForegroundColor Green
Write-Host ""
Write-Host "L'explorateur est ouvert!" -ForegroundColor Yellow
Write-Host ""

