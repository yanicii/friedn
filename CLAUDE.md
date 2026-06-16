# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**friedn** is an open-source Android app blocker built with Flutter/Dart. It uses NFC tags as physical keys — users must scan a registered NFC tag to enable/disable app blocking. Inspired by Brick and Tapout as a free alternative.

Android-only despite being Flutter (NFC hardware + accessibility services are Android-specific). No backend — all data stored locally via SharedPreferences.

## Build & Development Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run debug mode (hot reload)
flutter run --release        # Run release mode
flutter build apk --debug   # Build debug APK
flutter build apk --release # Build release APK (needs android/key.properties)
flutter analyze              # Static analysis (Dart linter)
flutter test                 # Run tests
```

Release APK output: `build/app/outputs/flutter-apk/app-release.apk`

Release signing requires `android/key.properties` (gitignored) with keystore credentials.

## Architecture

### State & Data Flow

```
UI Screens → AppStateProvider (ChangeNotifier) → NativeService / StorageService
                                                       ↓
                                              Platform Channel (MethodChannel)
                                                       ↓
                                              Kotlin Android Services
```

- **Provider pattern** for state management: `AppStateProvider` is the single ChangeNotifier managing all app state (blocked apps, NFC tag, blocking sessions, timers, permissions)
- **Platform channel** `com.friedn.friedn/native` bridges Dart ↔ Kotlin for all native operations (NFC, accessibility, permissions, app blocking)

### Dart Layer (`lib/`)

| Path | Role |
|------|------|
| `main.dart` | Entry point, theme setup, provider initialization |
| `providers/app_state_provider.dart` | Central state management — largest logic file |
| `services/native_service.dart` | Dart wrapper for all platform channel calls |
| `services/storage_service.dart` | SharedPreferences wrapper with typed accessors |
| `screens/home_screen.dart` | Main dashboard (blocking toggle, stats, timer, permissions) |
| `screens/nfc_setup_screen.dart` | NFC tag registration flow |
| `screens/app_selection_screen.dart` | Installed apps list with block/unblock |
| `models/app_info.dart` | App data model (package name, icon, blocked state) |
| `models/blocking_session.dart` | Session tracking model + statistics aggregation |
| `theme/app_theme.dart` | Material 3 theme (black/white minimalist, dark mode support) |

### Android Native Layer (`android/app/src/main/kotlin/com/friedn/friedn/`)

| File | Role |
|------|------|
| `MainActivity.kt` | Flutter engine init, MethodChannel handler, NFC processing |
| `AppBlockerService.kt` | Accessibility service — detects blocked app launches, triggers lock screen |
| `LockScreenActivity.kt` | Fullscreen overlay shown when user opens a blocked app |
| `BlockingForegroundService.kt` | Foreground service for continuous monitoring |
| `BootReceiver.kt` | Restarts services after device reboot |

### Key Android Permissions

The app requires several restricted permissions that need Play Store declaration forms:
- `QUERY_ALL_PACKAGES` — list installed apps
- `PACKAGE_USAGE_STATS` — monitor app usage
- `SYSTEM_ALERT_WINDOW` — overlay lock screen
- `NFC` — core feature (hardware required)
- Accessibility service — core feature (detect app launches)

## CI/CD

GitHub Actions (`.github/workflows/android-apk-release.yml`): pushing any git tag triggers a release build that creates a GitHub Release with the APK attached. Uses Java 17 (Temurin).

## Tech Stack

- **Flutter/Dart** (SDK ^3.10.7), **Kotlin** for Android native
- **Provider** for state management, **SharedPreferences** for persistence
- **Gradle Kotlin DSL** for Android build, Java 17 target
- **flutter_lints** for static analysis
