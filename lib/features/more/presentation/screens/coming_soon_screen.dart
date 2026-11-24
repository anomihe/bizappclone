import 'package:flutter/material.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Placeholder for destinations that exist in the menu but have no design yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: title,
      scroll: false,
      body: const Center(
        child: EmptyState(
          icon: Icons.construction_outlined,
          title: 'Coming soon',
          message: "We're still putting this together. Check back soon.",
        ),
      ),
    );
  }
}
