# Research: Fix Premature Fasting Notification

## Investigation Summary

### Bug Reproduction Path

1. User starts fast with custom protocol where `customFastingHours = 0`
2. `startFast()` calculates `duration = 0 * 3600 = 0`
3. `scheduleGoalNotification(at: now.addingTimeInterval(0))` called
4. `date.timeIntervalSinceNow` ≈ 0 (or negative due to execution time)
5. `max(1, 0)` = 1 second
6. Notification fires in 1 second while user just started fasting

### Alternative Trigger Scenarios

1. **App restore after device was off**:
   - Goal time passed while app suspended
   - `rescheduleNotificationsForRestoredFast()` has guard `if goalDate > Date()`
   - Should be safe, but notification already delivered before restore

2. **Clock manipulation**:
   - Device time set forward then back
   - Existing scheduled notification fires early
   - iOS limitation, cannot fully prevent

### UNTimeIntervalNotificationTrigger Behavior

- Apple docs: `timeInterval` must be > 0
- Passing 0 or negative causes runtime error
- `max(1, ...)` was intended as safety but creates the bug

### Solution Patterns

**Pattern 1: Guard clause (chosen)**
```swift
guard date.timeIntervalSinceNow > 0 else { return }
```

**Pattern 2: Optional return**
```swift
func scheduleGoalNotification(...) -> Bool {
    guard interval > 0 else { return false }
    ...
    return true
}
```

**Pattern 3: UNCalendarNotificationTrigger**
- Uses DateComponents instead of interval
- More robust for absolute times
- Overkill for this use case

### Decision

- Use guard clause pattern (simple, direct)
- Add duration validation in `startFast()`
- Minimum fast duration: 1 hour (reasonable lower bound)

## References

- [UNTimeIntervalNotificationTrigger](https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger)
- Existing code: `NotificationManager.swift`, `FastingManager.swift`
