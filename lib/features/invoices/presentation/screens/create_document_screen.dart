import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/calendar_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/invoice_sheets.dart';
import 'document_preview_screen.dart';
import 'invoice_details_screen.dart';
import 'quotation_details_screen.dart';

/// "New Invoice" / "New Quotation" editor. Pass an existing draft to edit it.
class CreateDocumentScreen extends StatefulWidget {
  final Invoice? invoice;
  final Quotation? quotation;
  final bool isQuotation;
  final Customer? customer;

  const CreateDocumentScreen.invoice({super.key, Invoice? draft, this.customer})
      : invoice = draft,
        quotation = null,
        isQuotation = false;

  const CreateDocumentScreen.quotation({super.key, Quotation? draft})
      : quotation = draft,
        invoice = null,
        customer = null,
        isQuotation = true;

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen> {
  final store = BizStore.instance;
  late final Invoice? _invoice = widget.isQuotation ? null : (widget.invoice ?? store.newInvoiceDraft());
  late final Quotation? _quote = widget.isQuotation ? (widget.quotation ?? store.newQuotationDraft()) : null;

  Customer? _customer;
  List<LineItem> _items = [];
  final _discount = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _due;
  bool _partPay = false;
  bool _vat = false;
  int _validity = 7;

  @override
  void initState() {
    super.initState();
    if (_invoice != null) {
      _customer = widget.customer ?? _invoice.customer;
      _items = _invoice.items.map((e) => e.copy()).toList();
      _due = _invoice.dueDate;
      _partPay = _invoice.allowPartPayment;
      _notes.text = _invoice.notes;
      if (_invoice.discount > 0) _discount.text = _invoice.discount.toStringAsFixed(0);
    } else {
      _customer = _quote!.customer;
      _items = _quote.items.map((e) => e.copy()).toList();
      _notes.text = _quote.notes;
      _vat = _quote.addVat;
      _validity = _quote.validityDays;
      if (_quote.discount > 0) _discount.text = _quote.discount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _discount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _discountValue => double.tryParse(_discount.text) ?? 0;
  double get _net => (_items.fold<double>(0, (s, i) => s + i.total) - _discountValue).clamp(0, double.infinity).toDouble();
  double get _vatAmount => widget.isQuotation && _vat ? _net * Quotation.vatRate : 0;
  double get _total => _net + _vatAmount;
  bool get _ready => _customer != null && _items.isNotEmpty;
  String get _noun => widget.isQuotation ? 'Quotation' : 'Invoice';

  /// Last issued invoice offered as a one-tap "Repeat" shortcut.
  Invoice? get _repeatCandidate {
    if (widget.isQuotation || _items.isNotEmpty) return null;
    for (final i in store.invoices) {
      if (i.kind == DocKind.invoice && i.items.isNotEmpty && i.customer != null && i != _invoice) return i;
    }
    return null;
  }

  void _apply() {
    if (_invoice != null) {
      _invoice
        ..customer = _customer
        ..items = _items
        ..discount = _discountValue
        ..dueDate = _due
        ..allowPartPayment = _partPay
        ..notes = _notes.text.trim();
    } else {
      _quote!
        ..customer = _customer
        ..items = _items
        ..discount = _discountValue
        ..notes = _notes.text.trim()
        ..addVat = _vat
        ..validityDays = _validity;
    }
  }

  void _saveDraft() {
    _apply();
    if (_invoice != null) {
      store.saveInvoice(_invoice, issue: false);
    } else {
      store.saveQuotation(_quote!, send: false);
    }
    showToast(context, '$_noun saved as draft');
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => _invoice != null ? InvoiceDetailsScreen(invoice: _invoice) : QuotationDetailsScreen(quotation: _quote!),
      ),
    );
  }

  void _preview() {
    _apply();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _invoice != null ? DocumentPreviewScreen.invoice(_invoice) : DocumentPreviewScreen.quotation(_quote!)),
    );
  }

  Future<void> _addItem({int? editIndex}) async {
    final item = await showAddLineItemSheet(context, existing: editIndex == null ? null : _items[editIndex]);
    if (item == null) return;
    setState(() => editIndex == null ? _items.add(item) : _items[editIndex] = item);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final repeat = _repeatCandidate;

    return InnerScaffold(
      title: widget.invoice != null || widget.quotation != null ? 'Edit $_noun' : 'New $_noun',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text('Total', style: tx(context, 13.5, weight: FontWeight.w700))),
          MoneyText(_total, size: 17),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: CustomButton(text: 'Save Draft', variant: ButtonVariant.outline, onPressed: _ready ? _saveDraft : null)),
          const SizedBox(width: 10),
          Expanded(child: CustomButton(text: widget.isQuotation ? 'Save & Share' : 'Preview', onPressed: _ready ? _preview : null)),
        ]),
      ]),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _label('Customer'),
        if (_customer == null)
          DashedButton(
            label: 'Choose or Add a customer',
            icon: Icons.person_outline,
            onTap: () async {
              final c = await showChooseCustomerSheet(context);
              if (c != null) setState(() => _customer = c);
            },
          )
        else
          BpCard(
            onTap: () async {
              final c = await showChooseCustomerSheet(context);
              if (c != null) setState(() => _customer = c);
            },
            color: p.card,
            borderColor: p.border,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              InitialsAvatar(_customer!.name, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_customer!.name, style: tx(context, 13.5, weight: FontWeight.w700)),
                  Text(_customer!.phone, style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right, color: p.textMuted),
            ]),
          ),
        const SizedBox(height: 16),
        _label('Items'),
        for (var i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BpCard(
              onTap: () => _addItem(editIndex: i),
              color: p.card,
              borderColor: p.border,
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_items[i].name, style: tx(context, 13, weight: FontWeight.w700)),
                    Text('${_items[i].qty} × ${Fmt.money(_items[i].unitPrice)}', style: tx(context, 11.5, color: p.textMuted)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  icon: Icon(Icons.cancel, size: 20, color: p.textMuted),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              ]),
            ),
          ),
        CustomButton(text: 'Add item', variant: ButtonVariant.outline, height: 44, icon: const Icon(Icons.add), onPressed: _addItem),
        if (repeat != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SelectChip(
              icon: Icons.replay,
              label: 'Repeat ${repeat.number} · ${repeat.customerName.split(' ').first} (${repeat.items.length})',
              selected: false,
              onTap: () => setState(() {
                _customer ??= repeat.customer;
                _items = repeat.items.map((e) => e.copy()).toList();
              }),
            ),
          ),
        ],
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Discount (optional)',
          hint: '0',
          prefixText: '₦ ',
          controller: _discount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
        ),
        if (!widget.isQuotation) ...[
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Due Date',
            hint: 'dd/mm/yyyy',
            readOnly: true,
            controller: TextEditingController(text: _due == null ? '' : Fmt.dateNumeric(_due!)),
            suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: p.textMuted),
            onTap: () async {
              final d = await showDatePickerSheet(context, initial: _due ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now());
              if (d != null) setState(() => _due = d);
            },
          ),
          const SizedBox(height: 12),
          BpCard(
            color: p.card,
            borderColor: p.border,
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Allow part-payments', style: tx(context, 13, weight: FontWeight.w700)),
                  Text('The customer can pay in instalments.', style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              Switch(value: _partPay, activeThumbColor: Colors.white, activeTrackColor: AppColors.primary, onChanged: (v) => setState(() => _partPay = v)),
            ]),
          ),
        ],
        if (widget.isQuotation) ...[
          const SizedBox(height: 12),
          BpCard(
            color: p.card,
            borderColor: p.border,
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add VAT (7.5%)', style: tx(context, 13, weight: FontWeight.w700)),
                  Text(_vat ? '+${Fmt.money(_vatAmount)}' : 'No tax', style: tx(context, 11.5, color: p.textMuted)),
                ]),
              ),
              Switch(value: _vat, onChanged: (v) => setState(() => _vat = v)),
            ]),
          ),
          const SizedBox(height: 16),
          _label('Validity Period'),
          Wrap(spacing: 8, children: [
            for (final d in const [7, 14, 30]) SelectChip(label: '$d Days', selected: _validity == d, onTap: () => setState(() => _validity = d)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Valid until ${Fmt.date(DateTime.now().add(Duration(days: _validity)))} if you send it today. After that it shows as Expired and cannot be converted.',
            style: tx(context, 11.5, color: p.textMuted, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        CustomTextField(label: 'Notes (optional)', hint: 'Thanks for your business', controller: _notes, maxLines: 3),
      ]),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: tx(context, 12.5, weight: FontWeight.w600, color: context.p.textSecondary)),
      );
}
