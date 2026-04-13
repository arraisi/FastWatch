# Tasks: FastWatch MVP - Notification Flow Fix

**Input**: Design documents from `/specs/001-fastwatch-mvp/`
**Prerequisites**: plan.md, research.md, data-model.md, quickstart.md
**Bug Report**: User received fasting state notifications during eating time

## Bug Analysis Summary

**Root Causes Identified**:
1. Eating state not persisted - app restart loses eating window context
2. No notification cleanup on state restore
3. Delivered notifications remain in notification center after state change
4. Auto-transition from eating to fasting schedules new notifications unexpectedly

**Affected Files**:
- `FastWatch Watch App/Managers/FastingManager.swift`
- `FastWatch Watch App/Managers/NotificationManager.swift`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 = Notification Fix, US2 = State Persistence, US3 = UX Polish

---

## Phase 1: Setup

**Purpose**: Preparation for bug fix

- [x] T001 Review current notification identifiers in NotificationManager.swift
- [x] T002 Document current state transition flow in FastingManager.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core fixes that must be in place before other improvements

- [x] T003 Add method to cancel only fasting-related notifications (not eating) in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T004 Add method to remove delivered notifications from notification center in FastWatch Watch App/Managers/NotificationManager.swift

**Checkpoint**: Notification infrastructure ready for state-aware cancellation

---

## Phase 3: User Story 1 - Fix Notification Timing (Priority: P1)

**Goal**: Ensure fasting notifications never fire during eating state

**Independent Test**: Start fast, complete it, enter eating state, verify no fasting notifications appear

### Implementation for User Story 1

- [x] T005 [US1] Update completeFast() to clear delivered fasting notifications when entering eating state in FastWatch Watch App/Managers/FastingManager.swift
- [x] T006 [US1] Add notification category identifiers (fasting vs eating) in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T007 [US1] Update scheduleMilestoneNotifications to use fasting category identifier in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T008 [US1] Update scheduleGoalNotification to use fasting category identifier in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T009 [US1] Update scheduleOvertimeReminder to use fasting category identifier in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T010 [US1] Update scheduleEatingWindowReminder to use eating category identifier in FastWatch Watch App/Managers/NotificationManager.swift

**Checkpoint**: Fasting and eating notifications are categorized and can be selectively cancelled

---

## Phase 4: User Story 2 - Persist Eating State (Priority: P2)

**Goal**: Eating state survives app restart so notifications align with actual state

**Independent Test**: Enter eating state, kill app, relaunch, verify eating state restored with correct remaining time

### Implementation for User Story 2

- [x] T011 [US2] Create EatingSession struct (startTime, endTime, protocolType) in FastWatch Watch App/Models/EatingSession.swift
- [x] T012 [US2] Add persistEatingState() method to save eating window to UserDefaults in FastWatch Watch App/Managers/FastingManager.swift
- [x] T013 [US2] Add clearPersistedEatingState() method in FastWatch Watch App/Managers/FastingManager.swift
- [x] T014 [US2] Update completeFast() to call persistEatingState() when entering eating in FastWatch Watch App/Managers/FastingManager.swift
- [x] T015 [US2] Add restoreEatingState() method to restore eating from UserDefaults in FastWatch Watch App/Managers/FastingManager.swift
- [x] T016 [US2] Update init() to call restoreEatingState() after restoreActiveFast() in FastWatch Watch App/Managers/FastingManager.swift
- [x] T017 [US2] Clear eating state when startFast() is called in FastWatch Watch App/Managers/FastingManager.swift
- [x] T018 [US2] Clear eating state when eating window expires naturally in updateState() in FastWatch Watch App/Managers/FastingManager.swift

**Checkpoint**: Eating state persists across app lifecycle

---

## Phase 5: User Story 3 - Notification Cleanup on Restore (Priority: P3)

**Goal**: When app restores state, ensure notifications match current state

**Independent Test**: Schedule fasting notifications, kill app mid-fast, relaunch, verify only appropriate notifications remain

### Implementation for User Story 3

- [x] T019 [US3] Add cancelFastingNotifications() that removes fasting-category notifications only in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T020 [US3] Add cancelEatingNotifications() that removes eating-category notifications only in FastWatch Watch App/Managers/NotificationManager.swift
- [x] T021 [US3] Update restoreEatingState() to cancel any leftover fasting notifications in FastWatch Watch App/Managers/FastingManager.swift
- [x] T022 [US3] Update restoreActiveFast() to cancel any leftover eating notifications in FastWatch Watch App/Managers/FastingManager.swift
- [x] T023 [US3] Add notification re-scheduling for restored fasting state (for remaining milestones) in FastWatch Watch App/Managers/FastingManager.swift
- [x] T024 [US3] Add notification re-scheduling for restored eating state (for eating window reminder) in FastWatch Watch App/Managers/FastingManager.swift

**Checkpoint**: App restore properly syncs notification state

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [x] T025 Update WidgetCenter.shared.reloadAllTimelines() calls to match new state persistence in FastWatch Watch App/Managers/FastingManager.swift
- [ ] T026 Run quickstart.md test scenarios to validate full flow
- [ ] T027 Test edge cases: app killed during state transition, rapid start/stop cycles

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2
- **User Story 2 (Phase 4)**: Depends on Phase 2, independent of US1
- **User Story 3 (Phase 5)**: Depends on Phase 2, Phase 3, and Phase 4
- **Polish (Phase 6)**: Depends on all user stories

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - Core notification fix
- **User Story 2 (P2)**: Can start after Foundational - Can run parallel to US1
- **User Story 3 (P3)**: Requires US1 + US2 - Ties both fixes together

### Parallel Opportunities

```bash
# After Phase 2 completes, run US1 and US2 in parallel:
# Agent 1: T005-T010 (Notification Timing)
# Agent 2: T011-T018 (State Persistence)

# Then US3 sequentially after both complete
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Notification Timing Fix)
4. **VALIDATE**: Fasting notifications should no longer fire during eating state
5. Deploy if immediate fix needed

### Full Fix (Recommended)

1. Complete Setup + Foundational
2. US1 + US2 in parallel (fixes timing AND persistence)
3. US3 ties them together (cleanup on restore)
4. Polish phase validates end-to-end

---

## Notes

- All notification identifier changes should use consistent prefix: `fasting-` and `eating-`
- UserDefaults key for eating state: `eatingSession` (parallel to `activeFast`)
- Test on actual watchOS device - simulator doesn't reliably show notifications
- Commit after each phase for easy rollback if needed
