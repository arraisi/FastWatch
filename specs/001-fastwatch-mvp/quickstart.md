# Quickstart: FastWatch MVP

## Setup

1. Open Xcode, create new watchOS App project named "FastWatch"
2. Set deployment target: watchOS 10.0
3. Add Widget Extension target named "FastWatchWidget"
4. Enable App Group capability on both targets: `group.com.fastwatch.shared`

## Build & Run

```bash
# Build for watchOS Simulator
xcodebuild -scheme FastWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# Or open in Xcode
open FastWatch.xcodeproj
```

## Project Structure

```
FastWatch/           # Main app target
FastWatchWidget/     # Widget extension target
```

## Key Files (MVP)

| File | Purpose |
|------|---------|
| `FastWatchApp.swift` | Entry point, injects FastingManager |
| `FastingManager.swift` | State machine, persistence |
| `NotificationManager.swift` | Local notifications + haptics |
| `HomeView.swift` | Main screen with ring |
| `ProgressRingView.swift` | Animated progress ring |
| `FastWatchTimelineProvider.swift` | Widget timeline |

## Testing

1. **Xcode Previews**: Each view has preview providers with mock data
2. **Simulator**: Run on Apple Watch simulator, test full flow
3. **Key scenarios**:
   - Start fast -> watch ring fill -> goal reached notification
   - Kill app mid-fast -> relaunch -> fast resumes
   - Add complication to watch face -> verify updates
