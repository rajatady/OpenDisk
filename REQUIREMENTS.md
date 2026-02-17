# OpenDisk — Requirements Document

> A native macOS disk management app that feels like Apple made it, with Airbnb-level aesthetics.
> Open source. Free forever.

---

## Design Philosophy

- **Apple-native feel** — SwiftUI-first, AppKit where needed, no Electron/web vibes
- **Liquid glass** — translucent materials, vibrancy, depth via shadows and layering
- **Zero cognitive load** — every interaction feels inevitable, not learned
- **Motion-rich** — spring animations, matched geometry transitions, smooth state changes
- **Airbnb warmth** — muted palette, generous spacing, information-rich without clutter
- **Progressive disclosure** — show what matters, reveal details on demand

---

## Architecture

- **Pattern:** Strict MVVM
  - Views are dumb — only render state
  - ViewModels handle all logic, expose published state
  - Models are pure data structs
- **Services:** Protocol-oriented, every service behind a protocol for testability
- **Concurrency:** Actor-based — all disk scanning on background actors, never block UI
- **DI:** Dependency injection container for all services
- **Navigation:** Coordinator pattern for navigation flow
- **Testing:** 100% unit tests for all models, services, ViewModels + UI automation tests for every user flow

---

## Design System

### Tokens
- **Colors:** Muted neutrals, single accent color, semantic safety colors (green/amber/red)
- **Typography:** SF Pro with defined hierarchy (largeTitle, title, headline, body, caption)
- **Spacing:** 4pt grid system with defined scale (xs, sm, md, lg, xl)
- **Corner radius:** Consistent scale matching macOS HIG
- **Shadows:** Layered depth system (subtle, medium, elevated)

### Materials
- Liquid glass translucency on sidebar and panels
- Vibrancy effects for background layers
- Frosted glass overlays for modals/sheets

### Components (Reusable)
- SizeBadge — human-readable file sizes with color coding
- SafetyLabel — green (safe) / amber (review) / red (risky)
- ProgressRing — animated circular progress
- ActionButton — primary, secondary, destructive variants
- FileRow — icon + name + size + metadata
- CategoryCard — icon + title + size + trend indicator
- AppCard — app icon + name + true size + last used
- TreemapCell — colored rectangle with label for storage visualization
- EmptyState — illustration + message + action
- SearchBar — with filter chips
- StatCard — big number + label + trend
- ShimmerLoader — skeleton loading placeholder

### Animations
- Spring configs: snappy (response 0.3, damping 0.7), smooth (response 0.5, damping 0.8), bouncy (response 0.4, damping 0.6)
- Matched geometry transitions between views
- Staggered list animations on data load
- Progress animations for scanning/cleaning
- Micro-interactions on hover and click

### App Icon
- Clean, minimal, Apple-style
- Concept: disk/storage with a clean/organize motif
- Generate as SVG, export all required macOS sizes (16, 32, 64, 128, 256, 512, 1024)

---

## Features

### 1. Main Shell
- Sidebar navigation with category icons and liquid glass material
- Content area with animated transitions between sections
- Toolbar with scan/refresh actions
- Persistent status bar showing: total disk / used / free / percentage

### 2. App Uninstaller & Complete Cleanup [PRIORITY — BUILD FIRST]

