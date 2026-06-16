<div align="center">
  <img src="friedn-logo-v2.png" alt="friedn logo" width="96">

  <h1>friedn</h1>

  <p><strong>An open-source Android app blocker that uses NFC tags as physical keys.</strong></p>

  <p>
    <a href="https://github.com/yanicii/friedn/actions/workflows/android-apk-release.yml"><img src="https://github.com/yanicii/friedn/actions/workflows/android-apk-release.yml/badge.svg" alt="Build Status"></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
    <img src="https://img.shields.io/badge/platform-Android-3DDC84.svg?logo=android&logoColor=white" alt="Platform: Android">
    <img src="https://img.shields.io/badge/built%20with-Flutter-02569B.svg?logo=flutter&logoColor=white" alt="Built with Flutter">
    <a href="https://www.paypal.com/paypalme/YannikR"><img src="https://img.shields.io/badge/PayPal-Donate-blue.svg?logo=paypal" alt="Donate via PayPal"></a>
  </p>
</div>

---

## Overview

**friedn** (pronounced *"frieden"*, German for *peace*) is a **free and open-source** productivity tool that helps you break the habit of mindlessly scrolling through distracting apps on Android.

Unlike traditional app blockers that can be disabled with a few taps, friedn requires you to physically scan a registered **NFC tag** to toggle blocking on or off. That small piece of physical friction is the point — it keeps you intentional about your screen time.

friedn is a free alternative inspired by **Brick** and **Tapout**.

> **Disclaimer:** Brick and Tapout are trademarks of their respective owners. This project is not affiliated with, endorsed by, or connected to them.

## Contents

- [How It Works](#how-it-works)
- [Features](#features)
- [Privacy](#privacy)
- [Permissions](#permissions)
- [Getting Started](#getting-started)
- [Building](#building)
- [First-Time Setup](#first-time-setup)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## How It Works

```
   Scan NFC tag  ──►  Toggle blocking  ──►  Open a blocked app  ──►  Lock screen overlay
```

1. You register any NFC tag (card, sticker, keychain) as your physical "key".
2. Scanning the tag enables or disables app blocking.
3. While blocking is active, opening a blocked app shows a full-screen lock overlay instead.
4. Optionally, a timer can keep blocking active for a fixed duration.

No data is ever written to the NFC tag — it is used purely as a unique identifier.

## Features

- **App blocking** — choose exactly which apps to block (social media, games, etc.)
- **NFC tag as a key** — register any tag to act as your physical unlock key
- **Tap to toggle** — scan your tag to switch blocking on or off
- **Timer mode** — block apps automatically for a set duration (e.g. focus for two hours)
- **Overlay lock screen** — a lock screen appears when you try to open a blocked app
- **Reboot-safe** — blocking persists across device restarts
- **Fully local** — no account, no backend, no tracking

## Privacy

friedn is designed to be private by default:

- **No data is stored on the NFC tag.**
- **No user data is collected, transmitted, or shared** with any third-party service.
- All settings (blocked apps, registered tag, sessions) are stored **locally on your device** only.

## Permissions

friedn requires several sensitive Android permissions, each tied directly to its core functionality:

| Permission | Why it is needed |
|---|---|
| `NFC` | Read the registered NFC tag used to toggle blocking |
| Accessibility Service | Detect when a blocked app is launched |
| `SYSTEM_ALERT_WINDOW` | Display the lock screen overlay over blocked apps |
| `QUERY_ALL_PACKAGES` | List installed apps so you can choose which to block |
| `PACKAGE_USAGE_STATS` | Monitor which app is in the foreground |
| `FOREGROUND_SERVICE` | Keep blocking active reliably in the background |
| `RECEIVE_BOOT_COMPLETED` | Re-enable blocking after a device reboot |
| `POST_NOTIFICATIONS` | Show the foreground-service notification |

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) SDK `^3.10.7`
- An **Android device with NFC** (required — the emulator cannot test NFC or accessibility features)
- Android Studio or the Android SDK command-line tools

### Run

```bash
flutter pub get          # Install dependencies
flutter run              # Run in debug mode (hot reload)
flutter run --release    # Run in release mode
```

## Building

```bash
flutter build apk --release          # Release APK
flutter build appbundle --release    # Release App Bundle (for Google Play)
```

Outputs:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Release Signing

Release builds are signed using credentials from `android/key.properties` (git-ignored). Create it with:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=<path-to-keystore.jks>
```

If `key.properties` is absent, the build falls back to debug signing so `flutter run --release` still works.

> Publishing to the Google Play Store involves additional steps (permission declaration forms, privacy policy, store assets). See **[docs/PUBLISH.md](docs/PUBLISH.md)**.

## First-Time Setup

After installing the app:

1. **Register an NFC tag** — tap "NFC Tag" and scan your tag.
2. **Enable the Accessibility Service** — required to detect when blocked apps launch.
3. **Grant the Overlay permission** — required to display the lock screen.
4. **Select apps to block.**

Once setup is complete, scan your NFC tag to enable blocking.

## Architecture

friedn is built with Flutter/Dart for the UI and Kotlin for the Android-native blocking logic, bridged by a platform channel. State is managed with the Provider pattern and persisted via `SharedPreferences`.

```
UI (Flutter)  ──►  AppStateProvider  ──►  Platform channel  ──►  Native services (Kotlin)
```

| Layer | Responsibility |
|---|---|
| Flutter / Dart (`lib/`) | UI, state management, persistence |
| Kotlin (`android/`) | Accessibility service, lock-screen overlay, foreground service |

Android-only by design: NFC hardware access and accessibility-based app detection are Android-specific.

## Contributing

Contributions are welcome — bug fixes, features, and documentation improvements all help.

1. **Fork** the repository and branch from `main`.
2. **Make your changes.**
3. **Verify** the app builds and `flutter analyze` passes.
4. **Open a Pull Request** with a clear description.

Found a bug or have an idea? [Open an issue](https://github.com/yanicii/friedn/issues).

## License

Released under the [MIT License](LICENSE).

## Support

If friedn is useful to you, consider supporting its development:

<a href="https://www.paypal.com/paypalme/YannikR"><img src="https://img.shields.io/badge/PayPal-Donate-blue.svg?logo=paypal" alt="Donate via PayPal"></a>
