# MobilePhoneVisionFlutter

Prototype Flutter app for real-time mobile object detection with optional cloud-based enrichment.

## Status
Early prototype. Not production-ready.

## Core Components
- Camera stream + overlay UI
- Inference manager with local/cloud/hybrid modes
- Firebase auth/history/storage integration
- Runtime settings for model/provider/thresholds

## Quick Start
1. Install Flutter SDK and platform tooling.
2. Run `flutter pub get`.
3. Add valid Firebase config files for Android/iOS.
4. Run `flutter run`.

## Testing & Quality
- `flutter test`
- `flutter analyze`

## Security/Privacy Warning
Current implementation stores cloud API keys in app settings and includes prototype cloud request handling. Review `PROJECT_REVIEW.md` and `TODO.md` before shipping to any users.
