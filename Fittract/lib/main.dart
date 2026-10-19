import 'package:flutter/material.dart';

import 'store/store.dart';
import 'screens/auth_screen.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const App());
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final primary = dark ? kMint : kPri;
  final scheme = ColorScheme.fromSeed(seedColor: kPri, brightness: brightness)
      .copyWith(
        primary: primary,
        onPrimary: dark ? kInk : Colors.white,
        secondary: dark ? kMint : kDk,
        surface: dark ? kSurfaceDark : Colors.white,
        onSurface: dark ? const Color(0xFFE4EFEC) : kInk,
        outlineVariant: dark ? kLineDark : kLn,
      );
  final outline = dark ? kLineDark : kLn;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? kBgDark : kBg,
    fontFamily: 'Roboto',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: dark ? const Color(0xFF294A43) : kLt,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (_, _) => MaterialApp(
      title: 'FITTRACK',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: store.on('dark') ? ThemeMode.dark : ThemeMode.light,
      home: store.d['user'] == null ? const AuthScreen() : const Shell(),
    ),
  );
}
