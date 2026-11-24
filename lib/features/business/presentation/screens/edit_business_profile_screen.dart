import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/select_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../store/presentation/widgets/store_widgets.dart';

const businessTypes = ['Fashion', 'Accessories', 'Services', 'Foods & Refreshments', 'Beauty & Cosmetics', 'Electronics', 'Retail', 'Other'];
const profileCurrencies = ['Nigeria Naira (NGN)', 'Ghana Cedi (GHS)', 'Kenyan Shilling (KES)', 'US Dollar (USD)'];

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
  late String? _type = b.type.isEmpty ? null : b.type;
  late String _currency = b.currency;
  late bool _logo = b.hasLogo;
  late CountryInfo _country = CountryInfo.all.firstWhere((c) => c.dialCode == b.dialCode, orElse: () => CountryInfo.all.first);

  @override
  void dispose() {
    for (final c in [_name, _reg, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || Fmt.isEmail(_email.text);
  bool get _valid => _name.text.trim().isNotEmpty && _emailOk;

  void _save() {
    b
      ..name = _name.text.trim()
      ..registrationNumber = _reg.text.trim()
      ..dialCode = _country.dialCode
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..address = _address.text.trim()
      ..type = _type ?? ''
      ..currency = _currency
      ..hasLogo = _logo;
    final store = BizStore.instance;
    store.updateProfile();
    store.submitForReview();
    showToast(context, 'Business profile saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    void refresh(_) => setState(() {});
    return InnerScaffold(
      title: 'Business Profile',
      bottom: CustomButton(text: 'Save Changes', onPressed: _valid ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          child: Row(children: [
            _logo ? const ProductThumb(photo: 2, size: 44) : InitialsAvatar(_name.text.isEmpty ? '?' : _name.text, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Brand Logo', style: tx(context, 13, weight: FontWeight.w700)),
                Text('Shown on invoices, quotations and receipts.', style: tx(context, 11, color: p.textMuted)),
              ]),
            ),
            CustomButton(
              text: _logo ? 'Change' : 'Upload',
              width: 86,
              height: 34,
              variant: ButtonVariant.outline,
              onPressed: () async {
                if (await showImageSourceSheet(context)) setState(() => _logo = true);
              },
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
        SelectField(label: 'Currency', hint: 'Select currency', value: _currency, options: profileCurrencies, onChanged: (v) => setState(() => _currency = v)),
      ]),
    );
  }
}
