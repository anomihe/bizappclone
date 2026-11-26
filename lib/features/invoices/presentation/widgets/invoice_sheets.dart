import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../customers/presentation/screens/customer_form_screen.dart';

// ------------------------------------------------------------------ customer

/// "Choose Customer" sheet. Returns the picked or newly created customer.
Future<Customer?> showChooseCustomerSheet(BuildContext context) async {
  final result = await showBpSheet<Object>(context, title: 'Choose Customer', builder: (_) => const _CustomerPicker());
  if (result is Customer) return result;
  if (result == 'add' && context.mounted) {
    return Navigator.push<Customer>(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
  }
  return null;
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();
  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final list = BizStore.instance.customers
        .where((c) => c.name.toLowerCase().contains(_q.toLowerCase()) || c.phone.replaceAll(' ', '').contains(_q.replaceAll(' ', '')))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(children: [
        SearchField(hint: 'Search customers', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? EmptyState(icon: Icons.person_search_outlined, title: _q.isEmpty ? 'No customer found' : 'No matching customer', message: 'Add new customer below.')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return BpCard(
                      onTap: () => Navigator.pop(context, c),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        InitialsAvatar(c.name, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: tx(context, 13.5, weight: FontWeight.w700)),
                            Text(c.phone, style: tx(context, 11.5, color: p.textMuted)),
                          ]),
                        ),
                        Icon(Icons.chevron_right, color: p.textMuted),
                      ]),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Add new Contact',
          variant: ButtonVariant.outline,
          icon: const Icon(Icons.person_add_alt_outlined),
          onPressed: () => Navigator.pop(context, 'add'),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ line item

Future<LineItem?> showAddLineItemSheet(BuildContext context, {LineItem? existing}) {
  return showBpSheet<LineItem>(context, title: existing == null ? 'Add line item' : 'Edit line item', builder: (_) => _LineItemForm(existing: existing));
}

class _LineItemForm extends StatefulWidget {
  final LineItem? existing;
  const _LineItemForm({this.existing});
  @override
  State<_LineItemForm> createState() => _LineItemFormState();
}

class _LineItemFormState extends State<_LineItemForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(text: widget.existing == null ? '' : widget.existing!.unitPrice.toStringAsFixed(0));
  late int _qty = widget.existing?.qty ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  double get _unit => double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
  bool get _valid => _name.text.trim().isNotEmpty && _unit > 0 && _qty > 0;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget stepBtn(IconData icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: onTap == null ? p.border : AppColors.primary)),
            child: Icon(icon, size: 16, color: onTap == null ? p.textMuted : AppColors.primary),
          ),
        );

    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(
          label: 'What are you selling?',
          hint: 'E.g Ankara Fabric (6 yards)',
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: CustomTextField(
              label: 'Unit Price',
              hint: '0.00',
              prefixText: '₦ ',
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quantity', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: Row(children: [
                stepBtn(Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null),
                SizedBox(width: 36, child: Text('$_qty', textAlign: TextAlign.center, style: tx(context, 15, weight: FontWeight.w800))),
                stepBtn(Icons.add, () => setState(() => _qty++)),
              ]),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: Text('Line Total', style: tx(context, 13, color: p.textSecondary))),
            MoneyText(_unit * _qty, size: 15),
          ]),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: widget.existing == null ? 'Add item' : 'Save item',
          onPressed: _valid ? () => Navigator.pop(context, LineItem(name: _name.text.trim(), unitPrice: _unit, qty: _qty)) : null,
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ reminder

Future<void> showSendReminderSheet(BuildContext context, Invoice invoice) {
  return showBpSheet(context, title: 'Send a reminder', showHandle: true, builder: (_) => _ReminderForm(invoice: invoice));
}

class _ReminderForm extends StatefulWidget {
  final Invoice invoice;
  const _ReminderForm({required this.invoice});
  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  int _channel = 0;
  static const _channels = [(Icons.chat_outlined, 'WhatsApp'), (Icons.sms_outlined, 'SMS'), (Icons.email_outlined, 'Email')];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final i = widget.invoice;
    final first = i.customerName.split(' ').first;
    final due = i.dueDate == null ? '' : ' was due on ${Fmt.date(i.dueDate!)}';
    final message =
        'Hi $first, a friendly reminder that invoice ${i.number} (${Fmt.money(i.balance)})$due. Pay here: ${i.payLink}';

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('To ${i.customerName} · ${Fmt.money(i.balance)} still owed', style: tx(context, 12, color: p.textSecondary)),
      const SizedBox(height: 12),
      Row(children: [
        for (var c = 0; c < _channels.length; c++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectChip(icon: _channels[c].$1, label: _channels[c].$2, selected: _channel == c, onTap: () => setState(() => _channel = c)),
          ),
      ]),
      const SizedBox(height: 14),
      Text('Message', style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
        child: Text(message, style: tx(context, 12.5, height: 1.45)),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.info_outline, size: 14, color: p.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text('Reminders stop on their own once the invoice is paid.', style: tx(context, 11, color: p.textMuted))),
      ]),
      const SizedBox(height: 16),
      CustomButton(
        text: 'Send on ${_channels[_channel].$2}',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: message));
          Navigator.pop(context);
          showToast(context, 'Reminder copied — paste it in ${_channels[_channel].$2}');
        },
      ),
      const SizedBox(height: 10),
      CustomButton(text: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
    ]);
  }
}

// ------------------------------------------------------------------ share

Future<void> showSharePayLinkSheet(BuildContext context, Invoice invoice) => showShareSheet(
      context,
      title: 'Share Pay link',
      heading: '${invoice.customerName} · ${invoice.number}',
      link: invoice.payLink,
      amount: invoice.balance > 0 ? invoice.balance : invoice.total,
      footnote: 'The customer pays on a web page. No app or login needed.',
    );

/// Share card with WhatsApp / Telegram / Instagram / Copy Link.
/// Opening other apps needs `share_plus` or `url_launcher`; until those are
/// added every target copies the link.
Future<void> showShareSheet(BuildContext context, {required String title, required String heading, required String link, required num amount, String? footnote}) {
  return showBpSheet(
    context,
    title: title,
    builder: (ctx) {
      final p = ctx.p;
      void share(String app) {
        Clipboard.setData(ClipboardData(text: 'https://$link'));
        Navigator.pop(ctx);
        showToast(context, app == 'Copy Link' ? 'Link copied' : 'Link copied — paste it in $app');
      }

      Widget target(IconData icon, Color color, String label) => Expanded(
            child: InkWell(
              onTap: () => share(label),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: tx(ctx, 11, color: p.textSecondary)),
                ]),
              ),
            ),
          );

      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accent)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(heading, style: tx(ctx, 13, weight: FontWeight.w700)),
                Text(link, style: tx(ctx, 11.5, color: p.textSecondary)),
              ]),
            ),
            MoneyText(amount, size: 14, color: context.p.brand),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          target(Icons.chat, const Color(0xFF25D366), 'WhatsApp'),
          target(Icons.send, const Color(0xFF229ED9), 'Telegram'),
          target(Icons.camera_alt_outlined, const Color(0xFFE1306C), 'Instagram'),
          target(Icons.link, p.textSecondary, 'Copy Link'),
        ]),
        if (footnote != null) ...[
          const SizedBox(height: 10),
          Text(footnote, textAlign: TextAlign.center, style: tx(ctx, 11, color: p.textMuted)),
        ],
      ]);
    },
  );
}
