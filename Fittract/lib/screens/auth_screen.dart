import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../store/store.dart';
import '../services/google_auth_service.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  bool reg = false, agree = false;
  bool googleBusy = false;
  String err = '';
  final googleAuth = GoogleAuthService();
  final nm = TextEditingController(),
      em = TextEditingController(),
      pw = TextEditingController(),
      pw2 = TextEditingController();

  void submit() {
    if (!reg) {
      if (em.text.isEmpty || pw.text.isEmpty) {
        return setState(() => err = 'Enter email and password.');
      }
      final saved = store.d['pw'] as String;
      if (saved.isNotEmpty &&
          store.d['lastUser'] == em.text &&
          saved != pw.text) {
        return setState(() => err = 'Wrong password.');
      }
      store.d['user'] = em.text;
      store.d['lastUser'] = em.text;
      store.save();
    } else {
      if (nm.text.isEmpty || em.text.isEmpty) {
        return setState(() => err = 'Fill in all fields.');
      }
      if (pw.text.length < 8) {
        return setState(() => err = 'Password needs 8+ characters.');
      }
      if (pw.text != pw2.text) {
        return setState(() => err = 'Passwords do not match.');
      }
      if (!agree) return setState(() => err = 'Please accept the terms.');
      store.d = store.seed();
      store.d['user'] = em.text;
      store.d['lastUser'] = em.text;
      store.d['pw'] = pw.text;
      store.d['name'] = nm.text;
      store.save();
    }
  }

  Future<void> signInWithGoogle() async {
    if (reg && !agree) {
      setState(() => err = 'Please accept the terms.');
      return;
    }
    setState(() {
      googleBusy = true;
      err = '';
    });
    try {
      final credential = await googleAuth.signIn();
      final user = credential.user;
      if (user == null) {
        throw StateError('Google sign-in did not return an account.');
      }
      store.activateGoogleAccount(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? nm.text,
      );
    } on GoogleSignInException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on FirebaseAuthException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on FirebaseException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on StateError catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => googleBusy = false);
    }
  }

  void _showGoogleError(String message) {
    if (message.isNotEmpty && mounted) setState(() => err = message);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5A5A), kDk],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '▲ FITTRACK',
                  style: TextStyle(color: kMint, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 40),
                Text(
                  reg
                      ? 'Build a routine.\nFind your rhythm.'
                      : 'Small steps.\nStronger you.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            reg ? 'Create your account' : 'Welcome back',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (reg)
            TextField(
              controller: nm,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
          TextField(
            controller: em,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          TextField(
            controller: pw,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (reg)
            TextField(
              controller: pw2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          if (reg)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agree,
              onChanged: (v) => setState(() => agree = v!),
              title: const Text(
                'I agree to the Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(err, style: const TextStyle(color: kRed)),
            ),
          if (!reg)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final r = await form(context, 'Reset password', [
                    F('e', 'Email', ''),
                  ], ok: 'Send link');
                  if (r != null && context.mounted) {
                    snack(
                      context,
                      'If that email exists, a reset link was sent.',
                    );
                  }
                },
                child: const Text('Forgot password?'),
              ),
            ),
          btn(reg ? 'Create account' : 'Log in', submit),
          if (!reg) ...[
            const SizedBox(height: 10),
            if (googleBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              btn('Continue with Google', signInWithGoogle, tonal: true),
          ],
          TextButton(
            onPressed: () => setState(() {
              reg = !reg;
              err = '';
            }),
            child: Text(
              reg ? 'Already a member? Log in' : 'New here? Create an account',
            ),
          ),
        ],
      ),
    ),
  );
}
