import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/store_widgets.dart';
import 'categories_screen.dart';

/// "Add product" and editing an existing product.
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final store = BizStore.instance;
  late final Product? _editing = widget.product;
  late final _name = TextEditingController(text: _editing?.name ?? '');
  late final _price = TextEditingController(text: _editing == null ? '' : _editing.price.toStringAsFixed(0));
  late final _discount = TextEditingController(text: (_editing?.discount ?? 0) > 0 ? _editing!.discount.toStringAsFixed(0) : '');
  late final _description = TextEditingController(text: _editing?.description ?? '');
  late List<int> _photos = [...?_editing?.photos];
  late String? _categoryId = _editing?.categoryId;
  late int _qty = _editing?.quantity ?? 0;
  late bool _visible = _editing?.showOnStorefront ?? true;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _discount.dispose();
    _description.dispose();
    super.dispose();
  }

  double get _priceValue => double.tryParse(_price.text) ?? 0;
  double get _discountValue => double.tryParse(_discount.text) ?? 0;
  bool get _discountInvalid => _discountValue > 0 && _discountValue >= _priceValue;
  bool get _valid => _name.text.trim().isNotEmpty && _priceValue > 0 && !_discountInvalid;

  Future<void> _addPhoto() async {
    if (_photos.length >= 3) return;
    final ok = await showImageSourceSheet(context, title: 'Add Photo');
    if (ok) setState(() => _photos = [..._photos, DateTime.now().millisecond % 6]);
  }

  Future<void> _pickCategory() async {
    final picked = await showBpSheet<String>(
      context,
      title: 'Select Category',
      builder: (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final c in store.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BpCard(
                onTap: () => Navigator.pop(ctx, c.id),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  Expanded(child: Text(c.name, style: tx(ctx, 13.5, weight: FontWeight.w600))),
                  Icon(c.id == _categoryId ? Icons.check_circle : Icons.chevron_right, size: 20, color: c.id == _categoryId ? ctx.p.brand : ctx.p.textMuted),
                ]),
              ),
            ),
          const SizedBox(height: 4),
          CustomButton(
            text: 'Add new Category',
            variant: ButtonVariant.outline,
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await showAddCategorySheet(ctx);
              if (created != null && ctx.mounted) Navigator.pop(ctx, created.id);
            },
          ),
        ]),
      ),
    );
    if (picked != null) setState(() => _categoryId = picked);
  }

  void _save() {
    final p = _editing ?? store.newProductDraft();
    p
      ..name = _name.text.trim()
      ..price = _priceValue
      ..discount = _discountValue
      ..categoryId = _categoryId
      ..quantity = _qty
      ..description = _description.text.trim()
      ..photos = _photos
      ..showOnStorefront = _visible;
    if (_editing == null) {
      store.addProduct(p);
    } else {
      store.updateProduct(p);
    }
    showToast(context, _editing == null ? 'Product added' : 'Product updated');
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete ${_editing!.name}?',
      message: 'It disappears from your storefront straight away. Past orders keep their details.',
      confirmLabel: 'Delete Product',
    );
    if (ok && mounted) {
      store.deleteProduct(_editing);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final category = store.categoryById(_categoryId);
    final numeric = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
        );

    return InnerScaffold(
      title: _editing == null ? 'Add product' : 'Edit product',
      actions: [
        if (_editing != null) CircleIconButton(icon: Icons.delete_outline, color: p.error, tooltip: 'Delete product', onTap: _delete),
      ],
      bottom: CustomButton(text: _editing == null ? 'Add Product' : 'Save Changes', onPressed: _valid ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        label(_photos.isEmpty ? 'Photos' : 'Product photos'),
        if (_photos.isEmpty)
          InkWell(
            onTap: _addPhoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 96,
              decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, color: p.textSecondary),
                const SizedBox(height: 6),
                Text('Add Photo', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
              ]),
            ),
          )
        else
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (var i = 0; i < _photos.length; i++)
              ProductThumb(photo: _photos[i], size: 72, onRemove: () => setState(() => _photos = [..._photos]..removeAt(i))),
            if (_photos.length < 3)
              InkWell(
                onTap: _addPhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, size: 20, color: p.textSecondary),
                    Text('Add photo', style: tx(context, 10.5, color: p.textSecondary)),
                  ]),
                ),
              ),
          ]),
        const SizedBox(height: 6),
        Text('Up to 3 photos. Camera and gallery access are asked only when you add one.', style: tx(context, 11, color: p.textMuted)),
        const SizedBox(height: 16),
        CustomTextField(label: 'Product Name', hint: 'Enter product name', controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(label: 'Price', hint: '0', prefixText: '₦ ', controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: numeric, onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Discount Price (optional)',
          hint: '0',
          prefixText: '₦ ',
          controller: _discount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: numeric,
          errorText: _discountInvalid ? 'Discount must be less than the price' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        label('Category'),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _pickCategory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border, width: 1.2)),
            child: Row(children: [
              Expanded(child: Text(category?.name ?? 'Select Category', style: tx(context, 14, color: category == null ? p.textMuted : p.text))),
              Icon(Icons.keyboard_arrow_down, color: p.textSecondary),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        label('Stock quantity'),
        QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
        const SizedBox(height: 14),
        CustomTextField(label: 'Description', hint: 'Product description here', controller: _description, maxLines: 4),
        const SizedBox(height: 10),
        ToggleRow(
          title: _editing == null ? 'Show on storefront' : 'Publish to store',
          subtitle: 'Customers can see and buy this item.',
          value: _visible,
          onChanged: (v) => setState(() => _visible = v),
        ),
      ]),
    );
  }
}
