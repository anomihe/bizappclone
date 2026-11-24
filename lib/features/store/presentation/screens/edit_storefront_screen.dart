import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/ui_kit.dart';

class EditStorefrontScreen extends StatefulWidget {
  const EditStorefrontScreen({super.key});

  @override
  State<EditStorefrontScreen> createState() => _EditStorefrontScreenState();
}

class _EditStorefrontScreenState extends State<EditStorefrontScreen> {
  final s = BizStore.instance.storefront;
  late final _name = TextEditingController(text: s.name);
  late final _description = TextEditingController(text: s.description);
  late final _phone = TextEditingController(text: s.phone);
  late final _email = TextEditingController(text: s.email);
  late CountryInfo _country = CountryInfo.all.firstWhere((c) => c.dialCode == s.dialCode, orElse: () => CountryInfo.all.first);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || Fmt.isEmail(_email.text);
  bool get _valid => _name.text.trim().isNotEmpty && _emailOk;

  @override
  Widget build(BuildContext context) {
    void refresh(_) => setState(() {});
    return InnerScaffold(
      title: 'Edit Storefront',
      bottom: CustomButton(
        text: 'Save',
        onPressed: _valid
            ? () {
                s
                  ..name = _name.text.trim()
                  ..description = _description.text.trim()
                  ..dialCode = _country.dialCode
                  ..phone = _phone.text.trim()
                  ..email = _email.text.trim();
                BizStore.instance.updateStorefront();
                showToast(context, 'Storefront updated');
                Navigator.pop(context);
              }
            : null,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Store name', hint: 'Enter store name', controller: _name, onChanged: refresh),
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
