import 'dart:convert';

import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/shared_widgets.dart';
import 'exercise_library_screen.dart';
import 'workout_screen.dart';

class RoutinesTab extends StatefulWidget {
  const RoutinesTab({super.key});
  @override
  State<RoutinesTab> createState() => _RoutinesState();
}

class _RoutinesState extends State<RoutinesTab> {
  String q = '';
  int seg = 0;

  Future<void> createRoutine(BuildContext context) async {
    final exercises = await goForResult<List<Map<String, dynamic>>>(
      context,
      const ExerciseLibraryScreen(title: 'Create a routine'),
    );
    if (exercises == null || exercises.isEmpty || !context.mounted) return;
    final cardio =
        exercises.where((exercise) => exercise['m'] == 'Cardio').length >
        exercises.length / 2;
    go(
      context,
      EditRoutine({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': 'New routine',
        'type': cardio ? 'Cardio' : 'Strength',
        'ex': exercises,
        'isNew': true,
      }),
    );
  }

  @override
  Widget build(BuildContext context) => live((c) {
    final list = store.routines
        .where(
          (r) => (r['name'] as String).toLowerCase().contains(q.toLowerCase()),
        )
        .toList();
    return tabBody([
      hdr(c, 'Build your momentum', 'Your routines'),
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search your routines',
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('My routines')),
            ButtonSegment(value: 1, label: Text('Explore')),
          ],
          selected: {seg},
          onSelectionChanged: (s) => setState(() => seg = s.first),
        ),
      ),
      const SizedBox(height: 12),
      if (seg == 1)
        for (final e in exploreList())
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      e['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    tag(e['type']),
                  ],
                ),
                Text('${(e['ex'] as List).length} exercises', style: muted),
                const SizedBox(height: 10),
                btn('+ Add to my routines', () {
                  store.routines.add({
                    ...e,
                    'id': DateTime.now().millisecondsSinceEpoch,
                  });
                  store.save();
                  setState(() => seg = 0);
                }, tonal: true),
              ],
            ),
          )
      else ...[
        h3(
          'Made for your week',
          trailing: Text('${store.routines.length} routines', style: muted),
        ),
        for (final r in list)
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tag(r['type']),
                const SizedBox(height: 6),
                Text(
                  r['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  '${(r['ex'] as List).length} exercises · ~${(r['ex'] as List).length * 7} min',
                  style: muted,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: btn('▷ Start', () => go(c, WorkoutScreen(r))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: btn(
                        'Edit',
                        () => go(c, EditRoutine(r)),
                        tonal: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: btn('Delete', () async {
                        if (await confirm(c, 'Delete routine?', 'Delete')) {
                          store.routines.removeWhere((x) => x['id'] == r['id']);
                          store.sch.removeWhere((s) => s['r'] == r['id']);
                          store.save();
                        }
                      }, danger: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        btn('+ Create a routine', () => createRoutine(c)),
      ],
    ]);
  });
}

class EditRoutine extends StatefulWidget {
  final Map src;
  const EditRoutine(this.src, {super.key});
  @override
  State<EditRoutine> createState() => _EditState();
}

class _EditState extends State<EditRoutine> {
  late Map<String, dynamic> r = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(widget.src)),
  );

  Widget num2(String label, Map e, String k) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextFormField(
        initialValue: '${e[k]}',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (v) => e[k] = int.tryParse(v) ?? e[k],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final exs = r['ex'] as List;
    return screen([
      hdr(context, 'Make it your own', 'Edit routine', back: true),
      TextFormField(
        initialValue: r['name'],
        decoration: const InputDecoration(labelText: 'Routine name'),
        onChanged: (v) => r['name'] = v,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          tag(r['type']),
          const SizedBox(width: 8),
          Text('${exs.length} exercises', style: muted),
        ],
      ),
      h3('Your exercises'),
      if (exs.isEmpty)
        card(
          child: const Text(
            'No exercises yet. Add a few to build your routine.',
            style: muted,
          ),
        ),
      for (int i = 0; i < exs.length; i++)
        cardKey(
          key: ValueKey('${exs[i]['n']}$i'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exs[i]['n'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => exs.removeAt(i)),
                    icon: const Icon(Icons.remove_circle_outline, color: kRed),
                  ),
                ],
              ),
              Text(exs[i]['m'], style: muted),
              Row(
                children: [
                  num2('Sets', exs[i], 's'),
                  num2('Reps/sec', exs[i], 'r'),
                  num2('Rest s', exs[i], 'rest'),
                ],
              ),
            ],
          ),
        ),
      btn('+ Browse exercises', () async {
        final picked = await goForResult<List<Map<String, dynamic>>>(
          context,
          const ExerciseLibraryScreen(title: 'Add exercises'),
        );
        if (picked != null && mounted) setState(() => exs.addAll(picked));
      }, tonal: true),
      const SizedBox(height: 10),
      btn('✓ Save routine', () {
        if ((r['name'] as String).trim().isEmpty) {
          return snack(context, 'Name your routine.');
        }
        r.remove('isNew');
        final i = store.routines.indexWhere((x) => x['id'] == r['id']);
        if (i >= 0) {
          store.routines[i] = r;
        } else {
          store.routines.add(r);
        }
        store.save();
        Navigator.pop(context);
      }),
    ]);
  }
}

Widget cardKey({Key? key, required Widget child}) => KeyedSubtree(
  key: key,
  child: card(child: child),
);
