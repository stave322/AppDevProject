import 'package:flutter/material.dart';

import '../store/store.dart';

Widget live(Widget Function(BuildContext) f) =>
    ListenableBuilder(listenable: store, builder: (c, _) => f(c));

Widget card({
  required Widget child,
  Color? color,
  VoidCallback? onTap,
  EdgeInsets? pad,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Builder(
    builder: (context) => Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: color == null
            ? BorderSide(color: Theme.of(context).colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: pad ?? const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    ),
  ),
);

Widget bar(double p, {bool dark = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Builder(
    builder: (context) => ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: LinearProgressIndicator(
        value: p.clamp(0.0, 1.0),
        minHeight: 6,
        color: dark ? kMint : primaryOf(context),
        backgroundColor: dark
            ? Colors.white24
            : (isDark(context) ? kLineDark : kLn),
      ),
    ),
  ),
);

Widget btn(
  String label,
  VoidCallback f, {
  bool tonal = false,
  bool danger = false,
}) => _AnimatedButton(label: label, onPressed: f, tonal: tonal, danger: danger);

class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool tonal;
  final bool danger;

  const _AnimatedButton({
    required this.label,
    required this.onPressed,
    required this.tonal,
    required this.danger,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final primary = primaryOf(context);
    final foreground = widget.danger
        ? kRed
        : (widget.tonal ? primary : (dark ? kInk : Colors.white));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: widget.danger
          ? const BorderSide(color: kRed, width: 1.2)
          : BorderSide.none,
    );

    return SizedBox(
      width: double.infinity,
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            child: Ink(
              decoration: ShapeDecoration(
                color: widget.danger
                    ? Colors.transparent
                    : (widget.tonal ? tintOf(context) : primary),
                shape: shape,
              ),
              child: SizedBox(
                height: 50,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget tag(String s) => Builder(
  builder: (context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: tintOf(context),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      s,
      style: TextStyle(
        color: primaryOf(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
);

Widget h3(String s, {Widget? trailing}) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        s,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      ?trailing,
    ],
  ),
);

Widget hdr(
  BuildContext c,
  String k,
  String t, {
  bool back = false,
  List<Widget> act = const [],
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (back || act.isNotEmpty)
      Row(
        children: [
          if (back)
            CircleAvatar(
              backgroundColor: Theme.of(c).colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(c),
              ),
            ),
          const Spacer(),
          ...act,
        ],
      ),
    const SizedBox(height: 6),
    Text(
      k.toUpperCase(),
      style: TextStyle(
        color: primaryOf(c),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
    Text(
      t,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: Theme.of(c).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 14),
  ],
);

Widget screen(List<Widget> kids) => Scaffold(
  body: SafeArea(
    child: ListView(padding: const EdgeInsets.all(16), children: kids),
  ),
);
Widget tabBody(List<Widget> kids) => SafeArea(
  child: ListView(padding: const EdgeInsets.all(16), children: kids),
);
PageRoute<T> _animatedRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, _, _) => page,
  transitionDuration: const Duration(milliseconds: 300),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.045, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);

void go(BuildContext c, Widget w) {
  Navigator.push(c, _animatedRoute<void>(w));
}

Future<T?> goForResult<T>(BuildContext c, Widget w) =>
    Navigator.push<T>(c, _animatedRoute<T>(w));
void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Future<bool> confirm(BuildContext c, String title, String ok) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: primaryOf(c),
              foregroundColor: Theme.of(c).colorScheme.onPrimary,
            ),
            child: Text(ok),
          ),
        ],
      ),
    ) ??
    false;

class F {
  final String k, label, v, type;
  final List<String> opts;
  F(this.k, this.label, this.v, {this.type = 'text', this.opts = const []});
}

Future<Map<String, String>?> form(
  BuildContext c,
  String title,
  List<F> fs, {
  String ok = 'Save',
}) async {
  final ctl = {for (final f in fs) f.k: TextEditingController(text: f.v)};
  Widget buildField(BuildContext dc, F f) => f.type == 'choice'
      ? StatefulBuilder(
          builder: (ctx, ss) => DropdownButtonFormField<String>(
            initialValue: ctl[f.k]!.text,
            decoration: InputDecoration(labelText: f.label),
            items: [
              for (final o in f.opts)
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: (v) {
              if (v != null) ss(() => ctl[f.k]!.text = v);
            },
          ),
        )
      : TextField(
          controller: ctl[f.k],
          readOnly: f.type == 'date' || f.type == 'time',
          obscureText: f.type == 'pass',
          keyboardType: f.type == 'number'
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(labelText: f.label),
          onTap: () async {
            if (f.type == 'date') {
              final p = await showDatePicker(
                context: dc,
                initialDate:
                    DateTime.tryParse(ctl[f.k]!.text) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (p != null) ctl[f.k]!.text = isoOf(p);
            } else if (f.type == 'time') {
              final parts = ctl[f.k]!.text.split(':');
              final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
              final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
              final p = await showTimePicker(
                context: dc,
                initialTime: TimeOfDay(hour: hour ?? 18, minute: minute ?? 0),
              );
              if (p != null) {
                ctl[f.k]!.text =
                    '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
              }
            }
          },
        );
  try {
    return await showDialog<Map<String, String>>(
      context: c,
      builder: (dc) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fs.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                buildField(dc, fs[i]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dc, {
              for (final e in ctl.entries) e.key: e.value.text,
            }),
            style: FilledButton.styleFrom(
              backgroundColor: primaryOf(dc),
              foregroundColor: Theme.of(dc).colorScheme.onPrimary,
            ),
            child: Text(ok),
          ),
        ],
      ),
    );
  } finally {
    for (final controller in ctl.values) {
      controller.dispose();
    }
  }
}

double num_(String? s) => double.tryParse(s ?? '') ?? 0;

void showNotes(BuildContext c) {
  final l = store.notes();
  showModalBottomSheet(
    context: c,
    backgroundColor: Theme.of(c).colorScheme.surface,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (l.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('All caught up 🎉'),
              ),
            for (final n in l)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(n[0], style: const TextStyle(fontSize: 24)),
                title: Text(
                  n[1],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(n[2]),
              ),
            btn('Close', () => Navigator.pop(c)),
          ],
        ),
      ),
    ),
  );
}
