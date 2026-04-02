import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_reveal/src/animations.dart';
import 'package:pull_to_reveal/src/physics.dart';
import 'package:pull_to_reveal/pull_to_reveal.dart';

void main() {
  // ── PullPhysics ────────────────────────────────────────────────────────────
  group('PullPhysics.linear', () {
    test('returns zero for zero input', () {
      expect(PullPhysics.linear(rawDistance: 0, resistanceFactor: 0.35), 0.0);
    });

    test('applies resistance factor correctly', () {
      expect(
        PullPhysics.linear(rawDistance: 100, resistanceFactor: 0.5),
        50.0,
      );
    });

    test('clamps resistance factor above 1.0 to 1.0', () {
      expect(
        PullPhysics.linear(rawDistance: 100, resistanceFactor: 2.0),
        100.0,
      );
    });

    test('clamps resistance factor of 0.0 to minimum', () {
      final result =
      PullPhysics.linear(rawDistance: 100, resistanceFactor: 0.0);
      expect(result, greaterThan(0.0));
    });
  });

  group('PullPhysics.rubberBand', () {
    test('returns zero for zero input', () {
      expect(
        PullPhysics.rubberBand(rawDistance: 0, resistanceFactor: 0.35),
        0.0,
      );
    });

    test('grows sub-linearly — 200px pull is less than 2x the 100px pull', () {
      final at100 = PullPhysics.rubberBand(
        rawDistance: 100,
        resistanceFactor: 0.35,
      );
      final at200 = PullPhysics.rubberBand(
        rawDistance: 200,
        resistanceFactor: 0.35,
      );
      expect(at200, lessThan(at100 * 2));
    });

    test('result is positive for positive input', () {
      final result = PullPhysics.rubberBand(
        rawDistance: 999999,
        resistanceFactor: 1.0,
        maxDistance: 300,
      );
      expect(result, greaterThan(0));
    });
  });

  group('PullPhysics.progress', () {
    test('returns 0.0 at zero distance', () {
      expect(PullPhysics.progress(adjustedDistance: 0, threshold: 140), 0.0);
    });

    test('returns 1.0 at threshold', () {
      expect(
          PullPhysics.progress(adjustedDistance: 140, threshold: 140), 1.0);
    });

    test('clamps to 1.0 beyond threshold', () {
      expect(
          PullPhysics.progress(adjustedDistance: 200, threshold: 140), 1.0);
    });

    test('returns correct mid value', () {
      expect(PullPhysics.progress(adjustedDistance: 70, threshold: 140), 0.5);
    });
  });

  group('PullPhysics.isArmed', () {
    test('returns false below threshold', () {
      expect(
        PullPhysics.isArmed(adjustedDistance: 100, threshold: 140),
        isFalse,
      );
    });

    test('returns true at exact threshold', () {
      expect(
        PullPhysics.isArmed(adjustedDistance: 140, threshold: 140),
        isTrue,
      );
    });

    test('returns true above threshold', () {
      expect(
        PullPhysics.isArmed(adjustedDistance: 200, threshold: 140),
        isTrue,
      );
    });
  });

  group('PullPhysics.reducePull', () {
    test('reduces distance by delta', () {
      expect(
        PullPhysics.reducePull(currentDistance: 100, delta: 30),
        70.0,
      );
    });

    test('clamps to zero, never negative', () {
      expect(
        PullPhysics.reducePull(currentDistance: 20, delta: 999),
        0.0,
      );
    });
  });

  // ── RevealAnimations ───────────────────────────────────────────────────────
  group('RevealAnimations', () {
    test('slide: offset is zero at zero progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.slide,
        progress: 0.0,
        revealHeight: 200,
      );
      expect(v.offset, 0.0);
      expect(v.opacity, 1.0);
      expect(v.scale, 1.0);
    });

    test('slide: offset equals revealHeight at full progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.slide,
        progress: 1.0,
        revealHeight: 200,
      );
      expect(v.offset, 200.0);
    });

    test('fade: opacity is 1.0 at zero progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.fade,
        progress: 0.0,
        revealHeight: 0,
      );
      expect(v.opacity, 1.0);
    });

    test('fade: opacity is 0.0 at full progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.fade,
        progress: 1.0,
        revealHeight: 0,
      );
      expect(v.opacity, 0.0);
    });

    test('scale: scale is 1.0 at zero progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.scale,
        progress: 0.0,
        revealHeight: 0,
      );
      expect(v.scale, 1.0);
    });

    test('scale: scale equals minScale at full progress', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.scale,
        progress: 1.0,
        revealHeight: 0,
      );
      expect(v.scale, closeTo(0.85, 0.001));
    });

    test('progress clamped — values beyond 1.0 do not exceed bounds', () {
      final v = RevealAnimations.resolve(
        mode: RevealMode.slide,
        progress: 5.0,
        revealHeight: 200,
      );
      expect(v.offset, 200.0);
    });
  });

  // ── PullToRevealController ─────────────────────────────────────────────────
  group('PullToRevealController', () {
    late PullToRevealController controller;

    setUp(() => controller = PullToRevealController());
    tearDown(() => controller.dispose());

    test('initial state is idle', () {
      expect(controller.state, RevealState.idle);
    });

    test('updateState notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.updateState(RevealState.pulling);
      expect(notified, isTrue);
    });

    test('updateState does not notify on identical state', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.updateState(RevealState.idle);
      expect(count, 0);
    });

    test('reveal() sets consumeRevealRequest to true once', () {
      controller.reveal();
      expect(controller.consumeRevealRequest(), isTrue);
      expect(controller.consumeRevealRequest(), isFalse);
    });

    test('dismiss() sets consumeDismissRequest to true once', () {
      controller.updateState(RevealState.revealed);
      controller.dismiss();
      expect(controller.consumeDismissRequest(), isTrue);
      expect(controller.consumeDismissRequest(), isFalse);
    });

    test('reveal() is no-op if already revealed', () {
      controller.updateState(RevealState.revealed);
      var count = 0;
      controller.addListener(() => count++);
      controller.reveal();
      expect(count, 0);
    });

    test('dismiss() is no-op if already idle', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.dismiss();
      expect(count, 0);
    });

    test('isRevealed reflects state correctly', () {
      expect(controller.isRevealed, isFalse);
      controller.updateState(RevealState.revealed);
      expect(controller.isRevealed, isTrue);
    });
  });

  // ── PullToReveal widget ────────────────────────────────────────────────────
  group('PullToReveal widget', () {
    // Helper: wraps widget in a testable app with a fixed screen size.
    Widget buildTestApp(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    testWidgets('renders with scrollable child', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PullToReveal(
            background: const Text('background'),
            child: ListView(
              children: const [Text('item')],
            ),
          ),
        ),
      );
      expect(find.text('background'), findsOneWidget);
      expect(find.text('item'), findsOneWidget);
    });

    testWidgets('renders with non-scrollable child', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PullToReveal(
            background: Text('background'),
            child: Column(
              children: [Text('content')],
            ),
          ),
        ),
      );
      expect(find.text('background'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('renders in all three RevealModes without error',
            (tester) async {
          for (final mode in RevealMode.values) {
            await tester.pumpWidget(
              buildTestApp(
                PullToReveal(
                  revealMode: mode,
                  background: const Text('bg'),
                  child: const Text('fg'),
                ),
              ),
            );
            expect(tester.takeException(), isNull,
                reason: 'RevealMode.$mode threw an exception');
          }
        });

    testWidgets('controller programmatic reveal animates to 1.0',
            (tester) async {
          final controller = PullToRevealController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildTestApp(
              PullToReveal(
                controller: controller,
                background: const Text('background'),
                child: const Text('foreground'),
              ),
            ),
          );

          controller.reveal();
          await tester.pumpAndSettle();

          expect(controller.state, RevealState.revealed);
        });

    testWidgets('controller programmatic dismiss returns to idle',
            (tester) async {
          final controller = PullToRevealController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            buildTestApp(
              PullToReveal(
                controller: controller,
                background: const Text('background'),
                child: const Text('foreground'),
              ),
            ),
          );

          // Reveal first, then dismiss.
          controller.reveal();
          await tester.pumpAndSettle();
          expect(controller.state, RevealState.revealed);

          controller.dismiss();
          await tester.pumpAndSettle();
          expect(controller.state, RevealState.idle);
        });

    testWidgets('onReveal callback fires after snap open', (tester) async {
      var revealed = false;
      final controller = PullToRevealController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          PullToReveal(
            controller: controller,
            onReveal: () => revealed = true,
            background: const Text('background'),
            child: const Text('foreground'),
          ),
        ),
      );

      controller.reveal();
      await tester.pumpAndSettle();

      expect(revealed, isTrue);
    });

    testWidgets('onCancel callback fires after snap back', (tester) async {
      var cancelled = false;
      final controller = PullToRevealController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          PullToReveal(
            controller: controller,
            onCancel: () => cancelled = true,
            background: const Text('background'),
            child: const Text('foreground'),
          ),
        ),
      );

      controller.reveal();
      await tester.pumpAndSettle();

      controller.dismiss();
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('does not throw when child rebuilds mid-gesture',
            (tester) async {
          final notifier = ValueNotifier<int>(0);

          await tester.pumpWidget(
            buildTestApp(
              PullToReveal(
                background: const Text('background'),
                child: ValueListenableBuilder<int>(
                  valueListenable: notifier,
                  builder: (_, value, __) => Text('value: $value'),
                ),
              ),
            ),
          );

          expect(find.text('value: 0'), findsOneWidget);

          // Simulate a child rebuild mid-state
          notifier.value = 1;
          await tester.pump();

          expect(find.text('value: 1'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
  });
}