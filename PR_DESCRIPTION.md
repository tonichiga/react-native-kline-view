# PR: Integrate trade markers, scroll toggle, and volume guard into library source

## Summary

This PR moves the previously external patch into the actual library source code.
The goal is to make behavior stable and reproducible without patching node_modules.

## Why we implemented these changes

- Remove dependency on postinstall/local patch workflows.
- Keep Android and iOS behavior aligned for the same input data.
- Add support for trade marker visualization directly in chart rendering.
- Add runtime control for chart scroll interaction via config.
- Prevent misleading volume header rendering when volume area is disabled.
- Relax CocoaPods dependency constraint for better compatibility in host apps.

## What changed

### 1) iOS dependency compatibility

- Updated lottie dependency range in [RNKLineView.podspec](RNKLineView.podspec).
- From: ~> 4.5.0
- To: >= 4.5.0 and < 5.0

Reason:

- Reduces pod resolution conflicts in apps that already use newer 4.x versions.

### 2) New config option: scrollEnabled

- Android config support added in [android/src/main/java/com/github/fujianlian/klinechart/HTKLineConfigManager.java](android/src/main/java/com/github/fujianlian/klinechart/HTKLineConfigManager.java).
- Android application in view container added in [android/src/main/java/com/github/fujianlian/klinechart/container/HTKLineContainerView.java](android/src/main/java/com/github/fujianlian/klinechart/container/HTKLineContainerView.java).
- iOS config support added in [ios/Classes/HTKLineConfigManager.swift](ios/Classes/HTKLineConfigManager.swift).
- iOS application in view added in [ios/Classes/HTKLineView.swift](ios/Classes/HTKLineView.swift).

Reason:

- Allows product-level control over user scroll interaction without custom forks.

### 3) Trade marker data model support

- Android trade fields added in [android/src/main/java/com/github/fujianlian/klinechart/KLineEntity.java](android/src/main/java/com/github/fujianlian/klinechart/KLineEntity.java):
  - openTradePrice
  - closeTradePrice
  - openTradeCount
  - closeTradeCount
- Android parsing from incoming data added in [android/src/main/java/com/github/fujianlian/klinechart/HTKLineConfigManager.java](android/src/main/java/com/github/fujianlian/klinechart/HTKLineConfigManager.java).
- iOS trade fields and parsing added in [ios/Classes/HTKLineModel.swift](ios/Classes/HTKLineModel.swift) with numeric coercion for counts.

Reason:

- Enables chart to consume and render trade event metadata from feed payloads.

### 4) Trade marker rendering on chart

- Android rendering added in [android/src/main/java/com/github/fujianlian/klinechart/draw/MainDraw.java].
- iOS rendering added in [ios/Classes/HTMainDraw.swift](ios/Classes/HTMainDraw.swift).

Behavior:

- Markers are drawn for open and close trades.
- Marker color uses increase/decrease palette to preserve existing visual semantics.
- Marker size scales by count with cap.
- Count label is shown for count > 1.
- Label displays 9+ for values above 9.
- Rendering is enabled for both minute and candle modes.
- Invalid prices (NaN/Infinity) are ignored safely.

Reason:

- Makes trade activity visible at exact price levels directly on the main chart.

### 5) Volume text guard when volume panel is disabled

- Android guard added in [android/src/main/java/com/github/fujianlian/klinechart/draw/VolumeDraw.java](android/src/main/java/com/github/fujianlian/klinechart/draw/VolumeDraw.java).
- iOS guard added in [ios/Classes/HTVolumeDraw.swift](ios/Classes/HTVolumeDraw.swift).

Behavior:

- Volume header text is not drawn when volumeFlex <= 0.

Reason:

- Prevents inconsistent UI where header text appears even when volume area is effectively disabled.

## Impact

- No breaking API removals.
- New optional input keys are backward compatible.
- Improves parity between Android and iOS behavior.
- Eliminates need for external patch application in consuming apps.

## Validation status

- Static diagnostics show no new issues in all modified files.
- Changes are integrated directly into source and match intended patch behavior.

## Suggested QA checklist

- Verify scrollEnabled true and false on Android and iOS.
- Verify trade markers in minute mode and candle mode.
- Verify marker colors and count labels, including 9+.
- Verify behavior with missing trade fields and NaN prices.
- Verify volume header hidden when volumeFlex <= 0.
- Build and run both example apps to confirm runtime parity.
