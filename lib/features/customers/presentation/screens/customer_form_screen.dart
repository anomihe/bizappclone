import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/ui_kit.dart';

/// "New Customer" and "Edit (name)". Pops with the saved [Customer].
class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final _name = TextEditingController(text: widget.customer?.name ?? '');
  late final _phone = TextEditingController(text: widget.customer?.phone ?? '');
  late final _email = TextEditingController(text: widget.customer?.email ?? '');
  late final _notes = TextEditingController(text: widget.customer?.notes ?? '');
  late CountryInfo _country = CountryInfo.all.firstWhere(
    (c) => c.dialCode == (widget.customer?.dialCode ?? '+234'),
    orElse: () => CountryInfo.all.first,
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  // The backend requires an email for every customer (they get a portal login).
  bool get _emailOk => LiveSession.enabled ? Fmt.isEmail(_email.text) : (_email.text.trim().isEmpty || Fmt.isEmail(_email.text));
  bool get _valid => _name.text.trim().isNotEmpty && _phone.text.replaceAll(' ', '').length >= 7 && _emailOk;

  void _save() {
    final store = BizStore.instance;
    final existing = widget.customer;
    Customer saved;
    if (existing != null) {
      existing
        ..name = _name.text.trim()
        ..dialCode = _country.dialCode
        ..phone = _phone.text.trim()
        ..email = _email.text.trim()
        ..notes = _notes.text.trim();
      store.updateCustomer(existing);
      saved = existing;
    } else {
      saved = store.addCustomer(
        name: _name.text.trim(),
        dialCode: _country.dialCode,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        notes: _notes.text.trim(),
      );
    }
    showToast(context, existing == null ? 'Customer added' : 'Customer updated');
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.customer != null;
    void refresh(_) => setState(() {});
    return InnerScaffold(
      title: editing ? 'Edit ${widget.customer!.name}' : 'New Customer',
      bottom: CustomButton(text: editing ? 'Save' : 'Save Customer', onPressed: _valid ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(label: 'Name', hint: 'Enter customer name', controller: _name, textCapitalization: TextCapitalization.words, onChanged: refresh),
        const SizedBox(height: 14),
        PhoneField(controller: _phone, country: _country, onCountryChanged: (c) => setState(() => _country = c), onChanged: refresh),
        const SizedBox(height: 14),
        CustomTextField(
          label: LiveSession.enabled ? 'Email' : 'Email (optional)',
          hint: 'Enter your email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _email.text.trim().isNotEmpty && !_emailOk ? 'Invalid email address' : null,
          onChanged: refresh,
        ),
        const SizedBox(height: 14),
        CustomTextField(label: 'Notes (optional)', hint: 'e.g Prefers WhatsApp calls', controller: _notes, maxLines: 3),
      ]),
    );
  }
}
