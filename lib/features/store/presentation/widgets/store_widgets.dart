import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Colour swatches standing in for product photos until image upload exists.
const _swatches = [Color(0xFF2E6B5A), Color(0xFFB4532A), Color(0xFF7A4BA0), Color(0xFFC08A12), Color(0xFF2F5D9E), Color(0xFF8C2F4B)];
const _icons = [Icons.checkroom, Icons.texture, Icons.dry_cleaning, Icons.diamond_outlined, Icons.shopping_bag_outlined, Icons.watch_outlined];

class ProductThumb extends StatelessWidget {
  final int? photo;
  final double size;
  final VoidCallback? onRemove;
  const ProductThumb({super.key, this.photo, this.size = 44, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final i = photo;
    final thumb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: i == null ? p.cardAlt : _swatches[i % _swatches.length],
        borderRadius: BorderRadius.circular(size * 0.18),
        gradient: i == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_swatches[i % _swatches.length], Color.lerp(_swatches[i % _swatches.length], Colors.black, 0.35)!],
              ),
      ),
      child: Icon(i == null ? Icons.image_outlined : _icons[i % _icons.length], color: i == null ? p.textMuted : Colors.white70, size: size * 0.45),
    );
    if (onRemove == null) return thumb;
    return Stack(clipBehavior: Clip.none, children: [
      thumb,
      Positioned(
        top: -6,
        right: -6,
        child: InkWell(
          onTap: onRemove,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 13, color: Colors.white),
          ),
        ),
      ),
    ]);
  }
}

/// "Add Logo" / "Add Banner" / "Add Photo" source picker. Returns true when
/// the user picked a source (camera/gallery access needs `image_picker`).
Future<bool> showImageSourceSheet(BuildContext context, {String title = 'Add Logo'}) async {
  final picked = await showBpSheet<bool>(
    context,
    title: title,
    builder: (ctx) {
      final p = ctx.p;
      Widget option(IconData icon, String label) => Expanded(
            child: InkWell(
              onTap: () => Navigator.pop(ctx, true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
                    child: Icon(icon, size: 30, color: p.brand),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: tx(ctx, 12.5, color: p.textSecondary)),
                ]),
              ),
            ),
          );
      return Row(children: [option(Icons.photo_camera_outlined, 'Take a photo'), option(Icons.photo_library_outlined, 'Choose from Gallery')]);
    },
  );
  return picked ?? false;
}

/// Quantity − n + stepper used on the product form.
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const QuantityStepper({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget btn(IconData icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: onTap == null ? p.border : p.brand)),
            child: Icon(icon, size: 15, color: onTap == null ? p.textMuted : p.brand),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border, width: 1.2)),
      child: Row(children: [
        Expanded(child: Text('$value', style: tx(context, 14, weight: FontWeight.w700))),
        btn(Icons.remove, value > 0 ? () => onChanged(value - 1) : null),
        const SizedBox(width: 10),
        btn(Icons.add, () => onChanged(value + 1)),
      ]),
    );
  }
}

/// Label + switch row ("Show on storefront").
class ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const ToggleRow({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tx(context, 13, weight: FontWeight.w600)),
            if (subtitle != null) Text(subtitle!, style: tx(context, 11.5, color: p.textMuted)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}
