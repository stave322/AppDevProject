import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────── THEME ─────────────────────────
const kPri = Color(0xFF0A7F6F);
const kDk = Color(0xFF1A4640);
const kLt = Color(0xFFD3EFE5);
const kBg = Color(0xFFF0F4F4);
const kInk = Color(0xFF0F2D29);
const kMut = Color(0xFF6F8A86);
const kLn = Color(0xFFE4ECEC);
const kRed = Color(0xFFC0392B);
const kMint = Color(0xFFA6EAD5);
const muted = TextStyle(color: kMut, fontSize: 12);

// ───────────────────────── DATE HELPERS ─────────────────────────
String isoOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String today() => isoOf(DateTime.now());
String daysAgo(int n) => isoOf(DateTime.now().subtract(Duration(days: n)));
String niceDate() {
  const w = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  const m = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final n = DateTime.now();
  return '${w[n.weekday - 1]}, ${m[n.month - 1]} ${n.day}';
}

Map<String, dynamic> ex(String n, String m, int s, int r, int rest) =>
    {'n': n, 'm': m, 's': s, 'r': r, 'rest': rest};

List<Map<String, dynamic>> exploreList() => [
      {
        'name': 'Full body HIIT',
        'type': 'Cardio',
        'ex': [
          ex('Burpees', 'Full', 4, 12, 30),
          ex('Mountain climbers', 'Core', 4, 30, 30),
          ex('Jump squats', 'Legs', 4, 15, 30)
        ]
      },
      {
        'name': 'Push day',
        'type': 'Strength',
        'ex': [
          ex('Push-ups', 'Chest', 4, 15, 45),
          ex('Overhead press', 'Shoulders', 3, 10, 60),
          ex('Dips', 'Triceps', 3, 12, 60)
        ]
      },
      {
        'name': 'Core crusher',
        'type': 'Strength',
        'ex': [
          ex('Crunches', 'Abs', 3, 20, 30),
          ex('Leg raises', 'Abs', 3, 15, 30),
          ex('Plank', 'Core', 3, 45, 30)
        ]
      },
    ];

double num_(String? s) => double.tryParse(s ?? '') ?? 0;

