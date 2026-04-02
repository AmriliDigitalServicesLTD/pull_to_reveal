/// The core [PullToReveal] widget and its associated state.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animations.dart';
import 'controller.dart';
import 'physics.dart';
import 'reveal_state.dart';

/// A widget that reveals a hidden background layer when the user performs
/// a hard pull-down gesture — similar to WeChat's marketplace reveal.
///
/// ## Universal child support
///
/// [PullToReveal] works with **any** child widget type:
/// - Scrollable widgets ([ListView], [CustomScrollView], [GridView]) —
///   pull is only triggered when the scroll position is at the top.
/// - Non-scrollable widgets ([Column], [Container], [Scaffold]) —
///   pull gesture is always active.
/// - State-managed widgets ([Consumer], [ValueListenableBuilder]) —
///   child rebuilds do not interrupt gesture state.
///
/// ## Input architecture
///
/// Two input sources operate simultaneously without conflicting:
///
/// - A [Listener] captures raw pointer events **outside** the gesture
///   arena — it never competes with child scroll recognisers and always
///   fires regardless of what the child does with the gesture.
/// - A [NotificationListener] tracks scroll position via
///   [ScrollUpdateNotification] to gate the pull behind `offset <= 0`.
///
/// For scrollable children: downward pointer delta is accumulated only
/// when `_isAtTop == true`. This works cross-platform because at scroll
/// offset 0 the scroll view cannot scroll further down — the pointer
/// delta is therefore always available as pull distance.
///
/// For non-scrollable children: downward pointer delta is always
/// accumulated since there is no scroll position constraint.
///
/// ## Basic usage
///
/// ```dart
/// PullToReveal(
///   threshold: 140,
///   resistanceFactor: 0.35,
///   revealMode: RevealMode.slide,
///   onReveal: () => Navigator.push(context, ...),
///   child: ListView(...),
/// )
/// ```
class PullToReveal extends StatefulWidget {
  /// Creates a [PullToReveal] widget.
  ///
  /// [child] is required. [background] is optional — when omitted a
  /// built-in indicator is shown. Provide [onReveal] to navigate or
  /// perform an action when the layer is fully revealed.
  const PullToReveal({
    super.key,
    required this.child,
    this.background,
    this.threshold = 90,
    this.resistanceFactor = 0.35,
    this.revealMode = RevealMode.slide,
    this.onReveal,
    this.onCancel,
    this.onPull,
    this.controller,
    this.enableHapticFeedback = true,
  })  : assert(threshold > 0, 'threshold must be positive'),
        assert(
        resistanceFactor > 0 && resistanceFactor <= 1.0,
        'resistanceFactor must be in range (0.0, 1.0]',
        );

  /// The primary content widget.
  ///
  /// Can be any widget — scrollable or non-scrollable. When the child
  /// contains a scrollable, pull is only allowed from the top position.
  final Widget child;

  /// The widget revealed behind the foreground when the pull threshold
  /// is exceeded and the user releases.
  ///
  /// Optional. When `null`, a built-in default indicator is shown.
  /// Provide your own to display a marketplace, settings panel, or
  /// any other content. If you prefer to navigate on reveal, leave
  /// this `null` and use [onReveal] instead.
  final Widget? background;

  /// The resistance-adjusted pull distance in logical pixels required to
  /// arm and trigger a reveal on release.
  ///
  /// Defaults to `90.0`.
  final double threshold;

  /// Controls how aggressively the rubber-band physics dampens the raw
  /// pull delta. Lower values create more resistance.
  ///
  /// Must be in the range `(0.0, 1.0]`. Defaults to `0.35`.
  final double resistanceFactor;

  /// The animation style used when revealing the background layer.
  ///
  /// Defaults to [RevealMode.slide].
  final RevealMode revealMode;

  /// Called when the reveal animation completes successfully.
  ///
  /// Use this to navigate to another screen, load content, or take any
  /// action. The widget remains mounted unless navigation unmounts it.
  final VoidCallback? onReveal;

  /// Called when the pull is abandoned (released before threshold),
  /// or when [PullToRevealController.dismiss] is invoked.
  final VoidCallback? onCancel;

