# friedn

An app blocker that uses NFC tags as physical keys to unlock distracting apps.

## Description

friedn helps you stay focused by blocking distracting apps on your Android device. Unlike traditional app blockers that can be easily bypassed, friedn requires you to physically scan a registered NFC tag to enable or disable blocking. This adds a layer of friction that helps break the habit of mindlessly opening distracting apps.

### Features

- **NFC-based unlocking**: Register any NFC tag as your physical key
- **App blocking**: Select which apps to block when blocking is enabled
- **Timer mode**: Set a blocking duration that automatically disables after the timer expires
- **Lock screen overlay**: Shows a blocking screen when you try to open a blocked app
- **Light/Dark theme**: Follows system theme preferences

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.7 or higher)
- Android device with NFC support
- Android Studio or VS Code with Flutter extensions

## Getting Started

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release
```

### Build APK

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

The built APK will be located at `build/app/outputs/flutter-apk/`.

## Setup

After installing the app, complete these setup steps:

1. **Register NFC Tag**: Tap "NFC Tag" and scan your NFC tag to register it
2. **Enable Accessibility Service**: Required to detect when blocked apps are launched
3. **Grant Overlay Permission**: Required to display the lock screen over blocked apps
4. **Select Apps to Block**: Choose which apps you want to block

Once setup is complete, scan your NFC tag to enable blocking.
