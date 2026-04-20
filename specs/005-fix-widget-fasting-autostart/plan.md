# Implementation Plan: Fix Widget Fasting Timer Autostart

**Branch**: `005-fix-widget-fasting-autostart` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/005-fix-widget-fasting-autostart/spec.md`

## Summary

Fix widget not automatically transitioning from eating to fasting state when eating window ends. Root cause: `FastWatchTimelineProvider` filters out expired eating sessions but doesn't detect the eating→fasting transition or calculate fasting time from the eating end time. The app has this logic in `FastingManager.updateState()` but the widget lacks it.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: WidgetKit, SwiftUI, SwiftData
**Storage**: UserDefaults (App Group: `group.com.fastwatch.shared`)
**Testing**: XCTest (manual testing for widget behavior)
**Target Platform**: watchOS 10+
**Project Type**: mobile-app (watchOS with widget extension)
**Performance Goals**: Widget updates within 1 minute of eating window ending
**Constraints**: WidgetKit timeline refresh limitations, low-power mode considerations
**Scale/Scope**: Single user, single active session at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| No constitution defined | N/A | Project uses template constitution - no specific gates to enforce |

## Project Structure

### Documentation (this feature)

```text
specs/005-fix-widget-fasting-autostart/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
FastWatch Watch App/
├── Managers/
│   ├── FastingManager.swift       # Main app state management (reference)
│   └── NotificationManager.swift  # Notification scheduling
├── Models/
│   ├── EatingSession.swift        # Eating session model (app)
│   └── FastSession.swift          # Fasting session model (app)
└── Views/

FastWatchWidget/
├── FastWatchTimelineProvider.swift  # PRIMARY FIX LOCATION
├── FastWatchWidgetEntryView.swift   # Widget UI (may need updates)
├── FastWatchWidget.swift            # Widget configuration
└── Models/
    ├── EatingSession.swift          # Eating session model (widget)
    └── FastSession.swift            # Fasting session model (widget)
```

**Structure Decision**: Existing watchOS + widget extension structure. Bug fix primarily in `FastWatchWidget/FastWatchTimelineProvider.swift` with supporting changes to shared models.

## Complexity Tracking

> No constitution violations - standard bug fix within existing architecture.

## Root Cause Analysis

### Current Flow (Buggy)

1. User ends fast → `FastingManager.completeFast()` saves `EatingSession` to UserDefaults
2. Widget loads → `getTimeline()` calls `loadEatingSession()` which returns session if `!session.isExpired`
3. **BUG**: When `session.isExpired == true`, `loadEatingSession()` returns `nil`
4. Widget falls through to idle state ("No FastTime")
5. App opens → `FastingManager.updateState()` detects expired eating → calls `startFast()`
6. New `FastSession` saved → widget now shows fasting

### Fix Strategy

**Option A (Timeline-based)**: Schedule timeline entries past eating end that show fasting state
- Pro: Pure widget solution, no background refresh needed
- Con: Requires calculating fasting state in widget

**Option B (Background Refresh)**: Schedule background app refresh at eating end to start fasting
- Pro: Uses existing app logic
- Con: Background refresh not guaranteed, especially in low-power mode

**Chosen**: Option A with background refresh as backup (per FR-007)

## Implementation Approach

1. **Modify `loadEatingSession()`** to return expired sessions with a flag indicating expiry
2. **Add `loadExpiredEatingForTransition()`** method that returns recently-expired eating session
3. **Update `getTimeline()`** to detect eating→fasting transition and build fasting timeline from eating end time
4. **Update `buildEatingTimeline()`** to include transition entries at eating end
5. **Add background refresh scheduling** in main app when eating session starts