  /// Called continuously during the pull gesture with a normalised
  /// progress value in `[0.0, 1.0]`.
  ///
  /// `0.0` = no pull; `1.0` = threshold reached (armed).
  final ValueChanged<double>? onPull;

  /// Optional controller for programmatic reveal and dismiss.
  final PullToRevealController? controller;

  /// Whether to fire haptic feedback when the pull transitions to
  /// [RevealState.armed] (threshold first exceeded).
  ///
  /// Defaults to `true`.
  final bool enableHapticFeedback;

  @override
  State<PullToReveal> createState() => _PullToRevealState();
}

class _PullToRevealState extends State<PullToReveal>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────

  late AnimationController _animationController;

  // ── Gesture tracking ───────────────────────────────────────────────────────

  RevealState _revealState = RevealState.idle;
  double _rawPullDistance = 0.0;

  /// True once any [ScrollNotification] has been received, meaning the
  /// child tree contains at least one scrollable widget.

  /// Whether the detected scrollable is at its top boundary.
  ///
  /// Defaults to `true` so non-scrollable children (which never emit
  /// scroll notifications) always allow the pull gesture.
  bool _isAtTop = true;

  /// Measured height of this widget. Updated by [LayoutBuilder].
  double _widgetHeight = 300.0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: RevealAnimations.snapOpenDuration,
    );
    widget.controller?.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(PullToReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _animationController.dispose();
    super.dispose();
  }

  // ── Controller ─────────────────────────────────────────────────────────────

  void _onControllerUpdate() {
    final ctrl = widget.controller;
    if (ctrl == null) return;
    if (ctrl.consumeRevealRequest()) {
      _snapOpen();
    } else if (ctrl.consumeDismissRequest()) {
      _snapBack();
    }
  }

  // ── State machine ──────────────────────────────────────────────────────────

  void _setRevealState(RevealState newState) {
    if (_revealState == newState) return;
    setState(() => _revealState = newState);
    widget.controller?.updateState(newState);
  }

  // ── Pull physics ───────────────────────────────────────────────────────────

  void _updatePull(double newRawDistance) {
    _rawPullDistance = newRawDistance.clamp(0.0, double.infinity);

    final adjusted = PullPhysics.rubberBand(
      rawDistance: _rawPullDistance,
      resistanceFactor: widget.resistanceFactor,
    );

    _animationController.value =
        (adjusted / _widgetHeight).clamp(0.0, 1.0);

    final progress = PullPhysics.progress(
      adjustedDistance: adjusted,
      threshold: widget.threshold,
    );

    final isNowArmed = PullPhysics.isArmed(
      adjustedDistance: adjusted,
      threshold: widget.threshold,
    );

    if (_rawPullDistance > 0 && _revealState == RevealState.idle) {
      _setRevealState(RevealState.pulling);
    }

    if (isNowArmed && _revealState == RevealState.pulling) {
      _setRevealState(RevealState.armed);
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
    } else if (!isNowArmed && _revealState == RevealState.armed) {
      _setRevealState(RevealState.pulling);
    }

    if (_rawPullDistance == 0 && _revealState != RevealState.revealed) {
      _setRevealState(RevealState.idle);
    }

    widget.onPull?.call(progress);
  }

  // ── Snap animations ────────────────────────────────────────────────────────

  void _snapOpen() {
    if (_revealState == RevealState.revealed) return;
    _rawPullDistance = 0;
    _setRevealState(RevealState.revealed);
    _animationController
        .animateTo(
      1.0,
      duration: RevealAnimations.snapOpenDuration,
      curve: RevealAnimations.snapOpenCurve,
    )
        .then((_) {
      if (mounted) widget.onReveal?.call();
    });
  }

  void _snapBack() {
    if (_revealState == RevealState.idle) return;
    _rawPullDistance = 0;
    _setRevealState(RevealState.idle);
    _animationController
        .animateTo(
      0.0,
      duration: RevealAnimations.snapBackDuration,
      curve: RevealAnimations.snapBackCurve,
    )
        .then((_) {
      if (mounted) widget.onCancel?.call();
    });
  }

  void _resolveGestureEnd() {
    if (_revealState == RevealState.armed) {
      _snapOpen();
    } else if (_revealState.isActive) {
      _snapBack();
    }
  }

  // ── Pointer events ─────────────────────────────────────────────────────────

  /// Unified pointer handler — works for BOTH scrollable and
  /// non-scrollable children.
  ///
  /// **Why this works for scrollable children:**
  /// When a scroll view is at offset 0 it physically cannot scroll
  /// further upward. A downward drag at that position produces zero
  /// scroll movement — the entire pointer delta is "free" and we
  /// accumulate it as pull distance. `Listener` operates below the
  /// gesture arena so it always fires regardless of what the scroll
  /// view does with the same gesture.
  void _onPointerMove(PointerMoveEvent event) {
    if (_revealState == RevealState.revealed) return;

    final dy = event.delta.dy;

    if (dy > 0) {
      // Pulling downward.
      // Gate: for scrollable children only allow pull when at the top.
      // Non-scrollable children always pass this gate (_isAtTop == true).
      if (_isAtTop) {
        _updatePull(_rawPullDistance + dy);
      }
    } else if (dy < 0 && _rawPullDistance > 0) {
      // Pulling back upward — always reduce regardless of child type.
      _updatePull(
        PullPhysics.reducePull(
          currentDistance: _rawPullDistance,
          delta: dy.abs(),
        ),
      );
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_revealState == RevealState.revealed) return;
    _resolveGestureEnd();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_revealState.isActive) _snapBack();
  }

  // ── Scroll notifications ───────────────────────────────────────────────────

  bool _onScrollNotification(ScrollNotification notification) {
    // Lazily detect that the child tree contains a scrollable.

    if (notification is ScrollUpdateNotification) {
      _isAtTop = notification.metrics.pixels <= 0.0;
      // If user scrolled away from top during a pull, cancel the pull.
      if (!_isAtTop && _revealState.isActive) {
        _snapBack();
      }
    } else if (notification is ScrollEndNotification) {
      // Fallback gesture-end for scrollable children. In most cases
      // _onPointerUp already fired, making this a no-op. It catches
      // edge cases where the scroll gesture absorbs the pointer-up
      // event before Listener sees it.
      if (_revealState.isActive) {
        _resolveGestureEnd();
      }
    }

    // Never absorb — child scroll must continue to work normally.
    return false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final measuredHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        if (measuredHeight > 0) _widgetHeight = measuredHeight;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              final values = RevealAnimations.resolve(
                mode: widget.revealMode,
                progress: _animationController.value,
                revealHeight: _widgetHeight,
              );

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // ── Background layer ──────────────────────────────
                  // Fills the entire Stack. RepaintBoundary means it
                  // never repaints during foreground animation frames.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: widget.background ??
                          _DefaultRevealBackground(
                            progress: _animationController.value,
                            revealState: _revealState,
                          ),
                    ),
                  ),

                  // ── Foreground layer ──────────────────────────────
                  // Wrapped in Material so it always has a solid opaque
                  // surface — prevents the background from bleeding
                  // through transparent child widgets (e.g. ListView).
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _buildForeground(values),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildForeground(AnimationValues values) {
    // Material provides an opaque surface colour from the active theme,
    // ensuring the foreground fully occludes the background at rest.
    final content = Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.child,
      ),
    );

    return switch (widget.revealMode) {
      RevealMode.slide => Transform.translate(
        offset: Offset(0, values.offset),
        child: content,
      ),
      RevealMode.fade => Opacity(
        opacity: values.opacity.clamp(0.0, 1.0),
        child: content,
      ),
      RevealMode.scale => Transform.scale(
        scale: values.scale,
        child: content,
      ),
    };
  }
}

// ── Default background ────────────────────────────────────────────────────────

/// The built-in background shown when [PullToReveal.background] is `null`.
///
/// Displays a pull-progress indicator that responds to gesture state.
/// Replace this by providing your own [PullToReveal.background] widget,
/// or use [PullToReveal.onReveal] to navigate instead.
class _DefaultRevealBackground extends StatelessWidget {
  const _DefaultRevealBackground({
    required this.progress,
    required this.revealState,
  });

  final double progress;
  final RevealState revealState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArmed = revealState == RevealState.armed ||
        revealState == RevealState.revealed;
    final color = isArmed
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final icon = isArmed ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final label = isArmed ? 'Release to reveal' : 'Pull down to reveal';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: isArmed ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.bodyMedium!.copyWith(color: color),
              child: Text(label),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}