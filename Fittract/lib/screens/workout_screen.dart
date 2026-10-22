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
  late List exs = widget.r['ex'] as List;
  int i = 0, secs = 0;
  bool paused = false;
  bool _allowLeave = false;
  bool _askingLeave = false;
  bool _finished = false;
  bool _blockedByOtherSession = false;
  int restLeft = 0, restTotal = 0;
  String restAfter = '';
  late List<bool> done;
  late List<List<Map<String, dynamic>>> sets;
  Timer? tm;

  dynamic get _rid => widget.r['id'] ?? widget.r['name'];

  @override
  void initState() {
    super.initState();
    done = List.filled(exs.length, false);
    sets = _freshSets();
    _adoptSavedProgress();
    tm = Timer.periodic(const Duration(seconds: 1), _tick);
    if (!_blockedByOtherSession) _persist();
    if (_restoredFromSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) snack(context, 'Resumed your saved session.');
      });
    }
  }

  @override
  void dispose() {
    tm?.cancel();
    // Snapshot on the way out so an interrupted session can be recovered,
    // unless the workout was already finished or discarded (which clears it).
    if (!_finished && !_blockedByOtherSession) _persist();
    super.dispose();
  }

  bool _restoredFromSession = false;

  int _exSets(dynamic e) =>
      (((e['s'] as num?) ?? kSetsMin).toInt()).clamp(kSetsMin, kSetsMax);

  List<List<Map<String, dynamic>>> _freshSets() => [
    for (final e in exs)
      [
        for (int j = 0; j < _exSets(e); j++)
          {'kg': 12.5, 'rp': e['r'], 'ok': false},
      ],
  ];

  void _adoptSavedProgress() {
    final raw = store.d['activeW'];
    if (raw is! Map) return;
    final saved = Map<String, dynamic>.from(raw);

    if (saved['rid'] != _rid) {
      // A different routine has a saved session; never clobber it silently.
      _blockedByOtherSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final discard = await confirm(
          context,
          'Discard the saved session for ${saved['name'] ?? 'another workout'}?',
          'Discard',
        );
        if (!mounted) return;
        if (discard) {
          _blockedByOtherSession = false;
          store.d.remove('activeW');
          _persist();
          setState(() {});
        } else {
          // Keep the block flag set: we are leaving without taking over the
          // saved session, so dispose() must not snapshot a blank session
          // over the other routine's progress.
          _popSafely();
        }
      });
      return;
    }

    final sDone = saved['done'];
    final sSets = saved['sets'];
    bool shapeOk =
        sDone is List &&
        sDone.length == exs.length &&
        sSets is List &&
        sSets.length == exs.length;
    if (shapeOk) {
      for (int k = 0; k < exs.length; k++) {
        final row = sSets[k];
        if (row is! List || row.length != _exSets(exs[k])) {
          shapeOk = false;
          break;
        }
      }
    }
    if (!shapeOk) return; // routine changed underneath: start fresh

    done = List<bool>.from(sDone.map((x) => x == true));
    sets = [
      for (final row in sSets)
        [for (final s in row as List) Map<String, dynamic>.from(s as Map)],
    ];
    final savedIndex = ((saved['i'] as num?) ?? 0).toInt();
    final hi = exs.length - 1;
    i = hi < 0 ? 0 : savedIndex.clamp(0, hi);
    secs = (((saved['secs'] as num?) ?? 0).toInt()).clamp(0, 86400);
    final rl = (((saved['restLeft'] as num?) ?? 0).toInt()).clamp(0, kRestMax);
    final rt = (((saved['restTotal'] as num?) ?? 0).toInt()).clamp(0, kRestMax);
    if (rl > 0 && rt > 0) {
      restLeft = rl;
      restTotal = rt;
      restAfter = '${saved['restAfter'] ?? ''}';

      // Rest is wall-clock time: advance it for the gap between the last
      // save and now, and expire it entirely when the gap outlasted the
      // rest. The gap is deliberately NOT added to `secs`, so elapsed
      // workout time never jumps after a long interruption. A future
      // savedAt (clock skew) is ignored by treating the gap as zero.
      final savedAt = ((saved['savedAt'] as num?) ?? 0).toInt();
      if (savedAt > 0) {
        final gapSecs =
            ((DateTime.now().millisecondsSinceEpoch - savedAt) ~/ 1000)
                .clamp(0, kRestMax)
                .toInt();
        if (gapSecs >= restLeft) {
          restLeft = 0;
          restTotal = 0;
          restAfter = '';
        } else {
          restLeft -= gapSecs;
        }
      }
    }
    _restoredFromSession = true;
  }

  void _persist() {
    // Never snapshot over a saved session that belongs to a different
    // routine; that progress is only replaced after explicit confirmation.
    if (_blockedByOtherSession) return;
    store.d['activeW'] = {
      'rid': _rid,
      'name': widget.r['name'],
      'i': i,
      'secs': secs,
      'done': done,
      'sets': sets,
      'restLeft': restLeft,
      'restTotal': restTotal,
      'restAfter': restAfter,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    store.saveQuiet();
  }

  void _clearProgress() {
    _finished = true;
    store.d.remove('activeW');
    store.save();
  }

  void _popSafely() {
    if (!mounted) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _tick(Timer t) {
    if (!mounted || paused) return;
    setState(() {
      secs++;
      if (restLeft > 0) {
        restLeft--;
        if (restLeft == 0) restTotal = 0;
      }
      if (secs % 15 == 0) _persist();
    });
  }

  String _clock(int total) =>
      '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';

  void _startRestFor(int exIndex) {
    final e = exs[exIndex];
    final r = (((e['rest'] as num?) ?? 0).toInt()).clamp(kRestMin, kRestMax);
    if (r <= 0) return;
    restTotal = r;
    restLeft = r;
    restAfter = '${e['n']}';
  }

  void _skipRest() => setState(() {
    restLeft = 0;
    restTotal = 0;
    restAfter = '';
    _persist();
  });

  void _toggleSet(int j, bool? v) => setState(() {
    sets[i][j]['ok'] = v ?? false;
    if (v == true) _startRestFor(i);
    _persist();
  });

  void _markComplete() {
    final err = validateSetRow(sets[i]);
    if (err != null) {
      snack(context, err);
      return;
    }
    setState(() {
      done[i] = true;
      for (final s in sets[i]) {
        s['ok'] = true;
      }
      final completed = i;
      final n = done.indexOf(false);
      if (n >= 0) i = n;
      _startRestFor(completed);
      _persist();
    });
  }

  void finish() {
    // Invalid loads are reported first so data errors stay actionable, then
    // a workout with no completed exercise is refused entirely: it must not
    // be recorded in history.
    for (final row in sets) {
      final err = validateSetRow(row);
      if (err != null) {
        snack(context, err);
        return;
      }
    }
    final n = done.where((x) => x).length;
    if (n == 0) {
      snack(context, 'Complete at least one exercise before finishing.');
      return;
    }
    store.hist.add({
      'n': widget.r['name'],
      'd': today(),
      'min': secs < 60 ? 1 : (secs / 60).round(),
      'ex': n,
      'kc': (secs / 60 * 7 + n * 20).round(),
    });
    _clearProgress();
    if (!mounted) return;
    // Feedback must be raised before the route is popped so it is not
    // triggered after the route has already been removed.
    snack(context, 'Workout saved! 💪');
    _popSafely();
  }

  Future<void> _discard() async {
    if (!await confirm(context, 'Discard this session?', 'Discard')) return;
    if (!mounted) return;
    _clearProgress();
    _popSafely();
  }

  @override
  Widget build(BuildContext context) {
    final nDone = done.where((x) => x).length;
    return PopScope(
      canPop: _allowLeave,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || _askingLeave) return;
        _askingLeave = true;
        final leave = await confirm(
          context,
          'Leave this workout? Your progress stays saved.',
          'Leave',
        );
        _askingLeave = false;
        if (!mounted) return;
        if (leave) {
          if (!_finished && !_blockedByOtherSession) _persist();
          _popSafely();
        }
      },
      child: screen([
        hdr(context, 'Strength · Live session', widget.r['name']),
        card(
          color: kDk,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ELAPSED TIME', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Row(children: [
              Text(_clock(secs), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton.filledTonal(onPressed: () => setState(() { paused = !paused; _persist(); }), icon: Icon(paused ? Icons.play_arrow : Icons.pause)),
            ]),
            Text('$nDone of ${exs.length} exercises complete', style: const TextStyle(color: Colors.white)),
            bar(nDone / max(1, exs.length), dark: true),
          ]),
        ),
        if (restLeft > 0)
          card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tag('REST'),
              const SizedBox(height: kGapSm),
              Row(children: [
                Text(_clock(restLeft), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(restAfter, style: muted),
              ]),
              bar(1 - restLeft / max(1, restTotal)),
              const SizedBox(height: kGapSm),
              btn('Skip rest', _skipRest, tonal: true),
            ]),
          ),
        if (exs.isNotEmpty)
          card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tag('EXERCISE ${i + 1} OF ${exs.length}'),
              const SizedBox(height: kGapSm),
              Text(exs[i]['n'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: kGapXs),
              Text('${exs[i]['s']} sets × ${exs[i]['r']} · ${exs[i]['rest']} sec rest', style: muted),
              const SizedBox(height: kGapSm),
              for (int j = 0; j < sets[i].length; j++) ...[
                if (j > 0) const SizedBox(height: 6),
                Row(children: [
                  SizedBox(width: 24, child: Text('${j + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(child: Padding(padding: const EdgeInsets.all(kGapXs), child: TextFormField(key: ValueKey('kg$i$j'), initialValue: '${sets[i][j]['kg']}', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kg', isDense: true), onChanged: (v) => sets[i][j]['kg'] = num_(v)))),
                  Expanded(child: Padding(padding: const EdgeInsets.all(kGapXs), child: TextFormField(key: ValueKey('rp$i$j'), initialValue: '${sets[i][j]['rp']}', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'reps', isDense: true), onChanged: (v) => sets[i][j]['rp'] = num_(v).toInt()))),
                  Checkbox(value: sets[i][j]['ok'], activeColor: kPri, onChanged: (v) => _toggleSet(j, v)),
                ]),
              ],
              const SizedBox(height: kGapSm),
              btn('✓ Mark exercise complete', _markComplete),
              const SizedBox(height: kGapSm),
              Row(children: [
                Expanded(child: btn('‹ Prev', () => setState(() { i = max(0, i - 1); _persist(); }), tonal: true)),
                const SizedBox(width: 8),
                Expanded(child: btn('Next ›', () => setState(() { i = min(exs.length - 1, i + 1); _persist(); }), tonal: true)),
              ]),
            ]),
          ),
        h3('Session checklist', trailing: Text('$nDone / ${exs.length} done', style: muted)),
        for (int k = 0; k < exs.length; k++)
          ListTile(
            dense: true, contentPadding: EdgeInsets.zero, onTap: () => setState(() { i = k; _persist(); }),
            leading: Icon(done[k] ? Icons.check_circle : Icons.radio_button_unchecked, color: kPri),
            title: Text(exs[k]['n']), trailing: Text('${exs[k]['s']}×${exs[k]['r']}', style: muted),
          ),
        const SizedBox(height: kGapMd),
        btn('⚑ Finish workout', finish, tonal: true),
        const SizedBox(height: kGapSm),
        btn('Discard session', _discard, danger: true),
      ]),
    );
  }
}
