# MobilePhoneVisionFlutter

Prototype Flutter app for real-time object detection with local inference and optional cloud-based ROI enrichment.

## Status
Prototype only. **Not production-ready**.

## Quick Start
1. Install Flutter (stable), Android Studio/Xcode tooling.
2. Run `flutter pub get`.
3. Add Firebase configs:
   - `android/app/google-services.json`
   - `ios/GoogleService-Info.plist`
4. Run `flutter run`.

## Security & Privacy (Current)
- API keys are stored in `flutter_secure_storage` (platform keystore/keychain).
- Non-secret app settings remain in SharedPreferences.
- Cloud ROI upload requires explicit opt-in consent (`Allow cloud upload for ROI analysis`).
- Custom cloud endpoint is constrained to valid `https://` URLs.
- Cloud requests now use strict timeout + retry behavior.

## Runtime Notes
- `targetFps` is enforced in the inference pipeline.
- Inference worker drains queued frames deterministically while processing.
- Hybrid mode supports ROI cloud cooldown per tracked object to reduce duplicate cloud calls.

## Testing & Quality
- `flutter analyze`
- `flutter test`

## Remaining Work
See `TODO.md` for P1/P2/P3 follow-up items and `RUNNING_LOG.md` for completed changes in this pass.
