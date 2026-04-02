# pull_to_reveal

[![pub.dev](https://img.shields.io/pub/v/pull_to_reveal.svg)](https://pub.dev/packages/pull_to_reveal)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.3.0-blue.svg)](https://dart.dev)

**WeChat-style hard pull-to-reveal for Flutter.**

Reveal a hidden background layer — marketplace, control panel, quick actions, or any widget — when the user performs a deliberate hard pull-down gesture. Comes with rubber-band resistance physics, three animation modes, programmatic control, and full support for any child widget type.

---

## Why this package?

Flutter's built-in `RefreshIndicator` triggers on any overscroll and always calls a data-refresh callback. It was never designed to reveal a persistent hidden layer of UI behind the foreground content.

WeChat's signature interaction — a hard pull that peels back the chat list to expose a marketplace — requires:

- **Progressive resistance physics** that distinguish a soft accidental drag from a deliberate hard pull
- **A layered UI** where a full background widget lives behind the scrollable foreground
- **Threshold-based arming** so the reveal only fires when the user means it
- **Snap animations** that feel native, not scripted

None of Flutter's built-in widgets provide this. `pull_to_reveal` does.

---

## Demo

> 📹 ![Watch the demo](https://raw.githubusercontent.com/AmriliDigitalServicesLTD/pull_to_reveal/main/example/demo.gif)

The demo show:
- Scrollable child (ListView) with slide mode — pull from top to reveal
- Non-scrollable child (Column) — drag anywhere to reveal
- All three reveal modes: slide, fade, scale
- Programmatic reveal and dismiss via buttons
- The default built-in indicator vs a custom background widget

---

## Features

- ✅ **Universal child support** — works with `ListView`, `GridView`, `CustomScrollView`, `Column`, `Container`, `Scaffold`, `Consumer`, `ValueListenableBuilder`, and any other widget
- ✅ **Three reveal modes** — `slide` (WeChat-style), `fade`, and `scale`
- ✅ **Rubber-band resistance physics** — logarithmic curve that makes hard pulls feel deliberate and soft pulls feel safe
- ✅ **Programmatic control** — `PullToRevealController` for open/close from any code path
- ✅ **State callbacks** — `onReveal`, `onCancel`, `onPull(progress 0.0→1.0)`
- ✅ **State machine** — clean `idle → pulling → armed → revealed` transitions
- ✅ **Haptic feedback** — medium impact pulse when the threshold is crossed
- ✅ **60fps performance** — `RepaintBoundary` isolation, `AnimatedBuilder` scoped rebuilds, minimal `setState`
- ✅ **Gesture-safe** — uses `Listener` (below the gesture arena) so child scroll behaviour is never broken
- ✅ **Optional background** — provide your own widget or let the built-in pull indicator handle it
- ✅ **Navigation-friendly** — use `onReveal` to `Navigator.push` instead of revealing a background widget

---

## Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  pull_to_reveal_flutter: ^0.1.2
```

Then run:
```bash
flutter pub get
```

Import in your Dart file:
```dart
import 'package:pull_to_reveal/pull_to_reveal_flutter.dart';
```

---

## Quick start
```dart
import 'package:flutter/material.dart';
import 'package:pull_to_reveal/pull_to_reveal_flutter.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PullToReveal(
        threshold: 140,
        resistanceFactor: 0.35,
        revealMode: RevealMode.slide,
        background: const MarketplaceWidget(),
        onReveal: () {
          // Called when reveal animation completes.
          // Navigate, load data, or do nothing — the background is visible.
        },
        onCancel: () {
          // Called when the pull was abandoned before threshold.
        },
        child: ListView.builder(
          itemCount: 50,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      ),
    );
  }
}
```

> 💡 **Run the full demo:** `cd example && flutter run`
>
> The example app demonstrates all three reveal modes, both scrollable and
> non-scrollable children, custom vs default backgrounds, and programmatic
> reveal/dismiss via controller buttons.

---

## API Reference

### `PullToReveal`
```dart
PullToReveal(
  child: myWidget,               // required
  background: myBackgroundWidget, // optional
  threshold: 140.0,
  resistanceFactor: 0.35,
  revealMode: RevealMode.slide,
  onReveal: () {},
  onCancel: () {},
  onPull: (progress) {},
  controller: myController,
  enableHapticFeedback: true,
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | Any widget — scrollable or non-scrollable. When the child contains a scrollable, pull is gated behind `offset <= 0`. |
| `background` | `Widget?` | `null` | The widget revealed behind the foreground. When `null`, a built-in pull indicator is shown. |
| `threshold` | `double` | `140.0` | Resistance-adjusted pull distance in logical pixels required to arm the reveal. |
| `resistanceFactor` | `double` | `0.35` | Rubber-band damping factor in `(0.0, 1.0]`. Lower = more resistance, harder to trigger. |
| `revealMode` | `RevealMode` | `slide` | Animation style: `slide`, `fade`, or `scale`. |
| `onReveal` | `VoidCallback?` | `null` | Called when the reveal animation completes. Use for navigation or data loading. |
| `onCancel` | `VoidCallback?` | `null` | Called when the pull is abandoned before threshold, or after `controller.dismiss()` completes. |
| `onPull` | `ValueChanged<double>?` | `null` | Called continuously during pull with normalised progress `0.0→1.0`. |
| `controller` | `PullToRevealController?` | `null` | Attach a controller for programmatic reveal and dismiss. |
| `enableHapticFeedback` | `bool` | `true` | Fires a medium haptic impact when the pull crosses the threshold into `armed` state. |

---

### `RevealMode`

Controls the visual animation applied to the foreground when it is revealed.
```dart
enum RevealMode {
  /// Foreground slides downward to expose the background.
  /// This is the default WeChat-style behaviour.
  slide,

  /// Foreground fades out to expose the background.
  fade,

  /// Foreground scales down to expose the background.
  scale,
}
```

---

### `PullToRevealController`

Attach a controller to drive the widget programmatically and listen to state changes.
```dart
final _controller = PullToRevealController();

// Always dispose with your State:
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// Trigger reveal from a button:
ElevatedButton(
  onPressed: _controller.reveal,
  child: const Text('Open'),
);

// Dismiss the reveal layer:
ElevatedButton(
  onPressed: _controller.dismiss,
  child: const Text('Close'),
);

// Read current state:
print(_controller.state);      // RevealState.idle / pulling / armed / revealed
print(_controller.isRevealed); // bool
print(_controller.isPulling);  // bool

// Listen to state changes:
_controller.addListener(() {
  print(_controller.state);
});

// Attach to widget:
PullToReveal(
  controller: _controller,
  background: const MyBackground(),
  child: const MyScrollable(),
)
```

---

### `RevealState`

The four discrete states of the pull interaction state machine.
```dart
enum RevealState {
  /// At rest. No gesture in progress.
  idle,

  /// User is pulling down, below the reveal threshold.
  pulling,

  /// Pull distance has exceeded the threshold.
  /// Releasing now will trigger the reveal animation.
  armed,

  /// The background layer is fully revealed.
  revealed,
}
```

Convenience extension:
```dart
state.isActive // true when pulling or armed
state.isOpen   // true when revealed
state.isIdle   // true when idle
```

---

## Customisation

### Adjust physics feel
```dart
// Responsive — reveals quickly with a light pull
PullToReveal(
  resistanceFactor: 0.7,
  threshold: 100,
  child: myChild,
  background: myBackground,
)

// Firm — requires a deliberate hard pull (WeChat-like)
PullToReveal(
  resistanceFactor: 0.25,
  threshold: 160,
  child: myChild,
  background: myBackground,
)
```

### Track pull progress in real time
```dart
PullToReveal(
  onPull: (double progress) {
    // progress: 0.0 (no pull) → 1.0 (threshold reached)
    // Drive your own UI — e.g. a custom indicator or parallax effect
    myIndicatorController.value = progress;
  },
  child: myChild,
  background: myBackground,
)
```

### Navigate on reveal instead of showing a background widget
```dart
PullToReveal(
  // background is null — built-in indicator is shown during pull
  onReveal: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplacePage()),
    ).then((_) => _controller.dismiss());
  },
  controller: _controller,
  child: myScrollable,
)
```

### Programmatic reveal from anywhere
```dart
final _controller = PullToRevealController();

// Anywhere in your widget tree:
FloatingActionButton(
  onPressed: _controller.reveal,
  child: const Icon(Icons.arrow_downward),
),

PullToReveal(
  controller: _controller,
  background: const QuickActionsPanel(),
  child: myContent,
)
```

### Non-scrollable child
```dart
// No ListView required — pull gesture is always active on non-scrollables
PullToReveal(
  background: const SettingsPanel(),
  child: const Column(
    children: [
      MyHeader(),
      MyDashboard(),
      MyFooter(),
    ],
  ),
)
```

### Custom background widget
```dart
PullToReveal(
  background: Container(
    color: Colors.deepPurple,
    child: const Center(
      child: Text(
        'Marketplace',
        style: TextStyle(color: Colors.white, fontSize: 32),
      ),
    ),
  ),
  child: myScrollable,
)
```

---

## Use cases

| Use case | Description |
|---|---|
| **Marketplace / mini-program launcher** | Reveal a grid of app shortcuts or a shop behind a chat list — exactly WeChat's pattern |
| **Hidden control panel** | Pull down on a media player or dashboard to reveal playback settings |
| **Quick actions drawer** | Expose shortcuts (compose, search, scan) with a deliberate downward gesture |
| **Contextual content reveal** | Show recommendations, trending items, or personalised content on hard pull |
| **Onboarding overlay** | Introduce a hidden feature layer to new users via a guided pull gesture |
| **Settings panel** | Tuck settings behind a non-scrollable home screen, revealed on demand |

---

## Comparison with `RefreshIndicator`

| Feature | `RefreshIndicator` | `pull_to_reveal` |
|---|---|---|
| Reveals hidden UI layer | ❌ | ✅ |
| Rubber-band resistance physics | ❌ | ✅ |
| Hard pull threshold detection | ❌ | ✅ |
| Distinct armed / pulling states | ❌ | ✅ |
| Custom animation modes | ❌ | ✅ slide, fade, scale |
| Non-scrollable child support | ❌ | ✅ |
| Programmatic open / close | ❌ | ✅ |
| Pull progress callback | ❌ | ✅ |
| Haptic feedback on threshold | ❌ | ✅ |
| Data refresh (`Future` callback) | ✅ | ❌ (not its purpose) |

---

## How it works
```
1. Normal scroll
   └── NotificationListener tracks scroll offset
       └── Pull gesture is blocked while offset > 0

2. Soft pull (user drags lightly from the top)
   └── Listener captures raw pointer delta
       └── Rubber-band physics dampen movement
           └── Foreground follows finger with resistance
               └── State: idle → pulling

3. Hard pull (adjusted distance crosses threshold)
   └── State: pulling → armed
       └── Haptic feedback fires
           └── Visual indicator changes (default background shows arrow flip)

4. Release while armed
   └── AnimationController.animateTo(1.0)
       └── Foreground snaps fully open (slide / fade / scale)
           └── onReveal() callback fires
               └── State: revealed

5. Release before threshold (early release)
   └── AnimationController.animateTo(0.0)
       └── Foreground snaps back to rest position
           └── onCancel() callback fires
               └── State: idle
```

**Input architecture — why there is no gesture conflict:**

`Listener` operates below Flutter's gesture arena. It always fires regardless of what the child's scroll recogniser does. This means scrolling in a `ListView` and pull detection are fully independent — they never compete for the same gesture. The only coordination is the `_isAtTop` gate: pull accumulation is blocked while the scroll offset is above zero.

---

## Performance

- **`RepaintBoundary`** wraps both the background and foreground layers independently. The background never repaints during a pull gesture. The foreground repaint is scoped to the transform layer only.
- **`AnimatedBuilder`** limits rebuilds to the transform subtree. The rest of the widget tree is never rebuilt during animation frames.
- **`setState`** is only called on state machine transitions — four possible states, not on every animation frame.
- **`LayoutBuilder`** height is cached after the first measurement. Subsequent frames use the cached value with no recalculation.
- All physics calculations (`PullPhysics`) are pure Dart math — no Flutter framework calls, no layout, no painting.

---

## Contributing

Contributions, bug reports, and feature requests are welcome.

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit your changes with a clear message
4. Push and open a pull request

Please run `dart analyze` and `flutter test` before submitting.

---

## Support

If you find this package useful, you can support me:

- 💳 [Flutterwave (cards, bank, USSD)](https://flutterwave.com/donate/rboe3lpx5do8)

Your support helps me maintain and improve this package ❤️

---

---

## License

MIT — see [LICENSE](LICENSE) for details.
```
MIT License
Copyright (c) 2026 Amrili Digital Services Limited
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---