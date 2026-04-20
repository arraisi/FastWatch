# Data Model: Fix Widget Fasting Timer Autostart

**Date**: 2026-04-17 | **Feature**: 005-fix-widget-fasting-autostart

## Entities

### EatingSession (Existing - No Changes)

| Field | Type | Description |
|-------|------|-------------|
| startTime | Date (UTC) | When eating window began |
| endTime | Date (UTC) | When eating window ends |
| protocolType | FastingProtocol | The fasting protocol (e.g., 16:8) |

**Computed Properties**:
- `remainingTime`: `TimeInterval` - Time until eating ends
- `isExpired`: `Bool` - Whether current time >= endTime
- `progress`: `Double` - 0.0 to 1.0 progress through eating window

**Storage**: UserDefaults key `eatingSession` in App Group `group.com.fastwatch.shared`

### FastWatchEntry (Existing - No Changes)

| Field | Type | Description |
|-------|------|-------------|
| date | Date | Entry display time |
| progress | Double | Fasting progress (0.0-1.0) |
| remainingText | String | Formatted remaining time |
| elapsedText | String | Formatted elapsed time |
| isActive | Bool | Whether fasting is active |
| isGoalReached | Bool | Whether fasting goal met |
| zoneName | String | Current fasting zone name |
| protocolName | String | Protocol display name |
| isEating | Bool | Whether in eating state |
| eatingRemainingText | String | Eating time remaining |
| eatingProgress | Double | Eating progress (0.0-1.0) |

## State Transitions

```text
┌─────────┐     start fast      ┌─────────┐
│  IDLE   │ ──────────────────► │ FASTING │
│         │ ◄────────────────── │         │
└─────────┘     cancel/end      └────┬────┘
     ▲                               │
     │                          end fast
     │          eating ends          │
     │  ┌──────────────────────┐     ▼
     └──│       EATING         │◄────┘
        │                      │
        └──────────────────────┘
              (auto-transition to FASTING when eating ends)
```

### Widget State Detection Logic

```text
getTimeline():
  1. IF loadActiveFast() returns session:
       → Build FASTING timeline

  2. ELSE IF loadEatingSession() returns non-expired session:
       → Build EATING timeline (includes transition entries)

  3. ELSE IF loadExpiredEatingSession() returns recently-expired session:
       → Build FASTING timeline starting from eating.endTime

  4. ELSE:
       → Return IDLE state (legitimate "No FastTime")
```

## New Method: loadExpiredEatingSession

**Purpose**: Retrieve eating session that recently expired for calculating fasting start time

**Logic**:
```text
loadExpiredEatingSession():
  - Load eating session from UserDefaults (ignore isExpired check)
  - If session exists AND endTime <= now AND endTime > (now - 24 hours):
    → Return session (use endTime as fasting start)
  - Else:
    → Return nil (too old or doesn't exist)
```

**24-hour threshold**: Prevents showing stale fasting time if widget hasn't refreshed for days

## Timeline Entry Generation

### For Eating→Fasting Transition

When building eating timeline, generate entries past eating end:

```text
buildEatingTimeline(session):
  entries = []
  now = Date()

  for minuteOffset in 0...120 step 15:
    entryDate = now + minuteOffset minutes

    if entryDate < session.endTime:
      // Still eating
      entries.append(eatingEntry(entryDate, session))
    else:
      // Transitioned to fasting
      fastingElapsed = entryDate - session.endTime
      entries.append(fastingEntry(entryDate, fastingElapsed, session.protocolType))

  // Schedule next refresh at eating end (or 15 min from now if already past)
  nextRefresh = max(session.endTime, now + 15 min)
  return Timeline(entries, policy: .after(nextRefresh))
```

## Validation Rules

1. **Eating session**: `startTime < endTime` (duration > 0)
2. **Fasting calculation**: `fastingElapsed = currentTime - eatingEndTime` (not negative)
3. **Transition detection**: Only when `!hasActiveFast AND hasExpiredEating`
4. **Stale data**: Expired eating older than 24 hours → treat as idle (data may be corrupt)
