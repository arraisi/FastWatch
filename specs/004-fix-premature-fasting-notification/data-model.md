# Data Model: Fix Premature Fasting Notification

## No Data Model Changes Required

This is a bug fix affecting notification scheduling logic only. No changes to:
- `FastSession` model
- `CompletedFast` model
- `EatingSession` model
- `FastingProtocol` enum
- UserDefaults keys

## Logic Changes

### NotificationManager

| Method | Change |
|--------|--------|
| `scheduleGoalNotification` | Add guard: `interval > 0` |
| `scheduleMilestoneNotifications` | Already has guard (line 56) |
| `scheduleEatingWindowReminder` | Already has guard (line 82) |
| `scheduleOvertimeReminder` | Already has guard (line 106) |

### FastingManager

| Method | Change |
|--------|--------|
| `startFast` | Validate `duration >= 3600` (1 hour minimum) |

## Validation Rules

```swift
// Minimum fasting duration: 1 hour
static let minimumFastingDuration: TimeInterval = 3600

// In startFast():
guard duration >= Self.minimumFastingDuration else {
    // Don't start fast, optionally show alert
    return
}
```
