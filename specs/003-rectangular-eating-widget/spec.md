# Feature Specification: Rectangular Eating Widget

**Feature Branch**: `003-rectangular-eating-widget`
**Created**: 2026-04-13
**Status**: Draft
**Input**: User description: "improve widget, i want rectangular widget for eating time"

## User Scenarios & Testing

### User Story 1 - Eating Window Widget Display (Priority: P1)

As a user in the eating phase, I want the rectangular widget to show my eating window countdown so I know when my next fast should begin.

**Why this priority**: Core functionality - users need visibility into eating window timing on watch face.

**Independent Test**: Complete a fast, verify rectangular widget shows eating countdown with remaining time.

**Acceptance Scenarios**:

1. **Given** I complete a fast and enter eating phase, **When** I view the rectangular widget, **Then** I see eating time remaining and progress bar
2. **Given** I am in eating phase, **When** time passes, **Then** the widget updates to show decreasing remaining time
3. **Given** eating window ends, **When** I view widget, **Then** it transitions back to fasting display (or idle)

---

### User Story 2 - Distinct Eating Visual (Priority: P1)

As a user, I want the eating widget to look visually different from fasting so I can quickly tell which phase I'm in.

**Why this priority**: Equally important - prevents confusion between phases at a glance.

**Independent Test**: Compare eating and fasting widget side-by-side, verify distinct appearance.

**Acceptance Scenarios**:

1. **Given** I am in eating phase, **When** I view widget, **Then** I see orange color theme (matching app eating state)
2. **Given** I am in eating phase, **When** I view widget, **Then** I see "Eating" label and fork/knife icon
3. **Given** I am fasting, **When** I view widget, **Then** I see different color and timer icon

---

### Edge Cases

- What if eating session data is corrupted? Show idle/fasting state
- What about expired eating sessions? Check isExpired, show idle
- Widget refresh timing? 15-minute intervals like fasting widget

## Requirements

### Functional Requirements

- **FR-001**: Widget MUST display eating window remaining time when in eating state
- **FR-002**: Widget MUST show distinct visual (orange theme, eating icon) for eating phase
- **FR-003**: Widget MUST load eating session from UserDefaults (key: eatingSession)
- **FR-004**: Widget MUST update timeline every 15 minutes during eating phase
- **FR-005**: Widget MUST gracefully handle missing/expired eating data

### Key Entities

- **EatingSession**: Existing model (startTime, endTime, protocolType)
- **FastWatchEntry**: Needs new fields for eating state (isEating, eatingRemainingText)
- **FastWatchTimelineProvider**: Needs to load eating session

## Success Criteria

### Measurable Outcomes

- **SC-001**: Eating widget displays within 1 minute of completing fast
- **SC-002**: Time remaining is accurate within 1 minute
- **SC-003**: Visual clearly distinguishes eating from fasting at arm's length

## Assumptions

- Rectangular widget only (corner/circular continue to show fasting only)
- Same 15-minute refresh interval as fasting widget
- Eating session persisted to App Group UserDefaults (already implemented)
