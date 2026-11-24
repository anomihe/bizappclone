import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/ui_kit.dart';

String themeModeLabel(ThemeMode m) => switch (m) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };

/// More → Appearance: pick Light, Dark or follow the device, with previews.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = context.p;
        final options = [
          (ThemeMode.light, 'Bright and clear, best in daylight.'),
          (ThemeMode.dark, 'Easier on the eyes at night and saves battery.'),
          (ThemeMode.system, 'Match your phone’s setting automatically.'),
        ];
        return InnerScaffold(
          title: 'Appearance',
          subtitle: 'Choose how Bizpaddi looks on this device',
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(builder: (context, c) {
              // Previews side by side when there is room, stacked otherwise.
              final cols = c.maxWidth >= 520 ? 3 : 1;
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final (mode, blurb) in options)
                  SizedBox(
                    width: w,
                    child: _ThemeOption(
                      mode: mode,
                      blurb: blurb,
                      selected: controller.themeMode == mode,
                      compact: cols == 1,
                      onTap: () => controller.setThemeMode(mode),
                    ),
                  ),
              ]);
            }),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.info_outline, size: 14, color: p.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text('Your choice is saved on this device.', style: tx(context, 11.5, color: p.textMuted))),
            ]),
          ]),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final String blurb;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _ThemeOption({required this.mode, required this.blurb, required this.selected, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final preview = switch (mode) {
      ThemeMode.light => const _MiniPhone(dark: false),
      ThemeMode.dark => const _MiniPhone(dark: true),
      ThemeMode.system => const Row(mainAxisSize: MainAxisSize.min, children: [
          _MiniPhone(dark: false, half: true),
          _MiniPhone(dark: true, half: true),
        ]),
    };
    final label = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(themeModeLabel(mode), style: tx(context, 14, weight: FontWeight.w800))),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(selected),
            size: 20,
            color: selected ? p.brand : p.textMuted,
          ),
        ),
      ]),
      const SizedBox(height: 2),
      Text(blurb, style: tx(context, 12, color: p.textSecondary, height: 1.35)),
    ]);

    return Semantics(
      selected: selected,
      button: true,
      label: '${themeModeLabel(mode)} theme',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? p.primarySoft : p.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.brand : p.border, width: selected ? 1.6 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: compact
                  ? Row(children: [preview, const SizedBox(width: 14), Expanded(child: label)])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: preview), const SizedBox(height: 12), label]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny schematic of the home screen in the given mode.
class _MiniPhone extends StatelessWidget {
  final bool dark;
  final bool half;
  const _MiniPhone({required this.dark, this.half = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette(dark);
    Widget bar(double w, Color c, [double h = 5]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));
    final width = half ? 34.0 : 60.0;
    return Container(
      width: width,
      height: 88,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: half
            ? BorderRadius.horizontal(left: Radius.circular(dark ? 0 : 10), right: Radius.circular(dark ? 10 : 0))
            : BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        bar(width * 0.5, p.text.withValues(alpha: 0.7)),
        const SizedBox(height: 6),
        Container(height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: Container(height: 14, decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(width: 3),
          Expanded(child: Container(height: 14, decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(3)))),
        ]),
        const Spacer(),
        Align(alignment: Alignment.centerRight, child: bar(width * 0.4, AppColors.accent, 7)),
      ]),
    );
  }
}
