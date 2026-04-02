/// Animation configuration for [PullToReveal] reveal modes.
///
/// This library maps [RevealMode] values to concrete animation parameters —
/// offsets, opacities, and scale factors — that the widget applies each frame.
/// It has no state of its own; all methods are pure functions of their inputs.
library;

import 'package:flutter/animation.dart';
import 'reveal_state.dart';

/// Provides animation curves and value calculators for each [RevealMode].
///
/// All methods are static and stateless. The [PullToReveal] widget calls
/// these each frame to derive the visual properties of the foreground layer.
abstract final class RevealAnimations {
  /// The curve used when snapping open (threshold exceeded, finger released).
  ///
  /// [Curves.easeOutCubic] gives a fast initial movement that decelerates
  /// smoothly — natural for a "snap into place" feel.
  static const Curve snapOpenCurve = Curves.easeOutCubic;

  /// The curve used when snapping back (released before threshold).
  ///
  /// [Curves.easeInOutCubic] gives a symmetrical ease — natural for
  /// "returning to rest" motion.
  static const Curve snapBackCurve = Curves.easeInOutCubic;

  /// The curve used while the finger is actively pulling.
  ///
  /// [Curves.linear] here is intentional — the resistance physics in
  /// [PullPhysics] already shape the curve. Applying a second curve
  /// on top would make the gesture feel disconnected from the finger.
  static const Curve followFingerCurve = Curves.linear;

  /// Duration for the snap-open animation.
  static const Duration snapOpenDuration = Duration(milliseconds: 380);

  /// Duration for the snap-back animation.
  static const Duration snapBackDuration = Duration(milliseconds: 280);

  // ── Slide mode ─────────────────────────────────────────────────────────────

  /// Calculates the vertical offset for [RevealMode.slide].
  ///
  /// The foreground travels downward by [revealHeight] pixels at full reveal.
  ///
  /// - [progress] is clamped to `[0.0, 1.0]`.
  /// - [revealHeight] is the pixel height the foreground slides down.
  ///   Defaults to the threshold value used by the widget.
  static double slideOffset({
    required double progress,
    required double revealHeight,
  }) {
    return progress.clamp(0.0, 1.0) * revealHeight;
  }

  // ── Fade mode ──────────────────────────────────────────────────────────────

  /// Calculates the foreground opacity for [RevealMode.fade].
  ///
  /// At `progress = 0.0` the foreground is fully opaque.
  /// At `progress = 1.0` the foreground is fully transparent.
  static double fadeOpacity({required double progress}) {
    return (1.0 - progress.clamp(0.0, 1.0));
  }

  // ── Scale mode ─────────────────────────────────────────────────────────────

  /// Calculates the foreground scale for [RevealMode.scale].
  ///
  /// The foreground shrinks from `1.0` down to [minScale] as progress
  /// increases. A [minScale] of `0.85` gives a natural "zoom out" feel.
  static double scaleValue({
    required double progress,
    double minScale = 0.85,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    return 1.0 - (1.0 - minScale) * clamped;
  }

  // ── Unified resolver ───────────────────────────────────────────────────────

  /// Returns the resolved [AnimationValues] for the given [mode] and [progress].
  ///
  /// The widget calls this once per animation frame instead of switching
  /// on [RevealMode] inline — keeping the widget code clean.
  ///
  /// [revealHeight] is only used by [RevealMode.slide].
  static AnimationValues resolve({
    required RevealMode mode,
    required double progress,
    required double revealHeight,
  }) {
    return switch (mode) {
      RevealMode.slide => AnimationValues(
        offset: slideOffset(progress: progress, revealHeight: revealHeight),
        opacity: 1.0,
        scale: 1.0,
      ),
      RevealMode.fade => AnimationValues(
        offset: 0.0,
        opacity: fadeOpacity(progress: progress),
        scale: 1.0,
      ),
      RevealMode.scale => AnimationValues(
        offset: 0.0,
        opacity: 1.0,
        scale: scaleValue(progress: progress),
      ),
    };
  }
}

/// A resolved set of visual properties for the foreground layer at a given
/// animation frame.
///
/// Produced by [RevealAnimations.resolve] and consumed by the widget's
/// build method.
final class AnimationValues {
  /// Creates an [AnimationValues] instance.
  const AnimationValues({
    required this.offset,
    required this.opacity,
    required this.scale,
  });

  /// Vertical pixel offset for [RevealMode.slide].
  /// Zero for other modes.
  final double offset;

  /// Opacity of the foreground layer.
  /// `1.0` means fully opaque; `0.0` means fully transparent.
  final double opacity;

  /// Scale factor of the foreground layer.
  /// `1.0` means no scaling.
  final double scale;

  @override
  String toString() =>
      'AnimationValues(offset: $offset, opacity: $opacity, scale: $scale)';
}