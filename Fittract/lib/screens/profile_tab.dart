import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/google_auth_service.dart';
import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> editPersonalDetails(BuildContext context) async {
    final details = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PersonalDetailsSheet(
        name: store.d['name'] as String? ?? '',
        age: store.d['age'] as int?,
        height: store.d['h'] as int?,
        weight: store.d['weights'].isEmpty
            ? null
            : store.lastW() * (store.on('lb') ? 2.2046 : 1),
        isImperial: store.on('lb'),
      ),
    );
    if (details == null || !context.mounted) return;
    store.d['name'] = details['name'];
    store.d['age'] = details['age'];
    store.d['h'] = details['height'];
    final weight = details['weight'] as double?;
    if (weight != null) {
      final weights = store.d['weights'] as List;
      if (weights.isEmpty && (store.goal['sw'] as num) == 0) {
        store.goal['sw'] = weight;
      }
      weights.removeWhere((entry) => entry[0] == today());
      weights.add([today(), weight]);
    }
    store.save();
  }

  Widget sw(BuildContext context, String k, String title, String sub) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(sub, style: muted),
        trailing: Switch(
          value: store.on(k),
          activeTrackColor: primaryOf(context),
          onChanged: (_) => store.toggle(k),
        ),
      );

  @override
  Widget build(BuildContext context) => live((c) {
    final name = (store.d['name'] as String?) ?? '';
    final displayName = name.isEmpty ? 'Your name' : name;
    final age = store.d['age'];
    final height = store.d['h'];
    return tabBody([
      hdr(c, 'Profile & preferences', 'Your corner.'),
      card(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: tintOf(c),
                  child: CircleAvatar(
                    radius: 31,
                    backgroundColor: primaryOf(c),
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                        color: isDark(c) ? kInk : Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-24, 25),
                  child: Material(
                    color: Theme.of(c).colorScheme.surface,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: Theme.of(c).colorScheme.outlineVariant,
                      ),
                    ),
                    child: InkResponse(
                      onTap: () {},
                      radius: 22,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: primaryOf(c),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text('${store.d['user']}', style: muted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      age == null ? '—' : '$age',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text('Age', style: muted),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      height == null ? '—' : '$height cm',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text('Height', style: muted),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      store.d['weights'].isEmpty
                          ? 'Not logged'
                          : store.wt(store.lastW()),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text('Weight', style: muted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            btn(
              '✎  Edit personal details',
              () => editPersonalDetails(c),
              tonal: true,
            ),
          ],
        ),
      ),
      h3('A nudge when you need it'),
      card(
        child: Column(
          children: [
            sw(c, 'wr', 'Workout reminders', 'Never miss a scheduled session'),
            sw(c, 'wtr', 'Water reminders', 'Every 2 hours'),
            sw(c, 'mr', 'Meal reminders', 'Breakfast, lunch & dinner'),
          ],
        ),
      ),
      h3('Make it yours'),
      card(
        child: Column(
          children: [
            sw(
              c,
              'dark',
              'Dark mode',
              'A darker look that is easier on the eyes',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Units'),
              subtitle: Text(
                store.on('lb') ? 'Imperial · lb' : 'Metric · kg, km, ml',
                style: muted,
              ),
              onTap: () => store.toggle('lb'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Privacy & account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final f = await form(c, 'Change password', [
                  F('p', 'New password', '', type: 'pass'),
                ], ok: 'Update');
                if (f == null || !c.mounted) return;
                if (f['p']!.length >= 8) {
                  store.d['pw'] = f['p'];
                  store.save();
                  snack(c, 'Password updated.');
                } else {
                  snack(c, 'Use 8+ characters.');
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reset all data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                if (await confirm(c, 'Erase all data?', 'Erase')) {
                  final u = store.d['user'];
                  store.d = store.seed();
                  store.d['user'] = u;
                  store.save();
                }
              },
            ),
          ],
        ),
      ),
      btn('Log out', () async {
        if (store.d['authProvider'] == 'google') {
          try {
            await GoogleAuthService().signOut();
          } on FirebaseAuthException catch (error) {
            if (!c.mounted) return;
            snack(c, googleAuthErrorMessage(error));
            return;
          } on FirebaseException catch (error) {
            if (!c.mounted) return;
            snack(c, googleAuthErrorMessage(error));
            return;
          } on GoogleSignInException catch (error) {
            if (!c.mounted) return;
            snack(c, googleAuthErrorMessage(error));
          }
        }
        store.d['user'] = null;
        store.d.remove('accountId');
        store.d.remove('authProvider');
        store.save();
      }, tonal: true),
    ]);
  });
}

class _PersonalDetailsSheet extends StatefulWidget {
  final String name;
  final int? age;
  final int? height;
  final double? weight;
  final bool isImperial;

  const _PersonalDetailsSheet({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.isImperial,
  });

  @override
  State<_PersonalDetailsSheet> createState() => _PersonalDetailsSheetState();
}

class _PersonalDetailsSheetState extends State<_PersonalDetailsSheet> {
  late final _name = TextEditingController(text: widget.name);
  late final _age = TextEditingController(text: widget.age?.toString() ?? '');
  late final _height = TextEditingController(
    text: widget.height?.toString() ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.weight?.toStringAsFixed(1) ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Personal details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Make your profile feel like yours.', style: muted),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixText: 'years',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      prefixIcon: Icon(Icons.height),
                      suffixText: 'cm',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Weight',
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                suffixText: widget.isImperial ? 'lb' : 'kg',
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tintOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: primaryOf(context)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your personal details stay on your profile.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            btn('Save changes', _save),
          ],
        ),
      ),
    ),
  );

  void _save() {
    final name = _name.text.trim();
    final ageText = _age.text.trim();
    final heightText = _height.text.trim();
    final weightText = _weight.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final height = heightText.isEmpty ? null : int.tryParse(heightText);
    final enteredWeight = weightText.isEmpty
        ? null
        : double.tryParse(weightText);

    if (ageText.isNotEmpty && (age == null || age < 1 || age > 120)) {
      snack(context, 'Enter a valid age between 1 and 120.');
      return;
    }
    if (heightText.isNotEmpty &&
        (height == null || height < 50 || height > 300)) {
      snack(context, 'Enter a valid height between 50 and 300 cm.');
      return;
    }
    if (weightText.isNotEmpty &&
        (enteredWeight == null || enteredWeight <= 0 || enteredWeight > 1000)) {
      snack(
        context,
        'Enter a valid weight greater than 0 and no more than 1000.',
      );
      return;
    }

    final weight = enteredWeight == null
        ? null
        : enteredWeight / (widget.isImperial ? 2.2046 : 1);
    Navigator.pop(context, {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
    });
  }
}
