import 'dart:math';
import 'package:flutter/material.dart';
import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});
  @override
  Widget build(BuildContext context) => live((c) {
        final k = store.kcal();
        return screen([
          hdr(c, 'Food & meals', 'Fuel your day.', back: true),
          card(
            child: Row(children: [
              SizedBox(width: 110, height: 110, child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: (k / 2100).clamp(0.0, 1.0), strokeWidth: 10, color: kPri, backgroundColor: kLn)),
                Column(mainAxisSize: MainAxisSize.min, children: [Text('$k', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const Text('kcal eaten', style: muted)]),
              ])),
              const SizedBox(width: 18),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${max(0, 2100 - k)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('kcal remaining · goal 2,100', style: muted),
              ]),
            ]),
          ),
          card(child: Column(children: [
            for (final m in [['Protein', 'p', 140], ['Carbs', 'c', 220], ['Fat', 'f', 65]])
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${m[0]}  ${store.macro(m[1] as String)} / ${m[2]} g', style: muted), bar(store.macro(m[1] as String) / (m[2] as int))]),
          ])),
          h3("Today's meals", trailing: Text('${store.meals.length} logged', style: muted)),
          for (int i = 0; i < store.meals.length; i++)
            card(child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.meals[i]['t'], style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(store.meals[i]['n'], style: muted),
                Text('${store.meals[i]['k']} kcal', style: const TextStyle(color: kPri, fontWeight: FontWeight.w700)),
              ])),
              IconButton(onPressed: () { store.meals.removeAt(i); store.save(); }, icon: const Icon(Icons.close, color: kRed)),
            ])),
          btn('+ Log food', () async {
            final f = await form(c, 'Log food', [
              F('t', 'Meal', 'Dinner', type: 'choice', opts: ['Breakfast', 'Lunch', 'Snack', 'Dinner']), F('n', 'What did you eat?', ''),
              F('k', 'Calories (kcal)', '', type: 'number'), F('p', 'Protein g', '0', type: 'number'), F('c', 'Carbs g', '0', type: 'number'), F('f', 'Fat g', '0', type: 'number'),
            ], ok: 'Log');
            if (f == null || f['n']!.isEmpty || num_(f['k']) == 0) return;
            store.meals.add({'t': f['t'], 'n': f['n'], 'k': num_(f['k']).round(), 'p': num_(f['p']).round(), 'c': num_(f['c']).round(), 'f': num_(f['f']).round()});
            store.save();
          }),
        ]);
      });
}
