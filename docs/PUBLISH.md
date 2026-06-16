# Publishing friedn to Google Play Store

## 1. Google Play Developer Account

- Register at [play.google.com/console](https://play.google.com/console)
- One-time **$25 fee**
- Identity verification takes a few days

## 2. App Signing

Your `build.gradle.kts` already reads from `key.properties`, and that file exists. Make sure you have:
- A release keystore (`.jks` or `.keystore` file)
- **Back it up securely** - if you lose it, you can never update the app

Google Play also uses **Play App Signing** (they hold an upload key and a separate app signing key). You'll enroll during your first upload.

## 3. Build an AAB (not APK)

Google Play **requires** an Android App Bundle (`.aab`), not an APK. Your current workflow builds APK. To build an AAB:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 4. Sensitive Permissions - Declaration Forms

This is where the app will face the most scrutiny. Several restricted permissions each require justification in Play Console:

| Permission | Requirement |
|---|---|
| `QUERY_ALL_PACKAGES` | Must submit a **Permissions Declaration Form** explaining why you need to see all installed apps |
| Accessibility Service | Must submit a separate **Accessibility Service declaration** proving it's core functionality (not just convenience) |
| `PACKAGE_USAGE_STATS` | Protected permission - needs justification |
| `SYSTEM_ALERT_WINDOW` | Overlay permission - needs justification |

Google is **very strict** about these. The app genuinely needs them for its core functionality (blocking apps), which is a valid use case - but be prepared for potential rejections and appeals. Write clear, detailed explanations.

## 5. Store Listing Assets

Prepare the following:

- **App icon**: 512x512 PNG
- **Feature graphic**: 1024x500 PNG
- **Screenshots**: At least 2 phone screenshots (recommended: 4-8), 16:9 or 9:16
- **Short description**: Max 80 characters
- **Full description**: Max 4000 characters
- **App category**: Likely "Productivity" or "Tools"

## 6. Privacy Policy

**Required**, especially given the sensitive permissions. Must be hosted at a public URL. It should explain:
- What data the app accesses (installed apps list, usage stats)
- That no data is sent to third parties
- How accessibility service data is used

Can be hosted as a GitHub Pages site or a simple webpage.

## 7. Play Console Setup

Once you have an account, in the Play Console complete:

1. **App content** section:
   - Privacy policy URL
   - Content rating questionnaire (IARC)
   - Target audience (not children - important given COPPA)
   - Data safety form (declare what data is collected/shared)
   - Ads declaration
2. **Permissions declaration forms** (see section 4)
3. **Store listing** (see section 5)
4. **Release track**: Start with **Internal testing** or **Closed testing** before going to Production

---

## Checklist

- [ ] Register Google Play Developer account and verify identity
- [x] Ensure release keystore is backed up securely
- [x] Write and host a privacy policy at a public URL
- [ ] Prepare store listing assets (icon, feature graphic, screenshots, descriptions)
- [X] Build the AAB with `flutter build appbundle --release`
- [ ] Create the app in Play Console
- [ ] Fill out all "App content" requirements (privacy policy, content rating, data safety, target audience)
- [ ] Submit permissions declaration forms (QUERY_ALL_PACKAGES, Accessibility Service, PACKAGE_USAGE_STATS, SYSTEM_ALERT_WINDOW)
- [ ] Upload the AAB to **internal testing** track
- [ ] Test on devices via internal testing
- [ ] Promote to **production** once everything is approved
