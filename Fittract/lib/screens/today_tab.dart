import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/shared_widgets.dart';
import 'food_screen.dart';
import 'water_screen.dart';
import 'weight_screen.dart';
import 'workout_screen.dart';
import '../widgets/log_activity_sheet.dart';

class TodayTab extends StatelessWidget {
  final void Function(int) goTo;
  const TodayTab({super.key, required this.goTo});

  Widget tile(
    BuildContext context,
    IconData ic,
    String big,
    String sub,
    double? p,
    VoidCallback f,
  ) => Expanded(
    child: SizedBox(
      height: 132,
      child: card(
        onTap: f,
        pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, color: primaryOf(context), size: 18),
            const SizedBox(height: 8),
            Text(
              big,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (p != null) bar(p),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => live((c) {
    final nx = store.next();
    final r = nx == null ? null : store.routine(nx['r']);
    final n = store.notes().length;
    final calorieGoal = (store.nutritionGoals['calories'] as num).toInt();
    final name = (store.d['name'] as String?)?.trim() ?? '';
    final waterGoalMl = store.waterGoalMl;
    final stepGoal = store.stepGoal;
    return tabBody([
      hdr(
        c,
        niceDate(),
        "Let's go, ${name.isEmpty ? 'there' : name.split(' ').first}.",
        act: [
          IconButton(
            tooltip: "Today's reminders",
            onPressed: () => showNotes(c),
            icon: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
      ),
      Text('🔥 ${store.streak()}-day streak · Keep showing up.', style: muted),
      const SizedBox(height: 12),
      if (nx == null)
        card(
          child: Column(
            children: [
              const Text('Nothing scheduled'),
              const SizedBox(height: kGapMd),
              btn('Schedule a workout', () => goTo(2)),
            ],
          ),
        )
      else if (r == null)
        // The schedule entry exists but its routine was deleted: say so
        // rather than claiming the schedule is empty, and offer the way out.
        card(
          color: tintOf(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UP NEXT · ${nx['d'] == today() ? 'TODAY' : nx['d']}',
                style: TextStyle(
                  color: primaryOf(c),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '(deleted routine)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${nx['t']} · this workout was deleted. Remove it from your schedule.',
                style: muted,
              ),
              const SizedBox(height: 12),
              btn('Go to schedule', () => goTo(2), tonal: true),
            ],
          ),
        )
      else
        card(
          color: kDk,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UP NEXT · ${nx['d'] == today() ? 'TODAY' : nx['d']}',
                style: const TextStyle(
                  color: kMint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                r['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
                Text(
                  '${nx['t']} · ${(r['ex'] as List).length} exercises${store.on('wr') ? ' · Today reminder on' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              const SizedBox(height: 12),
              btn('▷  Start workout', () => go(c, WorkoutScreen(r))),
            ],
          ),
        ),
      h3('Your daily balance'),
      Row(
        children: [
          tile(
            c,
            Icons.restaurant,
            '${store.kcal()} kcal',
            'Food & meals',
            calorieGoal <= 0 ? null : store.kcal() / calorieGoal,
            () => go(c, const FoodScreen()),
          ),
          const SizedBox(width: kGapMd),
          tile(
            c,
            Icons.water_drop_outlined,
            '${(store.water() / 1000).toStringAsFixed(1)} L',
            'Water · of ${(waterGoalMl / 1000).toStringAsFixed(1)} L',
            waterGoalMl <= 0 ? null : store.water() / waterGoalMl,
            () => go(c, const WaterScreen()),
          ),
        ],
      ),
      Row(
        children: [
          tile(
            c,
            Icons.directions_walk,
            '${store.steps}',
            'Daily activity · of ${store.withThousands(stepGoal)}',
            stepGoal <= 0 ? null : store.steps / stepGoal,
            () => showLogActivity(c),
          ),
          const SizedBox(width: kGapMd),
          tile(
            c,
            Icons.monitor_weight_outlined,
            store.d['weights'].isEmpty ? 'Not logged' : store.wt(store.lastW()),
            'Current weight',
            null,
            () => go(c, const WeightScreen()),
          ),
        ],
      ),
      card(
        color: tintOf(c),
        onTap: () => goTo(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last week's workouts · ${store.wkCount(0)} / ${store.weeklyWorkoutGoal}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            bar(store.wkCount(0) / store.weeklyWorkoutGoal),
          ],
        ),
      ),
    ]);
  });
}
