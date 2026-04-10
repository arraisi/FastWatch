# Data Model: FastWatch MVP

## Entities

### FastingProtocol
**Type**: `enum` (String, Codable, CaseIterable)

| Case | Raw Value | Fasting Duration | Eating Duration |
|------|-----------|-----------------|-----------------|
| sixteen8 | "16:8" | 16h | 8h |
| eighteen6 | "18:6" | 18h | 6h |
| twenty4 | "20:4" | 20h | 4h |
| omad | "23:1" | 23h | 1h |
| twentyFourHour | "24h" | 24h | nil |
| thirtySixHour | "36h" | 36h | nil |
| fortyEightHour | "48h+" | 48h | nil |
| custom | "Custom" | user-defined | user-defined |

**Computed Properties**: `fastingDuration: TimeInterval`, `eatingDuration: TimeInterval?`

### FastSession
**Type**: `struct` (Identifiable, Codable)

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| startTime | Date | When the fast began |
| endTime | Date? | When the fast ended (nil if active) |
| targetDuration | TimeInterval | Goal duration in seconds |
| protocolType | FastingProtocol | Which protocol was used |
| isActive | Bool | Whether this fast is currently running |

**Computed**: `actualDuration: TimeInterval?`, `completedGoal: Bool`

**Note**: Property named `protocolType` (not `protocol`) to avoid Swift keyword conflict.

### UserPreferences
**Type**: `struct` (Codable)

| Field | Type | Default |
|-------|------|---------|
| defaultProtocol | FastingProtocol | .sixteen8 |
| customFastingHours | Double | 16 |
| customEatingHours | Double | 8 |
| notifyOnMilestones | Bool | true |
| notifyOnGoalReached | Bool | true |
| notifyEatingWindowEnding | Bool | true |
| eatingWindowReminderMinutes | Int | 30 |
| hapticsEnabled | Bool | true |
| hapticIntensity | HapticIntensity | .strong |
| overtimeReminder | Bool | true |

### HapticIntensity
**Type**: `enum` (String, Codable)

| Case | Description |
|------|-------------|
| light | Subtle haptic |
| strong | Prominent haptic |

### FastState (nested in FastingManager)
**Type**: `enum`

| Case | Associated Values | Description |
|------|-------------------|-------------|
| idle | — | No active fast |
| fasting | startTime: Date, protocolType: FastingProtocol | Active fast in progress |
| goalReached | startTime: Date, protocolType: FastingProtocol | Target duration met |
| eating | until: Date | Eating window countdown |

## State Transitions

```
idle ──[Start Fast]──> fasting
fasting ──[elapsed >= target]──> goalReached
fasting ──[End Fast]──> idle (early end)
goalReached ──[End Fast + has eating window]──> eating
goalReached ──[End Fast + no eating window]──> idle
eating ──[window expires]──> idle
eating ──[Start Fast]──> fasting
```

## Persistence Strategy

| Data | Storage | Scope |
|------|---------|-------|
| Active fast (FastSession) | UserDefaults (App Group) | App + Widget |
| User preferences | UserDefaults | App only |
| Fast history | SwiftData (Phase 2) | App only |

**App Group ID**: `group.com.fastwatch.shared`
**UserDefaults Keys**: `activeFast` (JSON-encoded FastSession), `userPreferences` (JSON-encoded)
