# Cloudflare Pages (reference)

This repo deploys the Flutter **web** build from `sermon_notes/build/web`.

- **SPA fallback**: `sermon_notes/web/_redirects` is copied into the build output so deep links reload correctly.
- **CI**: see `.github/workflows/deploy-cloudflare-pages.yml` (GitHub Actions + Wrangler).
- **Manual deploy** (after `flutter build web`):

```bash
cd sermon_notes
flutter build web --release
npx wrangler pages deploy build/web --project-name=YOUR_PROJECT_NAME
```

Use a **Pages** (not Workers-only) project in the Cloudflare dashboard, or create one with Wrangler:

```bash
npx wrangler pages project create YOUR_PROJECT_NAME --production-branch=main
```
