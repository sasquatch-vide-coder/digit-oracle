# Binary Curious — Master Build Plan

An iOS app for tracking sightings of the number 47 "in the wild."

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 1 | Foundation | Done |
| 2 | Photo Import + Metadata | Done |
| 3 | Camera | Done |
| 4 | Location | Done |
| 5 | OCR + Verification | Done |
| 6 | Annotation/Markup | Done |
| 7 | Albums + Organization | Done |
| 8 | Repository Refactor | Skipped |
| 9 | Stats + Calendar | Done |
| 10 | Achievements | Done |
| 11 | Challenges + Streaks | Done |
| 12 | Wrapped + Memories | Done |
| 13 | Notifications + Time Alerts | Done |
| 14 | Widgets + Shortcuts | Done |
| 15 | Share Sheet Extension | Done |
| 16 | AR Live Scan + Live Text | Not started |
| 17 | Drop Sharing + PDF Export | Not started |
| 18 | Time Capsules | Not started |
| 19 | Social Stubs + Final Polish | Not started |

---

## Phase 1: Foundation

- Create Xcode project with SwiftData and xcodegen (`project.yml`)
- Define `@Model` classes: `Sighting`, `Album`, `Tag`, `UserProfile`
- Set up `ModelContainer` in `BinaryCuriousApp.swift`
- Build `ContentView` with `TabView` (Sightings, Capture, Albums, Profile)
- Build `SightingListView` with `@Query` fetching sightings
- Build `SightingRowView` (date + notes)
- Build `SightingDetailView` (read-only display)
- Add sample data for previews

## Phase 2: Photo Import + Metadata

- Build `ImageStorageService` (save/load images to `Documents/SightingImages/`)
- Add `PhotosPicker` to `CaptureView`
- Build `PhotoReviewView` (shows imported image before saving)
- Build `MetadataFormView` (notes, category, rarity, tags, album picker)
- Wire up save flow: import → review → add metadata → save Sighting
- Update row/detail views to display actual images

## Phase 3: Camera

- Build `CameraService` (AVFoundation capture session)
- Build `CameraPreviewView` (UIViewRepresentable)
- Integrate camera into `CaptureView` with shutter button
- Connect captured photo to existing `PhotoReviewView` flow
- Handle camera permissions gracefully

## Phase 4: Location

- Build `LocationService` (CLLocationManager wrapper)
- Request location permission on first capture
- Auto-attach latitude/longitude when saving a sighting
- Add reverse geocoding to populate `locationName`
- Display location in `SightingDetailView`

## Phase 5: OCR + Verification

- Build `OCRService` (Vision framework `VNRecognizeTextRequest`)
- Run OCR during photo review (parallel with location fetch)
- Display detection badge in `PhotoReviewView`
- Store `detectedText` and `contains47` on Sighting
- Add "verified" filter option

## Phase 6: Annotation/Markup

- Build `AnnotationView` using PencilKit
- Allow users to circle/markup the 47 in their photo
- Save annotation as separate PNG overlay
- Display annotation overlay in detail view

## Phase 7: Albums + Organization

- Build `AlbumListView` (grid of album cards)
- Build `AlbumDetailView` (sightings in album)
- Build `AddSightingsToAlbumView` (add existing sightings to album)
- Build `AlbumPickerView` (toggle sighting in/out of albums from detail view)
- Build `FilterSheetView` (full filter/sort: category, rarity, verified, date range, favorites)

## Phase 8: Repository Refactor — SKIPPED

Architectural-only refactor (repository pattern). Skipped to continue building features.

## Phase 9: Stats + Calendar

- Build `StatsCalculator` (total, verified, streak, category breakdown, etc.)
- Build `RarityCalculator` (auto-score based on time, category, uniqueness)
- Build `StatsOverviewView` (hero card, quick stats grid, streak card)
- Build `CalendarHeatmapView` (monthly calendar with GitHub-style heat colors)
- Build `CategoryBreakdownView` (Swift Charts bar charts)
- Build `HeatmapView` (MapKit map with sighting annotations)

