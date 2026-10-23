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
    text: store.goalField('w') > 0
        ? _displayWeight(store.goalField('w')).toStringAsFixed(1)
        : '',
  );
  late final td = TextEditingController(text: '${store.goal['d']}');
  late final weightInput = TextEditingController(
    text: (store.d['weights'] as List).isEmpty
        ? ''
        : _displayWeight(store.lastW()).toStringAsFixed(1),
  );

  String get _unit => store.on('lb') ? 'lb' : 'kg';

  /// Weekly workout target from the store, decoded tolerantly (legacy
  /// snapshots may hold a double or lack the key) and clamped to 1–7.
  int _weeklyGoal() => store.weeklyWorkoutGoal;

  double _displayWeight(double kg) => store.on('lb') ? kg * 2.2046 : kg;

  double _weightInKg(double value) => store.on('lb') ? value / 2.2046 : value;

  @override
  void dispose() {
    tw.dispose();
    td.dispose();
    weightInput.dispose();
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
    final sw = store.goalField('sw');
    final gw = store.goalField('w');
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
            const SizedBox(height: kGapLg),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(painter: Chart(vals)),
            ),
            const SizedBox(height: kGapMd),
            Text(
              !hasWeight
                  ? 'Log your first weight to start tracking.'
                  : vals.length < 2
                  ? 'Log another weight to see your progress.'
                  : diff >= 0
                  ? '${store.wt(diff.abs())} down in this period.'
                  : '${store.wt(diff.abs())} up in this period.',
              style: const TextStyle(color: kPri),
            ),
          ],
        ),
      ),
      card(
        color: tintOf(c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: primaryOf(c)),
                const SizedBox(width: kGapMd),
                const Expanded(
                  child: Text(
                    "Log today's weight",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                if (hasWeight) tag('LATEST ${store.wt(store.lastW())}'),
              ],
            ),
            const SizedBox(height: kGapXs),
            Text(
              'Record your progress and keep your trend up to date.',
              style: muted,
            ),
            const SizedBox(height: kGapLg),
            TextField(
              controller: weightInput,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Your weight',
                hintText: 'Enter weight',
                suffixText: _unit,
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: kGapMd),
            btn('Save weight', () => _saveWeight(c)),
          ],
        ),
      ),
      h3('Weight goals'),
      card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(kGapLg),
              decoration: BoxDecoration(
                color: tintOf(c),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, color: primaryOf(c), size: 25),
                  const SizedBox(width: kGapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gw > 0 ? 'Your target' : 'Set a weight target',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: kGapXs),
                        Text(
                          gw > 0
                              ? '${store.wt(gw)}${td.text.isEmpty ? '' : ' · ${td.text}'}'
                              : 'Choose a goal that feels right for you.',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  if (gw > 0)
                    Text(
                      '${(prog * 100).round()}%',
                      style: TextStyle(
                        color: primaryOf(c),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (gw > 0) ...[
              const SizedBox(height: kGapSm),
              bar(prog),
              Text(
                sw > 0
                    ? 'Starting weight · ${store.wt(sw)}'
                    : 'Progress toward your target',
                style: muted,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: tw,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target weight',
                hintText: 'Enter target',
                suffixText: _unit,
                prefixIcon: const Icon(Icons.track_changes_outlined),
              ),
            ),
            const SizedBox(height: kGapMd),
            TextField(
              controller: td,
              readOnly: true,
              onTap: () => _pickGoalDate(c),
              decoration: InputDecoration(
                labelText: 'Target date',
                hintText: 'Choose a date',
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: td.text.isEmpty
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        tooltip: 'Clear target date',
                        onPressed: () => setState(() => td.clear()),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: kGapLg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(c).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(c).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week_outlined, color: primaryOf(c)),
                  const SizedBox(width: kGapMd),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly workouts',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('Your activity target', style: muted),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Decrease weekly workouts',
                    onPressed: _weeklyGoal() <= 1
                        ? null
                        : () {
                            store.goal['wk'] = max(1, _weeklyGoal() - 1);
                            store.save();
                          },
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kGapMd, vertical: kGapSm),
                    child: Text(
                      '${_weeklyGoal()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Increase weekly workouts',
                    onPressed: _weeklyGoal() >= 7
                        ? null
                        : () {
                            store.goal['wk'] = min(7, _weeklyGoal() + 1);
                            store.save();
                          },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kGapLg),
            btn('Save goals', () => _saveGoals(c)),
          ],
        ),
      ),
    ]);
  });

  void _saveWeight(BuildContext context) {
    final entered = double.tryParse(weightInput.text.trim());
    if (entered == null || entered <= 0 || entered > 1000) {
      snack(
        context,
        'Enter a valid weight greater than 0 and no more than 1000.',
      );
      return;
    }
    final weight = _weightInKg(entered);
    final weights = store.d['weights'] as List;
    if (weights.isEmpty && store.goalField('sw') == 0) {
      store.goal['sw'] = weight;
    }
    weights.removeWhere((entry) => entry[0] == today());
    weights.add([today(), weight]);
    store.save();
    snack(context, "Today's weight saved.");
  }

  Future<void> _pickGoalDate(BuildContext context) async {
    final now = DateTime.now();
    final existing = DateTime.tryParse(td.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: existing != null && !existing.isBefore(now) ? existing : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null || !mounted) return;
    setState(() => td.text = isoOf(picked));
  }

  void _saveGoals(BuildContext context) {
    final targetText = tw.text.trim();
    final target = targetText.isEmpty ? null : double.tryParse(targetText);
    if (targetText.isNotEmpty &&
        (target == null || target <= 0 || target > 1000)) {
      snack(
        context,
        'Enter a valid target weight greater than 0 and no more than 1000.',
      );
      return;
    }
    store.goal['w'] = target == null ? 0.0 : _weightInKg(target);
    store.goal['d'] = td.text;
    store.save();
    snack(context, 'Goals saved.');
  }
}
