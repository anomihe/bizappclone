import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models.dart';
import '../layout/responsive.dart';

export '../layout/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import 'bizpaddi_logo.dart';
import 'custom_button.dart';

/// Shorthand for Figtree text styles.
TextStyle tx(BuildContext context, double size, {FontWeight weight = FontWeight.w500, Color? color, double? height}) =>
    GoogleFonts.figtree(fontSize: size, fontWeight: weight, color: color ?? context.p.text, height: height);

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primaryDark,
      duration: const Duration(milliseconds: 1600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
}

// ------------------------------------------------------------------ buttons

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? color;
  final String? tooltip;

  const CircleIconButton({super.key, required this.icon, this.onTap, this.size = 36, this.background, this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final btn = Material(
      color: background ?? p.card,
      shape: CircleBorder(side: BorderSide(color: background == null ? p.border : Colors.transparent)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: color ?? p.text)),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Close (X) on the left and the Bizpaddi mark on the right, used across auth.
class AuthTopBar extends StatelessWidget {
  final bool showClose;
  final VoidCallback? onClose;
  const AuthTopBar({super.key, this.showClose = true, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          if (showClose)
            CircleIconButton(icon: Icons.close, size: 32, onTap: onClose ?? () => Navigator.maybePop(context), tooltip: 'Close'),
          const Spacer(),
          const BizpaddiLogo(size: 26),
        ],
      ),
    );
  }
}

/// Dashed outline button ("Choose or Add a customer").
class DashedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const DashedButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _DashedRectPainter(color: p.textMuted),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: Row(children: [
            Icon(icon, size: 18, color: p.textSecondary),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: tx(context, 13.5, color: p.textSecondary))),
          ]),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) => old.color != color;
}

// ------------------------------------------------------------------ layout

/// Root header for bottom-nav tabs, with the soft gold/green gradient.
class TabHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? bottom;
  final double maxWidth;
  const TabHeader({super.key, required this.title, this.trailing, this.bottom, this.maxWidth = Breakpoints.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: context.p.headerGradient),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: maxWidth,
          child: Padding(
          padding: EdgeInsets.fromLTRB(20, context.isShort ? 8 : 14, 20, context.isShort ? 8 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(title, style: tx(context, 22, weight: FontWeight.w800))),
                ?trailing,
              ]),
              if (bottom != null) ...[const SizedBox(height: 14), bottom!],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Rounded content panel under a [TabHeader], width-capped on large screens.
class TabPanel extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const TabPanel({super.key, required this.child, this.maxWidth = Breakpoints.content});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ContentWidth(
      maxWidth: maxWidth,
      child: Container(
        decoration: BoxDecoration(color: p.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Inner screen: back button, title block, white body panel and optional
/// sticky bottom bar. Matches the "Payments Details", "New Invoice" frames.
class InnerScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottom;
  final bool scroll;
  final EdgeInsets bodyPadding;
  final IconData leadingIcon;

  const InnerScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.actions = const [],
    required this.body,
    this.bottom,
    this.scroll = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
    this.leadingIcon = Icons.arrow_back,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final short = context.isShort;

    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        CircleIconButton(icon: leadingIcon, onTap: () => Navigator.maybePop(context), tooltip: 'Back'),
        // On short screens the title sits inline with the back button to save height.
        if (short) ...[
          const SizedBox(width: 12),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 17, weight: FontWeight.w800))),
          if (titleTrailing != null) ...[titleTrailing!, const SizedBox(width: 8)],
        ] else
          const Spacer(),
        ...actions,
      ]),
    );

    final bottomBar = bottom == null
        ? null
        : Container(
            color: p.card,
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: bottom,
          );

    // Phone landscape: one scroll for body + actions so the form keeps usable height.
    if (short && scroll) {
      return Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: Column(children: [
              topBar,
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: p.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (subtitle != null) Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Text(subtitle!, style: tx(context, 12.5, color: p.textSecondary))),
                      Padding(padding: bodyPadding, child: body),
                      ?bottomBar,
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            if (short) const SizedBox(height: 8) else Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: tx(context, 20, weight: FontWeight.w800)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, style: tx(context, 12.5, color: p.textSecondary)),
                      ],
                    ]),
                  ),
                  ?titleTrailing,
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: scroll ? SingleChildScrollView(padding: bodyPadding, child: body) : Padding(padding: bodyPadding, child: body),
              ),
            ),
            ?bottomBar,
          ],
        ),
        ),
      ),
    );
  }
}

class BpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  const BpCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.borderColor, this.onTap, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: color ?? p.cardAlt,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: tx(context, 11, weight: FontWeight.w700, color: context.p.textMuted).copyWith(letterSpacing: 0.8)),
        ),
        ?trailing,
      ]),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool bold;

  const InfoRow({super.key, required this.label, this.value, this.valueWidget, this.valueColor, this.onTap, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        // Both sides loose + spaceBetween keeps values flush right while long
        // labels and values can still wrap on narrow screens.
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(flex: 2, child: Text(label, style: tx(context, 13, color: p.textSecondary))),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(value ?? '',
                      textAlign: TextAlign.right,
                      style: tx(context, 13, weight: bold ? FontWeight.w800 : FontWeight.w700, color: valueColor)),
            ),
          ),
          if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, size: 18, color: valueColor ?? p.textMuted)],
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ data display

/// "₦37,000.00" with the kobo part rendered lighter, as in the designs.
class MoneyText extends StatelessWidget {
  final num value;
  final double size;
  final Color? color;
  final FontWeight weight;
  const MoneyText(this.value, {super.key, this.size = 15, this.color, this.weight = FontWeight.w800});

  @override
  Widget build(BuildContext context) {
    final (main, dec) = Fmt.moneyParts(value);
    final c = color ?? context.p.text;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: main, style: tx(context, size, weight: weight, color: c)),
        TextSpan(text: dec, style: tx(context, size * 0.62, weight: FontWeight.w600, color: c.withValues(alpha: 0.55))),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class StatusPill extends StatelessWidget {
  final StatusStyle style;
  final bool dot;
  const StatusPill(this.style, {super.key, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final c = p.readable(style.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: p.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 5, height: 5, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
        ],
        Flexible(child: Text(style.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 10.5, weight: FontWeight.w700, color: c))),
      ]),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialsAvatar(this.name, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.p.primarySoft, shape: BoxShape.circle),
      child: Text(Fmt.initials(name), style: tx(context, size * 0.34, weight: FontWeight.w800, color: context.p.brand)),
    );
  }
}

/// Square tinted icon used at the start of list rows.
class LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  const LeadingIcon(this.icon, {super.key, this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.p.brand;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: size * 0.5, color: c),
    );
  }
}

/// Generic list row: icon, title/subtitle, amount + status on the right.
class RecordTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final num amount;
  final StatusStyle? status;
  final VoidCallback? onTap;
  final Widget? footer;

  const RecordTile({super.key, required this.leading, required this.title, required this.subtitle, required this.amount, this.status, this.onTap, this.footer});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BpCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(children: [
          Row(children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 13.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: p.textMuted)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              MoneyText(amount, size: 13.5),
              if (status != null) ...[const SizedBox(height: 4), StatusPill(status!, dot: true)],
            ]),
          ]),
          ?footer,
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          Container(width: 92, height: 72, decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(40))),
          Icon(icon, size: 40, color: p.textMuted),
        ]),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: tx(context, 14, weight: FontWeight.w700)),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(message!, textAlign: TextAlign.center, style: tx(context, 12.5, color: p.textSecondary, height: 1.4)),
        ],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoBanner(this.text, {super.key, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: context.p.infoSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 16, color: context.p.info),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: tx(context, 12, color: context.p.info, weight: FontWeight.w600))),
      ]),
    );
  }
}

// ------------------------------------------------------------------ inputs

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Widget? trailing;
  const SearchField({super.key, required this.hint, required this.onChanged, this.controller, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: tx(context, 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tx(context, 13.5, color: p.textMuted),
        isDense: true,
        filled: true,
        fillColor: p.card,
        prefixIcon: Icon(Icons.search, size: 19, color: p.textMuted),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.brand)),
      ),
    );
  }
}

