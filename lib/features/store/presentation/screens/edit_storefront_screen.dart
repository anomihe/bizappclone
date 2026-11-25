import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/utils/pick_file.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/store_widgets.dart';

class EditStorefrontScreen extends StatefulWidget {
  const EditStorefrontScreen({super.key});

  @override
  State<EditStorefrontScreen> createState() => _EditStorefrontScreenState();
}

class _EditStorefrontScreenState extends State<EditStorefrontScreen> {
  final s = BizStore.instance.storefront;
  late final _name = TextEditingController(text: s.name);
  late final _tagline = TextEditingController(text: s.tagline);
  late final _description = TextEditingController(text: s.description);
  late final _phone = TextEditingController(text: s.phone);
  late final _email = TextEditingController(text: s.email);
  late CountryInfo _country = CountryInfo.all.firstWhere((c) => c.dialCode == s.dialCode, orElse: () => CountryInfo.all.first);

  /// Live mode: new banner image (the API stores one, 5MB max).
  PickedFile? _banner;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _tagline, _description, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || Fmt.isEmail(_email.text);
  bool get _valid => _name.text.trim().isNotEmpty && _emailOk;

  Future<void> _save() async {
    // Keep the old values so a failed save can be undone.
    final before = (s.name, s.tagline, s.description, s.dialCode, s.phone, s.email);
    s
      ..name = _name.text.trim()
      ..tagline = _tagline.text.trim()
      ..description = _description.text.trim()
      ..dialCode = _country.dialCode
      ..phone = _phone.text.trim()
      ..email = _email.text.trim();

    if (LiveSession.enabled) {
      setState(() => _saving = true);
      final ok = await runLiveAction(context, () => LiveSession.instance.saveStorefront(banner: _banner?.bytes, filename: _banner?.name),
          done: 'Storefront updated');
      if (!mounted) return;
      setState(() => _saving = false);
      if (!ok) {
        s
          ..name = before.$1
          ..tagline = before.$2
          ..description = before.$3
          ..dialCode = before.$4
          ..phone = before.$5
          ..email = before.$6;
        return;
      }
    } else {
      BizStore.instance.updateStorefront();
      showToast(context, 'Storefront updated');
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickBanner() async {
    final f = await pickUploadFile(context, title: 'Store banner', maxBytes: 5 * 1024 * 1024);
    if (f != null && mounted) setState(() => _banner = f);
  }

  @override
  Widget build(BuildContext context) {
    void refresh(_) => setState(() {});
    final live = LiveSession.enabled;
    return InnerScaffold(
      title: 'Edit Storefront',
      bottom: CustomButton(text: 'Save', isLoading: _saving, onPressed: _valid && !_saving ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (live) ...[
          Text('Banner', style: tx(context, 12.5, weight: FontWeight.w600, color: context.p.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickBanner,
            borderRadius: BorderRadius.circular(12),
            child: _banner != null || s.bannerUrl != null
                ? ProductThumb(size: 120, bytes: _banner?.bytes, url: _banner == null ? s.bannerUrl : null)
                : Container(
                    height: 90,
                    decoration: BoxDecoration(color: context.p.cardAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.p.border)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, color: context.p.textSecondary),
                      const SizedBox(height: 4),
                      Text('Add a banner', style: tx(context, 12.5, weight: FontWeight.w600, color: context.p.textSecondary)),
                    ]),
                  ),
          ),
          if (_banner != null || s.bannerUrl != null)
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _pickBanner, child: const Text('Change banner'))),
          const SizedBox(height: 14),
        ],
        CustomTextField(label: 'Store name', hint: 'Enter store name', controller: _name, onChanged: refresh),
        if (live) ...[
          const SizedBox(height: 14),
          CustomTextField(label: 'Tagline (optional)', hint: 'e.g. Fresh fabrics, fast delivery', controller: _tagline),
        ],
        const SizedBox(height: 14),
        CustomTextField(label: 'Description', hint: 'What do you sell?', controller: _description, maxLines: 3),
        const SizedBox(height: 14),
        PhoneField(label: 'Contact Phone', controller: _phone, country: _country, onCountryChanged: (c) => setState(() => _country = c)),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Contact Email',
          hint: 'hello@yourstore.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailOk ? null : 'Invalid email address',
          onChanged: refresh,
        ),
      ]),
    );
  }
}
