import '../data/biz_store.dart';

/// JSON ↔ app model conversion for the Bizpaddi Laravel API.
///
/// Laravel serialises `decimal` casts as strings ("37000.00") and dates as
/// ISO-8601, so everything goes through the tolerant readers below.
class ApiMappers {
  // ------------------------------------------------------------ readers

  static double num0(dynamic v) => switch (v) {
        num n => n.toDouble(),
        String s => double.tryParse(s.replaceAll(',', '')) ?? 0,
        _ => 0,
      };

  static int? intOrNull(dynamic v) => switch (v) {
        int n => n,
        num n => n.toInt(),
        String s => int.tryParse(s),
        _ => null,
      };

  static DateTime? date(dynamic v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

  static String str(dynamic v) => v == null ? '' : '$v';

  /// "YYYY-MM-DD" for Laravel `date` validation.
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ------------------------------------------------------------ customers (clients)

  static Customer customer(Map<String, dynamic> j) {
    final (dial, phone) = splitPhone(str(j['phone']));
    final name = str(j['name']).isNotEmpty ? str(j['name']) : str(j['company_name']);
    return Customer(
      id: 'srv-c-${j['id']}',
      name: name.isEmpty ? 'Unnamed customer' : name,
      dialCode: dial,
      phone: phone,
      email: str(j['email']),
      notes: str(j['description']),
    )..serverId = intOrNull(j['id']);
  }

  static Map<String, dynamic> customerBody(Customer c, {String? password}) => {
        'name': c.name,
        'email': c.email,
        if (c.phone.isNotEmpty) 'phone': '${c.dialCode}${c.phone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '')}',
        if (c.notes.isNotEmpty) 'description': c.notes,
        'password': ?password,
      };

  /// "+2348035550142" / "08035550142" → ("+234", "803 555 0142").
  static (String, String) splitPhone(String raw) {
    final s = raw.replaceAll(RegExp(r'[^\d+]'), '');
    for (final code in const ['+234', '+233', '+254', '+27', '+44', '+1']) {
      if (s.startsWith(code)) return (code, s.substring(code.length));
    }
    return ('+234', s);
  }

  // ------------------------------------------------------------ invoices

  static InvoiceStatus invoiceStatus(String s) => switch (s) {
        'draft' => InvoiceStatus.draft,
        'paid' => InvoiceStatus.paid,
        'cancelled' => InvoiceStatus.voided,
        // 'sent' / 'overdue' → unpaid; the app derives overdue from the due date.
        _ => InvoiceStatus.unpaid,
      };

  static String invoiceStatusOut(InvoiceStatus s) => switch (s) {
        InvoiceStatus.draft => 'draft',
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.voided || InvoiceStatus.cancelled => 'cancelled',
        InvoiceStatus.overdue => 'overdue',
        _ => 'sent',
      };

  static LineItem lineItem(Map<String, dynamic> j) {
    final qty = num0(j['quantity']);
    return LineItem(
      name: str(j['title']).isNotEmpty ? str(j['title']) : str(j['description']),
      unitPrice: num0(j['unit_price']),
      qty: qty <= 0 ? 1 : qty.round(),
    );
  }

  static Invoice invoice(Map<String, dynamic> j, {required Customer? Function(int?) findCustomer}) {
    final clientJson = j['client'] is Map<String, dynamic> ? j['client'] as Map<String, dynamic> : null;
    final customer = findCustomer(intOrNull(j['client_id']));
    final rawStatus = str(j['status']);
    final inv = Invoice(
      id: 'srv-i-${j['id']}',
      number: str(j['invoice_number']).isEmpty ? '#${j['id']}' : str(j['invoice_number']),
      customer: customer,
      customerNameOverride: customer == null
          ? (str(j['client_name']).isNotEmpty ? str(j['client_name']) : (clientJson == null ? null : str(clientJson['name'])))
          : null,
      customerPhone: str(j['client_phone']),
      items: (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(lineItem).toList(),
      discount: num0(j['discount_amount']),
      taxAmount: num0(j['tax_amount']),
      totalOverride: num0(j['total_amount']),
      dueDate: date(j['due_date']),
      notes: str(j['notes']),
      status: invoiceStatus(rawStatus),
      createdAt: date(j['issue_date']) ?? date(j['created_at']) ?? DateTime.now(),
      serverId: intOrNull(j['id']),
    );
    // Marked paid on the server without a matching transaction: record the
    // payment so "Paid by customer" and the dashboard add up.
    if (rawStatus == 'paid') {
      inv.payments.add(Payment(
        id: 'srv-i-${j['id']}-paid',
        invoiceId: inv.id,
        invoiceNumber: inv.number,
        customerName: inv.customerName,
        amount: inv.total,
        providerCharge: 0,
        serviceCharge: 0,
        status: PaymentStatus.paid,
        date: date(j['paid_at']) ?? inv.createdAt,
        settled: true,
        receiptNo: inv.number,
      ));
    }
    return inv;
  }

  /// Status the API lets the app set directly; null leaves it alone
  /// (paid only comes from mark-paid / real payments).
  static String? invoiceStatusBody(InvoiceStatus s) => switch (s) {
        InvoiceStatus.draft => 'draft',
        InvoiceStatus.voided || InvoiceStatus.cancelled => 'cancelled',
        InvoiceStatus.paid || InvoiceStatus.partlyPaid => null,
        _ => 'sent',
      };

  static List<Map<String, dynamic>> itemsBody(List<LineItem> items) => [
        for (final it in items) {'title': it.name, 'description': it.name, 'quantity': it.qty, 'unit_price': it.unitPrice},
      ];

  /// Same fields as the web invoice form; totals are worked out by the server.
  static Map<String, dynamic> invoiceBody(Invoice i) {
    final due = i.dueDate ?? i.createdAt.add(const Duration(days: 14));
    return {
      if (i.customer?.serverId != null) 'client_id': i.customer!.serverId,
      'client_name': i.customerName,
      if (i.customer?.email.isNotEmpty == true) 'client_email': i.customer!.email,
      if (i.customerPhone.isNotEmpty) 'client_phone': i.customerPhone,
      'issue_date': ymd(i.createdAt),
      'due_date': ymd(due.isBefore(i.createdAt) ? i.createdAt : due),
      'discount_amount': i.discount,
      'tax_rate': 0,
      'status': ?invoiceStatusBody(i.status),
      'notes': i.notes,
      'items': itemsBody(i.items),
    };
  }

  // ------------------------------------------------------------ quotations

  static QuotationStatus quoteStatus(String s) => switch (s) {
        'sent' => QuotationStatus.sent,
        'approved' || 'converted' => QuotationStatus.accepted,
        'expired' || 'rejected' => QuotationStatus.expired,
        _ => QuotationStatus.draft,
      };

  static String quoteStatusOut(QuotationStatus s) => switch (s) {
        QuotationStatus.sent => 'sent',
        QuotationStatus.accepted => 'approved',
        QuotationStatus.expired => 'expired',
        QuotationStatus.draft => 'draft',
      };

  static Quotation quotation(Map<String, dynamic> j, {required Customer? Function(int?) findCustomer}) {
    final created = date(j['issue_date']) ?? date(j['created_at']) ?? DateTime.now();
    final validTill = date(j['valid_until']);
    return Quotation(
      id: 'srv-q-${j['id']}',
      number: str(j['quote_number']).isEmpty ? 'Q-${j['id']}' : str(j['quote_number']),
      customer: findCustomer(intOrNull(j['client_id'])),
      items: (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(lineItem).toList(),
      discount: num0(j['discount_amount']),
      notes: str(j['notes']),
      status: quoteStatus(str(j['status'])),
      validTill: validTill,
      createdAt: created,
      addVat: num0(j['tax_amount']) > 0,
      validityDays: validTill == null ? 7 : validTill.difference(created).inDays.clamp(1, 365),
      totalOverride: num0(j['total_amount']),
      serverId: intOrNull(j['id']),
    );
  }

  /// Same fields as the web quote form. Accepting uses POST …/approve, so it isn't sent as a status.
  static Map<String, dynamic> quotationBody(Quotation q) {
    final until = q.validTill ?? q.createdAt.add(Duration(days: q.validityDays));
    return {
      if (q.customer?.serverId != null) 'client_id': q.customer!.serverId,
      'client_name': q.customer?.name ?? '',
      if (q.customer?.email.isNotEmpty == true) 'client_email': q.customer!.email,
      'issue_date': ymd(q.createdAt),
      'valid_until': ymd(until.isBefore(q.createdAt) ? q.createdAt : until),
      'discount_amount': q.discount,
      'tax_rate': q.addVat ? Quotation.vatRate * 100 : 0,
      if (q.status != QuotationStatus.accepted) 'status': quoteStatusOut(q.status),
      'notes': q.notes,
      'items': itemsBody(q.items),
    };
  }

  // ------------------------------------------------------------ payments (transactions)

  /// Only money coming in (invoice / order payments, credits) counts as a payment.
  static bool isIncoming(Map<String, dynamic> j) {
    final payable = str(j['payable_type']).toLowerCase();
    final type = str(j['type']).toLowerCase();
    return payable.contains('invoice') || payable.contains('order') || const ['credit', 'income', 'inflow', 'payment'].contains(type);
  }

  static PaymentStatus paymentStatus(String s) => switch (s.toLowerCase()) {
        'successful' || 'success' || 'completed' || 'paid' => PaymentStatus.paid,
        'failed' || 'declined' || 'cancelled' => PaymentStatus.failed,
        'refunded' || 'reversed' => PaymentStatus.refunded,
        _ => PaymentStatus.pending,
      };

  static Payment payment(Map<String, dynamic> j, {required Invoice? Function(int?) findInvoice}) {
    final invoice = str(j['payable_type']).toLowerCase().contains('invoice') ? findInvoice(intOrNull(j['payable_id'])) : null;
    final status = paymentStatus(str(j['status']));
    return Payment(
      id: 'srv-t-${j['id']}',
      invoiceId: invoice?.id ?? '',
      invoiceNumber: invoice?.number ?? str(j['reference']),
      customerName: invoice?.customerName ?? (str(j['description']).isNotEmpty ? str(j['description']) : 'Customer'),
      amount: num0(j['amount']),
      method: 'Bank Transfer',
      provider: str(j['provider']).isEmpty ? 'Bank transfer' : str(j['provider']),
      providerCharge: 0,
      serviceCharge: 0,
      status: status,
      date: date(j['paid_at']) ?? date(j['transaction_date']) ?? date(j['created_at']) ?? DateTime.now(),
      // The API has no settlement field; a confirmed payment is treated as settled.
      settled: status == PaymentStatus.paid,
      receiptNo: str(j['provider_reference']).isNotEmpty
          ? str(j['provider_reference'])
          : (str(j['reference']).isNotEmpty ? str(j['reference']) : str(j['transaction_number'])),
    );
  }

  // ------------------------------------------------------------ team

  static StaffRole staffRole(String r) => switch (r.toLowerCase()) {
        'admin' || 'administrator' => StaffRole.administrator,
        'cashier' => StaffRole.cashier,
        'accountant' || 'finance' => StaffRole.accountant,
        _ => StaffRole.manager,
      };

  static StaffMember staff(Map<String, dynamic> j) {
    final role = str(j['role']);
    final mapped = staffRole(role);
    return StaffMember(
      id: 'srv-u-${j['id']}',
      name: str(j['name']),
      phone: str(j['phone']),
      email: str(j['email']),
      role: mapped,
      status: str(j['status']) == 'inactive' ? StaffStatus.deactivated : StaffStatus.active,
      lastActive: date(j['updated_at']) ?? date(j['created_at']) ?? DateTime.now(),
    )
      ..serverId = intOrNull(j['id'])
      ..backendRole = (mapped == StaffRole.manager && role.toLowerCase() != 'manager') ? role : null;
  }

  static Map<String, dynamic> staffBody(StaffMember m, {String? password}) => {
        'name': m.name,
        'email': m.email,
        if (m.phone.isNotEmpty) 'phone': m.phone,
        'role': m.backendRole ?? m.role.name,
        'status': m.status == StaffStatus.deactivated ? 'inactive' : 'active',
        'password': ?password,
      };

  // ------------------------------------------------------------ notifications

  static AppNotification notification(Map<String, dynamic> j) {
    final data = j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : const <String, dynamic>{};
    final type = str(j['type']).toLowerCase();
    return AppNotification(
      title: str(data['title']).isNotEmpty ? str(data['title']) : 'Notification',
      body: str(data['body']).isNotEmpty ? str(data['body']) : str(data['message']),
      time: date(j['created_at']) ?? DateTime.now(),
      type: type.contains('payment') || type.contains('transaction')
          ? NotificationType.payment
          : (type.contains('invoice') ? NotificationType.invoice : NotificationType.system),
      read: j['read_at'] != null,
      serverId: str(j['id']),
    );
  }

  // ------------------------------------------------------------ store

  /// The API stores the category as text; the app keys categories by name.
  static String categoryId(String name) => 'cat:${name.trim().toLowerCase()}';

  /// `price` is the list price; the app's discount is `price − sale_price`.
  static Product product(Map<String, dynamic> j) {
    final price = num0(j['price']);
    final sale = j['sale_price'] == null ? null : num0(j['sale_price']);
    final category = str(j['category']);
    final image = str(j['image_full_url']).isNotEmpty ? str(j['image_full_url']) : str(j['image_url']);
    return Product(
      id: 'srv-p-${j['id']}',
      name: str(j['name']),
      sku: str(j['slug']).isEmpty ? 'ID${j['id']}' : str(j['slug']).toUpperCase(),
      price: price,
      discount: sale == null || sale >= price ? 0 : price - sale,
      categoryId: category.isEmpty || category == 'General' ? null : categoryId(category),
      quantity: intOrNull(j['stock_quantity']) ?? 0,
      description: str(j['description']),
      showOnStorefront: j['is_active'] != false && j['is_active'] != 0,
    )
      ..serverId = intOrNull(j['id'])
      ..imageUrl = image.isEmpty ? null : image;
  }

  static Map<String, String> productFields(Product p, {String? category}) => {
        'name': p.name.trim(),
        'category': category ?? '',
        'price': p.price.toStringAsFixed(2),
        if (p.discount > 0) 'sale_price': p.salePrice.toStringAsFixed(2),
        'stock_quantity': '${p.quantity}',
        'description': p.description,
        'is_active': p.showOnStorefront ? '1' : '0',
      };

  static OrderStatus orderStatus(String s) => switch (s) {
        'paid' || 'processing' => OrderStatus.processing,
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.pending,
      };

  static Order order(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map((i) {
      final qty = num0(i['quantity']).round();
      return LineItem(name: str(i['product_name']), unitPrice: num0(i['unit_price']), qty: qty <= 0 ? 1 : qty);
    }).toList();
    final status = str(j['status']);
    final placed = date(j['created_at']) ?? DateTime.now();
    final order = Order(
      id: 'srv-o-${j['id']}',
      number: str(j['order_number']).isEmpty ? '#${j['id']}' : str(j['order_number']),
      customerName: str(j['customer_name']).isEmpty ? 'Customer' : str(j['customer_name']),
      phone: str(j['customer_phone']),
      address: str(j['shipping_address']),
      items: items,
      status: orderStatus(status),
      placedAt: placed,
      cancelReason: status == 'cancelled' && str(j['customer_notes']).isNotEmpty ? str(j['customer_notes']) : null,
      // Unpaid orders from the last two days still need a look.
      isNew: status == 'pending' && DateTime.now().difference(placed).inHours < 48,
    )
      ..serverId = intOrNull(j['id'])
      ..email = str(j['customer_email'])
      ..backendStatus = status;
    if (j['paid_at'] != null || status == 'paid' || status == 'processing' || status == 'completed') {
      order.payments.add(Payment(
        id: 'srv-o-${j['id']}-paid',
        invoiceId: '',
        invoiceNumber: '',
        customerName: order.customerName,
        amount: num0(j['total_amount']) > 0 ? num0(j['total_amount']) : order.total,
        method: str(j['payment_method']).isEmpty ? 'Bank Transfer' : str(j['payment_method']),
        providerCharge: 0,
        serviceCharge: 0,
        status: PaymentStatus.paid,
        date: date(j['paid_at']) ?? placed,
        settled: true,
        receiptNo: str(j['payment_reference']).isEmpty ? order.number : str(j['payment_reference']),
        orderId: order.id,
        orderNumber: order.number,
      ));
    }
    return order;
  }

  static void applyStorefront(Storefront s, Map<String, dynamic> j) {
    final (dial, phone) = splitPhone(str(j['store_phone']));
    s
      ..name = str(j['store_name'])
      ..description = str(j['store_description'])
      ..tagline = str(j['store_tagline'])
      ..dialCode = dial
      ..phone = phone
      ..email = str(j['store_email'])
      ..currency = str(j['currency']).isEmpty ? 'NGN' : str(j['currency'])
      ..slug = str(j['slug']).isEmpty ? s.slug : str(j['slug'])
      ..liveUrl = str(j['url']).isEmpty ? null : str(j['url'])
      ..bannerUrl = str(j['store_banner']).isEmpty ? null : str(j['store_banner'])
      ..hasBanner = str(j['store_banner']).isNotEmpty
      ..customDomain = str(j['custom_domain']).isEmpty ? null : str(j['custom_domain'])
      ..hasCustomDomainPlan = j['has_custom_domain_plan'] == true
      ..expectedCname = str(j['expected_cname']).isEmpty ? null : str(j['expected_cname']);
    final ds = j['domain_status'];
    if (ds is Map) s.domainStatus = str(ds['overall_status']);
  }

  static Map<String, String> storefrontFields(Storefront s) => {
        'store_name': s.name.trim(),
        'store_tagline': s.tagline,
        'store_description': s.description,
        'store_phone': s.phone.isEmpty ? '' : '${s.dialCode} ${s.phone}'.trim(),
        'store_email': s.email.trim(),
        'currency': s.currency.length == 3 ? s.currency : 'NGN',
      };

  // ------------------------------------------------------------ payment links

  /// A backend payment link as the app's [Invoice] with kind paymentLink.
  static Invoice paymentLink(Map<String, dynamic> j, {required Customer? Function(int?) findCustomer}) {
    final status = str(j['effective_status']).isEmpty ? str(j['status']) : str(j['effective_status']);
    final amount = num0(j['amount']);
    final client = j['client'] is Map ? j['client'] as Map : null;
    final link = Invoice(
      id: 'srv-l-${j['id']}',
      number: str(j['number']),
      linkNumber: str(j['number']),
      kind: DocKind.paymentLink,
      customer: findCustomer(intOrNull(j['client_id'])),
      customerNameOverride: str(j['customer_name']).isNotEmpty ? str(j['customer_name']) : (client == null ? null : str(client['name'])),
      customerPhone: str(j['customer_phone']),
      items: [LineItem(name: str(j['purpose']), unitPrice: amount, qty: 1)],
      dueDate: date(j['expires_at']),
      allowPartPayment: j['allow_part_payment'] == true || j['allow_part_payment'] == 1,
      status: switch (status) {
        'paid' => InvoiceStatus.paid,
        'disabled' => InvoiceStatus.cancelled,
        'pending' => InvoiceStatus.partlyPaid,
        _ => InvoiceStatus.unpaid,
      },
      createdAt: date(j['created_at']) ?? DateTime.now(),
      serverId: intOrNull(j['id']),
    )..linkUrl = str(j['url']).isEmpty ? null : str(j['url']);
    for (final t in (j['payments'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      link.payments.add(Payment(
        id: 'srv-t-${t['id']}',
        invoiceId: link.id,
        invoiceNumber: link.number,
        customerName: link.customerName,
        amount: num0(t['amount']),
        providerCharge: 0,
        serviceCharge: 0,
        status: PaymentStatus.paid,
        date: date(t['paid_at']) ?? date(t['created_at']) ?? DateTime.now(),
        settled: true,
        receiptNo: str(t['reference']),
      ));
    }
    // A paid link without a transaction list (list endpoint): still count what was paid.
    if (link.payments.isEmpty && num0(j['amount_paid']) > 0) {
      link.payments.add(Payment(
        id: 'srv-l-${j['id']}-paid',
        invoiceId: link.id,
        invoiceNumber: link.number,
        customerName: link.customerName,
        amount: num0(j['amount_paid']),
        providerCharge: 0,
        serviceCharge: 0,
        status: PaymentStatus.paid,
        date: date(j['paid_at']) ?? date(j['updated_at']) ?? DateTime.now(),
        settled: true,
        receiptNo: link.number,
      ));
    }
    return link;
  }

  static Map<String, dynamic> paymentLinkBody(Invoice l) => {
        'purpose': l.purpose,
        'amount': l.items.isEmpty ? 0 : l.items.first.unitPrice,
        if (l.customer?.serverId != null) 'client_id': l.customer!.serverId,
        if (l.customerNameOverride != null && l.customerNameOverride!.isNotEmpty) 'customer_name': l.customerNameOverride,
        if (l.customerPhone.isNotEmpty) 'customer_phone': l.customerPhone,
        if (l.dueDate != null) 'expires_at': l.dueDate!.toUtc().toIso8601String(),
        'allow_part_payment': l.allowPartPayment,
      };

  // ------------------------------------------------------------ credit notes & refunds

  static CreditNote creditNote(Map<String, dynamic> j, String invoiceId) => CreditNote(
        id: 'srv-cn-${j['id']}',
        number: str(j['number']),
        invoiceId: invoiceId,
        amount: num0(j['amount']),
        reason: str(j['reason']),
        date: date(j['created_at']) ?? DateTime.now(),
      );

  /// Null for a cancelled refund (the app doesn't show those).
  static RefundRequest? refund(Map<String, dynamic> j, String invoiceId) {
    final stage = switch (str(j['stage'])) {
      'approved' => RefundStage.approved,
      'confirmed' => RefundStage.confirmed,
      'refunded' => RefundStage.refunded,
      'requested' => RefundStage.requested,
      _ => null,
    };
    if (stage == null) return null;
    return RefundRequest(
      id: 'srv-rf-${j['id']}',
      invoiceId: invoiceId,
      amount: num0(j['amount']),
      reason: str(j['reason']),
      stage: stage,
      createdAt: date(j['created_at']) ?? DateTime.now(),
    );
  }

  // ------------------------------------------------------------ business profile & payout account

  static void applyBusiness(BusinessProfile p, Map<String, dynamic> j) {
    final (dial, phone) = splitPhone(str(j['phone']));
    p
      ..name = str(j['name'])
      ..type = str(j['type'])
      ..registrationNumber = str(j['registration_number'])
      ..dialCode = dial
      ..phone = phone
      ..email = str(j['email'])
      ..address = str(j['address'])
      ..currency = str(j['currency']).isEmpty ? 'NGN' : str(j['currency'])
      ..logoUrl = str(j['logo_url']).isEmpty ? null : str(j['logo_url'])
      ..hasLogo = str(j['logo_url']).isNotEmpty;
  }

  static Map<String, dynamic> businessBody(BusinessProfile p) => {
        'name': p.name.trim(),
        'type': p.type.trim(),
        'registration_number': p.registrationNumber.trim(),
        'phone': p.phone.trim().isEmpty ? '' : '${p.dialCode} ${p.phone.trim()}',
        'email': p.email.trim(),
        'address': p.address.trim(),
      };

  static void applySettlement(BusinessProfile p, Map<String, dynamic> j) {
    final a = j['account'];
    p.bank = a is Map
        ? BankAccount(bank: str(a['bank_name']), number: str(a['account_number_masked']), name: str(a['account_name']))
        : null;
    p.settlementBankCode = a is Map ? str(a['bank_code']) : null;
    p.bankHistory
      ..clear()
      ..addAll([
        for (final h in (j['history'] as List? ?? const []).whereType<Map>())
          BankChange(str(h['title']), str(h['detail']), date(h['created_at']) ?? DateTime.now()),
      ]);
  }

  // ------------------------------------------------------------ billing

  /// Home banner state from `GET /admin/billing`. Pay-as-you-go businesses
  /// have no expiry (they pay per action from the wallet).
  static PlanStatus planStatus(Map<String, dynamic> j) {
    if (str(j['billing_model']) != 'subscription') return PlanStatus.active;
    if (j['has_access'] == false) return PlanStatus.expired;
    final sub = j['subscription'];
    if (sub is Map) {
      if (sub['grace_period_ends_at'] != null && str(sub['status']) != 'active') return PlanStatus.grace;
      final end = date(sub['current_period_end']);
      if (end != null && end.difference(DateTime.now()).inDays <= 3) return PlanStatus.endingSoon;
    }
    if (j['on_trial'] == true) return PlanStatus.trial;
    return PlanStatus.active;
  }

  // ------------------------------------------------------------ KYC

  static VerificationStatus verification(String s) => switch (s) {
        'verified' => VerificationStatus.verified,
        'in_review' => VerificationStatus.inReview,
        _ => VerificationStatus.incomplete,
      };

  static void applyKyc(BusinessProfile p, Map<String, dynamic> j) {
    p.documentStatus.clear();
    p.documentNotes.clear();
    for (final d in (j['documents'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      final label = kycDocumentTypes[str(d['document_type'])];
      if (label == null) continue;
      final status = str(d['status']);
      p.documents[label] = status == 'missing' || status.isEmpty ? null : (str(d['file_name']).isEmpty ? label : str(d['file_name']));
      if (status != 'missing') p.documentStatus[label] = status;
      if (str(d['rejection_reason']).isNotEmpty) p.documentNotes[label] = str(d['rejection_reason']);
    }
    p.verification = verification(str(j['status']));
  }
}
