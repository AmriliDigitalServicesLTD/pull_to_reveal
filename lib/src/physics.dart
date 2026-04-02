/// Resistance physics for [PullToReveal] gestures.
///
/// This library is intentionally free of Flutter dependencies —
/// it operates purely on [double] values so it can be unit-tested
/// without a widget tree.
library;

import 'dart:math' as math;

/// Calculates resistance-adjusted pull distances for [PullToReveal].
///
/// The physics model applies a non-linear curve so that pulling feels
/// progressively harder the further the user drags — mimicking the
/// elasticity of a rubber band.
abstract final class PullPhysics {
  /// Applies a **linear** resistance factor to a raw overscroll distance.
  ///
  /// This is the simplest model: every pixel of overscroll is dampened
  /// by [resistanceFactor].
  ///
  /// ```
  /// adjusted = rawDistance * resistanceFactor
  /// ```
  ///
  /// - [rawDistance] must be ≥ 0.
  /// - [resistanceFactor] is clamped to the range `(0.0, 1.0]`.
  ///   A value of `1.0` means no resistance; `0.1` means heavy resistance.
  static double linear({
    required double rawDistance,
    required double resistanceFactor,
  }) {
    assert(rawDistance >= 0, 'rawDistance must be non-negative');
    final factor = resistanceFactor.clamp(0.01, 1.0);
    return rawDistance * factor;
  }

  /// Applies a **rubber-band** (logarithmic) resistance curve.
  ///
  /// Early pulls feel responsive; resistance increases non-linearly
  /// as [rawDistance] grows. This matches the WeChat-style feel.
  ///
  /// Formula:
  /// ```
  /// adjusted = factor * maxDistance * ln(1 + rawDistance / maxDistance)
  /// ```
  ///
  /// - [rawDistance] must be ≥ 0.
  /// - [maxDistance] is the visual cap — the maximum pixels the foreground
  ///   will ever travel regardless of how far the user pulls.
  /// - [resistanceFactor] controls overall sensitivity, clamped to `(0.0, 1.0]`.
  static double rubberBand({
    required double rawDistance,
    required double resistanceFactor,
    double maxDistance = 300.0,
  }) {
    assert(rawDistance >= 0, 'rawDistance must be non-negative');
    assert(maxDistance > 0, 'maxDistance must be positive');
    final factor = resistanceFactor.clamp(0.01, 1.0);
    return factor * maxDistance * math.log(1.0 + rawDistance / maxDistance);
  }

  /// Calculates normalised pull progress in the range `[0.0, 1.0]`.
  ///
  /// Returns `1.0` once [adjustedDistance] meets or exceeds [threshold].
  /// This value drives animation controllers and [onPull] callbacks.
  ///
  /// - [adjustedDistance] is the output of [linear] or [rubberBand].
  /// - [threshold] must be > 0.
  static double progress({
    required double adjustedDistance,
    required double threshold,
  }) {
    assert(threshold > 0, 'threshold must be positive');
    return (adjustedDistance / threshold).clamp(0.0, 1.0);
  }

  /// Returns `true` if [adjustedDistance] has met or exceeded [threshold].
  static bool isArmed({
    required double adjustedDistance,
    required double threshold,
  }) {
    return adjustedDistance >= threshold;
  }

  /// Reduces [currentDistance] by [delta], clamped to zero.
  ///
  /// Used when the user moves their finger back up during a pull gesture,
  /// reducing the accumulated pull distance.
  static double reducePull({
    required double currentDistance,
    required double delta,
  }) {
    return (currentDistance - delta.abs()).clamp(0.0, double.infinity);
  }
}