import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/google_auth_service.dart';
import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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
                  radius: 28,
                  backgroundColor: kPri,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22),
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
            btn('✎  Edit profile', () async {
              final f = await form(c, 'Edit profile', [
                F('n', 'Name', name),
                F('a', 'Age', age?.toString() ?? '', type: 'number'),
                F('h', 'Height (cm)', height?.toString() ?? '', type: 'number'),
              ]);
              if (f == null) return;
              if (f['n']!.isNotEmpty) store.d['name'] = f['n'];
              if (num_(f['a']) > 0) store.d['age'] = num_(f['a']).round();
              if (num_(f['h']) > 0) store.d['h'] = num_(f['h']).round();
              store.save();
            }, tonal: true),
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
