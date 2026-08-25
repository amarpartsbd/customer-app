# Automated per-tenant APK build

The ERP's **Customer App** page has a "Build App" button. It sends a
`repository_dispatch` to this repo, the workflow (`.github/workflows/build.yml`)
builds a branded, signed APK, uploads it to storage, and calls back to the ERP
with the download URL (which auto-fills the store's "Download app" link).

## One-time setup

### 1. This repo (GitHub) — Settings → Secrets and variables → Actions

**Signing (one platform keystore signs every tenant's app):**
- `ANDROID_KEYSTORE_BASE64` — `base64 -i upload-keystore.jks` output
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Generate a keystore once:
```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Callback auth (must equal the ERP's `APPBUILD_CALLBACK_SECRET`):**
- `APPBUILD_CALLBACK_SECRET` — any long random string

**APK storage (S3 or Cloudflare R2, public bucket):**
- `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_REGION`
- `S3_BUCKET` — bucket name
- `S3_PUBLIC_BASE` — public URL base, e.g. `https://cdn.yourdomain.com`
- `S3_ENDPOINT` — only for R2 (e.g. `https://<acct>.r2.cloudflarestorage.com`)

### 2. The ERP — `.env`
```
APPBUILD_ENABLED=true
APPBUILD_GITHUB_REPO=<owner>/customer-app
APPBUILD_GITHUB_TOKEN=<PAT with "contents: write" on this repo>
APPBUILD_EVENT_TYPE=build-customer-app
APPBUILD_CALLBACK_SECRET=<same secret as the GitHub one>
APPBUILD_PACKAGE_PREFIX=cloud.sahin.store
```
Then `php artisan config:clear`.

## Flow
1. Tenant sets app name / icon / color on the Customer App page → **Build App**.
2. ERP creates an `app_builds` row (queued) and dispatches to GitHub.
3. Workflow: prepare branding → build signed APK → upload → callback.
4. Build status shows live on the admin page; when ready the APK download link
   appears there and on the storefront ("অ্যাপ ডাউনলোড").

Package id per tenant: `<APPBUILD_PACKAGE_PREFIX>.t<companyId>` (unique, stable).
