# Architecture

## Layers
- `Core`: design system, navigation, formatting, DI container.
- `Domain`: immutable models, view state contracts, service protocols.
- `Services`: concrete implementations for permissions, app catalog, artifact resolution, cleanup planning/execution, AI profile inference, semantic unit detection.
- `Features`: SwiftUI views + ViewModels for onboarding, root shell, app manager, and recommendations.

## Design Decisions
- Strict MVVM. Views render state; ViewModels orchestrate service calls.
- Protocol-first service boundaries for testability and AI strategy swapping.
- Safe cleanup defaults to Trash path and explicit confirmation.
- AI capability is gated in onboarding under Apple Intelligence-only policy.
- Profile inference uses Apple Foundation Models when runtime is available, then falls back to deterministic heuristics.

## Extensibility
Future phases plug into existing protocols:
- `DiskScannerProtocol` for storage map.
- `TimelineStoreProtocol` and `AutomationSchedulerProtocol` for trend and automation.
- `ProfileInferenceServiceProtocol` and `SemanticUnitDetectorProtocol` for richer model-backed personalization.
