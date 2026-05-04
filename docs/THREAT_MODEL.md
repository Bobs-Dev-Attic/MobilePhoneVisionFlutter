# Threat Model (STRIDE + LINDDUN)

## Scope
- Mobile client camera frame processing.
- Local detection and optional cloud ROI enrichment.
- Firebase auth, Firestore, and storage integrations.

## STRIDE Summary
- **Spoofing**: account/session abuse, API impersonation.
- **Tampering**: modified client payloads, model response manipulation.
- **Repudiation**: missing audit trail for cloud upload consent changes.
- **Information Disclosure**: image frames, metadata, API keys, and telemetry leakage.
- **Denial of Service**: endpoint throttling, cloud timeout storms, frame queue saturation.
- **Elevation of Privilege**: insecure rules or weak role checks in backend services.

## LINDDUN Summary
- **Linkability**: repeated detections tied to account/device.
- **Identifiability**: face/location/context in frames.
- **Non-repudiation**: retained cloud logs proving user activity.
- **Detectability**: traffic patterns revealing inference mode.
- **Information disclosure**: accidental storage exposure.
- **Unawareness**: insufficient user understanding of cloud upload behavior.
- **Non-compliance**: retention and deletion policy gaps.

## Current Controls
- Secure key storage, consent gate, endpoint validation, timeout/retry policies.

## Required Annual Review Cadence
- Review date: every 12 months in Q1.
- Owners: mobile lead + security reviewer.
- Outputs: updated risk register, mitigations, and test evidence.
