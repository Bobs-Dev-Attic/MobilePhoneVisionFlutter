# Secure SDLC Checklist

## Pre-merge (every PR)
- [ ] Static analysis clean (`flutter analyze`).
- [ ] Unit/integration tests pass.
- [ ] Secrets scan run on changed files.
- [ ] Dependency delta reviewed for licenses and known CVEs.

## Weekly
- [ ] Dependency audit (`flutter pub outdated` + advisory review).
- [ ] Verify Firebase rules drift and least-privilege posture.

## Release gate
- [ ] SAST results triaged and approved.
- [ ] Mobile build uses production-safe endpoints and feature flags.
- [ ] Threat model deltas reviewed.
- [ ] Data retention/deletion controls validated.

## Tooling targets
- SAST: Dart/Flutter linting + security-focused rule set.
- Dependency audit: pub package vulnerability review.
- Secrets scan: CI secret scanner over repo history and diffs.
