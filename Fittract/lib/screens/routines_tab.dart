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
      const SizedBox(height: kGapMd),
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
                const SizedBox(height: kGapMd),
                btn('+ Add to my routines', () {
                  // Repeated taps must not create identical presets. Only
                  // exact-name matches of an existing routine are blocked;
                  // renaming/duplicating via the editor stays possible.
                  final name = e['name'] as String;
                  final exists = store.routines.any(
                    (existing) => existing['name'] == name,
                  );
                  if (exists) {
                    snack(c, '“$name” is already in your routines.');
                    return;
                  }
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
                const SizedBox(height: kGapSm),
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
                const SizedBox(height: kGapMd),
                btn('▷ Start', () => go(c, WorkoutScreen(r))),
                const SizedBox(height: kGapSm),
                Row(
                  children: [
                    Expanded(
                      child: btn(
                        'Edit',
                        () => go(c, EditRoutine(r)),
                        tonal: true,
                      ),
                    ),
                    const SizedBox(width: kGapMd),
                    Expanded(
                      child: btn('Delete', () async {
                        if (await confirm(c, 'Delete routine?', 'Delete')) {
                          store.routines.removeWhere((x) => x['id'] == r['id']);
                          store.sch.removeWhere((s) => s['r'] == r['id']);
                          // Drop the in-progress snapshot only when it
                          // belongs to this routine; unrelated sessions and
                          // workout history are left untouched. The snapshot
                          // records id ?? name as its routine reference.
                          final active = store.d['activeW'];
                          if (active is Map) {
                            final rid = active['rid'];
                            if (rid == r['id'] || rid == r['name']) {
                              store.d.remove('activeW');
                            }
                          }
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

  /// One stable key per exercise row. Index-suffixed keys (or names alone)
  /// shift when a row is removed, which re-creates every later TextFormField
  /// and drops its focus and in-progress value; these keys travel with their
  /// row instead. Kept in lockstep with `exs` (same length, same order).
  late final List<Key> _rowKeys;

  @override
  void initState() {
    super.initState();
    _rowKeys = [for (final _ in r['ex'] as List) UniqueKey()];
  }

  Widget num2(String label, Map e, String k) => Expanded(
    child: TextFormField(
      initialValue: '${e[k]}',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (v) => e[k] = int.tryParse(v) ?? e[k],
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
          key: _rowKeys[i],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    exerciseIconFor(exs[i]['n'], exs[i]['m']),
                    color: primaryOf(context),
                    size: 19,
                  ),
                  const SizedBox(width: kGapSm),
                  Expanded(
                    child: Text(
                      exs[i]['n'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove ${exs[i]['n']}',
                    onPressed: () => setState(() {
                      exs.removeAt(i);
                      _rowKeys.removeAt(i);
                    }),
                    icon: const Icon(Icons.remove_circle_outline, color: kRed),
                  ),
                ],
              ),
              Text(exs[i]['m'], style: muted),
              const SizedBox(height: kGapSm),
              Row(
                spacing: kGapMd,
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
        if (picked != null && mounted) {
          setState(() {
            exs.addAll(picked);
            _rowKeys.addAll([for (final _ in picked) UniqueKey()]);
          });
        }
      }, tonal: true),
      const SizedBox(height: kGapMd),
      btn('✓ Save routine', () {
        if ((r['name'] as String).trim().isEmpty) {
          return snack(context, 'Name your routine.');
        }
        if (exs.isEmpty) {
          // An empty routine would open a workout with nothing to do and no
          // way to finish it; refuse it at the door instead.
          return snack(context, 'Add at least one exercise before saving.');
        }
        for (final ex in exs) {
          final err = validateExerciseConfig(
            ex['s'] as num? ?? 0,
            ex['r'] as num? ?? 0,
            ex['rest'] as num? ?? 0,
          );
          if (err != null) {
            return snack(context, "${ex['n']}: $err");
          }
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
