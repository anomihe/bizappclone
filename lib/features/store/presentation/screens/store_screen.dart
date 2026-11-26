import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/utils/pick_file.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../invoices/presentation/widgets/invoice_sheets.dart';
import '../widgets/store_widgets.dart';
import 'categories_screen.dart';
import 'custom_domain_screen.dart';
import 'edit_storefront_screen.dart';
import 'product_form_screen.dart';

/// More → Store Front & Products: Products | Storefront tabs.
class StoreScreen extends StatefulWidget {
  final int initialTab;
  const StoreScreen({super.key, this.initialTab = 0});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final store = BizStore.instance;
  late int _tab = widget.initialTab;
  String _q = '';
  String? _category; // null = All

  void _addProduct() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => InnerScaffold(
        title: 'Store Front & Products',
        scroll: false,
        bodyPadding: EdgeInsets.zero,
        titleTrailing: CircleIconButton(
          icon: _tab == 0 ? Icons.add : Icons.storefront_outlined,
          background: AppColors.primary,
          color: Colors.white,
          tooltip: _tab == 0 ? 'Add product' : 'Copy store link',
          onTap: _tab == 0
              ? _addProduct
              : () {
                  Clipboard.setData(ClipboardData(text: 'https://${store.storefront.link}'));
                  showToast(context, 'Store link copied');
                },
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SegmentedPills(
              options: [store.products.isEmpty ? 'Products' : 'Products (${store.products.length})', 'Storefront'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(child: _tab == 0 ? _products() : const _StorefrontTab()),
        ]),
      ),
    );
  }

  Widget _products() {
    final p = context.p;
    final q = _q.toLowerCase();
    final list = store.products
        .where((x) => (_category == null || x.categoryId == _category) && (q.isEmpty || x.name.toLowerCase().contains(q) || x.sku.toLowerCase().contains(q)))
        .toList();

    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
      SearchField(hint: 'Search products', onChanged: (v) => setState(() => _q = v)),
      const SizedBox(height: 10),
      SizedBox(
        height: 34,
        child: Row(children: [
          Expanded(
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null))),
              for (final c in store.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SelectChip(label: c.name, selected: _category == c.id, onTap: () => setState(() => _category = c.id)),
                ),
            ]),
          ),
          CircleIconButton(
            icon: Icons.tune,
            size: 34,
            tooltip: 'Manage categories',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      if (store.products.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Product Here',
            action: CustomButton(text: 'Create a New Product', variant: ButtonVariant.accent, icon: const Icon(Icons.add), width: 230, height: 42, onPressed: _addProduct),
          ),
        )
      else if (list.isEmpty)
        const Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.search_off, title: 'No matching products'))
      else
        for (final x in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BpCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: x))),
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                ProductThumb(photo: x.photos.isEmpty ? null : x.photos.first, url: x.imageUrl, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(x.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 13.5, weight: FontWeight.w700)),
                    Text([if (x.unitLabel.isNotEmpty) x.unitLabel, x.sku].join(' · '), style: tx(context, 11.5, color: p.textMuted)),
                    const SizedBox(height: 2),
                    MoneyText(x.salePrice, size: 13.5),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusPill(BizStatus.stock(x.stock)),
                  if (!x.showOnStorefront) ...[
                    const SizedBox(height: 4),
                    Text('Hidden', style: tx(context, 10.5, color: p.textMuted)),
                  ],
                ]),
              ]),
            ),
          ),
    ]);
  }
}

class _StorefrontTab extends StatelessWidget {
  const _StorefrontTab();

  /// The banner is uploaded from the storefront editor.
  void _editStorefront(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStorefrontScreen()));

  /// The store logo is the business logo (`POST /admin/business/logo`).
  Future<void> _uploadLogo(BuildContext context) async {
    final f = await pickUploadFile(context, title: 'Store logo', maxBytes: 5 * 1024 * 1024);
    if (f == null || !context.mounted) return;
    showToast(context, 'Uploading logo…');
    await runLiveAction(context, () => LiveSession.instance.uploadBusinessLogo(f.bytes, f.name), done: 'Logo uploaded');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = BizStore.instance.storefront;

    Widget row(IconData icon, String title, String subtitle, Widget? trailing, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BpCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              LeadingIcon(icon, color: p.textSecondary, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tx(context, 13.5, weight: FontWeight.w700)),
                  Text(subtitle, style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              if (trailing != null) ...[trailing, const SizedBox(width: 4)],
              Icon(Icons.chevron_right, color: p.textMuted),
            ]),
          ),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
      // Banner + logo + name
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: p.cardAlt,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.primarySoft, p.accentSoft]),
                  image: s.bannerUrl == null ? null : DecorationImage(image: NetworkImage(s.bannerUrl!), fit: BoxFit.cover),
                ),
                alignment: Alignment.center,
                child: s.bannerUrl != null ? null : Text('No banner yet', style: tx(context, 12, color: p.textMuted)),
              ),
              Positioned(
                left: 14,
                bottom: -26,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
                  child: BizStore.instance.profile.logoUrl == null
                      ? InitialsAvatar(s.name, size: 52)
                      : ClipOval(
                          child: Image.network(BizStore.instance.profile.logoUrl!, width: 52, height: 52, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => InitialsAvatar(s.name, size: 52)),
                        ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: tx(context, 15, weight: FontWeight.w800)),
                if (s.description.isNotEmpty) Text(s.description, style: tx(context, 12, color: p.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      BpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Store Link', style: tx(context, 12, color: p.textSecondary)),
          const SizedBox(height: 6),
          DashedButton(label: s.customDomain ?? s.link, icon: Icons.link, onTap: () {
            Clipboard.setData(ClipboardData(text: 'https://${s.customDomain ?? s.link}'));
            showToast(context, 'Store link copied');
          }),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: CustomButton(
                text: 'Copy',
                variant: ButtonVariant.soft,
                height: 40,
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://${s.customDomain ?? s.link}'));
                  showToast(context, 'Store link copied');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'Share',
                variant: ButtonVariant.outline,
                height: 40,
                icon: const Icon(Icons.ios_share),
                onPressed: () => showShareSheet(context, title: 'Share Store', heading: s.name, link: s.customDomain ?? s.link, amount: 0, footnote: 'Customers browse and order on a web page. No app needed.'),
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      const SectionLabel('Domain'),
      row(Icons.language, 'Custom Domain', s.customDomain ?? 'Add a customised domain (optional)', null,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomDomainScreen()))),
      const SizedBox(height: 8),
      const SectionLabel('Brand'),
      row(Icons.image_outlined, 'Logo', s.hasLogo ? 'Added' : 'Not added', StatusPill(s.hasLogo ? BizStatus.uploaded : BizStatus.notUploaded),
          () => _uploadLogo(context)),
      row(Icons.panorama_outlined, 'Banner', s.bannerUrl != null ? 'Added' : 'Not added', StatusPill(s.bannerUrl != null ? BizStatus.uploaded : BizStatus.notUploaded),
          () => _editStorefront(context)),
      const SizedBox(height: 12),
      CustomButton(
        text: 'Edit Storefront',
        variant: ButtonVariant.outline,
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStorefrontScreen())),
      ),
    ]);
  }
}

