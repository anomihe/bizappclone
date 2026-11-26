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
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/ui_kit.dart';

const businessTypes = ['Fashion', 'Accessories', 'Services', 'Foods & Refreshments', 'Beauty & Cosmetics', 'Electronics', 'Retail', 'Other'];

/// Business details saved to `PUT /admin/business`; the logo goes to
/// `POST /admin/business/logo` as soon as it is picked.
class EditBusinessProfileScreen extends StatefulWidget {
  const EditBusinessProfileScreen({super.key});

  @override
  State<EditBusinessProfileScreen> createState() => _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState extends State<EditBusinessProfileScreen> {
  final b = BizStore.instance.profile;
  late final _name = TextEditingController(text: b.name);
  late final _reg = TextEditingController(text: b.registrationNumber);
  late final _phone = TextEditingController(text: b.phone);
  late final _email = TextEditingController(text: b.email);
  late final _address = TextEditingController(text: b.address);
  late String? _type = b.type.isEmpty ? null : (businessTypes.contains(b.type) ? b.type : 'Other');
  late CountryInfo _country = CountryInfo.all.firstWhere((c) => c.dialCode == b.dialCode, orElse: () => CountryInfo.all.first);
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_name, _reg, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || Fmt.isEmail(_email.text);
  bool get _valid => _name.text.trim().isNotEmpty && _emailOk;

  Future<void> _save() async {
    // Keep the old values so a failed save leaves the profile as it was.
    final before = (b.name, b.registrationNumber, b.dialCode, b.phone, b.email, b.address, b.type);
    b
      ..name = _name.text.trim()
      ..registrationNumber = _reg.text.trim()
      ..dialCode = _country.dialCode
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..address = _address.text.trim()
      ..type = _type ?? '';
    setState(() => _saving = true);
    final ok = await runLiveAction(context, LiveSession.instance.saveBusinessProfile, done: 'Business profile saved');
    if (!ok) {
      b
        ..name = before.$1
        ..registrationNumber = before.$2
        ..dialCode = before.$3
        ..phone = before.$4
        ..email = before.$5
        ..address = before.$6
        ..type = before.$7;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _uploadLogo() async {
    final f = await pickUploadFile(context, title: 'Brand logo', maxBytes: 5 * 1024 * 1024);
    if (f == null || !mounted) return;
    setState(() => _uploading = true);
    await runLiveAction(context, () => LiveSession.instance.uploadBusinessLogo(f.bytes, f.name), done: 'Logo updated');
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    void refresh(_) => setState(() {});
    final initials = InitialsAvatar(_name.text.isEmpty ? '?' : _name.text, size: 44);
    return InnerScaffold(
      title: 'Business Profile',
      bottom: CustomButton(text: 'Save Changes', isLoading: _saving, onPressed: _valid && !_saving ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          child: Row(children: [
            if (b.logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(b.logoUrl!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, _, _) => initials),
              )
            else
              initials,
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Brand Logo', style: tx(context, 13, weight: FontWeight.w700)),
                Text('Shown on invoices, quotations and receipts.', style: tx(context, 11, color: p.textMuted)),
              ]),
            ),
            CustomButton(
              text: b.logoUrl != null ? 'Change' : 'Upload',
              width: 86,
              height: 34,
              variant: ButtonVariant.outline,
              isLoading: _uploading,
              onPressed: _uploading ? null : _uploadLogo,
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CustomTextField(label: 'Business Name', hint: 'Enter business name', controller: _name, onChanged: refresh),
        const SizedBox(height: 14),
        CustomTextField(label: 'Registration Number', hint: 'RC1234567', controller: _reg),
        const SizedBox(height: 14),
        SelectField(label: 'Business Type', hint: 'Select business type', value: _type, options: businessTypes, onChanged: (v) => setState(() => _type = v)),
        const SizedBox(height: 14),
        PhoneField(label: 'Business Phone', controller: _phone, country: _country, onCountryChanged: (c) => setState(() => _country = c)),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Business Email',
          hint: 'you@business.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailOk ? null : 'Invalid email address',
          onChanged: refresh,
        ),
        const SizedBox(height: 14),
        CustomTextField(label: 'Address', hint: 'Street, city, state', controller: _address, maxLines: 2),
        const SizedBox(height: 14),
        InfoRow(label: 'Currency', value: b.currency),
      ]),
    );
  }
}
