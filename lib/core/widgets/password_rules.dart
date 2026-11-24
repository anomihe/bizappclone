import 'package:flutter/material.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

class PasswordRules {
  static final rules = <(String, bool Function(String))>[
    ('8+ Characters', (s) => s.length >= 8),
    ('Uppercase (A-Z)', (s) => RegExp(r'[A-Z]').hasMatch(s)),
    ('Lowercase (a-z)', (s) => RegExp(r'[a-z]').hasMatch(s)),
    ('Number (0-9)', (s) => RegExp(r'[0-9]').hasMatch(s)),
    ('Special (!@#\$…)', (s) => RegExp(r'[^A-Za-z0-9]').hasMatch(s)),
  ];

  static bool isValid(String s) => rules.every((r) => r.$2(s));
}

/// Checklist under password fields; each rule turns green when met.
class PasswordRulesView extends StatelessWidget {
  final String password;
  const PasswordRulesView({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final r in PasswordRules.rules)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(r.$2(password) ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14, color: r.$2(password) ? p.brand : p.textMuted),
            const SizedBox(width: 4),
            Text(r.$1, style: tx(context, 11, color: r.$2(password) ? p.text : p.textMuted)),
          ]),
      ],
    );
  }
}
