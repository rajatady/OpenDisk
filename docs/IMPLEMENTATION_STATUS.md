# OpenDisk Implementation Status

## Completed in this iteration
- Phase 1 foundation:
  - MVVM structure, protocolized service layer, DI container.
  - Design tokens and reusable components (glass panel, buttons, safety labels, size badges, stat cards).
  - Main shell with sidebar and section routing.
  - First-boot onboarding with permission checks, AI capability gate, scan scope, and quick scan.
- Phase 2 uninstaller-first:
  - Installed app catalog service.
  - Associated artifact resolver across common user/system locations.
  - True-size computation model.
  - App Manager list/grid, sorting, searching, detail breakdown.
  - Deep uninstall modes (remove all / keep user data) with Trash-based cleanup executor.
  - Orphan scan and cleanup flow.
- Phase 3 partial:
  - AI profile inference service with Apple Foundation Models runtime path plus deterministic heuristic fallback.
  - Semantic cleanup unit detection service.
  - Recommendation ranking service and Smart Cleanup UI.
- App icon system:
  - Vector source plus generated macOS app icon set.
- Quality foundation:
  - Unit tests and UI automation tests added.
  - CI workflow and coverage gate script added.

## Pending from the full roadmap
- Foundation Model tool-calling for deeper semantic file-cluster inspection beyond prompt-only profile inference.
- Treemap storage map feature set (phase 4).
- Smart categories and full cache cleaner modules (phase 5).
- Large files explorer and duplicate finder pipeline (phase 6).
- Timeline snapshots, trend projection, and automations/leftover guard (phase 7).
- Release hardening and additional performance/accessibility polish (phase 8).

## Validation status
- `xcodebuild build` passes.
- `xcodebuild build-for-testing` passes.
- `xcodebuild test` is currently unstable in this sandbox due distributed-notification restrictions from the host environment; execute tests in a normal local/CI environment for full run results.
