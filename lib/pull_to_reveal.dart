/// A Flutter package that enables WeChat-style hard pull-to-reveal interactions.
///
/// ## Usage
///
/// ```dart
/// PullToReveal(
///   threshold: 140,
///   resistanceFactor: 0.35,
///   revealMode: RevealMode.slide,
///   background: MyHiddenWidget(),
///   child: ListView(...),
/// )
/// ```
library pull_to_reveal;

export 'src/pull_to_reveal_widget.dart';
export 'src/controller.dart';
export 'src/reveal_state.dart';