#### 2a. App Scanner
- Enumerate all installed apps: /Applications, ~/Applications, Homebrew Cask
- Resolve bundle identifiers for each app
- Scan ALL associated file locations:
  - ~/Library/Application Support/{bundleId or appName}
  - ~/Library/Caches/{bundleId or appName}
  - ~/Library/Preferences/{bundleId}.plist
  - ~/Library/Saved Application State/{bundleId}.savedState
  - ~/Library/Containers/{bundleId}
  - ~/Library/Group Containers/*{bundleId}*
  - ~/Library/HTTPStorages/{bundleId}
  - ~/Library/WebKit/{bundleId}
  - ~/Library/Logs/{bundleId or appName}
  - ~/Library/Cookies/ (matching bundle ID)
  - /Library/Application Support/{appName}
  - /Library/LaunchAgents/ (matching bundle ID)
  - ~/Library/LaunchAgents/ (matching bundle ID)
  - /Library/LaunchDaemons/ (matching bundle ID)
  - /Library/PreferencePanes/ (matching app)
  - Login Items
- Calculate TRUE app size = bundle + all associated files

#### 2b. App Manager View
- Grid/list toggle for all installed apps
- Each app: icon, name, true size, last used date
- Sort by: size, name, last used
- Search and filter
- Detail panel: file breakdown by category (bundle, cache, preferences, data, system)

#### 2c. Deep Uninstaller
- Select app -> see every associated file grouped by type
- Safety labels per group: App Bundle / User Data / Cache / Preferences / System Integration
- Two modes: "Remove Everything" vs "Keep User Data"
- Animated removal progress
- Post-removal summary: space reclaimed, files removed

#### 2d. Orphan Detector
- Scan Library directories for files whose parent app no longer exists
- Cross-reference by bundle identifier
- Grouped results with one-click cleanup
- Show: orphan name, likely source app, size, location

### 3. Visual Storage Map
- Recursive directory traversal with actor isolation
- Interactive treemap visualization (hero screen)
- Color-coded by file type (media, code, documents, system, caches)
- Click to zoom into folders with spring animation
- Hover preview with metadata (size, modified date, type, path)
- Breadcrumb navigation
- Right-click: reveal in Finder, trash, Quick Look

### 4. Smart Categories & Cache Cleaner

#### Categories
- Applications, Documents, Media, Developer Tools, System Data, Caches, Mail & Messages, Other
- Each: total size, item count, growth trend, actionable suggestions

#### Cache Cleaner
- Browser caches: Safari, Chrome, Firefox, Arc, Brave
- Xcode: derived data, simulators, archives, device support files
- Homebrew cache
- Package managers: npm, yarn, pnpm, bun cache
- Docker: images, volumes, build cache
- CocoaPods cache
- System logs and temp files (/tmp, /var/folders)
- Each item: name, size, safety level (safe/review/risky), description
- Batch select + confirm + clean
- "Quick Clean" button for all safe items

### 5. Large File Scanner
- Top N largest files across entire disk
- Show: name, path, size, last accessed date, file type icon
- Quick Look preview integration
- Bulk actions: trash, move, compress
- Filters: minimum size, file type, last accessed before date

### 6. Duplicate Finder
- 3-phase detection:
  1. Group by file size (fast filter)
  2. Partial hash (first + last 4KB)
  3. Full content hash for confirmed matches
- Side-by-side duplicate comparison
- "Best copy" suggestion (newest, shortest path)
- Batch keep/remove toggle
- Space savings preview before confirmation

### 7. Storage Timeline
- Periodic snapshots stored locally (SQLite or JSON)
- Line chart: disk usage over time
- "What changed" diff between any two snapshots
- Trend projection: "At this rate, full in X days"
- Growth alerts via macOS notifications

### 8. Automations
- Scheduled background scans (configurable: daily, weekly, monthly)
- macOS notification center integration for suggestions
- Custom rules engine: condition + action (e.g., "When Xcode derived data > 10GB, notify me")
- Leftover Guard: watch Trash for .app deletions, notify about orphaned files

---

## Future Enhancement: AI-Powered User Profiling

> This is NOT for immediate implementation. It is a planned future differentiator.
> Keep architecture decisions compatible with this feature.

### Concept
Use Apple's on-device Foundation Models (available in macOS) to intelligently profile the user
and surface context-aware cleanup recommendations.

### How It Works
1. **Profile Detection:** Analyze installed apps, file types, directory structures to deduce user type:
   - Software Developer (iOS, web, backend, ML/AI, etc.)
   - Designer (UI/UX, 3D, video, photography)
   - Deep Learning Engineer
   - Data Scientist
   - Creative Professional (music, video production)
   - General User
   - Hybrid profiles (e.g., "iOS developer who does photography")

2. **Context-Aware Scanning:** Based on profile, adjust what gets surfaced:
   - **Deep Learning Engineer:** Detect checkpoint folders (model saves every N epochs).
     A single .pt/.h5 file is 2MB but a training run folder can balloon to 20GB+.
     Must recognize the FOLDER as the meaningful unit, not individual files.
   - **iOS Developer:** Prioritize Xcode derived data, simulator runtimes, old archives
   - **Web Developer:** node_modules, .next caches, dist folders across many projects
   - **Designer:** Large PSD/Figma exports, font caches, render caches
   - **Video Editor:** Proxy files, render caches, old project files

3. **Smart Folder Recognition:**
   The key insight: traditional disk tools show individual files or immediate directories.
   But meaningful cleanup units are often LOGICAL groups that span directory structures:
   - A training run: `experiments/run_042/checkpoints/` (20GB across 10,000 files)
   - A project's dependencies: `project/node_modules/` (2GB, deeply nested)
   - A build output: `project/.build/` (5GB across complex hierarchy)

   The tool must understand that these are single "units" for cleanup purposes,
   even if no single file or leaf directory is individually large.

   **Problem with naive approaches:**
   - "Show largest files" — misses distributed bulk (thousands of small checkpoint files)
   - "Show largest leaf directories" — a single subfolder inside breaks the heuristic
   - Must use SEMANTIC grouping: recognize known patterns (checkpoints/, node_modules/, .build/)
     and also detect anomalous size accumulation at any directory level

4. **Apple Foundation Model Integration:**
   - Pass directory trees and file metadata as tool calls to the on-device model
   - Model returns: user profile, cleanup recommendations, risk assessments
   - All processing stays on-device — no cloud, no privacy concerns
   - Graceful degradation if Foundation Models unavailable (fall back to heuristic rules)

### Architecture Implications (Keep In Mind Now)
- Service layer must be pluggable — scanning services should accept "strategy" protocols
  so AI-powered strategies can be swapped in later
- File metadata collection should be rich from the start (not just name/size but
  also directory depth, file count, modification patterns)
- Category/classification system should be extensible
- Keep a clean boundary where "detection logic" lives so it can be replaced
  with ML-powered detection later

---

## Cross-Cutting Concerns

### Permissions
- Full Disk Access: clear onboarding flow explaining why it's needed
- Graceful handling when permission denied (show what we CAN access, prompt for more)

### Safety
- NEVER auto-delete. Always confirm with user.
- Use Trash (not rm) — everything is reversible
- Clear safety labels on everything (safe / review / risky)
- Pre-action summary: "This will remove X files totaling Y GB"

### Performance
- All scanning off main thread via Swift actors
- Progressive UI updates during scans
- Lazy loading for large lists
- Cancel support for long-running operations

### Accessibility
- Full VoiceOver support with descriptive labels
- Keyboard navigation for all features
- Dynamic Type support
- High contrast mode compatibility

### Error Handling
- Graceful degradation for permission denied, missing files, locked files
- User-friendly error messages (not technical jargon)
- Retry options where applicable

### Logging
- Structured logging (OSLog) for debugging
- No user file content in logs — only metadata

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (primary) + AppKit (where SwiftUI falls short)
- **Minimum deployment:** macOS 14.0 (Sonoma) — for latest SwiftUI features
- **Testing:** XCTest for unit tests, XCUITest for automation
- **Storage:** UserDefaults for preferences, SQLite (via SwiftData or raw) for timeline snapshots
- **Concurrency:** Swift structured concurrency (async/await, actors)
- **No external dependencies** — pure Apple frameworks only (keeps it lean and App Store ready)
