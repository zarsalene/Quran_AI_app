# Rattil download website

A responsive, static product website for the Rattil Android Quran learning app. Built with plain HTML, CSS, and JavaScript to keep hosting simple. It includes English, French, and Arabic content, RTL layout, the Rattil brand assets, and direct links to the latest APK release.

## Run locally

Requires Node.js 18 or newer. From this directory:

```sh
npm start
```

Open <http://localhost:4173>. The selected language is remembered in browser local storage. First visit language is selected from the browser's preferred languages (English is the fallback).

## Deploy for free

This is a static site; no build step, backend, database, or environment variables are required.

### GitHub Pages

1. Push the repository to GitHub.
2. In the repository, open **Settings → Pages**.
3. Select **Deploy from a branch**, choose the branch and the `/prototype-pwa` folder if available as a publishing source. If the Pages UI cannot select that subfolder, publish the contents of `prototype-pwa` from a dedicated branch or configure a GitHub Actions Pages workflow to upload this directory.
4. Open the generated site URL and check the APK and privacy links.

### Cloudflare Pages

1. Create a Pages project connected to this GitHub repository.
2. Set the root directory to `prototype-pwa`.
3. Leave the build command blank and set the output directory to `.`.
4. Deploy, then check the APK and privacy links on the deployed URL.

The download buttons go directly to GitHub's `releases/latest/download/Rattil.apk` endpoint. GitHub resolves that URL to the current release asset; it was checked against release 0.2.8 on 28 October 2026. Keep the release asset name `Rattil.apk` stable so the link continues to work.

## Content and privacy

- The release notes describe the latest APK and its installation steps.
- The app's speech recognition runs on the device. Automatic feedback can be wrong and does not replace a qualified Quran teacher.
- Al-Husary Muʿallim audio for Al-Fatiha and Juz ʿAmma is bundled. Other recitations need downloading; downloaded audio can be played offline.
- No app screenshots were available in the repository, so the landing page uses the real Rattil logo and does not imply an invented app screen.
- [Privacy policy](privacy.html) covers the app and site. The site stores only the selected language in local storage and does not load analytics or tracking scripts.
- Arabic UI fonts are copied from the app assets. Their SIL Open Font License texts are in `assets/fonts/`.

## Project files

- `index.html`, `styles.css`, `app.js`: landing page and translated content.
- `privacy.html`, `privacy.js`: published, translated privacy policy.
- `assets/brand/`: official Rattil SVG brand marks and icon.
- `assets/fonts/`: self-hosted Amiri and IBM Plex Sans Arabic fonts.
- `server.js`: minimal local static server; no runtime dependencies.