## Phase 10: Achievements

- Define 19 achievements in `AchievementDefinitions` (milestones, time-based, category, streaks, special dates)
- Build `AchievementEngine` (check all achievements after each save)
- Build `AchievementsView` (3-column grid with progress rings)
- Build `AchievementCelebrationView` (modal overlay with spring animation)
- Wire celebration into `PhotoReviewView` save flow

## Phase 11: Challenges + Streaks

- Define daily (8) and weekly (6) challenge templates in `ChallengeTemplates`
- Build `ChallengeEngine` (auto-generate daily/weekly, check completion, award streak freezes)
- Build `ChallengeListView` (active, completed, expired sections with countdown timers)
- Build `ChallengeCelebrationView` (modal overlay for challenge completion)
- Wire into save flow with chained celebration (achievements first, then challenges)

## Phase 12: Wrapped + Memories

- Build `WrappedView` (Spotify-style swipeable story pages with gradient backgrounds)
- Build `OnThisDayView` (memories from past years matching today's date)
- Build `MonthlyDigestView` (month navigator with stats, rarest find, category breakdown)

## Phase 13: Notifications + Time Alerts

- Build `NotificationService` (singleton managing UNUserNotificationCenter)
- Schedule 4:47 PM/AM alerts, hourly :47 alerts, April 7th, Day 47
- Schedule daily reminder, monthly digest, memory notifications
- Build `NotificationSettingsView` (toggle preferences via @AppStorage)
- Build `SettingsView` (profile, notifications link, delete all, version info)

## Phase 14: Widgets + Shortcuts

- Add Widget Extension target with App Group (`group.com.binarycurious.app`)
- Build `WidgetDataService` (write stats + thumbnails to shared container)
- Build `WidgetData` (read stats + load images from shared container)
- Build `QuickCaptureWidget` (small, deep link to capture)
- Build `CountWidget` (Lock Screen accessory showing total)
- Build `StreakWidget` (Lock Screen accessory showing streak)
- Build `RecentSightingWidget` (random sighting with photo background)
- Build Siri shortcuts via AppIntents (`QuickCaptureIntent`, `ViewStatsIntent`)
- Update `ContentView` to sync widget data on launch

## Phase 15: Share Sheet Extension

- Add Share Extension target (`com.apple.share-services`)
- Build `PendingSightingService` (file-based queue in App Group container)
- Build `ShareViewController` (extracts image from NSItemProvider, downsamples if needed)
- Build `ShareExtensionView` (compact SwiftUI: image preview + notes + save)
- Update `ContentView` to import pending shares on launch/foreground with OCR
- Show green import banner after successful import

## Phase 16: AR Live Scan + Live Text

- Build `ARScanService` (ARKit + Vision per-frame text detection)
- Build `ARScanView` (AR camera with 47 highlight overlay)
- Build `LiveTextScanView` (DataScannerViewController wrapper)
- Add mode switcher in `CaptureView`: Camera / AR Scan / Live Text / Import

## Phase 17: Drop Sharing + PDF Export

- Build `DropCardRenderer` (generate shareable card image from a sighting)
- Build `DropShareView` (preview card + ShareLink)
- Build `ExportService` (PDF generation with UIGraphicsPDFRenderer)
- Build `PhotoBookExportView` (select sightings, generate multi-page PDF, share/save)

## Phase 18: Time Capsules

- Build `TimeCapsule` model (SwiftData, already in schema)
- Build `CreateTimeCapsuleView` (select sightings, set unlock date, write message)
- Build `TimeCapsuleListView` (locked/unlocked capsules)
- Build `OpenTimeCapsuleView` (reveal animation on unlock date)

## Phase 19: Social Stubs + Final Polish

- Build `SocialPlaceholderView` (friends list, global heatmap — "Coming Soon")
- Build `ProfileView` (user info and stats summary)
- Final UI polish, animations, and transitions throughout
- Bug fixes and performance optimization
