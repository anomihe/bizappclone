import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../theme/theme_controller.dart';

/// Round sun / moon button that flips light ⇄ dark with a rotating icon.
class ThemeToggleButton extends StatelessWidget {
  final double size;
  const ThemeToggleButton({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: dark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: p.card,
        shape: CircleBorder(side: BorderSide(color: p.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ThemeController.instance.toggleTheme(Theme.of(context).brightness),
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.6, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(dark),
                size: size * 0.5,
                color: dark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
