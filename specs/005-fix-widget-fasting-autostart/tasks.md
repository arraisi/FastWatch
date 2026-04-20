# Tasks: Fix Widget Fasting Timer Autostart

**Input**: Design documents from `specs/005-fix-widget-fasting-autostart/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Manual testing only (watchOS widget behavior cannot be unit tested effectively)

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Widget**: `FastWatchWidget/`
- **App**: `FastWatch Watch App/`

---

## Phase 1: Setup

**Purpose**: Verify existing code structure and prepare for modifications

- [x] T001 Review current `FastWatchTimelineProvider.swift` implementation in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T002 Review current `EatingSession.swift` model in `FastWatchWidget/Models/EatingSession.swift`
- [x] T003 Review `FastingManager.swift` eating state handling in `FastWatch Watch App/Managers/FastingManager.swift`

---

## Phase 2: Foundational (Core Timeline Logic)

**Purpose**: Add core infrastructure for eating→fasting transition detection

**⚠️ CRITICAL**: Must complete before user story implementation

- [x] T004 Add `loadExpiredEatingSession()` method in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T005 Add `buildTransitionFastingTimeline()` method in `FastWatchWidget/FastWatchTimelineProvider.swift`

**Checkpoint**: Core transition detection methods ready ✓

---

## Phase 3: User Story 1 - Automatic Fasting Start on Widget (Priority: P1) 🎯 MVP

**Goal**: Widget automatically shows fasting timer when eating window ends, without app interaction

**Independent Test**: Set eating window to end in 1-2 minutes, close app, verify widget shows fasting timer after eating ends

### Implementation for User Story 1

- [x] T006 [US1] Update `getTimeline()` to check for expired eating session after active fast check in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T007 [US1] Update `getTimeline()` to call `buildTransitionFastingTimeline()` when expired eating detected in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T008 [US1] Implement fasting elapsed calculation from `eatingEndTime` in `buildTransitionFastingTimeline()` in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T009 [US1] Generate 15-minute interval entries showing fasting state in `buildTransitionFastingTimeline()` in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T010 [US1] Set timeline refresh policy to update every 15 minutes in `buildTransitionFastingTimeline()` in `FastWatchWidget/FastWatchTimelineProvider.swift`

**Checkpoint**: Widget shows fasting timer when eating ends (core bug fixed) ✓

---

## Phase 4: User Story 2 - No "No FastTime" After Eating Ends (Priority: P1)

**Goal**: Eliminate false idle state when fasting should be active

**Independent Test**: Let eating time expire, verify widget never shows "No FastTime" during transition

### Implementation for User Story 2

- [x] T011 [US2] Update `buildEatingTimeline()` to generate entries past eating end time in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T012 [US2] Add conditional logic in `buildEatingTimeline()`: if `entryDate < eatingEndTime` show eating, else show fasting in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T013 [US2] Calculate fasting elapsed as `entryDate - eatingEndTime` for post-eating entries in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T014 [US2] Set `isActive = true` and `isEating = false` for post-eating entries in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T015 [US2] Update timeline refresh policy to use `max(eatingEndTime, now + 15min)` in `FastWatchWidget/FastWatchTimelineProvider.swift`

**Checkpoint**: Widget seamlessly transitions from eating to fasting state ✓

---

## Phase 5: User Story 3 - Consistency Between Widget and App (Priority: P2)

**Goal**: Widget and app show matching fasting times when app is eventually opened

**Independent Test**: Compare widget and app fasting times after eating→fasting transition without app open

### Implementation for User Story 3

- [x] T016 [US3] Add background refresh scheduling in `completeFast()` method in `FastWatch Watch App/Managers/FastingManager.swift`
- [x] T017 [US3] Import WatchKit for `WKApplication.shared()` access in `FastWatch Watch App/Managers/FastingManager.swift`
- [x] T018 [US3] Schedule `scheduleBackgroundRefresh(withPreferredDate:)` at eating end time in `FastWatch Watch App/Managers/FastingManager.swift`
- [x] T019 [US3] Handle background refresh callback to start fasting session in `FastWatch Watch App/FastWatchApp.swift`
- [x] T020 [US3] Call `WidgetCenter.shared.reloadAllTimelines()` after background refresh starts fasting in `FastWatch Watch App/FastWatchApp.swift`

**Checkpoint**: App and widget show synchronized fasting times ✓

---

## Phase 6: Polish & Validation

**Purpose**: Final validation and edge case handling

- [x] T021 Add 24-hour expiry threshold in `loadExpiredEatingSession()` to prevent stale data in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T022 Update `currentEntry()` snapshot method to handle transition state in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [ ] T023 Test low-power mode behavior by enabling Low Power Mode on watch
- [ ] T024 Validate timezone handling by changing timezone during eating window
- [ ] T025 Run quickstart.md validation scenarios

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - code review only ✓
- **Foundational (Phase 2)**: Depends on Setup - adds core methods ✓
- **User Story 1 (Phase 3)**: Depends on Foundational - implements transition detection ✓
- **User Story 2 (Phase 4)**: Depends on Foundational - improves timeline generation ✓
- **User Story 3 (Phase 5)**: Independent of US1/US2 - adds background refresh ✓
- **Polish (Phase 6)**: Depends on all user stories (manual testing pending)

### User Story Dependencies

- **User Story 1 (P1)**: Core fix - can start after Foundational ✓
- **User Story 2 (P1)**: Enhances US1 - can run in parallel with US1 ✓
- **User Story 3 (P2)**: Independent - can run in parallel with US1/US2 ✓

### Parallel Opportunities

**Within Phase 2 (Foundational)**:
```
T004 loadExpiredEatingSession() and T005 buildTransitionFastingTimeline() can run in parallel
```

**User Stories can run in parallel**:
```
US1 (T006-T010) and US2 (T011-T015) modify same file but different methods
US3 (T016-T020) modifies different files entirely - fully parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (review code) ✓
2. Complete Phase 2: Foundational (add helper methods) ✓
3. Complete Phase 3: User Story 1 (core bug fix) ✓
4. **STOP and VALIDATE**: Test widget transition without app
5. Deploy if core bug is fixed

### Incremental Delivery

1. MVP: US1 → Widget shows fasting when eating ends ✓
2. Enhancement: US2 → Seamless timeline transition ✓
3. Consistency: US3 → App/widget sync via background refresh ✓
4. Polish → Edge cases and validation (manual testing pending)

---

## Notes

- All tasks modify existing files (no new file creation)
- Primary fix file: `FastWatchWidget/FastWatchTimelineProvider.swift`
- Secondary fix file: `FastWatch Watch App/Managers/FastingManager.swift`
- Manual testing required (Xcode Simulator or physical watch)
- Commit after each task or logical group

## Implementation Summary

**Completed**: 22/25 tasks (88%)
**Pending**: 3 manual testing tasks (T023-T025)
**Files Modified**:
- `FastWatchWidget/FastWatchTimelineProvider.swift` - Added transition detection and mixed timeline generation
- `FastWatch Watch App/Managers/FastingManager.swift` - Added background refresh scheduling
- `FastWatch Watch App/FastWatchApp.swift` - Added background refresh handler
