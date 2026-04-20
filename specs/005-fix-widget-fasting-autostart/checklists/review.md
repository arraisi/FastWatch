# PR Review Checklist: Fix Widget Fasting Timer Autostart

**Purpose**: Validate requirements quality for PR review (Full Stack + All Edge Cases)
**Created**: 2026-04-17
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md)
**Depth**: Standard (Pre-Review)
**Focus**: Widget requirements + App-side background refresh + All edge cases

---

## Widget State Transition Requirements

- [ ] CHK001 - Is the eating→fasting transition trigger condition explicitly defined? [Completeness, Spec §FR-001]
- [ ] CHK002 - Are all three widget states (eating, fasting, idle) mutually exclusive in requirements? [Consistency, Spec §Key Entities]
- [ ] CHK003 - Is "within 1 minute" timing requirement testable with specific criteria? [Measurability, Spec §FR-003]
- [ ] CHK004 - Are requirements clear on whether transition uses refresh time or eating end time? [Clarity, Spec §FR-004]
- [ ] CHK005 - Is the widget state detection order (fast→eating→expired eating→idle) documented? [Completeness, Gap]
- [ ] CHK006 - Are requirements for `loadExpiredEatingSession()` threshold (24h) justified and documented? [Clarity, Plan §Research]

## "No FastTime" Display Requirements

- [ ] CHK007 - Are all valid conditions for showing "No FastTime" enumerated? [Completeness, Spec §FR-002]
- [ ] CHK008 - Is the distinction between "bug state" vs "legitimate idle" clearly defined? [Clarity, Spec §FR-002]
- [ ] CHK009 - Are requirements consistent between spec (FR-002) and clarification (missing/corrupted = idle)? [Consistency]
- [ ] CHK010 - Is "valid fasting session should be active" precisely defined with measurable conditions? [Measurability, Spec §FR-002]

## Timeline Generation Requirements

- [ ] CHK011 - Is the 15-minute interval requirement documented with rationale? [Completeness, Plan §buildEatingTimeline]
- [ ] CHK012 - Are requirements for mixed-state timelines (eating entries + fasting entries) specified? [Coverage, Gap]
- [ ] CHK013 - Is the timeline refresh policy requirement (`.after(date)`) explicitly stated? [Completeness, Gap]
- [ ] CHK014 - Are requirements clear on how many future entries to generate (120 minutes)? [Clarity, Gap]
- [ ] CHK015 - Is the fasting elapsed calculation formula documented (entryDate - eatingEndTime)? [Completeness, Plan §Data Model]

## App-Side Background Refresh Requirements

- [ ] CHK016 - Is the background refresh scheduling trigger point specified (when eating starts)? [Completeness, Spec §FR-007]
- [ ] CHK017 - Are requirements for `WKApplicationRefreshBackgroundTask` handling documented? [Coverage, Gap]
- [ ] CHK018 - Is the relationship between background refresh and widget reload specified? [Clarity, Gap]
- [ ] CHK019 - Are failure scenarios for background refresh documented (what if it doesn't fire)? [Coverage, Exception Flow]
- [ ] CHK020 - Is background refresh positioned as supplementary (not primary) mechanism? [Consistency, Plan §Research]

## Data Synchronization Requirements

- [ ] CHK021 - Are consistency requirements between widget and app quantified (5 seconds tolerance)? [Measurability, Spec §SC-003]
- [ ] CHK022 - Is the shared storage mechanism (App Group UserDefaults) explicitly required? [Completeness, Assumptions]
- [ ] CHK023 - Are requirements for fasting start time persistence documented? [Completeness, Spec §FR-006]
- [ ] CHK024 - Is the data format for eating session storage specified (JSON, fields)? [Clarity, Gap]

## Edge Case: Low-Power Mode (GATING)

- [ ] CHK025 - Are low-power mode behavior requirements explicitly documented? [Completeness, Spec §Edge Cases]
- [ ] CHK026 - Is "force update via background refresh" measurable and testable? [Measurability, Clarifications]
- [ ] CHK027 - Are degradation expectations in low-power mode defined? [Coverage, Gap]
- [ ] CHK028 - Is the fallback behavior if background refresh fails in low-power mode specified? [Exception Flow, Gap]

## Edge Case: Timezone Change (GATING)

- [ ] CHK029 - Is the UTC timestamp requirement explicitly stated in functional requirements? [Completeness, Spec §FR-008]
- [ ] CHK030 - Are requirements clear that "timezone changes don't affect duration calculations"? [Clarity, Clarifications]
- [ ] CHK031 - Is the scope limited to duration calculations (not display formatting)? [Clarity, Gap]
- [ ] CHK032 - Are test scenarios for timezone change during eating window defined? [Coverage, Spec §Edge Cases]

## Edge Case: Delayed Widget Refresh (GATING)

- [ ] CHK033 - Is the delayed refresh scenario addressed in requirements? [Completeness, Spec §Edge Cases]
- [ ] CHK034 - Is FR-004 (calculate from eating end time, not refresh time) sufficient to handle this? [Consistency]
- [ ] CHK035 - Are requirements clear on maximum acceptable delay before showing stale data? [Measurability, Gap]

## Edge Case: Corrupted/Missing Data (GATING)

- [ ] CHK036 - Is "show No FastTime as legitimate idle" clearly specified? [Completeness, Clarifications]
- [ ] CHK037 - Are detection criteria for corrupted data defined? [Clarity, Gap]
- [ ] CHK038 - Is the 24-hour threshold for "too old" data documented in requirements? [Completeness, Plan §Data Model]
- [ ] CHK039 - Are requirements for handling JSON decode failures specified? [Coverage, Exception Flow]

## Success Criteria Validation

- [ ] CHK040 - Is SC-001 (100% success rate) realistic given WidgetKit limitations? [Measurability, Spec §SC-001]
- [ ] CHK041 - Is SC-002 (never see No FastTime when fasting should be active) testable? [Measurability, Spec §SC-002]
- [ ] CHK042 - Is SC-004 (24+ hours without app) aligned with 24-hour expiry threshold? [Consistency, Spec §SC-004]
- [ ] CHK043 - Are success criteria independent of implementation details? [Clarity]

## Assumptions Validation

- [ ] CHK044 - Is the assumption "WidgetKit refresh intervals are system-controlled" validated? [Assumption, Spec §Assumptions]
- [ ] CHK045 - Is the assumption "App Group UserDefaults functioning correctly" testable? [Assumption]
- [ ] CHK046 - Are dependencies on system behavior (WidgetKit, WatchKit) documented as risks? [Coverage, Gap]

---

## Summary

| Category | Items | Gating |
|----------|-------|--------|
| Widget State Transition | CHK001-CHK006 | No |
| No FastTime Display | CHK007-CHK010 | No |
| Timeline Generation | CHK011-CHK015 | No |
| Background Refresh | CHK016-CHK020 | No |
| Data Synchronization | CHK021-CHK024 | No |
| Low-Power Mode | CHK025-CHK028 | **Yes** |
| Timezone Change | CHK029-CHK032 | **Yes** |
| Delayed Refresh | CHK033-CHK035 | **Yes** |
| Corrupted Data | CHK036-CHK039 | **Yes** |
| Success Criteria | CHK040-CHK043 | No |
| Assumptions | CHK044-CHK046 | No |

**Total Items**: 46
**Gating Items**: 15 (CHK025-CHK039)