class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final IconData? icon;
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap, this.trailing, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.primarySoft : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? context.p.brand : p.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: selected ? context.p.brand : p.textSecondary), const SizedBox(width: 4)],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: tx(context, 12, weight: FontWeight.w600, color: selected ? context.p.brand : p.textSecondary)),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ]),
      ),
    );
  }
}

/// Green filled pill segmented control ("Invoices | Quotations", "7 Days | 30 Days").
class SegmentedPills extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;
  final bool expand;
  final double fontSize;
  const SegmentedPills({super.key, required this.options, required this.index, required this.onChanged, this.expand = true, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget item(int i) {
      final sel = i == index;
      return GestureDetector(
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: fontSize * 0.6, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(20)),
          child: Text(options[i], style: tx(context, fontSize, weight: FontWeight.w700, color: sel ? Colors.white : p.textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.border)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (var i = 0; i < options.length; i++) expand ? Expanded(child: item(i)) : item(i)],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final Widget? trailing;
  const ActionTile({super.key, required this.icon, required this.title, this.subtitle, required this.onTap, this.danger = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final c = danger ? AppColors.error : p.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BpCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(children: [
          LeadingIcon(icon, color: danger ? AppColors.error : p.textSecondary, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(context, 13.5, weight: FontWeight.w700, color: c)),
              if (subtitle != null) Text(subtitle!, style: tx(context, 11.5, color: p.textMuted)),
            ]),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
          Icon(Icons.chevron_right, size: 20, color: danger ? AppColors.error : p.textMuted),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ sheets

/// Bottom sheet with a title row and close button, as in every sheet frame.
Future<T?> showBpSheet<T>(BuildContext context, {String? title, required Widget Function(BuildContext) builder, bool showHandle = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = ctx.p;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: p.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + MediaQuery.of(ctx).padding.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (showHandle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Expanded(child: Text(title, style: tx(ctx, 15.5, weight: FontWeight.w800))),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    customBorder: const CircleBorder(),
                    child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 20, color: p.textSecondary)),
                  ),
                ]),
              ),
            // Scrolls when the sheet is taller than the screen (phone landscape).
            Flexible(child: SingleChildScrollView(child: builder(ctx))),
          ]),
        ),
      );
    },
  );
}

/// Warning confirm sheet ("Void invoice #0043?", "Cancel this payment link?").
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Keep It',
  IconData icon = Icons.warning_amber_rounded,
  bool danger = true,
}) async {
  final result = await showBpSheet<bool>(
    context,
    showHandle: true,
    builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: danger ? ctx.p.errorSoft : ctx.p.primarySoft, shape: BoxShape.circle),
        child: Icon(icon, color: danger ? ctx.p.error : ctx.p.brand, size: 28),
      ),
      const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, style: tx(ctx, 16, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center, style: tx(ctx, 12.5, color: ctx.p.textSecondary, height: 1.4)),
      const SizedBox(height: 20),
      CustomButton(text: confirmLabel, variant: danger ? ButtonVariant.danger : ButtonVariant.primary, onPressed: () => Navigator.pop(ctx, true)),
      const SizedBox(height: 10),
      CustomButton(text: cancelLabel, variant: ButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false)),
    ]),
  );
  return result ?? false;
}

/// Success sheet ("Refund request submitted!").
Future<void> showSuccessSheet(BuildContext context, {required String title, required String message, required String actionLabel, required VoidCallback onAction}) {
  return showBpSheet(
    context,
    showHandle: true,
    builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: ctx.p.primarySoft, shape: BoxShape.circle),
        child: Icon(Icons.check_circle, color: context.p.brand, size: 34),
      ),
      const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, style: tx(ctx, 16, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center, style: tx(ctx, 12.5, color: ctx.p.textSecondary, height: 1.4)),
      const SizedBox(height: 20),
      CustomButton(
        text: actionLabel,
        variant: ButtonVariant.soft,
        onPressed: () {
          Navigator.pop(ctx);
          onAction();
        },
      ),
    ]),
  );
}
