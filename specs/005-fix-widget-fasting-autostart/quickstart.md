# Quickstart: Fix Widget Fasting Timer Autostart

**Date**: 2026-04-17 | **Feature**: 005-fix-widget-fasting-autostart

## Overview

This fix ensures the widget automatically transitions from eating to fasting state when the eating window ends, without requiring the user to open the main app.

## Files to Modify

| File | Change Type | Description |
|------|-------------|-------------|
| `FastWatchWidget/FastWatchTimelineProvider.swift` | Modify | Add transition detection and mixed timeline generation |
| `FastWatch Watch App/Managers/FastingManager.swift` | Modify | Add background refresh scheduling at eating end |

## Implementation Steps

### Step 1: Add Expired Eating Session Loader

In `FastWatchTimelineProvider.swift`, add method to load expired eating session:

```swift
private func loadExpiredEatingSession() -> EatingSession? {
    guard let data = defaults.data(forKey: "eatingSession"),
          let session = try? JSONDecoder().decode(EatingSession.self, from: data),
          session.isExpired,
          Date().timeIntervalSince(session.endTime) < 24 * 3600 // Within 24 hours
    else { return nil }
    return session
}
```

### Step 2: Update getTimeline() for Transition Detection

Modify the `getTimeline()` method to detect eating→fasting transition:

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
    // Check for active fast first
    if let session = loadActiveFast() {
        buildFastingTimeline(session: session, completion: completion)
        return
    }

    // Check for eating session (non-expired)
    if let eating = loadEatingSession() {
        buildEatingTimeline(session: eating, completion: completion)
        return
    }

    // Check for recently-expired eating (transition to fasting)
    if let expiredEating = loadExpiredEatingSession() {
        buildTransitionFastingTimeline(eatingEndTime: expiredEating.endTime,
                                       protocolType: expiredEating.protocolType,
                                       completion: completion)
        return
    }

    // Idle state (legitimate "No FastTime")
    // ... existing idle code ...
}
```

### Step 3: Add Transition Fasting Timeline Builder

```swift
private func buildTransitionFastingTimeline(eatingEndTime: Date,
                                            protocolType: FastingProtocol,
                                            completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
    var entries: [FastWatchEntry] = []
    let now = Date()
    let targetDuration = protocolType.fastingDuration

    for minuteOffset in stride(from: 0, through: 120, by: 15) {
        let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))
        let elapsed = entryDate.timeIntervalSince(eatingEndTime)
        let progress = targetDuration > 0 ? elapsed / targetDuration : 0
        let remaining = max(0, targetDuration - elapsed)
        let goalReached = elapsed >= targetDuration
        let zone = FastingZone.zone(for: elapsed / 3600)

        entries.append(FastWatchEntry(
            date: entryDate,
            progress: progress,
            remainingText: remaining.shortFormatted,
            elapsedText: elapsed.shortFormatted,
            isActive: true,
            isGoalReached: goalReached,
            zoneName: zone.rawValue,
            protocolName: protocolType.displayName,
            isEating: false,
            eatingRemainingText: "",
            eatingProgress: 0
        ))
    }

    let nextUpdate = now.addingTimeInterval(15 * 60)
    let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
    completion(timeline)
}
```

### Step 4: Update buildEatingTimeline() for Seamless Transition

Modify `buildEatingTimeline()` to include fasting entries after eating ends:

```swift
private func buildEatingTimeline(session: EatingSession, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
    var entries: [FastWatchEntry] = []
    let now = Date()
    let targetDuration = session.protocolType.fastingDuration

    for minuteOffset in stride(from: 0, through: 120, by: 15) {
        let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))

        if entryDate < session.endTime {
            // Still eating
            let remaining = session.endTime.timeIntervalSince(entryDate)
            let total = session.endTime.timeIntervalSince(session.startTime)
            let elapsed = entryDate.timeIntervalSince(session.startTime)
            let progress = total > 0 ? min(elapsed / total, 1.0) : 0

            entries.append(FastWatchEntry(
                date: entryDate,
                progress: 0,
                remainingText: "",
                elapsedText: "",
                isActive: false,
                isGoalReached: false,
                zoneName: "",
                protocolName: session.protocolType.displayName,
                isEating: true,
                eatingRemainingText: remaining.shortFormatted,
                eatingProgress: progress
            ))
        } else {
            // Transitioned to fasting
            let fastingElapsed = entryDate.timeIntervalSince(session.endTime)
            let progress = targetDuration > 0 ? fastingElapsed / targetDuration : 0
            let remaining = max(0, targetDuration - fastingElapsed)
            let zone = FastingZone.zone(for: fastingElapsed / 3600)

            entries.append(FastWatchEntry(
                date: entryDate,
                progress: progress,
                remainingText: remaining.shortFormatted,
                elapsedText: fastingElapsed.shortFormatted,
                isActive: true,
                isGoalReached: fastingElapsed >= targetDuration,
                zoneName: zone.rawValue,
                protocolName: session.protocolType.displayName,
                isEating: false,
                eatingRemainingText: "",
                eatingProgress: 0
            ))
        }
    }

    // Refresh at eating end time (or 15 min if already past)
    let nextUpdate = max(session.endTime, now.addingTimeInterval(15 * 60))
    let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
    completion(timeline)
}
```

### Step 5: Add Background Refresh (FR-007)

In `FastingManager.swift`, add background refresh scheduling when eating starts:

```swift
import WatchKit

// In completeFast(), after setting eating state:
if eatingDuration > 0 {
    // ... existing code ...

    // Schedule background refresh at eating end for low-power mode
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: eatingEnd,
        userInfo: ["action": "eatingEnded"] as NSDictionary
    ) { error in
        if let error = error {
            print("Failed to schedule background refresh: \(error)")
        }
    }
}
```

## Testing

1. Start a fast with short duration (1-2 min for testing)
2. End fast → eating window starts
3. Close the app (swipe away)
4. Wait for eating window to end
5. Verify widget shows fasting timer (not "No FastTime")
6. Open app → verify app shows same fasting time as widget
