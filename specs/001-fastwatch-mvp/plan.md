# Implementation Plan: FastWatch MVP

**Branch**: `001-fastwatch-mvp` | **Date**: 2026-04-10 | **Spec**: `specs/001-fastwatch-mvp/spec.md`
**Input**: Feature specification (inline, to be saved as spec.md)

## Summary

Standalone watchOS 10+ SwiftUI fasting timer with animated progress ring, state machine (idle/fasting/goalReached/eating), UserDefaults persistence, local notifications with haptics, and WidgetKit circular complication. MVP: 16:8 protocol only.

## Technical Context

**Language/Version**: Swift 5.9+, SwiftUI
**Primary Dependencies**: SwiftUI, WidgetKit, UserNotifications (Apple frameworks only)
**Storage**: UserDefaults (active fast + preferences), SwiftData (history, Phase 2)
**Testing**: XCTest, Xcode Previews
**Target Platform**: watchOS 10+ (standalone, no iPhone companion)
**Project Type**: mobile-app (watchOS)
**Performance Goals**: 60fps ring animation, instant state transitions
**Constraints**: Offline-capable (all local), WidgetKit timeline refresh budget, small screen
**Scale/Scope**: Single-user, ~7 screens total (MVP: 2-3 screens)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is an unfilled template — no project-specific gates defined. **PASS**.

## Project Structure

### Documentation (this feature)

```text
specs/001-fastwatch-mvp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── contracts/           # N/A (no external APIs)
```

### Source Code (repository root)

```text
FastWatch/
├── FastWatchApp.swift
├── Models/
│   ├── FastingProtocol.swift
│   ├── FastSession.swift
│   └── UserPreferences.swift
├── Managers/
│   ├── FastingManager.swift
│   └── NotificationManager.swift
├── Views/
│   ├── HomeView.swift
│   ├── ProgressRingView.swift
│   ├── ProtocolPickerView.swift        (Phase 2)
│   ├── ActiveFastDetailView.swift
│   ├── HistoryView.swift               (Phase 2)
│   ├── FastDetailView.swift            (Phase 2)
│   └── SettingsView.swift              (Phase 2)
├── Extensions/
│   └── TimeInterval+Formatting.swift
└── Widgets/
    ├── FastWatchWidgetBundle.swift
    ├── FastWatchWidget.swift
    ├── FastWatchTimelineProvider.swift
    └── FastWatchWidgetEntryView.swift
```

**Structure Decision**: Flat watchOS app structure. Single app target + widget extension target. App Group for shared data.

## MVP Implementation Steps

1. **Data Models** — FastingProtocol enum, FastSession struct, UserPreferences, TimeInterval formatting
2. **FastingManager** — @Observable state machine with UserDefaults persistence + App Group sync
3. **NotificationManager** — Permission, schedule/cancel, haptics
4. **ProgressRingView** — Animated ring with color transitions and overtime pulse
5. **HomeView + App Entry** — Main screen with ring, timer, controls
6. **Widget** — Circular complication with timeline provider
7. **Integration** — Persistence across restarts, edge cases

## Complexity Tracking

No violations. Simple architecture with Apple-native frameworks only.
