import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/invoice_sheets.dart';
import 'payment_link_details_screen.dart';

class CreatePaymentLinkScreen extends StatefulWidget {
  const CreatePaymentLinkScreen({super.key});

  @override
  State<CreatePaymentLinkScreen> createState() => _CreatePaymentLinkScreenState();
}

class _CreatePaymentLinkScreenState extends State<CreatePaymentLinkScreen> {
  final _amount = TextEditingController();
  final _purpose = TextEditingController();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  Customer? _customer;
  DateTime? _expires;
  bool _loading = false;

  @override
  void dispose() {
    _amount.dispose();
    _purpose.dispose();
    _customerName.dispose();
    _customerPhone.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;
  bool get _valid => _value > 0 && _purpose.text.trim().isNotEmpty;

  Future<void> _create() async {
    setState(() => _loading = true);
    final draft = BizStore.instance.newInvoiceDraft(kind: DocKind.paymentLink)
      ..customer = _customer
      ..customerNameOverride = _customer == null && _customerName.text.trim().isNotEmpty ? _customerName.text.trim() : null
      ..items = [LineItem(name: _purpose.text.trim(), unitPrice: _value, qty: 1)]
      ..customerPhone = _customerPhone.text.trim()
      ..dueDate = _expires;
    Invoice? link;
    final ok = await runLiveAction(context, () async => link = await LiveSession.instance.createPaymentLink(draft));
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok && link != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentLinkDetailsScreen(link: link!, justCreated: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InnerScaffold(
      title: 'Payment link',
      bottom: CustomButton(text: 'Create Link', isLoading: _loading, onPressed: _valid ? _create : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(
          label: 'Amount',
          hint: '0',
          prefixText: '₦ ',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'What is it for?',
          hint: 'e.g Ankara fabric deposit',
          controller: _purpose,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Customer name (optional)',
          hint: 'Search, Enter Customer Name',
          controller: _customerName,
          prefixIcon: Icon(Icons.search, size: 18, color: p.textMuted),
          suffixIcon: IconButton(
            tooltip: 'Choose customer',
            icon: Icon(Icons.contacts_outlined, size: 18, color: p.textSecondary),
            onPressed: () async {
              final c = await showChooseCustomerSheet(context);
              if (c != null) {
                setState(() {
                  _customer = c;
                  _customerName.text = c.name;
                });
              }
            },
          ),
          onChanged: (v) => setState(() {
            if (_customer != null && v != _customer!.name) _customer = null;
          }),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Customer Phone Number (optional)',
          hint: 'Enter Phone',
          controller: _customerPhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]'))],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Link expires on (optional)',
          hint: 'dd/mm/yy',
          readOnly: true,
          controller: TextEditingController(text: _expires == null ? '' : Fmt.dateNumeric(_expires!)),
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: p.textMuted),
          onTap: () async {
            final d = await showDatePickerSheet(context, initial: _expires ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now());
            if (d != null) setState(() => _expires = d);
          },
        ),
      ]),
    );
  }
}