// ───────────────────────── STORE ─────────────────────────
class Store extends ChangeNotifier {
  late SharedPreferences sp;
  Map<String, dynamic> d = {};

  Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    final raw = sp.getString('ft');
    d = raw == null ? seed() : Map<String, dynamic>.from(jsonDecode(raw));
    roll();
  }

  Map<String, dynamic> seed() => {
        'user': null,
        'pw': '',
        'name': 'Ash',
        'age': 21,
        'h': 176,
        'lb': false,
        'wr': true,
        'wtr': true,
        'mr': false,
        'goal': {'w': 75.0, 'd': '2026-12-21', 'wk': 4, 'sw': 81.2},
        'routines': [
          {
            'id': 1,
            'name': 'Upper body strength',
            'type': 'Strength',
            'ex': [
              ex('Dumbbell bench press', 'Chest', 3, 12, 60),
              ex('Seated cable row', 'Back', 3, 12, 60),
              ex('Shoulder press', 'Shoulders', 3, 10, 60),
              ex('Lat pulldown', 'Back', 3, 12, 60),
              ex('Triceps pushdown', 'Arms', 3, 15, 45),
              ex('Plank', 'Core', 3, 30, 30)
            ]
          },
          {
            'id': 2,
            'name': 'Lower body power',
            'type': 'Strength',
            'ex': [
              ex('Back squat', 'Legs', 4, 8, 90),
              ex('Romanian deadlift', 'Hamstrings', 3, 10, 90),
              ex('Lunges', 'Legs', 3, 12, 60),
              ex('Calf raise', 'Calves', 3, 15, 45),
              ex('Leg press', 'Legs', 3, 12, 60)
            ]
          },
          {
            'id': 3,
            'name': 'Recovery & mobility',
            'type': 'Mobility',
            'ex': [
              ex('Cat-cow', 'Spine', 2, 10, 20),
              ex('Hip opener', 'Hips', 2, 10, 20),
              ex('Hamstring stretch', 'Legs', 2, 30, 20)
            ]
          },
        ],
        'sch': [
          {'id': 1, 'r': 1, 'd': today(), 't': '18:00'},
          {'id': 2, 'r': 2, 'd': daysAgo(-2), 't': '18:00'},
          {'id': 3, 'r': 3, 'd': daysAgo(-4), 't': '07:00'},
        ],
        'water': [],
        'steps': 6240,
        'act': [
          {
            'n': 'Brisk walk',
            'min': 30,
            'km': 2.8,
            'kc': 120,
            'st': 3600,
            't': null
          }
        ],
        'weights': [
          [daysAgo(26), 81.2],
          [daysAgo(20), 80.4],
          [daysAgo(14), 80.6],
          [daysAgo(7), 79.3],
          [daysAgo(0), 78.4]
        ],
        'meals': [
          {
            't': 'Breakfast',
            'n': 'Greek yogurt, oats & berries',
            'k': 420,
            'p': 30,
            'c': 50,
            'f': 10
          },
          {
            't': 'Lunch',
            'n': 'Chicken & quinoa bowl',
            'k': 650,
            'p': 45,
            'c': 70,
            'f': 15
          },
          {
            't': 'Snack',
            'n': 'Banana, almonds & protein shake',
            'k': 410,
            'p': 27,
            'c': 48,
            'f': 20
          },
        ],
        'hist': [
          {
            'n': 'Recovery & mobility',
            'd': daysAgo(2),
            'min': 20,
            'ex': 6,
            'kc': 90
          },
          {
            'n': 'Lower body power',
            'd': daysAgo(3),
            'min': 40,
            'ex': 5,
            'kc': 310
          },
          {
            'n': 'Upper body strength',
            'd': daysAgo(5),
            'min': 45,
            'ex': 6,
            'kc': 280
          },
          {
            'n': 'Lower body power',
            'd': daysAgo(9),
            'min': 40,
            'ex': 5,
            'kc': 300
          },
          {
            'n': 'Upper body strength',
            'd': daysAgo(12),
            'min': 45,
            'ex': 6,
            'kc': 280
          },
          {
            'n': 'Recovery & mobility',
            'd': daysAgo(16),
            'min': 20,
            'ex': 6,
            'kc': 90
          },
          {
            'n': 'Lower body power',
            'd': daysAgo(19),
            'min': 40,
            'ex': 5,
            'kc': 300
          },
        ],
        'day': today(),
        'log': [],
      };

  void save() {
    sp.setString('ft', jsonEncode(d));
    notifyListeners();
  }

  // Daily reset: archive yesterday's food/steps/activity and start fresh.
  void roll() {
    final n = today();
    if (d['day'] != n) {
      if (meals.isNotEmpty || acts.isNotEmpty || steps > 0) {
        (d['log'] as List).add({
          'd': d['day'],
          'meals': d['meals'],
          'act': d['act'],
          'steps': d['steps']
        });
      }
      d['meals'] = [];
      d['act'] = [];
      d['steps'] = 0;
      d['day'] = n;
      save();
    }
  }

  List get routines => d['routines'];
  List get sch => d['sch'];
  List get meals => d['meals'];
  List get acts => d['act'];
  List get hist => d['hist'];
  int get steps => (d['steps'] as num).toInt();
  Map get goal => d['goal'];
  bool on(String k) => d[k] == true;
  void toggle(String k) {
    d[k] = !on(k);
    save();
  }

  Map? routine(dynamic id) {
    for (final r in routines) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  Map? next() {
    final l = sch
        .where((s) => (s['d'] as String).compareTo(today()) >= 0)
        .toList()
      ..sort((a, b) => ('${a['d']}${a['t']}').compareTo('${b['d']}${b['t']}'));
    return l.isEmpty ? null : l.first;
  }

  int water() => (d['water'] as List)
      .where((w) => w['d'] == today())
      .fold(0, (a, w) => a + (w['ml'] as num).toInt());
  int kcal() => meals.fold(0, (a, m) => a + (m['k'] as num).toInt());
  int macro(String k) => meals.fold(0, (a, m) => a + (m[k] as num).toInt());
  int actMin() => acts.fold(0, (a, m) => a + (m['min'] as num).toInt());
  int actKc() => acts.fold(0, (a, m) => a + (m['kc'] as num).toInt());

  double lastW() {
    final w = (d['weights'] as List).toList()
      ..sort((a, b) => (a[0] as String).compareTo(b[0] as String));
    return w.isEmpty ? 0 : (w.last[1] as num).toDouble();
  }

  int streak() {
    final ds = hist.map((h) => h['d']).toSet();
    int n = 0, i = ds.contains(today()) ? 0 : 1;
    while (ds.contains(daysAgo(i))) {
      n++;
      i++;
    }
    return n;
  }

  int wkCount(int o) {
    final a = daysAgo(o * 7 + 6), b = daysAgo(o * 7);
    return hist
        .where((h) =>
            (h['d'] as String).compareTo(a) >= 0 &&
            (h['d'] as String).compareTo(b) <= 0)
        .length;
  }

  String wt(double kg) => on('lb')
      ? '${(kg * 2.2046).toStringAsFixed(1)} lb'
      : '${kg.toStringAsFixed(1)} kg';

  List<List<String>> notes() {
    final l = <List<String>>[];
    final t = sch.where((s) => s['d'] == today()).toList();
    if (t.isNotEmpty && on('wr')) {
      l.add([
        '🏋',
        'Workout today',
        '${routine(t.first['r'])?['name'] ?? 'Workout'} at ${t.first['t']}'
      ]);
    }
    if (on('wtr') && water() < 2500) {
      l.add([
        '💧',
        'Stay hydrated',
        '${(water() / 1000).toStringAsFixed(1)} of 2.5 L so far'
      ]);
    }
    if (on('mr') && meals.length < 3) {
      l.add([
        '🍴',
        'Log your meals',
        '${meals.length} of 3 meals logged today'
      ]);
    }
    if (steps < 8000) {
      l.add(['👣', 'Keep moving', '${8000 - steps} steps to your goal']);
    }
    if (streak() > 0) l.add(['🔥', '${streak()}-day streak', 'Keep showing up.']);
    return l;
  }
}

final store = Store();
