# Quickstart: Rectangular Eating Widget

## Test Scenarios

### Scenario 1: Eating Phase Display

1. Start and complete a 16:8 fast (or mock by adjusting time)
2. App should transition to eating state
3. Check rectangular widget on watch face
4. **Expected**: Orange theme, fork icon, "8h" eating window countdown

### Scenario 2: Time Updates

1. While in eating phase, wait 15+ minutes
2. Check widget
3. **Expected**: Remaining time decreased (e.g., "7h 45m" → "7h 30m")

### Scenario 3: Eating Window Ends

1. Let eating window expire (or mock)
2. Check widget
3. **Expected**: Transitions to idle state or auto-starts new fast

### Scenario 4: Fasting vs Eating Visual

1. Compare widget during fasting (timer icon, green/blue)
2. Compare widget during eating (fork icon, orange)
3. **Expected**: Clearly distinguishable at a glance

## Preview Verification

```swift
// In Xcode, run these previews:
// - "Rectangular Eating" - should show orange eating UI
// - "Rectangular Active" - should show fasting UI (existing)
// - Compare colors and icons
```

## Manual Data Check

```swift
// Verify eating session in UserDefaults:
let defaults = UserDefaults(suiteName: "group.com.fastwatch.shared")
if let data = defaults?.data(forKey: "eatingSession"),
   let session = try? JSONDecoder().decode(EatingSession.self, from: data) {
    print("Eating until: \(session.endTime)")
    print("Remaining: \(session.remainingTime / 3600) hours")
}
```
