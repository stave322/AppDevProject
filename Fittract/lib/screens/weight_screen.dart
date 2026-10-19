import 'dart:math';

import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class Chart extends CustomPainter {
  final List<double> v;
  Chart(this.v);
  @override
  void paint(Canvas c, Size s) {
    if (v.length < 2) return;
    final mn = v.reduce(min) - 1, mx = v.reduce(max) + 1;
    final p = Path();
    for (int i = 0; i < v.length; i++) {
      final x = i * s.width / (v.length - 1),
          y = (mx - v[i]) / (mx - mn) * s.height;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    c.drawPath(
      p,
      Paint()
        ..color = kPri
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (int i = 0; i < v.length; i++) {
      c.drawCircle(
        Offset(
          i * s.width / (v.length - 1),
          (mx - v[i]) / (mx - mn) * s.height,
        ),
        3.5,
        Paint()..color = kPri,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  State<WeightScreen> createState() => _WeightState();
}

class _WeightState extends State<WeightScreen> {
  int per = 1;
  late final tw = TextEditingController(
    text: (store.goal['w'] as num).toDouble() > 0 ? '${store.goal['w']}' : '',
  );
  late final td = TextEditingController(text: '${store.goal['d']}');

  @override
  void dispose() {
    tw.dispose();
    td.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => live((c) {
    final ws = (store.d['weights'] as List).toList()
      ..sort((a, b) => (a[0] as String).compareTo(b[0] as String));
    final cut = daysAgo([7, 31, 92][per]);
    var pts = ws.where((x) => (x[0] as String).compareTo(cut) >= 0).toList();
    if (pts.length < 2) pts = ws.sublist(max(0, ws.length - 2));
    final vals = pts.map<double>((x) => (x[1] as num).toDouble()).toList();
    final hasWeight = ws.isNotEmpty;
    final diff = vals.length < 2 ? 0.0 : vals.first - vals.last;
    final sw = (store.goal['sw'] as num).toDouble();
    final gw = (store.goal['w'] as num).toDouble();
    final prog = store.goalProgress();
    return screen([
      hdr(c, 'Weight & goals', 'Stronger, steadily.', back: true),
      card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Latest weight', style: muted),
            Text(
              hasWeight ? store.wt(store.lastW()) : 'Not logged yet',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('1 week')),
                  ButtonSegment(value: 1, label: Text('1 month')),
                  ButtonSegment(value: 2, label: Text('3 months')),
                ],
                selected: {per},
                onSelectionChanged: (s) => setState(() => per = s.first),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(painter: Chart(vals)),
            ),
            Text(
              !hasWeight
                  ? 'Log your first weight to start tracking.'
                  : vals.length < 2
                  ? 'Log another weight to see your progress.'
                  : diff >= 0
                  ? '${diff.toStringAsFixed(1)} kg down in this period.'
                  : '${(-diff).toStringAsFixed(1)} kg up in this period.',
              style: const TextStyle(color: kPri),
            ),
          ],
        ),
      ),
      btn('+ Log weight', () async {
        final f = await form(c, 'Log weight', [
          F(
            'w',
            'Weight (kg)',
            hasWeight ? store.lastW().toStringAsFixed(1) : '',
            type: 'number',
          ),
        ], ok: 'Log');
        if (f == null || !c.mounted) return;
        final weight = num_(f['w']);
        if (weight <= 0) {
          snack(c, 'Enter a weight greater than zero.');
          return;
        }
        final l = store.d['weights'] as List;
        if (l.isEmpty && (store.goal['sw'] as num) == 0) {
          store.goal['sw'] = weight;
        }
        l.removeWhere((x) => x[0] == today());
        l.add([today(), weight]);
        store.save();
      }),
      h3('Set your goals'),
      card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tw,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target weight (kg)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: td,
                    decoration: const InputDecoration(
                      labelText: 'Target date (YYYY-MM-DD)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              !hasWeight
                  ? 'Log your first weight to set your starting point.'
                  : gw <= 0
                  ? 'Set a target weight to track your goal.'
                  : 'Start ${sw.toStringAsFixed(1)} kg · ${(prog * 100).round()}% of your journey',
              style: muted,
            ),
            bar(prog),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly workouts'),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        store.goal['wk'] = max(
                          1,
                          (store.goal['wk'] as int) - 1,
                        );
                        store.save();
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${store.goal['wk']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        store.goal['wk'] = min(
                          7,
                          (store.goal['wk'] as int) + 1,
                        );
                        store.save();
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            btn('✓ Save goals', () {
              store.goal['w'] = num_(tw.text) == 0 ? gw : num_(tw.text);
              store.goal['d'] = td.text;
              store.save();
              snack(c, 'Goals saved ✓');
            }),
          ],
        ),
      ),
    ]);
  });
}
