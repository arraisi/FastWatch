# Feature Specification: Fix Widget Fasting Timer Autostart

**Feature Branch**: `005-fix-widget-fasting-autostart`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "When eating time is over then the fasting timer not start automatically or freeze in No FastTime show on widget but after the app is opened, the fasting timer automatically starts running"

## Clarifications

### Session 2026-04-17

- Q: What happens if the device is in low-power mode when eating time ends? → A: Require workaround to force update via background refresh scheduling
- Q: How does the system handle if eating session data becomes unavailable (deleted/corrupted)? → A: Show "No FastTime" as legitimate idle state
- Q: How does the widget behave if the user's timezone changes during an eating window? → A: Use absolute timestamps (UTC); timezone changes don't affect duration calculations

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Fasting Start on Widget (Priority: P1)

When a user's eating window ends, the widget should automatically transition from showing eating time to showing fasting time without requiring the user to open the main app.

**Why this priority**: This is the core bug being fixed. Users rely on the widget for at-a-glance fasting status without opening the app. If the widget doesn't update, users lose trust in the widget's accuracy.

**Independent Test**: Can be fully tested by setting an eating window to end in 1-2 minutes and observing the widget transition without opening the app.

**Acceptance Scenarios**:

1. **Given** an active eating session displayed on the widget, **When** the eating window duration expires, **Then** the widget automatically displays the fasting timer counting up from 0:00
2. **Given** an active eating session displayed on the widget, **When** the eating window ends, **Then** the widget updates within 1 minute of the eating window ending
3. **Given** the widget shows fasting time after auto-transition, **When** the user opens the main app, **Then** the app shows the same fasting duration (within seconds)

---

### User Story 2 - No "No FastTime" State After Eating Ends (Priority: P1)

Users should never see "No FastTime" or a frozen/stale state on the widget when they have an active fasting schedule and eating time has ended.

**Why this priority**: Displaying incorrect state erodes user confidence and defeats the purpose of the widget.

**Independent Test**: Verify by letting eating time expire and confirming the widget never shows "No FastTime" or stale data.

**Acceptance Scenarios**:

1. **Given** an eating session that has just ended, **When** viewing the widget, **Then** the widget shows active fasting time (not "No FastTime")
2. **Given** a widget displaying eating time, **When** the eating window expires while the app is in background/closed, **Then** the widget does not freeze or show stale eating time

---

### User Story 3 - Consistency Between Widget and App (Priority: P2)

The fasting timer state displayed on the widget must match the state in the main app at all times.

**Why this priority**: Data consistency ensures users can trust either interface.

**Independent Test**: Compare widget and app displays at various points during eating/fasting transitions.

**Acceptance Scenarios**:

1. **Given** the widget showing fasting time, **When** the user opens the app, **Then** both show the same fasting duration (within 5 seconds tolerance)
2. **Given** the app was not opened during eating-to-fasting transition, **When** the user eventually opens the app, **Then** both widget and app show consistent fasting start time

---

### Edge Cases

- Low-power mode: System MUST use background refresh scheduling to force widget update even in low-power mode
- Timezone change: Use absolute timestamps (UTC); timezone changes don't affect duration calculations
- Delayed refresh: Widget calculates fasting time from eating end time, not refresh time (covered by FR-004)
- Missing/corrupted data: Show "No FastTime" as legitimate idle state (no session to display)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Widget MUST automatically transition from eating state to fasting state when the eating window duration expires
- **FR-002**: Widget MUST NOT display "No FastTime" when a valid fasting session should be active (eating ended, no manual stop); "No FastTime" is only valid when session data is missing/corrupted (legitimate idle)
- **FR-003**: Widget MUST refresh its state within 1 minute of the eating window ending
- **FR-004**: Widget MUST calculate fasting start time based on when the eating window ended, not when the widget refreshes
- **FR-005**: Widget state MUST remain synchronized with the main app's fasting state
- **FR-006**: System MUST persist the fasting session start time so widget can display accurate elapsed time across refreshes
- **FR-007**: System MUST schedule background refresh to ensure widget updates even in low-power mode
- **FR-008**: System MUST store all timestamps in absolute format (UTC) to ensure timezone changes don't affect calculations

### Key Entities

- **Eating Session**: Represents the current eating window with start time and duration
- **Fasting Session**: Represents the active fasting period with calculated start time (eating end time)
- **Widget State**: The current display state of the widget (eating, fasting, or idle)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Widget displays correct fasting time within 1 minute of eating window ending, 100% of the time
- **SC-002**: Users never see "No FastTime" when a fasting session should be active
- **SC-003**: Widget and app fasting times match within 5 seconds when viewed simultaneously
- **SC-004**: Widget continues functioning correctly when app is not opened for 24+ hours

## Assumptions

- Widget timeline refresh intervals are handled by the system (WidgetKit) and cannot be made more frequent than system allows
- Shared data storage (App Group UserDefaults) between app and widget is functioning correctly
- The eating session end time can be calculated from stored start time and duration
- System will wake the widget for timeline updates at reasonable intervals
