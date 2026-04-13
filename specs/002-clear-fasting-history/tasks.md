# Tasks: Clear Fasting History

**Input**: Design documents from `/specs/002-clear-fasting-history/`
**Prerequisites**: plan.md, spec.md, quickstart.md

**Tests**: Not requested - no test tasks included.

**Organization**: Tasks grouped by user story. US1 and US2 are combined since they're interdependent (clearing logic + UI entry point).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths included

## Path Conventions

- **watchOS app**: `FastWatch Watch App/`
- **Widget**: `FastWatchWidget/`

---

## Phase 1: Setup

**Purpose**: No setup needed - existing project with SwiftData already configured

*Skip - all infrastructure exists*

---

## Phase 2: Foundational

**Purpose**: Core clear method that UI depends on

- [x] T001 Add `clearHistory()` method to FastingManager in `FastWatch Watch App/Managers/FastingManager.swift`

**Implementation details for T001**:
```swift
func clearHistory() {
    guard let context = modelContext else { return }
    do {
        try context.delete(model: CompletedFast.self)
        WidgetCenter.shared.reloadAllTimelines()
    } catch {
        print("Failed to clear history: \(error)")
    }
}
```

**Checkpoint**: clearHistory() method ready for UI integration

---

## Phase 3: User Stories 1 & 2 - Clear All History + Entry Point (Priority: P1)

**Goal**: User can clear all fasting history via toolbar button with confirmation

**Independent Test**: Complete fasts → tap trash button → confirm → verify empty state

### Implementation

- [x] T002 [US1] [US2] Add `@State` property for showing confirmation alert in `FastWatch Watch App/Views/HistoryView.swift`
- [x] T003 [US1] [US2] Add toolbar button with trash icon in `FastWatch Watch App/Views/HistoryView.swift`
- [x] T004 [US1] [US2] Add confirmation alert with destructive action in `FastWatch Watch App/Views/HistoryView.swift`
- [x] T005 [US1] Disable clear button when `fasts.isEmpty` in `FastWatch Watch App/Views/HistoryView.swift`

**Checkpoint**: Clear history feature fully functional and testable

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Edge case handling and validation

- [x] T006 Run quickstart.md validation scenarios manually
- [x] T007 Verify widget updates after clearing history

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies - start immediately
- **User Stories (Phase 3)**: Depends on T001 completion
- **Polish (Phase 4)**: Depends on Phase 3 completion

### Task Dependencies

```
T001 (clearHistory method)
  ↓
T002 → T003 → T004 → T005 (sequential, same file)
  ↓
T006, T007 (parallel validation)
```

### Parallel Opportunities

- T006 and T007 can run in parallel (manual validation tasks)
- T002-T005 are sequential (same file, incremental changes)

---

## Implementation Strategy

### MVP (All Tasks)

This is a small feature - complete all tasks for full functionality:

1. T001: Add clearHistory() method
2. T002-T005: Add UI (confirmation dialog + button)
3. T006-T007: Validate

### Estimated Scope

- **New code**: ~25 lines
- **Files modified**: 2 (FastingManager.swift, HistoryView.swift)
- **Complexity**: Low

---

## Notes

- SwiftData `context.delete(model:)` deletes all instances atomically
- Confirmation alert uses `.destructive` role for red styling
- Widget refresh ensures complication updates if it shows history stats
- Button disabled state prevents clearing when already empty
