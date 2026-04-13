# Quickstart: Clear Fasting History

## Test Scenarios

### Scenario 1: Clear History with Data

1. Complete 2-3 fasts to populate history
2. Open History tab
3. Tap toolbar trash button
4. Confirm deletion in alert
5. **Expected**: History shows empty state, weekly stats show 0

### Scenario 2: Cancel Clear

1. Have fasts in history
2. Tap clear button
3. Tap "Cancel" in confirmation
4. **Expected**: History unchanged

### Scenario 3: Empty History State

1. Clear all history (or fresh install)
2. Check History tab
3. **Expected**: Clear button disabled or hidden

### Scenario 4: Active Fast Unaffected

1. Start a fast
2. Open History, clear it
3. **Expected**: Active fast continues normally

## Manual Verification

```swift
// In Xcode console after clear:
// Verify CompletedFast count is 0
let descriptor = FetchDescriptor<CompletedFast>()
let count = try modelContext.fetchCount(descriptor)
assert(count == 0)
```
