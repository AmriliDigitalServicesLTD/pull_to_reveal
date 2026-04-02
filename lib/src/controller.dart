/// Controller for programmatic interaction with [PullToReveal].
library;

import 'package:flutter/foundation.dart';
import 'reveal_state.dart';

/// Controls a [PullToReveal] widget programmatically.
///
/// Attach a [PullToRevealController] to a [PullToReveal] widget via the
/// [PullToReveal.controller] parameter. The controller exposes methods to
/// open and close the reveal layer without requiring a gesture, and
/// broadcasts [RevealState] changes to registered listeners.
///
/// ## Lifecycle
///
/// Always call [dispose] when the controller is no longer needed — typically
/// in the [State.dispose] method of the widget that owns the controller.
///
/// ## Example
///
/// ```dart
/// final _controller = PullToRevealController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// // Trigger reveal from a button:
/// ElevatedButton(
///   onPressed: _controller.reveal,
///   child: const Text('Open'),
/// )
///
/// // Attach to the widget:
/// PullToReveal(
///   controller: _controller,
///   background: MyLayer(),
///   child: ListView(...),
/// )
/// ```
class PullToRevealController extends ChangeNotifier {
  RevealState _state = RevealState.idle;

  /// The current [RevealState] of the attached [PullToReveal] widget.
  ///
  /// Listeners are notified whenever this value changes.
  RevealState get state => _state;

  /// Whether the background layer is currently fully revealed.
  bool get isRevealed => _state == RevealState.revealed;

  /// Whether a pull gesture is currently in progress.
  bool get isPulling => _state.isActive;

  // ── Internal API (called by the widget, not by users) ─────────────────────

  /// Updates the internal state and notifies listeners.
  ///
  /// This method is called exclusively by the [PullToReveal] widget.
  /// External callers should use [reveal] or [dismiss] instead.
  // ignore: use_setters_to_change_properties — notifyListeners side-effect required
  void updateState(RevealState newState) {
    if (_state == newState) return; // no-op on identical state
    _state = newState;
    notifyListeners();
  }

  // ── Public commands ────────────────────────────────────────────────────────

  /// Programmatically triggers the reveal animation.
  ///
  /// Has no effect if the widget is already in [RevealState.revealed].
  /// The attached [PullToReveal] widget listens to this and drives
  /// the animation accordingly.
  ///
  /// This does NOT directly mutate state — it signals intent.
  /// The widget transitions state when the animation completes.
  void reveal() {
    if (_state == RevealState.revealed) return;
    _revealRequested = true;
    notifyListeners();
  }

  /// Programmatically dismisses the reveal layer.
  ///
  /// Has no effect if the widget is already in [RevealState.idle].
  void dismiss() {
    if (_state == RevealState.idle) return;
    _dismissRequested = true;
    notifyListeners();
  }

  // ── Intent flags (consumed by the widget per frame) ───────────────────────

  /// True if [reveal] was called and the widget has not yet consumed
  /// the intent. The widget resets this after processing.
  bool _revealRequested = false;

  /// True if [dismiss] was called and the widget has not yet consumed
  /// the intent. The widget resets this after processing.
  bool _dismissRequested = false;

  /// Consumes and returns a pending reveal request.
  ///
  /// Called by the widget on each build cycle. Returns `true` once,
  /// then resets to `false` until [reveal] is called again.
  bool consumeRevealRequest() {
    if (_revealRequested) {
      _revealRequested = false;
      return true;
    }
    return false;
  }

  /// Consumes and returns a pending dismiss request.
  ///
  /// Called by the widget on each build cycle. Returns `true` once,
  /// then resets to `false` until [dismiss] is called again.
  bool consumeDismissRequest() {
    if (_dismissRequested) {
      _dismissRequested = false;
      return true;
    }
    return false;
  }

  @override
  String toString() =>
      'PullToRevealController(state: $_state)';
}