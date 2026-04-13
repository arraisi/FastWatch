# Implementation Plan: Rectangular Eating Widget

**Branch**: `003-rectangular-eating-widget` | **Date**: 2026-04-13 | **Spec**: `specs/003-rectangular-eating-widget/spec.md`
**Input**: Feature specification from `/specs/003-rectangular-eating-widget/spec.md`

## Summary

Enhance rectangular widget to display eating window countdown when user is in eating phase. Shows orange-themed UI with fork icon, remaining time, and progress bar. Loads eating session from App Group UserDefaults alongside fasting session.

## Technical Context

**Language/Version**: Swift 5.9+, SwiftUI
**Primary Dependencies**: WidgetKit, SwiftUI (existing)
**Storage**: UserDefaults App Group (eatingSession key - existing)
**Testing**: Xcode Previews
**Target Platform**: watchOS 10+ (standalone)
**Project Type**: mobile-app (watchOS widget extension)
**Performance Goals**: Widget updates within 15-minute intervals
**Constraints**: WidgetKit timeline refresh budget, small screen
**Scale/Scope**: 1 widget view modification, 2 model updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is an unfilled template - no project-specific gates defined. **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/003-rectangular-eating-widget/
├── plan.md              # This file
├── quickstart.md        # Phase 1 output
└── contracts/           # N/A (no external APIs)
```

### Source Code (changes)

```text
FastWatchWidget/
├── FastWatchTimelineProvider.swift    # Add loadEatingSession(), update timeline logic
├── FastWatchWidgetEntryView.swift     # Add eating-specific rectangularView variant
└── Models/
    └── EatingSession.swift            # Copy from main app (if not already present)
```

**Structure Decision**: Modify existing widget extension files. May need to copy EatingSession model to widget target.

## Implementation Steps

1. **Copy EatingSession model** - Ensure EatingSession.swift is in widget target (or copy it)
2. **Extend FastWatchEntry** - Add isEating, eatingRemainingText fields
3. **Update TimelineProvider** - Add loadEatingSession(), integrate into getTimeline()
4. **Eating rectangularView** - Add orange-themed eating state display
5. **Preview updates** - Add eating state previews

## Complexity Tracking

No violations. Minor extension of existing widget architecture.
