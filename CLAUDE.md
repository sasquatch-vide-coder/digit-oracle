# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Generate Xcode project (required after changing project.yml)
xcodegen generate

# Build main app (includes widget + share extension)
xcodebuild -project BinaryCurious.xcodeproj -scheme BinaryCurious -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install and run on booted simulator
xcrun simctl install booted <path-to-built-.app>
xcrun simctl launch booted com.binarycurious.app
```

The project uses **xcodegen** — the Xcode project is generated from `project.yml`. Never edit `BinaryCurious.xcodeproj` directly; always modify `project.yml` and regenerate.

## Architecture

**Binary Curious** is an iOS 18+ app (Swift 5.9, SwiftUI, SwiftData) for tracking sightings of the number 47. It has three targets sharing an App Group (`group.com.binarycurious.app`):

| Target | Bundle ID | Purpose |
|--------|-----------|---------|
| BinaryCurious | com.binarycurious.app | Main app |
| BinaryCuriousWidget | com.binarycurious.app.widget | Home/Lock Screen widgets |
| BinaryCuriousShareExtension | com.binarycurious.app.share | Share sheet for importing images |

### Data Flow Between Targets

Extensions **cannot** access the main app's Documents directory or SwiftData store. Cross-process communication uses two mechanisms:

1. **App Group UserDefaults** — `WidgetDataService` writes stats; `WidgetData` reads them in the widget.
2. **App Group file container** — Thumbnails copied to `WidgetImages/` for widgets; pending shares written to `PendingShares/<UUID>/` by the share extension and imported by the main app on foreground.

### SwiftData Models

Schema defined in `BinaryCuriousApp.swift`: `Sighting`, `Album`, `Tag`, `UserProfile`, `Achievement`, `Challenge`, `TimeCapsule`. Relationships use `deleteRule: .nullify` with explicit inverse paths.

### Image Storage

Images are stored on disk at `Documents/SightingImages/`, **not** in SwiftData. `ImageStorageService` handles save/load/delete with naming convention `{UUID}_full.jpg`, `{UUID}_thumb.jpg`, `{UUID}_annotation.png`. Thumbnails are 300px, JPEG at 0.8 quality.

### Capture & Save Flow

`CaptureView` → `PhotoReviewView` → save:
1. `ImageStorageService.saveImage()` — writes full + thumbnail
2. `OCRService.detectText()` — Vision framework, detects "47"
3. Create `Sighting` with metadata, insert into SwiftData
4. `WidgetDataService.update()` + `WidgetCenter.shared.reloadAllTimelines()`
5. `AchievementEngine.checkAll()` + `ChallengeEngine.checkCompletion()`
6. Show celebration overlay or dismiss

### Key Services

- **CameraService** — AVCaptureSession on background queue, `@Observable`
- **ImageStorageService** — Singleton, Documents-based file storage
- **OCRService** — Singleton, Vision `VNRecognizeTextRequest`, returns `OCRResult` (fullText, contains47, matchCount)
- **LocationService** — CLLocationManager + reverse geocoding, `@Observable`
- **WidgetDataService** — Writes to App Group UserDefaults + copies thumbnails to shared container
- **PendingSightingService** — File-based queue in App Group for share extension → main app handoff
- **StatsCalculator** — Pure enum with static functions for streaks, breakdowns, calendar data
- **AchievementEngine/ChallengeEngine** — `@Observable`, run after each save

### Navigation

`ContentView` uses `TabView` with `AppTab` enum: `.sightings`, `.capture`, `.albums`, `.profile`. Deep links via `binarycurious://` scheme handled in `BinaryCuriousApp.handleDeepLink()`.

## Patterns to Follow

- Use `@Observable` (not `ObservableObject`) for state management
- Use `@Environment(\.modelContext)` for SwiftData access in views
- Constants go in `Constants.swift` nested enums
- Services are singletons (`static let shared`) or `@Observable` classes
- When adding features visible in widgets/extensions, data must flow through App Group — not SwiftData directly
- Category definitions in `CategoryDefinitions.swift` (6 types: printed, digital, natural, handwritten, architectural, serendipitous)
- Rarity scale 1-5 (Common → Legendary) defined in `Constants.Rarity`

## GitHub

Repository: `sasquatch-vide-coder/binary-curious` (private)

```bash
# Push to GitHub (credentials from .env are already configured in the git remote)
git push origin main

# Build and install on physical device (iPhone 15 Pro Max)
xcodebuild -project BinaryCurious.xcodeproj -scheme BinaryCurious -destination 'generic/platform=iOS' build
xcrun devicectl device install app --device 68D99626-BCE0-5D39-B6A8-153B921C4DFE <path-to-built-.app>
xcrun devicectl device process launch --device 68D99626-BCE0-5D39-B6A8-153B921C4DFE com.binarycurious.app
```

Secrets are stored in `.env` (gitignored). Never commit `.env` or hardcode tokens.

## Known Issues

- SourceKit frequently shows false "Cannot find type" errors for cross-file references — these are analyzer issues, not real build errors. Always verify with `xcodebuild`.
- `Section("title") { } footer: { }` syntax fails in this Swift version — use `Section { } header: { Text("title") } footer: { }` instead.
- Every Siri AppShortcut phrase must include `\(.applicationName)`.
- Use `.foregroundColor(.accentColor)` instead of `.foregroundStyle(.accent)` — the latter is not a valid ShapeStyle.
