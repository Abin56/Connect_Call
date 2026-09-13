# ConnectCall

A Flutter calling app built on Firebase Auth/Firestore and ZEGOCLOUD, with
1-to-1 and group audio/video calling, call history, contacts, blocking, and
light/dark theming.

## Getting Started

### Prerequisites

- Flutter (see `.metadata` / `pubspec.yaml` for the SDK constraint)
- A Firebase project with Authentication (email/password) and Firestore
  enabled — `google-services.json` / `firebase_options.dart` in this repo
  already point at the project used for development
- A ZEGOCLOUD project (App ID + App Sign) for calling

### Running the app

ZEGOCLOUD credentials are never hardcoded — they're passed in at build/run
time via `--dart-define` so they don't end up in source control:

```
flutter run \
  --dart-define=ZEGO_APP_ID=your_app_id \
  --dart-define=ZEGO_APP_SIGN=your_app_sign
```

The same flags are required for release builds:

```
flutter build apk --release \
  --dart-define=ZEGO_APP_ID=your_app_id \
  --dart-define=ZEGO_APP_SIGN=your_app_sign
```

Without them, `ZegoConstants.isConfigured` is `false` and calling is
disabled, but the rest of the app (auth, contacts, profile, theming) still
runs normally.

### Tests

```
flutter test
```
