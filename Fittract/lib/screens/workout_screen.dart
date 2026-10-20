import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class WorkoutScreen extends StatefulWidget {
  final Map r;
  const WorkoutScreen(this.r, {super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutState();
}

class _WorkoutState extends State<WorkoutScreen> {
  late List exs = widget.r['ex'];
  int i = 0, secs = 0;
  bool paused = false;
  late List<bool> done = List.filled(exs.length, false);
  late List<List<Map<String, dynamic>>> sets = [for (final e in exs) [for (int j = 0; j < (e['s'] as int); j++) {'kg': 12.5, 'rp': e['r'], 'ok': false}]];
  Timer? tm;

  @override
  void initState() {
    super.initState();
    tm = Timer.periodic(const Duration(seconds: 1), (_) { if (!paused && mounted) setState(() => secs++); });
  }

  @override
  void dispose() { tm?.cancel(); super.dispose(); }

  String clock() => '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  void finish() {
    final n = done.where((x) => x).length;
    store.hist.add({'n': widget.r['name'], 'd': today(), 'min': secs < 60 ? 1 : (secs / 60).round(), 'ex': n, 'kc': (secs / 60 * 7 + n * 20).round()});
    store.save();
    Navigator.pop(context);
    snack(context, 'Workout saved! 💪');
  }

  @override
  Widget build(BuildContext context) {
    final nDone = done.where((x) => x).length;
    return screen([
      hdr(context, 'Strength · Live session', widget.r['name']),
      card(
        color: kDk,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ELAPSED TIME', style: TextStyle(color: Colors.white60, fontSize: 11)),
          Row(children: [
            Text(clock(), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton.filledTonal(onPressed: () => setState(() => paused = !paused), icon: Icon(paused ? Icons.play_arrow : Icons.pause)),
          ]),
          Text('$nDone of ${exs.length} exercises complete', style: const TextStyle(color: Colors.white)),
          bar(nDone / max(1, exs.length), dark: true),
        ]),
      ),
      if (exs.isNotEmpty)
        card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            tag('EXERCISE ${i + 1} OF ${exs.length}'),
            const SizedBox(height: 6),
            Text(exs[i]['n'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${exs[i]['s']} sets × ${exs[i]['r']} · ${exs[i]['rest']} sec rest', style: muted),
            const SizedBox(height: 8),
            for (int j = 0; j < sets[i].length; j++) ...[
              if (j > 0) const SizedBox(height: 6),
              Row(children: [
                SizedBox(width: 24, child: Text('${j + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Padding(padding: const EdgeInsets.all(4), child: TextFormField(key: ValueKey('kg$i$j'), initialValue: '${sets[i][j]['kg']}', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kg', isDense: true), onChanged: (v) => sets[i][j]['kg'] = num_(v)))),
                Expanded(child: Padding(padding: const EdgeInsets.all(4), child: TextFormField(key: ValueKey('rp$i$j'), initialValue: '${sets[i][j]['rp']}', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'reps', isDense: true), onChanged: (v) => sets[i][j]['rp'] = num_(v).toInt()))),
                Checkbox(value: sets[i][j]['ok'], activeColor: kPri, onChanged: (v) => setState(() => sets[i][j]['ok'] = v!)),
              ]),
            ],
            const SizedBox(height: 8),
            btn('✓ Mark exercise complete', () => setState(() {
                  done[i] = true;
                  for (final s in sets[i]) { s['ok'] = true; }
                  final n = done.indexOf(false);
                  if (n >= 0) i = n;
                })),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: btn('‹ Prev', () => setState(() => i = max(0, i - 1)), tonal: true)),
              const SizedBox(width: 8),
              Expanded(child: btn('Next ›', () => setState(() => i = min(exs.length - 1, i + 1)), tonal: true)),
            ]),
          ]),
        ),
      h3('Session checklist', trailing: Text('$nDone / ${exs.length} done', style: muted)),
      for (int k = 0; k < exs.length; k++)
        ListTile(
          dense: true, contentPadding: EdgeInsets.zero, onTap: () => setState(() => i = k),
          leading: Icon(done[k] ? Icons.check_circle : Icons.radio_button_unchecked, color: kPri),
          title: Text(exs[k]['n']), trailing: Text('${exs[k]['s']}×${exs[k]['r']}', style: muted),
        ),
      const SizedBox(height: 10),
      btn('⚑ Finish workout', finish, tonal: true),
      const SizedBox(height: 8),
      btn('Discard session', () async { final ok = await confirm(context, 'Discard this session?', 'Discard'); if (ok && context.mounted) Navigator.pop(context); }, danger: true),
    ]);
  }
}
