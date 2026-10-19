import 'dart:math';

import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/log_activity_sheet.dart';
import '../widgets/shared_widgets.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  String tf(int? ms) {
    if (ms == null) return '';
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  void addW(int ml) {
    (store.d['water'] as List).add({
      'd': today(),
      'ml': ml,
      't': DateTime.now().millisecondsSinceEpoch,
    });
    store.save();
  }

  @override
  Widget build(BuildContext context) => live((c) {
    final w = store.water(), g = w ~/ 250;
    final wl = store.d['water'] as List;
    final last = wl.isEmpty ? null : wl.last;
    return screen([
      hdr(c, 'Water & activity · Today', 'Every bit counts.', back: true),
      card(
        color: kDk,
        pad: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily hydration',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${(w / 1000).toStringAsFixed(1)} L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'of 2.5 L goal · ${(w / 25).clamp(0, 100).round()}% complete',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < 10; i++)
                  Expanded(
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: i < g ? kMint : Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.local_drink_outlined,
                        size: 14,
                        color: i < g ? kDk : Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              '${min(g, 10)} of 10 glasses · 250 ml each',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => addW(250),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryOf(c),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('+ 250 ml'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final f = await form(c, 'Custom amount', [
                        F('ml', 'Millilitres', '330', type: 'number'),
                      ], ok: 'Add');
                      if (f != null && num_(f['ml']) > 0) {
                        addW(num_(f['ml']).round());
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: tintOf(c),
                      foregroundColor: primaryOf(c),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Custom'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            last == null
                ? 'No drinks logged yet'
                : 'Last drink: ${last['ml']} ml${last['t'] != null ? ' at ${tf(last['t'])}' : ''}',
            style: muted,
          ),
          TextButton(
            onPressed: () {
              if (wl.isNotEmpty) {
                wl.removeLast();
                store.save();
              }
            },
            child: const Text('Undo'),
          ),
        ],
      ),
      h3('Move a little more'),
      card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${store.steps}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const Text('of 8,000 daily steps', style: muted),
            bar(store.steps / 8000),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${store.actMin()} min active',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text('${store.actKc()} kcal burned', style: muted),
              ],
            ),
          ],
        ),
      ),
      for (int i = 0; i < store.acts.length; i++)
        card(
          onTap: () async {
            if (await confirm(c, 'Remove this activity?', 'Remove')) {
              store.d['steps'] = max(
                0,
                store.steps - (store.acts[i]['st'] as num).toInt(),
              );
              store.acts.removeAt(i);
              store.save();
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: tintOf(c),
                child: Icon(Icons.directions_run, color: primaryOf(c)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.acts[i]['n'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${store.acts[i]['t'] != null ? '${tf(store.acts[i]['t'])} · ' : ''}${store.acts[i]['min']} min · ${store.acts[i]['km']} km',
                      style: muted,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kMut),
            ],
          ),
        ),
      btn('+ Log physical activity', () => showLogActivity(c)),
    ]);
  });
}
