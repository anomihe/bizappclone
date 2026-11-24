import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Layout shared by every auth frame: X + logo bar, title, subtitle,
/// scrollable form and a pinned footer.
///
/// Responsive: the form is capped at a comfortable width on tablets/desktop,
/// and on short screens (phone landscape) the footer scrolls with the form
/// instead of permanently taking up half the height.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool showClose;
  final Widget? header;

  const AuthScaffold({super.key, required this.title, this.subtitle, required this.children, this.footer, this.showClose = true, this.header});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final short = context.isShort;
    final footerWidget = footer == null ? null : Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: footer);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ContentWidth(
          maxWidth: Breakpoints.form,
          child: Column(children: [
            AuthTopBar(showClose: showClose),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, short ? 8 : 20, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ?header,
                  Text(title, style: tx(context, 22, weight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: tx(context, 13, color: p.textSecondary, height: 1.45)),
                  ],
                  SizedBox(height: short ? 14 : 22),
                  ...children,
                  if (short && footerWidget != null) ...[const SizedBox(height: 8), footer!],
                ]),
              ),
            ),
            if (!short) ?footerWidget,
          ]),
        ),
      ),
    );
  }
}
