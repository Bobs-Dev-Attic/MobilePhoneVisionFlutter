# Fast Context for Coding Agents

## Purpose
Token-efficient orientation file for Codex/Claude to reduce repetitive repo exploration.

## What this project is
Flutter mobile app prototype for camera-based object detection with local + optional cloud verification.

## Key files (start here)
- App bootstrap: `lib/main.dart`
- Camera UX + frame stream: `lib/screens/camera/camera_screen.dart`
- Inference orchestration: `lib/core/inference_manager.dart`
- Local detector: `lib/services/local_detection_service.dart` (currently stub)
- Cloud detector + ROI analysis: `lib/services/cloud_detection_service.dart`
- Settings model/provider/UI: `lib/models/app_settings.dart`, `lib/providers/settings_provider.dart`, `lib/screens/settings/settings_screen.dart`
- Firebase auth/storage/history: `lib/services/firebase_service.dart`

## Known important caveats
- README currently malformed.
- Local detection is synthetic/stubbed.
- Secrets persisted insecurely (SharedPreferences via settings serialization).
- Cloud parsing fragile (regex from model text).
- Performance path may allocate heavily per frame.

## Safe-first coding priorities
1. Correctness of frame processing and lifecycle.
2. Privacy/security controls before feature growth.
3. Memory/performance profiling before adding heavy UX features.
4. Deterministic tests for inference pipeline behavior.

## Recommended command shortcuts
- Run tests: `flutter test`
- Static analysis: `flutter analyze`
- Format: `dart format lib test`

## Documentation map
- Deep review: `PROJECT_REVIEW.md`
- Prioritized work: `TODO.md`
