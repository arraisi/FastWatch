# Tasks: Rectangular Eating Widget

**Input**: Design documents from `/specs/003-rectangular-eating-widget/`
**Prerequisites**: plan.md, spec.md, quickstart.md

**Tests**: Not requested - no test tasks included.

**Organization**: US1 and US2 are combined since they're tightly coupled (eating data + eating visuals).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths included

## Path Conventions

- **Widget extension**: `FastWatchWidget/`

---

## Phase 1: Setup

**Purpose**: Copy required model to widget target

- [x] T001 Copy EatingSession model to `FastWatchWidget/Models/EatingSession.swift`

**Checkpoint**: EatingSession available in widget target

---

## Phase 2: Foundational

**Purpose**: Extend entry model and timeline provider to support eating state

- [x] T002 Add eating state fields to FastWatchEntry in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T003 Add `loadEatingSession()` method to FastWatchTimelineProvider in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T004 Update `getTimeline()` to check eating session when no active fast in `FastWatchWidget/FastWatchTimelineProvider.swift`
- [x] T005 Update `currentEntry()` to handle eating state in `FastWatchWidget/FastWatchTimelineProvider.swift`

**Checkpoint**: Timeline provider can load and expose eating session data

---

## Phase 3: User Stories 1 & 2 - Eating Display + Visual Theme (Priority: P1)

**Goal**: Rectangular widget shows orange-themed eating countdown when in eating phase

**Independent Test**: Complete fast, verify widget shows orange eating UI with remaining time

### Implementation

- [x] T006 [US1] [US2] Add eating-specific rectangularView in `FastWatchWidget/FastWatchWidgetEntryView.swift`
- [x] T007 [US1] [US2] Update rectangularView to switch between fasting/eating display in `FastWatchWidget/FastWatchWidgetEntryView.swift`
- [x] T008 [US2] Add eating preview entries in `FastWatchWidget/FastWatchWidgetEntryView.swift`

**Checkpoint**: Eating widget fully functional and visually distinct

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Validation and edge cases

- [x] T009 Run quickstart.md validation scenarios manually
- [x] T010 Verify expired eating session handling (should show idle)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on T001 (EatingSession model)
- **User Stories (Phase 3)**: Depends on Phase 2 completion
- **Polish (Phase 4)**: Depends on Phase 3 completion

### Task Dependencies

```
T001 (copy model)
  ↓
T002 → T003 → T004 → T005 (sequential, same file)
  ↓
T006 → T007 → T008 (sequential, same file)
  ↓
T009, T010 (parallel validation)
```

### Parallel Opportunities

- T009 and T010 can run in parallel (manual validation)
- Phase 1 and Phase 2 are sequential (model dependency)

---

## Implementation Strategy

### MVP (All Tasks)

Small feature - complete all tasks:

1. T001: Copy EatingSession model
2. T002-T005: Update timeline provider
3. T006-T008: Add eating UI
4. T009-T010: Validate

### Estimated Scope

- **New file**: 1 (EatingSession.swift copy)
- **Modified files**: 2 (FastWatchTimelineProvider.swift, FastWatchWidgetEntryView.swift)
- **New code**: ~80 lines
- **Complexity**: Medium (timeline logic changes)

---

## Implementation Details

### T002: FastWatchEntry eating fields

```swift
// Add to FastWatchEntry struct:
let isEating: Bool
let eatingRemainingText: String
let eatingEndTime: Date?
```

### T003: loadEatingSession()

```swift
private func loadEatingSession() -> EatingSession? {
    guard let data = defaults.data(forKey: "eatingSession"),
          let session = try? JSONDecoder().decode(EatingSession.self, from: data),
          !session.isExpired
    else { return nil }
    return session
}
```

### T006: Eating rectangularView

```swift
// Orange theme with fork.knife icon
// Shows: "Eating" label, remaining time, progress gauge
// Color: .orange
```

---

## Notes

- EatingSession key in UserDefaults: "eatingSession"
- Orange color matches app's eating state
- fork.knife SF Symbol for eating icon
- 15-minute timeline refresh interval (same as fasting)
- Check isExpired before displaying eating state
