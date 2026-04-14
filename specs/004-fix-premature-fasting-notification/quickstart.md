# Quickstart: Fix Premature Fasting Notification

## Overview

Bug fix for notification firing immediately instead of at goal time.

## Prerequisites

- Xcode 15+
- watchOS 10+ simulator or device

## Changes Required

### 1. NotificationManager.swift

Location: `FastWatch Watch App/Managers/NotificationManager.swift`

In `scheduleGoalNotification(at:protocolName:)`, replace lines 32-35:

```swift
// OLD:
let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: max(1, date.timeIntervalSinceNow),
    repeats: false
)

// NEW:
let interval = date.timeIntervalSinceNow
guard interval > 0 else { return }

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: interval,
    repeats: false
)
```

### 2. FastingManager.swift

Location: `FastWatch Watch App/Managers/FastingManager.swift`

In `startFast(protocolType:)`, after line 59 (after duration calculation):

```swift
// Add validation:
guard duration >= 3600 else { return } // Minimum 1 hour
```

## Testing

1. Build and run on watchOS simulator
2. Set custom fast to 0 hours → tap Start → should not start
3. Set 16:8 protocol → start fast → verify notification scheduled for 16h later
4. Force quit app during fast → reopen → no immediate notification

## Verification

```bash
# Check pending notifications (in debugger):
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print(requests.map { ($0.identifier, $0.trigger) })
}
```
