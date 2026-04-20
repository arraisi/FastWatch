# Research: Fix Widget Fasting Timer Autostart

**Date**: 2026-04-17 | **Feature**: 005-fix-widget-fasting-autostart

## Research Topics

### 1. WidgetKit Timeline Behavior After Session Expiry

**Decision**: Use timeline entries that span past eating end time, with entries showing fasting state

**Rationale**: WidgetKit timelines can include future-dated entries. When the system displays an entry dated after the eating end, that entry should already show the fasting state with elapsed time calculated from eating end.

**Alternatives considered**:
- Rely on `.after(date)` policy to trigger reload → Not reliable, system may delay
- Background app refresh → Not guaranteed in low-power mode

### 2. Detecting Eating→Fasting Transition in Widget

**Decision**: Check for expired eating session AND absence of active fast to determine transition state

**Rationale**:
- Current code: `if let eating = loadEatingSession()` only returns non-expired sessions
- Fix: Add separate method to load eating session regardless of expiry for transition detection
- When eating expired AND no active fast → calculate fasting start = eating end time

**Alternatives considered**:
- Store explicit "pending fasting" flag → Adds complexity, doesn't solve widget-only case
- Modify `isExpired` check → Would break other usages of `loadEatingSession()`

### 3. Background Refresh for Low-Power Mode (FR-007)

**Decision**: Schedule `WKApplicationRefreshBackgroundTask` at eating end time

**Rationale**: Per FR-007, system must use background refresh scheduling. WatchOS supports background app refresh which can:
1. Wake the app briefly at eating end
2. Call `startFast()` to persist fasting session
3. Trigger `WidgetCenter.shared.reloadAllTimelines()`

**Alternatives considered**:
- Rely purely on widget timeline → May not refresh in low-power mode
- Use silent push notification → Requires server infrastructure

### 4. Timestamp Storage Format (FR-008)

**Decision**: Current implementation already uses `Date` type which stores UTC internally

**Rationale**: Swift's `Date` type stores absolute time (seconds since reference date in UTC). Encoding via `JSONEncoder` preserves this. No changes needed.

**Alternatives considered**:
- Store as Unix timestamp explicitly → Adds complexity, no benefit
- Store timezone offset → Unnecessary, `Date` is already timezone-agnostic

### 5. Widget Timeline Entry Generation Strategy

**Decision**: Generate timeline entries that span eating end, with post-eating entries showing fasting state

**Implementation**:
```text
buildEatingTimeline():
  for each 15-minute interval:
    if entryDate < eatingEndTime:
      entry.isEating = true
      entry.eatingRemainingText = remaining time
    else:
      entry.isEating = false
      entry.isActive = true (fasting)
      entry.elapsedText = entryDate - eatingEndTime
```

**Rationale**: Single timeline generation handles transition seamlessly. Widget displays correct state at any point in time.

## Key Findings

1. **Root cause confirmed**: `loadEatingSession()` returns `nil` for expired sessions, causing idle state instead of transition to fasting

2. **WidgetKit supports mixed timelines**: A single timeline can contain entries with different states, allowing eating→fasting transition in one timeline generation

3. **Background refresh is supplementary**: Timeline approach handles most cases; background refresh ensures fasting session is persisted for app consistency

4. **No storage format changes needed**: Current `Date` type already stores UTC timestamps

## Implementation Checklist

- [ ] Add `loadExpiredEatingSession()` method in TimelineProvider
- [ ] Modify `getTimeline()` to check for eating→fasting transition
- [ ] Update `buildEatingTimeline()` to generate entries past eating end with fasting state
- [ ] Add fasting state calculation from eating end time (not from refresh time)
- [ ] Schedule background refresh at eating end time in FastingManager
- [ ] Test widget behavior when eating ends without app open
