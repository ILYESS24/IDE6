# 🚀 Déploiement Admin Medusa sur Cloudflare Pages - INSTRUCTIONS FINALES

## ✅ Solution Simple et Directe

Pour déployer l'**interface admin de base** de Medusa sur Cloudflare Pages, suivez ces étapes :

### 1️⃣ Créer un projet Medusa

Ouvrez un **nouveau terminal PowerShell** et exécutez :

```powershell
cd C:\Users\lecoa\Downloads
npx create-medusa-app@latest mon-projet-medusa
```

**Répondez aux questions :**
- Database : `PostgreSQL` (ou `SQLite` pour test rapide)
- Redis : `Oui` (ou `Non` pour test)
- Admin : `Oui` ✅
- Storefront : `Non` (optionnel)

### 2️⃣ Builder l'admin

```powershell
cd mon-projet-medusa
npx medusa build --admin-only
```

Le build sera dans : `.medusa/admin`

### 3️⃣ Déployer sur Cloudflare Pages

**Option A : Interface Web (RECOMMANDÉ) ⭐**

1. Allez sur https://dash.cloudflare.com
2. Cliquez sur **Pages** dans le menu de gauche
3. Cliquez sur **Create a project**
4. Choisissez **Upload assets**
5. Sélectionnez le dossier `.medusa/admin` de votre projet
6. Cliquez sur **Deploy site**

**Option B : Wrangler CLI**

```powershell
wrangler login
wrangler pages deploy .medusa/admin --project-name=medusa-admin
```

### 4️⃣ Configurer

Dans les paramètres du projet Cloudflare Pages, ajoutez la variable d'environnement :

- **Nom** : `MEDUSA_BACKEND_URL`
- **Valeur** : URL de votre serveur Medusa backend (ex: `http://localhost:9000` ou `https://votre-backend.herokuapp.com`)

## ✅ Résultat

Votre admin Medusa sera accessible sur :
- `https://votre-projet.pages.dev`

## 📝 Notes

- L'admin doit pointer vers un backend Medusa actif
- Configurez CORS sur votre backend pour autoriser le domaine Cloudflare Pages
- L'URL de l'admin sera permanente (contrairement aux tunnels temporaires)

