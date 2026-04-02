/// Defines the state machine for [PullToReveal] interactions.
library;

/// The four discrete states of a [PullToReveal] interaction.
///
/// Transitions follow a strict path:
/// ```
/// idle → pulling → armed → revealed → idle
///              ↓
///           idle (snap back on early release)
/// ```
enum RevealState {
  /// The widget is at rest. No pull gesture is in progress.
  idle,

  /// The user is actively pulling down, but has not yet
  /// exceeded the reveal threshold.
  pulling,

  /// The pull distance has exceeded the threshold.
  /// The widget is "armed" — releasing now will trigger reveal.
  armed,

  /// The background layer is fully revealed.
  /// The foreground has slid out of view.
  revealed,
}

/// The supported animation modes when the background layer is revealed.
enum RevealMode {
  /// The foreground slides downward to expose the background.
  /// This is the default WeChat-style behaviour.
  slide,

  /// The foreground fades out to expose the background.
  fade,

  /// The foreground scales down to expose the background.
  scale,
}

/// Extension on [RevealState] providing semantic helper properties.
extension RevealStateX on RevealState {
  /// Returns true if a pull gesture is actively in progress.
  bool get isActive => this == RevealState.pulling || this == RevealState.armed;

  /// Returns true if the background layer is currently visible.
  bool get isOpen => this == RevealState.revealed;

  /// Returns true if the widget is in a resting, non-interactive state.
  bool get isIdle => this == RevealState.idle;
}