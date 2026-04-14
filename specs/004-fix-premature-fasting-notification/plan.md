# Implementation Plan: Fix Premature Fasting Notification

**Branch**: `004-fix-premature-fasting-notification` | **Date**: 2026-04-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-fix-premature-fasting-notification/spec.md`

## Summary

Fix bug where "Fasting Complete!" notification fires immediately when fasting duration is 0 or negative. Root cause: `max(1, date.timeIntervalSinceNow)` fallback in `scheduleGoalNotification()` schedules notification in 1 second instead of not scheduling. Solution: Add guard clause to reject past/invalid dates + validate minimum duration on fast start.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, UserNotifications, WidgetKit
**Storage**: UserDefaults (App Group), SwiftData
**Testing**: XCTest (manual testing for watchOS notifications)
**Target Platform**: watchOS 10+
**Project Type**: watchOS app + Widget
**Performance Goals**: N/A (bug fix)
**Constraints**: Must not break existing notification scheduling
**Scale/Scope**: 2 files, ~10 lines changed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is template (not customized). No blocking gates. Proceeding with standard practices:
- ✅ Simple fix, no over-engineering
- ✅ No new dependencies
- ✅ Backward compatible

## Project Structure

### Documentation (this feature)

```text
specs/004-fix-premature-fasting-notification/
├── plan.md              # This file
├── spec.md              # Bug description and requirements
├── research.md          # Root cause analysis
├── data-model.md        # No model changes (logic fix only)
└── quickstart.md        # Implementation steps
```

### Source Code (files to modify)

```text
FastWatch Watch App/
├── Managers/
│   ├── NotificationManager.swift  # Add guard clause
│   └── FastingManager.swift       # Add duration validation
```

**Structure Decision**: Existing watchOS app structure. No new files needed.

## Complexity Tracking

No violations. Simple bug fix with minimal changes.

## Implementation Tasks

### Task 1: Fix NotificationManager.scheduleGoalNotification

**File**: `FastWatch Watch App/Managers/NotificationManager.swift`

**Change**: Replace `max(1, ...)` pattern with guard clause

```swift
// Before (line 32-35):
let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: max(1, date.timeIntervalSinceNow),
    repeats: false
)

// After:
let interval = date.timeIntervalSinceNow
guard interval > 0 else { return }

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: interval,
    repeats: false
)
```

### Task 2: Add Duration Validation in FastingManager

**File**: `FastWatch Watch App/Managers/FastingManager.swift`

**Change**: Validate duration before starting fast

```swift
// In startFast(), after calculating duration:
guard duration >= 3600 else { return } // Minimum 1 hour
```

### Task 3: Manual Testing

1. Start custom fast with 0 hours → should not start
2. Start 16:8 fast → notification should fire at correct time
3. Kill app, restore before goal → no spurious notification
4. Kill app, restore after goal → no duplicate notification
