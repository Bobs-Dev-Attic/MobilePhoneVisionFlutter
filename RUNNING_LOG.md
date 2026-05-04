# Running Log (P0/P1/P2/P3 execution)

- [x] Reworked `InferenceManager.processFrame` into a deterministic worker loop and applied runtime FPS throttling.
- [x] Added cloud ROI cooldown/debounce by track id.
- [x] Added explicit cloud upload consent gate in settings + inference path.
- [x] Moved API key persistence to secure storage (`flutter_secure_storage`), while keeping non-secret settings in SharedPreferences.
- [x] Added strict HTTPS validation for custom endpoint URL.
- [x] Added timeout + retry behavior to cloud HTTP requests.
- [x] Replaced regex JSON extraction with strict JSON decode path.
- [x] Updated README with setup, security, privacy, and operational notes.
- [x] Marked completed items in TODO.md.
- [x] Added runtime telemetry tracking for FPS, dropped frames, cloud ROI latency, and fallback event counts.
- [x] Added STRIDE + LINDDUN threat model document with annual review cadence.
- [x] Added secure SDLC checklist document covering SAST, dependency audit, and secrets scanning gates.
- [x] Marked completed P2/P3 items in TODO.md and refreshed README references.

