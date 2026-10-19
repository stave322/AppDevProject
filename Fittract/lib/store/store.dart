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
const kBgDark = Color(0xFF0E1A19);
const kSurfaceDark = Color(0xFF162826);
const kLineDark = Color(0xFF29413D);
const muted = TextStyle(color: kMut, fontSize: 12);

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color primaryOf(BuildContext context) => isDark(context) ? kMint : kPri;

Color tintOf(BuildContext context) =>
    isDark(context) ? const Color(0xFF1D3934) : kLt;

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
    'Sunday',
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
    'December',
  ];
  final n = DateTime.now();
  return '${w[n.weekday - 1]}, ${m[n.month - 1]} ${n.day}';
}

Map<String, dynamic> ex(String n, String m, int s, int r, int rest) => {
  'n': n,
  'm': m,
  's': s,
  'r': r,
  'rest': rest,
};

List<Map<String, dynamic>> exploreList() => [
  {
    'name': 'Full body HIIT',
    'type': 'Cardio',
    'ex': [
      ex('Burpees', 'Full', 4, 12, 30),
      ex('Mountain climbers', 'Core', 4, 30, 30),
      ex('Jump squats', 'Legs', 4, 15, 30),
    ],
  },
  {
    'name': 'Push day',
    'type': 'Strength',
    'ex': [
      ex('Push-ups', 'Chest', 4, 15, 45),
      ex('Overhead press', 'Shoulders', 3, 10, 60),
      ex('Dips', 'Triceps', 3, 12, 60),
    ],
  },
  {
    'name': 'Core crusher',
    'type': 'Strength',
    'ex': [
      ex('Crunches', 'Abs', 3, 20, 30),
      ex('Leg raises', 'Abs', 3, 15, 30),
      ex('Plank', 'Core', 3, 45, 30),
    ],
  },
];

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
    'name': '',
    'age': null,
    'h': null,
    'lb': false,
    'wr': true,
    'wtr': true,
    'mr': false,
    'dark': false,
    'goal': {'w': 0.0, 'd': '', 'wk': 3, 'sw': 0.0},
    'nutritionGoals': {
      'calories': 2100,
      'protein': 140,
      'carbs': 220,
      'fat': 65,
    },
    'routines': <Map<String, dynamic>>[],
    'sch': <Map<String, dynamic>>[],
    'water': <Map<String, dynamic>>[],
    'steps': 0,
    'act': <Map<String, dynamic>>[],
    'weights': <List<dynamic>>[],
    'meals': <Map<String, dynamic>>[],
    'hist': <Map<String, dynamic>>[],
    'day': today(),
    'log': [],
  };

  void save() {
    sp.setString('ft', jsonEncode(d));
    final accountId = d['accountId'];
    if (accountId is String && accountId.isNotEmpty) {
      sp.setString('ft_account_$accountId', jsonEncode(d));
    }
    notifyListeners();
  }

  void activateGoogleAccount({
    required String uid,
    required String email,
    required String displayName,
  }) {
    final accountData = sp.getString('ft_account_$uid');
    d = accountData == null
        ? seed()
        : Map<String, dynamic>.from(jsonDecode(accountData));
    d['accountId'] = uid;
    d['authProvider'] = 'google';
    d['user'] = email;
    d['lastUser'] = email;
    if (displayName.trim().isNotEmpty) d['name'] = displayName.trim();
    save();
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
          'steps': d['steps'],
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
  Map<String, dynamic> get nutritionGoals {
    const defaults = <String, dynamic>{
      'calories': 2100,
      'protein': 140,
      'carbs': 220,
      'fat': 65,
    };
    final saved = d['nutritionGoals'];
    final goals = saved is Map
        ? Map<String, dynamic>.from(saved)
        : <String, dynamic>{};
    for (final entry in defaults.entries) {
      goals.putIfAbsent(entry.key, () => entry.value);
    }
    d['nutritionGoals'] = goals;
    return goals;
  }

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
    final l =
        sch.where((s) => (s['d'] as String).compareTo(today()) >= 0).toList()
          ..sort(
            (a, b) => ('${a['d']}${a['t']}').compareTo('${b['d']}${b['t']}'),
          );
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

  double goalProgress() {
    final start = (goal['sw'] as num).toDouble();
    final target = (goal['w'] as num).toDouble();
    if (start <= 0 || target <= 0 || start == target || lastW() <= 0) return 0;
    return ((start - lastW()) / (start - target)).clamp(0.0, 1.0);
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
        .where(
          (h) =>
              (h['d'] as String).compareTo(a) >= 0 &&
              (h['d'] as String).compareTo(b) <= 0,
        )
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
        '${routine(t.first['r'])?['name'] ?? 'Workout'} at ${t.first['t']}',
      ]);
    }
    if (on('wtr') && water() < 2500) {
      l.add([
        '💧',
        'Stay hydrated',
        '${(water() / 1000).toStringAsFixed(1)} of 2.5 L so far',
      ]);
    }
    if (on('mr') && meals.length < 3) {
      l.add([
        '🍴',
        'Log your meals',
        '${meals.length} of 3 meals logged today',
      ]);
    }
    if (steps < 8000) {
      l.add(['👣', 'Keep moving', '${8000 - steps} steps to your goal']);
    }
    if (streak() > 0) {
      l.add(['🔥', '${streak()}-day streak', 'Keep showing up.']);
    }
    return l;
  }
}

final store = Store();
