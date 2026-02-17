# OpenDisk

OpenDisk is a native macOS disk management app focused on safe cleanup, true-size uninstall, and profile-aware recommendations.

## Current Milestone
- MVVM architecture with protocol-backed services and DI container.
- First-boot onboarding with permissions, Apple Intelligence capability gate, scan scope, and quick scan.
- Uninstaller-first App Manager (true size, artifacts, deep uninstall modes, orphan cleanup).
- Profile-aware recommendation pipeline with Apple Foundation Models inference (runtime-gated) and semantic cleanup unit detection.
- Unit and UI automation tests.

## Build
```bash
CLANG_MODULE_CACHE_PATH=/tmp/clang-modules SWIFT_MODULE_CACHE_PATH=/tmp/swift-modules xcodebuild -project OpenDisk.xcodeproj -scheme OpenDisk -destination 'platform=macOS' test
```

## Design Principles
- Apple-native interaction patterns.
- Low-cognitive-load hierarchy and progressive disclosure.
- Glass surfaces, semantic color safety labels, and spring motion.

## Safety
- Cleanup is Trash-based by default.
- Every destructive flow is explicit and confirmation gated.

## AI Runtime Notes
- `FoundationModels` is used when available and enabled (Apple Intelligence policy).
- If unavailable, the profile pipeline falls back to deterministic heuristics to keep recommendations functional.
- For deterministic test runs, set `OPENDISK_DISABLE_FOUNDATION_MODEL=1`.
