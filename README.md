# FastLight ⚡️

A dead-simple app that shows you at a glance whether you're in your fasting window. The widget turns **green** (you're fasting, good to go) or **red** (you're in your eating window, or your fast is broken). No logging, no tracking, no complexity — just a glanceable status on your home screen.

## Requirements

- iOS 17.0+
- Xcode 15.3+

## Project Structure

```
FastLight/              # Main app target (SwiftUI)
FastLightWidget/        # WidgetKit extension target
FastLightKit/           # Shared framework with business logic
```

## Targets

| Target | Bundle ID | Type |
|--------|-----------|------|
| FastLight | `com.fastlight.app` | iOS Application |
| FastLightWidget | `com.fastlight.app.widget` | Widget Extension |
| FastLightKit | `com.fastlight.kit` | Embedded Framework |

## Getting Started

1. Open `FastLight.xcodeproj` in Xcode
2. Select your development team for code signing
3. Build and run on your device or simulator

## Architecture

- **FastLightKit** contains the core business logic (`FastingState`, `FastingSchedule`)
- Both the app and widget import `FastLightKit` for shared state calculation
- The widget uses TimelineProvider to refresh every hour (when the fasting state may change)
