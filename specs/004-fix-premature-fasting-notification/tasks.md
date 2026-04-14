# Tasks: Fix Premature Fasting Notification

**Input**: Design documents from `/specs/004-fix-premature-fasting-notification/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Type**: Bug Fix (no user stories - single fix scope)
**Tests**: Not requested - manual testing only

## Format: `[ID] [P?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions

- watchOS app: `FastWatch Watch App/`
- Widget: `FastWatchWidget/`

---

## Phase 1: Setup

**Purpose**: No setup needed - modifying existing files only

✅ Skip - existing project structure

---

## Phase 2: Bug Fix Implementation

**Purpose**: Fix the premature notification bug

### Core Fixes

- [x] T001 [P] Add guard clause for past dates in `FastWatch Watch App/Managers/NotificationManager.swift:scheduleGoalNotification()`
- [x] T002 [P] Add minimum duration validation (1 hour) in `FastWatch Watch App/Managers/FastingManager.swift:startFast()`

### Implementation Details

**T001 - NotificationManager fix**:
```swift
// Replace lines 32-35:
let interval = date.timeIntervalSinceNow
guard interval > 0 else { return }

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: interval,
    repeats: false
)
```

**T002 - FastingManager validation**:
```swift
// Add after line 59 (after duration calculation):
guard duration >= 3600 else { return } // Minimum 1 hour
```

**Checkpoint**: Both fixes complete - notification scheduling now safe

---

## Phase 3: Verification

**Purpose**: Manual testing to verify fixes

- [ ] T003 Verify custom fast with 0 hours does not start
- [ ] T004 Verify 16:8 fast schedules notification correctly
- [ ] T005 Verify app restore before goal time has no spurious notification
- [ ] T006 Verify app restore after goal time has no duplicate notification

**Checkpoint**: All acceptance criteria verified

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: Skipped (existing project)
- **Phase 2**: No dependencies - start immediately
- **Phase 3**: Depends on Phase 2 completion

### Within Phase 2

- T001 and T002 are independent (different files) - can run in parallel
- Both marked [P]

### Parallel Opportunities

```bash
# Launch both fixes in parallel:
Task: "T001 - Add guard clause in NotificationManager.swift"
Task: "T002 - Add duration validation in FastingManager.swift"
```

---

## Implementation Strategy

### Single-Pass Fix

1. Complete T001 and T002 (can be parallel)
2. Build and run on watchOS simulator
3. Execute T003-T006 verification steps
4. Commit and create PR

### Verification Checklist (from quickstart.md)

```bash
# In debugger, verify pending notifications:
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print(requests.map { ($0.identifier, $0.trigger) })
}
```

---

## Notes

- Both T001 and T002 touch different files - safe to parallelize
- No model changes - pure logic fix
- Backward compatible - existing fasts unaffected
- Commit after both fixes complete
