# Script ULTIME qui fait TOUT automatiquement

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOIEMENT AUTOMATIQUE COMPLET" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectName = "medusa-admin-pages"
$projectPath = Join-Path $env:USERPROFILE "Downloads\$projectName"

# Nettoyage
Write-Host "[1/6] Nettoyage..." -ForegroundColor Yellow
Get-Process -Name "cloudflared","node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
if (Test-Path $projectPath) {
    Remove-Item -Path $projectPath -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      OK" -ForegroundColor Green

# Creer le projet
Write-Host "[2/6] Creation du projet Medusa..." -ForegroundColor Yellow
Write-Host "      Dossier: $projectPath" -ForegroundColor Gray
Write-Host "      Cela peut prendre 3-5 minutes..." -ForegroundColor Gray

New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
Push-Location $projectPath

# Creer package.json
$packageJson = @{
    name = $projectName
    version = "1.0.0"
    private = $true
    scripts = @{
        build = "medusa build --admin-only"
    }
    dependencies = @{
        "@medusajs/medusa" = "^2.0.0"
    }
} | ConvertTo-Json -Depth 10

Set-Content -Path "package.json" -Value $packageJson -Encoding UTF8

# Creer medusa-config.js
$config = @"
module.exports = {
  projectConfig: {
    database_url: "postgres://localhost/medusa",
    database_type: "postgres",
    http: {
      jwtSecret: "supersecret",
      cookieSecret: "supersecret"
    }
  },
  admin: {
    disable: false,
    backendUrl: process.env.MEDUSA_BACKEND_URL || "http://localhost:9000"
  }
}
"@

Set-Content -Path "medusa-config.js" -Value $config -Encoding UTF8

# Installer Medusa
Write-Host "      Installation de Medusa..." -ForegroundColor Gray
npm install --yes @medusajs/medusa@latest 2>&1 | Out-Null

if (-not (Test-Path "node_modules/@medusajs/medusa")) {
    Write-Host "      ERREUR: Installation echouee" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "      Projet cree!" -ForegroundColor Green

# Builder l'admin
Write-Host "[3/6] Build de l'admin..." -ForegroundColor Yellow
Write-Host "      Cela peut prendre 2-3 minutes..." -ForegroundColor Gray

# Utiliser le CLI Medusa directement
$medusaCli = Join-Path "node_modules/@medusajs/medusa" "dist/cli.js"
if (Test-Path $medusaCli) {
    node $medusaCli build --admin-only 2>&1 | Out-Null
} else {
    # Essayer avec npx
    npx medusa build --admin-only 2>&1 | Out-Null
}

if (Test-Path ".medusa/admin") {
    Write-Host "      Build REUSSI!" -ForegroundColor Green
    
    # Creer _redirects
    $redirectsFile = Join-Path ".medusa/admin" "_redirects"
    Set-Content -Path $redirectsFile -Value "/* /index.html 200" -Encoding UTF8
    
    $adminPath = Resolve-Path ".medusa/admin"
} else {
    Write-Host "      ERREUR: Build echoue" -ForegroundColor Red
    Write-Host "      Tentative alternative..." -ForegroundColor Yellow
    
    # Alternative: utiliser directement le package admin
    Pop-Location
    $altPath = Join-Path $env:USERPROFILE "Downloads\medusa-develop\medusa\packages\admin\dashboard"
    
    if (Test-Path $altPath) {
        Push-Location $altPath
        Write-Host "      Build depuis le package source..." -ForegroundColor Gray
        
        yarn install 2>&1 | Out-Null
        $env:VITE_MEDUSA_BACKEND_URL = "http://localhost:9000"
        npx vite build --mode production 2>&1 | Out-Null
        
        if (Test-Path "dist") {
            $adminPath = Resolve-Path "dist"
            Write-Host "      Build REUSSI (alternative)!" -ForegroundColor Green
        } else {
            Write-Host "      ERREUR: Build alternatif echoue" -ForegroundColor Red
            Pop-Location
            exit 1
        }
        Pop-Location
    } else {
        Write-Host "      ERREUR: Aucune methode disponible" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

Pop-Location

# Preparer wrangler
Write-Host "[4/6] Preparation de Wrangler..." -ForegroundColor Yellow
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    npm install -g wrangler 2>&1 | Out-Null
}
Write-Host "      OK" -ForegroundColor Green

# Creer un fichier README
Write-Host "[5/6] Creation du README..." -ForegroundColor Yellow
$readme = @"
# Admin Medusa - Pret pour Cloudflare Pages

Dossier: $adminPath

## Deploiement

1. Interface Web:
   - https://dash.cloudflare.com > Pages > Create project
   - Upload: $adminPath

2. Wrangler CLI:
   wrangler login
   wrangler pages deploy `"$adminPath`"

## Configuration

Ajoutez dans Cloudflare Pages:
- MEDUSA_BACKEND_URL = URL de votre backend Medusa
"@

Set-Content -Path (Join-Path $adminPath "README.txt") -Value $readme -Encoding UTF8
Write-Host "      OK" -ForegroundColor Green

# Ouvrir l'explorateur
Write-Host "[6/6] Ouverture de l'explorateur..." -ForegroundColor Yellow
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

