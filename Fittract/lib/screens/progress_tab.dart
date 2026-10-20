import 'dart:math';
import 'package:flutter/material.dart';
import '../store/store.dart';
import '../widgets/shared_widgets.dart';
import 'weight_screen.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});
  @override
  State<ProgressTab> createState() => _ProgressState();
}

class _ProgressState extends State<ProgressTab> {
  int tab = 0;
  bool all = false;

  Widget stat(String big, String sub) => Expanded(
        child: card(color: kDk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(big, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      );

  List<Widget> overview(BuildContext c) {
    final recent = store.hist.where((h) => (h['d'] as String).compareTo(daysAgo(27)) >= 0).toList();
    final mins = recent.fold<int>(0, (a, h) => a + (h['min'] as int));
    final bs = [3, 2, 1, 0].map(store.wkCount).toList();
    final top = max(4, bs.reduce(max));
    final hist = store.hist.toList()..sort((a, b) => (b['d'] as String).compareTo(a['d'] as String));
    return [
      Row(children: [stat('${recent.length}', 'Workouts · last 4 weeks'), const SizedBox(width: 10), stat('${mins ~/ 60}h ${mins % 60}m', 'Time moving')]),
      card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('A stronger routine', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 8), tag('4 WEEKS')]),
        const SizedBox(height: 12),
        SizedBox(height: 120, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final v in bs) Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 6), height: max(8, v / top * 100), decoration: const BoxDecoration(color: kPri, borderRadius: BorderRadius.vertical(top: Radius.circular(6))), alignment: Alignment.topCenter, child: Text('$v', style: const TextStyle(color: Colors.white, fontSize: 11)))),
        ])),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('W-3', style: muted), Text('W-2', style: muted), Text('W-1', style: muted), Text('Now', style: muted)]),
      ])),
      h3('Workout history'),
      for (final h in hist.take(all ? 99 : 4))
        card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(h['n'], style: const TextStyle(fontWeight: FontWeight.w700)), Text(h['d'], style: muted)]),
          const SizedBox(height: 4),
          Text('${h['min']} min · ${h['ex']} exercises · ${h['kc']} kcal', style: muted),
          const SizedBox(height: 6),
          const Text('✓ Completed', style: TextStyle(color: kPri, fontSize: 12)),
        ])),
      btn(all ? 'Show less' : 'View all', () => setState(() => all = !all), tonal: true),
    ];
  }

  List<Widget> daily() {
    final m = <String, Map<String, dynamic>>{};
    for (final e in store.d['log'] as List) {
      m[e['d']] = {'k': (e['meals'] as List).fold<int>(0, (a, x) => a + (x['k'] as int)), 's': e['steps'], 'min': (e['act'] as List).fold<int>(0, (a, x) => a + (x['min'] as int)), 'ml': 0, 'n': (e['meals'] as List).map((x) => x['n']).join(', ')};
    }
    m[store.d['day']] = {'k': store.kcal(), 's': store.steps, 'min': store.actMin(), 'ml': 0, 'n': store.meals.map((x) => x['n']).join(', ')};
    for (final w in store.d['water'] as List) {
      m.putIfAbsent(w['d'], () => {'k': 0, 's': 0, 'min': 0, 'ml': 0, 'n': ''});
      m[w['d']]!['ml'] = (m[w['d']]!['ml'] as int) + (w['ml'] as num).toInt();
    }
    final keys = m.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Food, steps and activity reset every day. Past days are kept here.', style: muted)),
      for (final k in keys)
        card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k == today() ? 'Today' : k, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${m[k]!['min']} min active', style: muted)]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [Text('${m[k]!['k']}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), const Text('kcal', style: muted)]),
            Column(children: [Text('${m[k]!['s']}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), const Text('steps', style: muted)]),
            Column(children: [Text('${((m[k]!['ml'] as int) / 1000).toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), const Text('water', style: muted)]),
          ]),
          if ((m[k]!['n'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(m[k]!['n'], style: muted)),
        ])),
    ];
  }

  @override
  Widget build(BuildContext context) => live((c) {
        final sw = (store.goal['sw'] as num).toDouble(), gw = (store.goal['w'] as num).toDouble();
    final hasWeight = (store.d['weights'] as List).isNotEmpty;
    final body = tab == 0
        ? overview(c)
        : tab == 1
            ? [card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hasWeight ? store.wt(store.lastW()) : 'Not logged yet', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), Text(hasWeight ? 'Started at ${store.wt(sw)}' : 'Log your first weight to start tracking.', style: muted)])), btn('Open weight tracker', () => go(c, const WeightScreen()))]
            : tab == 2
                ? [card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(gw > 0 ? 'Target ${store.wt(gw)}${store.goal['d'] == '' ? '' : ' by ${store.goal['d']}'}' : 'No weight goal set yet', style: const TextStyle(fontWeight: FontWeight.w700)), bar(store.goalProgress()), Text('Weekly workouts goal: ${store.goal['wk']} (this week ${store.wkCount(0)})', style: muted)])), btn('Edit goals', () => go(c, const WeightScreen()))]
                    : daily();
        return tabBody([
          hdr(c, 'Your progress', "See how far you've come."),
          SizedBox(width: double.infinity, child: SegmentedButton<int>(showSelectedIcon: false, segments: const [ButtonSegment(value: 0, label: Text('Overview')), ButtonSegment(value: 1, label: Text('Weight')), ButtonSegment(value: 2, label: Text('Goals')), ButtonSegment(value: 3, label: Text('Daily'))], selected: {tab}, onSelectionChanged: (s) => setState(() => tab = s.first))),
          const SizedBox(height: 12),
          ...body,
        ]);
      });
}
