# Cloudflare Pages + Firebase (Auth & Firestore) — full setup

This project hosts the **Flutter web** build on **Cloudflare Pages** (free tier) and uses **Firebase Authentication** + **Cloud Firestore** so each user’s sermon draft is stored under their account.

Android builds use the same Firebase project via `google-services.json` (see §6).

---

## 1. Prerequisites

- A [Firebase](https://console.firebase.google.com/) project (free **Spark** plan is enough to start).
- A [Cloudflare](https://dash.cloudflare.com/) account.
- [Flutter](https://docs.flutter.dev/get-started/install) installed locally.
- Optional: [Node.js](https://nodejs.org/) if you deploy with Wrangler from your laptop.
- Optional: GitHub repo for **automatic** deploys via Actions.

---

## 2. Create and configure Firebase

### 2.1 Create the Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/) → **Add project**.
2. Disable Google Analytics if you do not need it (optional).
3. Wait for the project to finish provisioning.

### 2.2 Register apps (Web + Android)

**Web**

1. Project overview → **Add app** → **Web** (</>).
2. Register the app (nickname e.g. `sermon-notes-web`). You do **not** need Hosting for this flow (Cloudflare serves the site).
3. Copy the `firebaseConfig` values — you will use them in §4, or FlutterFire will fill them automatically.

**Android**

1. **Add app** → **Android**.
2. **Android package name** must match Flutter: `com.sermonnotes.sermon_notes` (see `android/app/build.gradle` → `applicationId`).
3. Download **`google-services.json`**.
4. Place it at:

   `sermon_notes/android/app/google-services.json`

   (This path is **gitignored**; never commit secrets. Use `google-services.json.example` only as a shape reference.)

### 2.3 Enable Authentication (Email/Password)

1. Firebase Console → **Build** → **Authentication** → **Get started**.
2. **Sign-in method** → **Email/Password** → Enable **Email/Password** (first toggle).  
   (You can leave “Email link” off unless you want it later.)

### 2.4 Create Firestore

1. **Build** → **Firestore Database** → **Create database**.
2. Start in **production mode** (you will deploy rules from this repo in §3).
3. Pick a **region** close to your users (cannot be changed later).

### 2.5 Authorized domains (required for web sign-in)

1. **Authentication** → **Settings** → **Authorized domains**.
2. Add:
   - Your **Cloudflare Pages** hostname, e.g. `your-project.pages.dev`.
   - Your **custom domain** if you add one later.
   - `localhost` is usually already allowed for local `flutter run -d chrome`.

Without this step, sign-in on the deployed site fails with an “unauthorized domain” style error.

---

## 3. Deploy Firestore security rules

Rules live in `firebase/firestore.rules` in this repository. They allow each user to read/write only:

`users/{theirUid}/data/*`

From the **repository root** (where `firebase.json` is):

```bash
npm install -g firebase-tools
firebase login
firebase use --add    # select your Firebase project
firebase deploy --only firestore:rules
```

To deploy indexes (currently empty, but kept for future queries):

```bash
firebase deploy --only firestore:indexes
```

---

## 4. Flutter: connect to Firebase (`firebase_options.dart`)

The app ships a **template** `sermon_notes/lib/firebase_options.dart` with placeholders. Replace it using the official tool:

```bash
dart pub global activate flutterfire_cli
cd sermon_notes
flutterfire configure
```

- Select your Firebase project.
- Select **Web** and **Android** (and others only if you actually build those platforms).

This **overwrites** `lib/firebase_options.dart` with real keys. Re-run after you add a new app in Firebase.

**Local checks**

```bash
cd sermon_notes
flutter run -d chrome
flutter run -d android   # requires google-services.json
```

Sign in via the **person** icon in the app bar; edits should sync to Firestore document:

`users/<uid>/data/sermon_draft`

---

## 5. Cloudflare Pages (free static hosting)

### 5.1 What gets deployed

- Build output directory: `sermon_notes/build/web`
- SPA fallback: `sermon_notes/web/_redirects` → copied into `build/web` so refreshes on deep routes load `index.html`.

### 5.2 One-time: create a Pages project

**Dashboard**

1. Cloudflare → **Workers & Pages** → **Create** → **Pages**.
2. Connect your Git repository **or** choose **Direct Upload** (manual).

**CLI (optional)**

```bash
npx wrangler pages project create YOUR_PROJECT_NAME --production-branch=main
```

### 5.3 Build settings (Dashboard)

If Cloudflare builds from Git:

| Setting            | Value                          |
|--------------------|--------------------------------|
| Root directory     | `sermon_notes` (if mono-repo) or repo root — see note below |
| Build command      | `flutter build web --release`  |
| Build output dir   | `build/web`                    |

**Note:** The default Flutter template does **not** include the Flutter SDK on Cloudflare’s build image. Easiest free path is **GitHub Actions** building Flutter and uploading the `build/web` folder (see §5.5). Alternatively use a **custom build container** — more work.

### 5.4 Manual deploy from your machine

```bash
cd sermon_notes
flutter pub get
flutter build web --release
npx wrangler pages deploy build/web --project-name=YOUR_PROJECT_NAME
```

You will need a Cloudflare **API token** with **Account → Cloudflare Pages → Edit** (and **Account settings → Read** if prompted).

### 5.5 GitHub Actions (recommended)

Workflow: `.github/workflows/deploy-cloudflare-pages.yml`

**Repository secrets**

| Secret | Purpose |
|--------|---------|
| `CLOUDFLARE_API_TOKEN` | API token with Pages deploy permission |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID from Cloudflare dashboard |
| `CLOUDFLARE_PAGES_PROJECT_NAME` | Exact Pages project name |

On push to `main`, the workflow runs `flutter build web` and `wrangler pages deploy`.

---

## 6. Android release checklist

1. `google-services.json` in `android/app/`.
2. `flutterfire configure` has generated `firebase_options.dart` with an **Android** entry.
3. `minSdk` is **23** in `android/app/build.gradle` (required by current Firebase stack).
4. Play Console / internal testing as you prefer.

---

## 7. Data model & behavior

- **Local:** `SharedPreferences` key `sermon_draft_v1` (offline cache).
- **Cloud (signed in):** Firestore doc `users/<uid>/data/sermon_draft` with:
  - `draftJson` — same JSON as local
  - `updatedAt` — server timestamp

**Merge rule (MVP):** When you are signed in and a remote draft exists, the **remote draft replaces** the local UI (then local prefs are updated). If remote is empty, the app **uploads** your current local draft.

---

## 8. Troubleshooting

| Symptom | Likely fix |
|--------|------------|
| Sign-in works locally but not on Pages | Add your `*.pages.dev` (and custom) domain under Firebase **Authorized domains**. |
| `PERMISSION_DENIED` in Firestore | Deploy rules (`firebase deploy --only firestore:rules`) and ensure the user is signed in. |
| Android Gradle error about `google-services.json` | Add the real file from Firebase; the template `.example` is not enough to build. |
| Web: `Firebase.initializeApp` errors | Re-run `flutterfire configure`; check `firebase_options.dart` matches the Web app in Firebase. |
| Cloudflare build has no Flutter | Use GitHub Actions in this repo or build locally and `wrangler pages deploy`. |

---

## 9. Files added for this stack

| Path | Purpose |
|------|---------|
| `firebase/firestore.rules` | User-scoped access rules |
| `firebase/firestore.indexes.json` | Index definitions (empty starter) |
| `firebase.json` | Firebase CLI entry (Firestore only — no Firebase Hosting) |
| `sermon_notes/web/_redirects` | SPA fallback on Pages |
| `sermon_notes/lib/firebase_options.dart` | FlutterFire config (replace via CLI) |
| `sermon_notes/lib/services/sermon_cloud_sync.dart` | Auth + Firestore sync |
| `sermon_notes/lib/widgets/account_sheet.dart` | Email sign-in UI |
| `.github/workflows/deploy-cloudflare-pages.yml` | CI → Pages deploy |
| `cloudflare/pages.md` | Short Wrangler reference |

---

## 10. Optional next steps

- **Email verification** / password reset flows in the account sheet.
- **Google Sign-In** (extra OAuth client setup in Firebase + platform config).
- **Cloudflare Worker** as a **CORS proxy** for “Load outline from URL” on web (still subject to terms of use for target sites).

When your Pages URL is live, add it under Firebase **Authorized domains** before testing sign-in on production.
