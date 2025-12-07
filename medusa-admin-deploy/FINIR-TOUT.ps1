# Script FINAL qui fait TOUT automatiquement

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BUILD ET DEPLOY AUTOMATIQUE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifier et installer Medusa CLI
Write-Host "[1/4] Verification de Medusa CLI..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules/.bin/medusa")) {
    Write-Host "      Installation de Medusa CLI..." -ForegroundColor Gray
    npm install --save-dev @medusajs/medusa-cli@latest 2>&1 | Out-Null
}
Write-Host "      OK" -ForegroundColor Green

# Builder l'admin
Write-Host "[2/4] Build de l'admin Medusa..." -ForegroundColor Yellow
Write-Host "      Cela peut prendre 2-3 minutes..." -ForegroundColor Gray

$buildCmd = "node node_modules/@medusajs/medusa/dist/cli.js build --admin-only"
Invoke-Expression $buildCmd 2>&1 | Out-Null

if (Test-Path ".medusa/admin") {
    Write-Host "      Build REUSSI!" -ForegroundColor Green
    
    # Creer _redirects
    $redirectsFile = Join-Path ".medusa/admin" "_redirects"
    Set-Content -Path $redirectsFile -Value "/* /index.html 200" -Encoding UTF8
    
    $adminPath = Resolve-Path ".medusa/admin"
} else {
    Write-Host "      ERREUR: Build echoue" -ForegroundColor Red
    exit 1
}

# Preparer wrangler
Write-Host "[3/4] Preparation de Wrangler..." -ForegroundColor Yellow
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    npm install -g wrangler 2>&1 | Out-Null
}
Write-Host "      OK" -ForegroundColor Green

# Ouvrir et afficher
Write-Host "[4/4] Finalisation..." -ForegroundColor Yellow
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

