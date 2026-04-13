# Research: FastWatch MVP

## Decisions

### Timer Mechanism
- **Decision**: `TimelineView(.animation)` for SwiftUI view updates
- **Rationale**: Native SwiftUI, no drift, battery efficient. View recalculates on display — no manual Timer.publish needed.
- **Alternatives**: `Timer.publish` (unnecessary complexity, potential drift), `DispatchSourceTimer` (not SwiftUI-native)

### Active Fast Persistence
- **Decision**: UserDefaults with App Group (`group.com.fastwatch.shared`)
- **Rationale**: Single active session — simple key-value storage. Shared with widget extension via App Group.
- **Alternatives**: SwiftData (overkill for single active record), file-based (no advantage over UserDefaults)

### History Persistence (Phase 2)
- **Decision**: SwiftData
- **Rationale**: watchOS 10+ native, replaces CoreData with simpler API. Good for list of FastSession records.
- **Alternatives**: CoreData (legacy, more boilerplate), UserDefaults array (doesn't scale, no querying)

### Widget Refresh Strategy
- **Decision**: `TimelineProvider` generating entries every 15 minutes during active fast
- **Rationale**: Matches watchOS widget refresh budget. Use `relevantDate` for milestone entries.
- **Alternatives**: More frequent updates (exceeds budget), push-based (no server)

### State Management
- **Decision**: `@Observable` (Observation framework, watchOS 10+)
- **Rationale**: Simpler than `ObservableObject`/`@Published`. Automatic view invalidation.
- **Alternatives**: `ObservableObject` (older API, more boilerplate)

### Ring Animation
- **Decision**: SwiftUI `Circle()` shape with `.trim(from:to:)` inside `TimelineView`
- **Rationale**: Standard Apple Activity Ring pattern. Smooth 60fps with `.animation` schedule.
- **Alternatives**: Canvas/CoreGraphics (more control but unnecessary complexity)

### Haptic Feedback
- **Decision**: `WKInterfaceDevice.current().play(.success)` for goal reached
- **Rationale**: Simple watchOS API. Maps directly to success haptic pattern.
- **Alternatives**: Custom haptic patterns (not needed for MVP)

### Notification Framework
- **Decision**: `UNUserNotificationCenter` with local notifications
- **Rationale**: Standard Apple framework. Schedule time-based notifications when fast starts.
- **Alternatives**: None reasonable for local watchOS notifications.
