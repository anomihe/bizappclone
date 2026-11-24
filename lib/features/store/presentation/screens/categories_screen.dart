import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';

/// "Add New Category" sheet. Returns the created category.
Future<ProductCategory?> showAddCategorySheet(BuildContext context) {
  return showBpSheet<ProductCategory>(context, title: 'Add New Category', builder: (_) => const _AddCategoryForm());
}

class _AddCategoryForm extends StatefulWidget {
  const _AddCategoryForm();
  @override
  State<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<_AddCategoryForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error {
    final n = _name.text.trim().toLowerCase();
    if (n.isEmpty) return null;
    return BizStore.instance.categories.any((c) => c.name.toLowerCase() == n) ? 'This category already exists' : null;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _name.text.trim().isNotEmpty && _error == null;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CustomTextField(
        label: 'Category',
        hint: 'Enter category name',
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        errorText: _error,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 18),
      CustomButton(text: 'Add', onPressed: valid ? () => Navigator.pop(context, BizStore.instance.addCategory(_name.text)) : null),
    ]);
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        return InnerScaffold(
          title: 'Categories',
          bottom: CustomButton(text: 'New Category', onPressed: () => showAddCategorySheet(context)),
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (store.categories.isEmpty)
              const EmptyState(icon: Icons.category_outlined, title: 'No categories yet', message: 'Group your products so customers find them faster.')
            else
              for (final c in store.categories)
                Builder(builder: (context) {
                  final count = store.productCountIn(c);
                  final canRemove = count == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BpCard(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: tx(context, 13.5, weight: FontWeight.w700)),
                            Text('$count Product${count == 1 ? '' : 's'}', style: tx(context, 11.5, color: p.textMuted)),
                          ]),
                        ),
                        TextButton.icon(
                          onPressed: canRemove
                              ? () async {
                                  final ok = await showConfirmSheet(context, title: 'Remove ${c.name}?', message: 'You can add it again any time.', confirmLabel: 'Remove');
                                  if (ok) store.removeCategory(c);
                                }
                              : null,
                          icon: Icon(Icons.delete_outline, size: 16, color: canRemove ? p.error : p.textMuted.withValues(alpha: 0.5)),
                          label: Text('Remove', style: tx(context, 12, weight: FontWeight.w600, color: canRemove ? p.error : p.textMuted.withValues(alpha: 0.5))),
                        ),
                      ]),
                    ),
                  );
                }),
            const SizedBox(height: 6),
            Text('A category with products in it cannot be removed.', textAlign: TextAlign.center, style: tx(context, 11.5, color: p.textMuted)),
          ]),
        );
      },
    );
  }
}
