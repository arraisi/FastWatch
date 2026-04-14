# Feature Spec: Fix Premature Fasting Notification

**ID**: 004-fix-premature-fasting-notification
**Date**: 2026-04-14
**Type**: Bug Fix

## Problem Statement

User receives "Fasting Complete!" notification while fasting is still in progress.

## Root Cause Analysis

1. **Primary Bug** (`NotificationManager.swift:33`):
   ```swift
   timeInterval: max(1, date.timeIntervalSinceNow)
   ```
   If `date.timeIntervalSinceNow <= 0` (target date in past), notification fires in 1 second instead of not firing.

2. **Secondary Bug** (`FastingProtocol.swift:24`):
   - Custom protocol returns `fastingDuration: 0`
   - If `customFastingHours` preference is unset/0, goal notification scheduled for "now"
   - Combined with `max(1, ...)` fallback → immediate notification

3. **Edge Cases**:
   - App restore after goal time passed
   - Timezone changes
   - Device clock adjustments

## Requirements

### Must Fix
- [ ] Guard against scheduling notifications for past dates
- [ ] Validate custom fasting duration > 0 before starting fast
- [ ] Remove `max(1, ...)` fallback - don't schedule if interval <= 0

### Should Fix
- [ ] Add minimum duration validation in `startFast()`
- [ ] Cancel existing notifications before rescheduling on app restore

## Acceptance Criteria

1. Notification fires only when `elapsed >= targetDuration`
2. Custom protocol with 0 hours shows validation error, doesn't start fast
3. App restore doesn't trigger spurious notifications
4. No regressions in milestone/overtime notifications

## Files to Modify

- `FastWatch Watch App/Managers/NotificationManager.swift`
- `FastWatch Watch App/Managers/FastingManager.swift`
