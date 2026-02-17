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
- Phase 4 foundation:
  - Storage map scanner integration with treemap-style visual drilldown and cache reuse.
- Phase 5 foundation:
  - Smart categories view, safety-tier totals, and quick-clean execution for safe artifacts.
- Phase 6 foundation:
  - Large-item surfacing and duplicate-cluster UI/state models.
- Phase 7 partial:
  - Activity monitor dashboard with metric switching, reclaim trend chart, and disk-growth projection.
  - Persistent timeline snapshots with bounded on-disk storage.
- App icon system:
  - Vector source plus generated macOS app icon set.
- Quality foundation:
  - Unit tests and UI automation tests added.
  - CI workflow and coverage gate script added.

## Pending from the full roadmap
- Foundation Model tool-calling for deeper semantic file-cluster inspection beyond prompt-only profile inference.
- Storage map: richer progressive rendering, contextual actions, and Finder/Quick Look integrations.
- Smart categories: full cache-cleaner detector modules (browsers, package managers, Docker, logs/temp).
- Duplicates: deterministic hash pipeline (size bucketing + partial hash + full hash confirmation).
- Timeline/automation: scheduled jobs, notification workflows, and leftover guard background monitoring.
- Release hardening and additional performance/accessibility polish (phase 8).

## Validation status
- `xcodebuild build` passes.
- `xcodebuild build-for-testing` passes.
- `xcodebuild test` is currently unstable in this sandbox due distributed-notification restrictions from the host environment; execute tests in a normal local/CI environment for full run results.
