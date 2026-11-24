import 'package:flutter/material.dart';

/// Width breakpoints (Material 3 window size classes).
class Breakpoints {
  /// Phones in portrait.
  static const double medium = 600;

  /// Tablets in landscape, desktop, phones in landscape — switch to a side rail.
  static const double expanded = 840;

  /// Comfortable reading widths.
  static const double form = 480;
  static const double content = 720;
  static const double dashboard = 1120;
}

extension ResponsiveX on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isCompact => screenSize.width < Breakpoints.medium;
  bool get isExpanded => screenSize.width >= Breakpoints.expanded;

  /// Short screens (phone landscape) where vertical space is precious.
  bool get isShort => screenSize.height < 500;
}

/// Centers [child] and caps its width so content doesn't stretch across
/// tablets and desktop windows. A no-op on phones.
class ContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final Alignment alignment;
  const ContentWidth({super.key, this.maxWidth = Breakpoints.content, required this.child, this.alignment = Alignment.topCenter});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// For layouts built from a Column with Spacers (success / biometric screens):
/// fills the viewport on tall screens, scrolls instead of overflowing on short ones.
class FillScroll extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const FillScroll({super.key, required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (c.maxHeight - padding.vertical).clamp(0, double.infinity)),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
