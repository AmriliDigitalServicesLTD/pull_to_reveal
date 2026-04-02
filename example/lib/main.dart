import 'package:flutter/material.dart';
import 'package:pull_to_reveal/pull_to_reveal.dart';

void main() => runApp(const PullToRevealExampleApp());

class PullToRevealExampleApp extends StatelessWidget {
  const PullToRevealExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PullToReveal Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _DemoHome(),
    );
  }
}

class _DemoHome extends StatefulWidget {
  const _DemoHome();

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  RevealMode _mode = RevealMode.slide;
  bool _useScrollable = true;
  bool _useCustomBackground = true;
  final _controller = PullToRevealController();
  String _status = 'idle — pull down hard to reveal';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        _status = switch (_controller.state) {
          RevealState.idle => 'idle — pull down hard to reveal',
          RevealState.pulling => 'pulling…',
          RevealState.armed => '🔓 armed — release!',
          RevealState.revealed => '✅ revealed!',
        };
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pull to Reveal Demo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _Controls(
            mode: _mode,
            useScrollable: _useScrollable,
            useCustomBackground: _useCustomBackground,
            onModeChanged: (m) => setState(() => _mode = m),
            onScrollableToggled: (v) =>
                setState(() => _useScrollable = v),
            onCustomBgToggled: (v) =>
                setState(() => _useCustomBackground = v),
            onReveal: _controller.reveal,
            onDismiss: _controller.dismiss,
          ),
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: PullToReveal(
              // key forces a clean rebuild when settings change
              key: ValueKey(
                  '${_mode.name}_${_useScrollable}_$_useCustomBackground'),
              controller: _controller,
              threshold: 90,
              resistanceFactor: 0.35,
              revealMode: _mode,
              enableHapticFeedback: true,
              // background is optional — null uses built-in default
              background:
              _useCustomBackground ? const _HiddenPlaceBackground() : null,
              onReveal: () {},
              onCancel: () {},
              onPull: (_) {},
              child: _useScrollable
                  ? _ScrollableChild()
                  : const _NonScrollableChild(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.mode,
    required this.useScrollable,
    required this.useCustomBackground,
    required this.onModeChanged,
    required this.onScrollableToggled,
    required this.onCustomBgToggled,
    required this.onReveal,
    required this.onDismiss,
  });

  final RevealMode mode;
  final bool useScrollable;
  final bool useCustomBackground;
  final ValueChanged<RevealMode> onModeChanged;
  final ValueChanged<bool> onScrollableToggled;
  final ValueChanged<bool> onCustomBgToggled;
  final VoidCallback onReveal;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<RevealMode>(
            segments: const [
              ButtonSegment(
                  value: RevealMode.slide,
                  label: Text('Slide'),
                  icon: Icon(Icons.swipe_down)),
              ButtonSegment(
                  value: RevealMode.fade,
                  label: Text('Fade'),
                  icon: Icon(Icons.opacity)),
              ButtonSegment(
                  value: RevealMode.scale,
                  label: Text('Scale'),
                  icon: Icon(Icons.zoom_out)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onModeChanged(s.first),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Scrollable', style: TextStyle(fontSize: 12)),
                Switch(value: useScrollable, onChanged: onScrollableToggled),
                const Text('Custom BG', style: TextStyle(fontSize: 12)),
                Switch(
                    value: useCustomBackground,
                    onChanged: onCustomBgToggled),
                const SizedBox(width: 8,),
                FilledButton.tonal(
                    onPressed: onReveal,
                    child: const Text('Reveal')),
                const SizedBox(width: 6),
                FilledButton.tonal(
                    onPressed: onDismiss,
                    child: const Text('Dismiss')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom background ─────────────────────────────────────────────────────────

class _HiddenPlaceBackground extends StatelessWidget {
  const _HiddenPlaceBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade800,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Hidden place',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Custom background layer.\nPull hard from the top to reveal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(
                  6, (i) => _HiddenPlaceCard(index: i)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenPlaceCard extends StatelessWidget {
  const _HiddenPlaceCard({required this.index});
  final int index;

  static const _colors = [
    Colors.pink, Colors.orange, Colors.teal,
    Colors.indigo, Colors.green, Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: _colors[index % _colors.length].shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined,
              color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text('Item ${index + 1}',
              style:
              const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Scrollable child ──────────────────────────────────────────────────────────

class _ScrollableChild extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 30,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade600,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('Chat ${index + 1}'),
        subtitle: const Text('Scroll to top then pull hard'),
        trailing: Text(
          '${index + 1}m ago',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
    );
  }
}

// ── Non-scrollable child ──────────────────────────────────────────────────────

class _NonScrollableChild extends StatelessWidget {
  const _NonScrollableChild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Non-scrollable child',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag down anywhere to reveal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Column inside Material\nNo ScrollView. Pull always active.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}