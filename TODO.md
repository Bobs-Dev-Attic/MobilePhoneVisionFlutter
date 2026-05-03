# TODO (Prioritized)

## P0 — Must Do Before Production
- [x] Fix `README.md` corruption and provide accurate setup/run/security notes.
- [x] Rework `InferenceManager.processFrame` into a proper worker loop that drains queue and processes latest frame deterministically.
- [x] Store API keys in secure storage (`flutter_secure_storage`) instead of SharedPreferences.
- [x] Add certificate pinning and strict HTTP timeout/retry policy for cloud requests.
- [x] Enforce `targetFps` throttling in pipeline (not just settings UI).
- [x] Add explicit consent gate before any cloud image upload.
- [x] Validate and constrain custom endpoint URL (https only, allowlist/domain rules).

## P1 — High Value / Near-Term
- [x] Replace regex JSON extraction from LLM responses with strict schema response handling and parser validation.
- [x] Add debounce/cooldown for repeated cloud ROI calls per tracked object.
- [x] Add robust camera lifecycle recovery and stream restart guards.
- [ ] Add Firebase security rules documentation and automated checks.
- [ ] Add delete/export user data controls and retention settings in app.
- [ ] Add structured error taxonomy and user-friendly error surfaces.

## P2 — Optimization / Architecture
- [ ] Reduce memory churn in image conversion/cropping/base64 path.
- [ ] Benchmark isolate crop overhead; consider pooled workers/native path.
- [ ] Introduce telemetry for FPS, dropped frames, cloud latency, and fallback events.
- [ ] Add integration tests for offline fallback and cloud timeout behavior.
- [ ] Add accessibility pass (semantics, dynamic type, color contrast, touch targets).

## P3 — Strategic Enhancements
- [ ] Evaluate MediaPipe/TFLite delegate options for better on-device throughput.
- [ ] Add remote config / feature flags for rollout safety.
- [ ] Add threat model document (STRIDE + LINDDUN) and annual review cadence.
- [ ] Establish secure SDLC checklist (SAST, dependency audit, secrets scan in CI).
