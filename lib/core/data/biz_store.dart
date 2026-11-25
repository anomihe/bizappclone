import 'package:flutter/foundation.dart';
import 'business_models.dart';
import 'models.dart';

export 'business_models.dart';
export 'models.dart';

/// In-memory app state with demo data. Swap the method bodies for API calls
/// when the backend is ready; screens only talk to this class.
class BizStore extends ChangeNotifier {
  BizStore._();
  static final BizStore instance = BizStore._();

  Account account = _demoAccount();
  final List<Customer> customers = [];
  final List<Invoice> invoices = [];
  final List<Quotation> quotations = [];
  final List<AppNotification> notifications = [];

  // Store, orders, team, business settings.
  final List<ProductCategory> categories = [];
  final List<Product> products = [];
  final List<Order> orders = [];
  final List<StaffMember> staff = [];
  Storefront storefront = Storefront(name: '', description: '', phone: '', email: '', slug: 'store');
  BusinessProfile profile = BusinessProfile(name: '');

  /// Whether a user has signed in on this device before ("Welcome back" screen).
  bool hasRememberedUser = false;
  bool bannerDismissed = false;

  /// Set while signed in to the real backend (see core/api/live_session.dart);
  /// null in demo mode. Mutations are pushed to it in the background.
  BizRemote? remote;

  /// Payments that aren't linked to an invoice or order (from the backend).
  final List<Payment> otherPayments = [];

  /// More → Settings → Notifications.
  final Map<String, bool> notificationPrefs = {
    'Payment received': true,
    'Invoice overdue': true,
    'New storefront orders': true,
    'Refund updates': true,
    'Tips and product news': false,
  };

  void setNotificationPref(String key, bool on) {
    notificationPrefs[key] = on;
    notifyListeners();
  }

  int _seq = 100;
  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  // ---------------------------------------------------------------- session

  /// Fresh workspace after sign-up: no customers, invoices or payments yet.
  void startNewWorkspace({
    required String businessName,
    required String email,
    required String dialCode,
    required String phone,
    required String category,
    required String currency,
  }) {
    account = Account(
      ownerFirstName: 'there',
      ownerFullName: businessName,
      businessName: businessName,
      businessPhone: '$dialCode $phone',
      email: email,
      dialCode: dialCode,
      phone: phone,
      category: category,
      currency: currency,
      plan: PlanStatus.trial,
      trialDaysLeft: 7,
    );
    customers.clear();
    invoices.clear();
    quotations.clear();
    products.clear();
    orders.clear();
    categories
      ..clear()
      ..addAll(_defaultCategories(category));
    staff
      ..clear()
      ..add(StaffMember(id: _id(), name: businessName, email: email, phone: '$dialCode $phone', role: StaffRole.owner, lastActive: DateTime.now()));
    final slug = businessName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    storefront = Storefront(name: businessName, description: '', dialCode: dialCode, phone: phone, email: email, slug: slug.isEmpty ? 'store' : slug);
    profile = BusinessProfile(name: businessName, type: category, dialCode: dialCode, phone: phone, email: email);
    notifications
      ..clear()
      ..add(AppNotification(
        title: 'Welcome to Bizpaddi',
        body: 'Create your first invoice and get paid faster.',
        time: DateTime.now(),
        type: NotificationType.system,
      ));
    bannerDismissed = false;
    hasRememberedUser = true;
    notifyListeners();
  }

  /// Existing user log in: load the demo business.
  void loadDemoWorkspace() {
    if (invoices.isEmpty && customers.isEmpty) _seed();
    hasRememberedUser = true;
    notifyListeners();
  }

  /// Replaces the workspace with data loaded from the backend.
  void applyLiveData({
    required Account account,
    required List<Customer> customers,
    required List<Invoice> invoices,
    required List<Quotation> quotations,
    required List<Payment> otherPayments,
    required List<StaffMember> staff,
    required List<AppNotification> notifications,
  }) {
    this.account = account;
    this.customers
      ..clear()
      ..addAll(customers);
    this.invoices
      ..clear()
      ..addAll(invoices);
    this.quotations
      ..clear()
      ..addAll(quotations);
    this.otherPayments
      ..clear()
      ..addAll(otherPayments);
    this.staff
      ..clear()
      ..addAll(staff);
    this.notifications
      ..clear()
      ..addAll(notifications);
    // Not in the backend API yet: start empty rather than mixing in demo data.
    products.clear();
    orders.clear();
    storefront = Storefront(name: account.businessName, description: '', phone: account.phone, email: account.email, slug: 'store');
    profile = BusinessProfile(name: account.businessName, phone: account.phone, email: account.email);
    bannerDismissed = false;
    hasRememberedUser = true;
    notifyListeners();
  }

  /// Notify listeners after an in-place change made outside the store.
  void refresh() => notifyListeners();

  void logOut() {
    bannerDismissed = false;
    notifyListeners();
  }

  void setBiometrics(bool on) {
    account.biometricsEnabled = on;
    notifyListeners();
  }

  void dismissBanner() {
    bannerDismissed = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- queries

  /// Every payment — from invoices, payment links and storefront orders.
  List<Payment> get payments {
    final all = [...invoices.expand((i) => i.payments), ...orders.expand((o) => o.payments), ...otherPayments];
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  Order? orderById(String? id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<Payment> paymentsFor(Customer c) =>
      payments.where((p) => p.customerName == c.name).toList();

  List<Invoice> get paymentLinks => invoices.where((i) => i.kind == DocKind.paymentLink).toList();

  int get newOrderCount => orders.where((o) => o.isNew && o.status != OrderStatus.cancelled).length;
  int get ordersToFulfil => orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.processing).length;

  ProductCategory? categoryById(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  int productCountIn(ProductCategory c) => products.where((p) => p.categoryId == c.id).length;

  StaffMember? get owner {
    for (final s in staff) {
      if (s.role == StaffRole.owner) return s;
    }
    return null;
  }

  Invoice? invoiceById(String id) {
    for (final i in invoices) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<Invoice> invoicesFor(Customer c) =>
      invoices.where((i) => i.customer?.id == c.id && i.kind == DocKind.invoice).toList();
  List<Quotation> quotationsFor(Customer c) => quotations.where((q) => q.customer?.id == c.id).toList();

  double owedBy(Customer c) => invoices
      .where((i) => i.customer?.id == c.id && _isOpen(i.status))
      .fold(0, (s, i) => s + i.balance);
  double paidBy(Customer c) =>
      invoices.where((i) => i.customer?.id == c.id).fold(0, (s, i) => s + i.paid);

  bool _isOpen(InvoiceStatus s) =>
      s == InvoiceStatus.unpaid || s == InvoiceStatus.partlyPaid || s == InvoiceStatus.overdue;

  // Dashboard figures (for a period starting at `from`).
  double collected(DateTime from, [DateTime? to]) => _paymentsIn(from, to)
      .where((p) => p.paidByCustomer)
      .fold(0, (s, p) => s + p.amount);
  double settled(DateTime from, [DateTime? to]) => _paymentsIn(from, to)
      .where((p) => p.settled)
      .fold(0, (s, p) => s + p.youReceive);
  double onItsWay(DateTime from, [DateTime? to]) => _paymentsIn(from, to)
      .where((p) => p.paidByCustomer && !p.settled)
      .fold(0, (s, p) => s + p.youReceive);
  double get outstanding => invoices
      .where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partlyPaid)
      .fold(0, (s, i) => s + i.balance);
  double get overdue =>
      invoices.where((i) => i.status == InvoiceStatus.overdue).fold(0, (s, i) => s + i.balance);
  int get overdueCount => invoices.where((i) => i.status == InvoiceStatus.overdue).length;
  double get pendingPayments => payments
      .where((p) => p.status == PaymentStatus.pending)
      .fold(0, (s, p) => s + p.amount);
  double todaysCollected() {
    final now = DateTime.now();
    return collected(DateTime(now.year, now.month, now.day));
  }

  Iterable<Payment> _paymentsIn(DateTime from, DateTime? to) =>
      payments.where((p) => !p.date.isBefore(from) && (to == null || p.date.isBefore(to)));

  /// Daily collected totals for the last [days] days, oldest first.
  List<double> dailyCollected(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return List.generate(days, (i) {
      final d = start.add(Duration(days: i));
      return collected(d, d.add(const Duration(days: 1)));
    });
  }

  // ---------------------------------------------------------------- customers

  Customer addCustomer({required String name, required String dialCode, required String phone, String email = '', String notes = ''}) {
    final c = Customer(id: _id(), name: name, dialCode: dialCode, phone: phone, email: email, notes: notes);
    customers.insert(0, c);
    notifyListeners();
    remote?.saveCustomer(c);
    return c;
  }

  void updateCustomer(Customer c) {
    notifyListeners();
    remote?.saveCustomer(c);
  }

  /// Removes a customer (their invoices stay, with the name on them).
  void deleteCustomer(Customer c) {
    customers.remove(c);
    notifyListeners();
    remote?.deleteCustomer(c);
  }

  // ---------------------------------------------------------------- invoices

  String nextInvoiceNumber() {
    final n = invoices.length + 44;
    return '#${n.toString().padLeft(4, '0')}';
  }

  String nextQuotationNumber() => 'Q-${(quotations.length + 16).toString().padLeft(3, '0')}';

  Invoice saveInvoice(Invoice draft, {required bool issue}) {
    draft.status = issue ? InvoiceStatus.unpaid : InvoiceStatus.draft;
    if (!invoices.contains(draft)) invoices.insert(0, draft);
    if (issue) {
      notifications.insert(
        0,
        AppNotification(
          title: draft.kind == DocKind.paymentLink ? 'Payment link created' : 'Invoice issued',
          body: '${draft.number} · ${draft.customerName}',
          time: DateTime.now(),
          type: NotificationType.invoice,
        ),
      );
    }
    notifyListeners();
    // Payment links are app-only until the backend has a payment-link API.
    if (draft.kind == DocKind.invoice) remote?.saveInvoice(draft);
    return draft;
  }

  Invoice newInvoiceDraft({DocKind kind = DocKind.invoice}) => Invoice(
        id: _id(),
        number: nextInvoiceNumber(),
        kind: kind,
        linkNumber: kind == DocKind.paymentLink ? '#${(paymentLinks.length + 1).toString().padLeft(4, '0')}' : '',
        items: [],
        createdAt: DateTime.now(),
      );

  /// "Change Expiry Date" on a payment link; null = never expires.
  void setLinkExpiry(Invoice link, DateTime? expiry) {
    link.dueDate = expiry;
    notifyListeners();
  }

  void voidInvoice(Invoice i) {
    i.status = i.kind == DocKind.paymentLink ? InvoiceStatus.cancelled : InvoiceStatus.voided;
    notifyListeners();
    if (i.kind == DocKind.invoice) remote?.saveInvoice(i);
  }

  /// Deletes a draft invoice (issued invoices are voided instead).
  void deleteDraft(Invoice i) {
    invoices.remove(i);
    notifyListeners();
    if (i.kind == DocKind.invoice) remote?.deleteInvoice(i);
  }

  void deleteQuotation(Quotation q) {
    quotations.remove(q);
    notifyListeners();
    remote?.deleteQuotation(q);
  }

  CreditNote issueCreditNote(Invoice i, double amount, String reason) {
    final cn = CreditNote(
      id: _id(),
      number: 'CN-${(42 + invoices.fold<int>(0, (s, x) => s + x.creditNotes.length)).toString().padLeft(4, '0')}',
      invoiceId: i.id,
      amount: amount,
      reason: reason,
      date: DateTime.now(),
    );
    i.creditNotes.add(cn);
    notifyListeners();
    return cn;
  }

  RefundRequest requestRefund(Invoice i, double amount, String reason) {
    final r = RefundRequest(id: _id(), invoiceId: i.id, amount: amount, reason: reason, createdAt: DateTime.now());
    i.refunds.add(r);
    notifyListeners();
    return r;
  }

  // ---------------------------------------------------------------- quotations

  Quotation newQuotationDraft() =>
      Quotation(id: _id(), number: nextQuotationNumber(), items: [], createdAt: DateTime.now());

  Quotation saveQuotation(Quotation q, {required bool send}) {
    q.status = send ? QuotationStatus.sent : QuotationStatus.draft;
    // The validity clock starts when the quotation is sent.
    q.validTill = DateTime.now().add(Duration(days: q.validityDays));
    if (!quotations.contains(q)) quotations.insert(0, q);
    notifyListeners();
    remote?.saveQuotation(q);
    return q;
  }

  void acceptQuotation(Quotation q) {
    q.status = QuotationStatus.accepted;
    notifyListeners();
    remote?.saveQuotation(q);
  }

  /// "Use to Create New Quotation" on an expired quote.
  Quotation duplicateQuotation(Quotation q) => Quotation(
        id: _id(),
        number: nextQuotationNumber(),
        customer: q.customer,
        items: q.items.map((e) => e.copy()).toList(),
        discount: q.discount,
        notes: q.notes,
        addVat: q.addVat,
        validityDays: q.validityDays,
        createdAt: DateTime.now(),
      );

  Invoice invoiceFromQuotation(Quotation q) => Invoice(
        id: _id(),
        number: nextInvoiceNumber(),
        customer: q.customer,
        items: [
          ...q.items.map((e) => e.copy()),
          if (q.addVat) LineItem(name: 'VAT (7.5%)', unitPrice: q.vat, qty: 1),
        ],
        discount: q.discount,
        notes: q.notes,
        createdAt: DateTime.now(),
      );

  // ---------------------------------------------------------------- products & storefront

  Product addProduct(Product p) {
    products.insert(0, p);
    notifyListeners();
    return p;
  }

  Product newProductDraft() => Product(id: _id(), name: '', sku: 'ID${(products.length + 1001)}', price: 0);

  void updateProduct(Product p) => notifyListeners();

  void deleteProduct(Product p) {
    products.remove(p);
    notifyListeners();
  }

  ProductCategory addCategory(String name) {
    // Live mode keys categories by name (the API stores the category as text).
    final c = ProductCategory(id: remote != null ? 'cat:${name.trim().toLowerCase()}' : _id(), name: name.trim());
    categories.add(c);
    notifyListeners();
    return c;
  }

  void removeCategory(ProductCategory c) {
    categories.remove(c);
    for (final p in products.where((p) => p.categoryId == c.id)) {
      p.categoryId = null;
    }
    notifyListeners();
  }

  void updateStorefront() => notifyListeners();

  // ---------------------------------------------------------------- orders

  void markOrderSeen(Order o) {
    if (!o.isNew) return;
    o.isNew = false;
    notifyListeners();
  }

  void cancelOrder(Order o, String reason) {
    o
      ..status = OrderStatus.cancelled
      ..cancelReason = reason;
    notifyListeners();
  }

  void completeOrder(Order o) {
    o.status = OrderStatus.completed;
    notifyListeners();
  }

  // ---------------------------------------------------------------- team

  StaffMember inviteStaff({required String contact, required StaffRole role, required Set<Permission> permissions}) {
    final isEmail = contact.contains('@');
    final m = StaffMember(
      id: _id(),
      name: isEmail ? contact.split('@').first : contact,
      email: isEmail ? contact : '',
      phone: isEmail ? '' : contact,
      role: role,
      status: StaffStatus.invited,
      permissions: permissions,
      lastActive: DateTime.now(),
    );
    staff.add(m);
    notifyListeners();
    return m;
  }

  void updateStaff(StaffMember m) {
    notifyListeners();
    remote?.updateStaff(m);
  }

  void removeStaff(StaffMember m) {
    staff.remove(m);
    notifyListeners();
    remote?.removeStaff(m);
  }

  // ---------------------------------------------------------------- business profile

  void updateProfile() {
    account.businessName = profile.name;
    notifyListeners();
  }

  void uploadDocument(String key, String fileName) {
    profile.documents[key] = fileName;
    notifyListeners();
  }

  /// Once info and documents are in, the profile goes to review.
  void submitForReview() {
    if (profile.infoComplete && profile.documentsComplete && profile.verification == VerificationStatus.incomplete) {
      profile.verification = VerificationStatus.inReview;
      notifyListeners();
    }
  }

  void setBankAccount(BankAccount bank) {
    final hadBank = profile.bank != null;
    profile.bank = bank;
    profile.bankHistory.insert(0, BankChange(hadBank ? 'Account Number Changed' : 'Bank Details Added', '${bank.bank} · ${bank.masked}', DateTime.now()));
    notifyListeners();
  }

  /// Stand-in for account-name lookup (NIBSS name enquiry) until the API exists.
  Future<String?> resolveAccountName(String bank, String number) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (number.length != 10) return null;
    return profile.name.toUpperCase();
  }

  // ---------------------------------------------------------------- reports

  /// Counts used by Reports → Payment Statistics.
  Map<PaymentStatus, int> paymentCounts(DateTime from, [DateTime? to]) {
    final m = {for (final s in PaymentStatus.values) s: 0};
    for (final p in _paymentsIn(from, to)) {
      m[p.status] = m[p.status]! + 1;
    }
    return m;
  }

  Map<InvoiceStatus, int> invoiceCounts(DateTime from, [DateTime? to]) {
    final m = {for (final s in InvoiceStatus.values) s: 0};
    for (final i in invoices.where((i) => i.kind == DocKind.invoice && !i.createdAt.isBefore(from) && (to == null || i.createdAt.isBefore(to)))) {
      m[i.status] = m[i.status]! + 1;
    }
    return m;
  }

  double invoicedIn(DateTime from, [DateTime? to]) => invoices
      .where((i) => i.status != InvoiceStatus.draft && i.status != InvoiceStatus.voided && !i.createdAt.isBefore(from) && (to == null || i.createdAt.isBefore(to)))
      .fold(0, (s, i) => s + i.total);

  List<Order> ordersIn(DateTime from, [DateTime? to]) =>
      orders.where((o) => !o.placedAt.isBefore(from) && (to == null || o.placedAt.isBefore(to))).toList();

  List<ProductCategory> _defaultCategories(String businessCategory) => [
        for (final n in ['Fabrics', 'Accessories', 'Services']) ProductCategory(id: _id(), name: n),
      ];

  // ---------------------------------------------------------------- notifications

  int get unreadCount => notifications.where((n) => !n.read).length;

  void markAllRead() {
    final hadUnread = unreadCount > 0;
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
    if (hadUnread) remote?.markAllRead();
  }

  void markRead(AppNotification n) {
    if (n.read) return;
    n.read = true;
    notifyListeners();
    remote?.markRead(n);
  }

  // ---------------------------------------------------------------- demo data

  static Account _demoAccount() => Account(
        ownerFirstName: 'Michael',
        ownerFullName: 'Michael Adalikwu',
        businessName: 'Mama Nkechi Foods',
        businessPhone: '0803 555 0142',
        email: 'michaeladalikwu@gmail.com',
        phone: '8035550142',
        plan: PlanStatus.trial,
        trialDaysLeft: 5,
        verified: true,
      );

  void _seed() {
    account = _demoAccount();
    final now = DateTime.now();
    DateTime daysAgo(int d, [int h = 11, int m = 2]) =>
        DateTime(now.year, now.month, now.day, h, m).subtract(Duration(days: d));

    final ada = Customer(id: _id(), name: 'Ada Obi', phone: '0803 555 0142', email: 'ada@gmail.com');
    final michael = Customer(id: _id(), name: 'Michael George', phone: '0802 555 0141', email: 'mike@gmail.com', notes: 'Prefers WhatsApp Calls');
    final chioma = Customer(id: _id(), name: 'Mama Chioma Stores', phone: '0807 555 0181', email: 'chioma@mail.com', notes: 'Prefers WhatsApp');
    final kola = Customer(id: _id(), name: 'Kola Damola', phone: '0803 555 0142');
    final chidi = Customer(id: _id(), name: 'Mama Chidi Stores', phone: '0805 555 0110');
    final tunde = Customer(id: _id(), name: 'Tunde Bakare', phone: '0809 555 0177');
    final emeka = Customer(id: _id(), name: 'Emeka Nwosu', phone: '0811 555 0123');
    final ibrahim = Customer(id: _id(), name: 'Ibrahim Musa', phone: '0813 555 0199');
    customers
      ..clear()
      ..addAll([ada, michael, chioma, kola, chidi, tunde, emeka, ibrahim]);

    List<LineItem> items(double a, double b) => [
          LineItem(name: 'Ankara', unitPrice: a, qty: 4),
          LineItem(name: 'Gown', unitPrice: b, qty: 4),
        ];

    int n = 30;
    Invoice inv(Customer c, List<LineItem> it, InvoiceStatus st, int createdDaysAgo, int dueInDays,
        {DocKind kind = DocKind.invoice, bool part = false}) {
      final i = Invoice(
        id: _id(),
        number: '#${(n++).toString().padLeft(4, '0')}',
        kind: kind,
        customer: c,
        items: it,
        status: st,
        allowPartPayment: part,
        createdAt: daysAgo(createdDaysAgo),
        dueDate: daysAgo(createdDaysAgo).add(Duration(days: dueInDays)),
      );
      invoices.insert(0, i);
      return i;
    }

    Payment pay(Invoice i, double amount, PaymentStatus st, DateTime when, {bool settled = false}) {
      final p = Payment(
        id: _id(),
        invoiceId: i.id,
        invoiceNumber: i.number,
        customerName: i.customerName,
        amount: amount,
        status: st,
        date: when,
        settled: settled,
        receiptNo: 'R-${i.number.substring(1)}-${100 + i.payments.length + 2}',
      );
      i.payments.add(p);
      return p;
    }

    invoices.clear();
    quotations.clear();

    // Historical paid invoices to fill the revenue trend.
    final weekly = [42000.0, 55000.0, 38000.0, 61000.0, 47000.0, 70000.0, 92500.0];
    for (var d = 0; d < 7; d++) {
      final c = [chidi, ada, tunde, kola, chioma, emeka, ibrahim][d];
      final amount = weekly[6 - d];
      final i = inv(c, [LineItem(name: 'Assorted order', unitPrice: amount, qty: 1)], InvoiceStatus.unpaid, d + 3, 14);
      pay(i, amount, PaymentStatus.paid, daysAgo(d, 9 + d, 10 + d), settled: d > 1);
    }

    // Overdue invoices.
    final o1 = inv(michael, items(5833.25, 3416.75), InvoiceStatus.unpaid, 30, 10);
    pay(o1, 37000, PaymentStatus.failed, daysAgo(12));
    inv(ibrahim, items(5000, 3500), InvoiceStatus.unpaid, 25, 7);
    inv(emeka, items(6000, 3000), InvoiceStatus.unpaid, 40, 14);

    // Unpaid & partly paid.
    final u1 = inv(tunde, items(1500, 1000), InvoiceStatus.unpaid, 2, 10, part: true);
    pay(u1, 5000, PaymentStatus.partlyPaid, daysAgo(1, 15, 20));
    final u2 = inv(chioma, items(5833.25, 3416.75), InvoiceStatus.unpaid, 1, 14);
    pay(u2, 37000, PaymentStatus.pending, daysAgo(0, 10, 34));

    // Paid with a refund + credit note.
    final p1 = inv(chidi, items(4625, 4625), InvoiceStatus.unpaid, 4, 10);
    pay(p1, 37000, PaymentStatus.paid, daysAgo(0, 10, 34));
    p1.creditNotes.add(CreditNote(id: _id(), number: 'CN-0042', invoiceId: p1.id, amount: 2000, reason: 'Cancelled Order', date: daysAgo(0)));
    p1.refunds.add(RefundRequest(id: _id(), invoiceId: p1.id, amount: 2000, reason: 'Customer returned item', stage: RefundStage.approved, createdAt: daysAgo(0)));

    final p2 = inv(ada, items(5000, 4250), InvoiceStatus.unpaid, 6, 10);
    pay(p2, 37000, PaymentStatus.refunded, daysAgo(5));
    p2.refunds.add(RefundRequest(id: _id(), invoiceId: p2.id, amount: 37000, reason: 'Customer returned item', stage: RefundStage.refunded, createdAt: daysAgo(4)));

    // Drafts.
    inv(kola, items(3000, 2000), InvoiceStatus.draft, 0, 14);

    // Payment links: active, paid, pending, expired, disabled.
    var linkNo = 1;
    Invoice link(Customer c, String purpose, double amount, InvoiceStatus st, int createdDaysAgo, int expiresIn) =>
        inv(c, [LineItem(name: purpose, unitPrice: amount, qty: 1)], st, createdDaysAgo, expiresIn, kind: DocKind.paymentLink)
          ..linkNumber = '#${(linkNo++).toString().padLeft(4, '0')}'
          ..customerPhone = c.phone;
    link(michael, 'Gucci Bags', 37000, InvoiceStatus.unpaid, 0, 7);
    final paidLink = link(chidi, 'Catering deposit', 10000, InvoiceStatus.unpaid, 2, 10);
    pay(paidLink, 10000, PaymentStatus.paid, daysAgo(1, 11, 2), settled: true);
    final pendingLink = link(kola, 'Cake order', 10000, InvoiceStatus.unpaid, 1, 10);
    pay(pendingLink, 10000, PaymentStatus.pending, daysAgo(0, 9, 40));
    link(tunde, 'Booking fee', 10000, InvoiceStatus.unpaid, 12, 5); // expired
    link(emeka, 'Gown balance', 12000, InvoiceStatus.cancelled, 3, 7);

    // Quotations.
    quotations.addAll([
      Quotation(id: _id(), number: 'Q-013', customer: tunde, items: items(1250, 1250), status: QuotationStatus.accepted, createdAt: daysAgo(10), validTill: daysAgo(-4), validityDays: 14),
      Quotation(id: _id(), number: 'Q-014', customer: emeka, items: items(3000, 2500), status: QuotationStatus.sent, createdAt: daysAgo(3), validTill: daysAgo(-11), validityDays: 14, addVat: true),
      Quotation(id: _id(), number: 'Q-015', customer: tunde, items: items(1500, 1000), status: QuotationStatus.draft, createdAt: daysAgo(1)),
      // Sent but past its validity -> derived as Expired.
      Quotation(id: _id(), number: 'Q-012', customer: michael, items: items(5833.25, 3416.75), status: QuotationStatus.sent, createdAt: daysAgo(30), validTill: daysAgo(16)),
    ]);

    _seedBusiness(daysAgo, [ada, chidi, michael]);

    notifications
      ..clear()
      ..addAll([
        AppNotification(title: 'Payment received', body: '₦40,000.00 from Tunde Bakare', time: now.subtract(const Duration(hours: 2)), type: NotificationType.payment),
        AppNotification(title: 'Invoice overdue', body: '#0030 · Michael George', time: now.subtract(const Duration(hours: 2)), type: NotificationType.invoice),
        AppNotification(title: 'Welcome to Bizpaddi', body: 'Create your first invoice and get paid faster.', time: now.subtract(const Duration(days: 9)), type: NotificationType.system, read: true),
      ]);
  }

  /// Demo store, orders, team and business profile (matching the Figma copy).
  void _seedBusiness(DateTime Function(int, [int, int]) daysAgo, List<Customer> cs) {
    // Categories & products.
    final fabrics = ProductCategory(id: _id(), name: 'Fabrics');
    final readyMade = ProductCategory(id: _id(), name: 'Ready Made');
    final uniforms = ProductCategory(id: _id(), name: 'Uniforms');
    final accessories = ProductCategory(id: _id(), name: 'Accessories');
    categories
      ..clear()
      ..addAll([fabrics, readyMade, uniforms, accessories]);
    products
      ..clear()
      ..addAll([
        Product(id: _id(), name: 'School Uniform Set', unitLabel: '5 yards/piece', sku: 'ID1001', price: 6000, categoryId: uniforms.id, quantity: 24, photos: [0], description: 'Shirt, shorts and tie in sizes 4–14.'),
        Product(id: _id(), name: 'Ankara Fabric (6 yards)', unitLabel: '6 yards/piece', sku: 'ID1002', price: 5500, categoryId: fabrics.id, quantity: 3, photos: [1]),
        Product(id: _id(), name: 'Lace Gown', unitLabel: '1 piece', sku: 'ID1003', price: 18000, discount: 2000, categoryId: readyMade.id, quantity: 9, photos: [2]),
        Product(id: _id(), name: 'Beaded Necklace', unitLabel: '1 piece', sku: 'ID1004', price: 3500, categoryId: accessories.id, quantity: 0, photos: [3], showOnStorefront: false),
      ]);

    storefront = Storefront(
      name: 'Bello Fabrics Store',
      description: 'Fabrics, ready-made outfits and uniforms from Central Market.',
      phone: '8162522424',
      email: 'hello@bellofabrics.example',
      slug: 'bello-fabrics',
      hasLogo: true,
    );

    // Orders.
    Order order(String number, String name, String phone, OrderStatus st, int ago, {bool isNew = false}) => Order(
          id: _id(),
          number: number,
          customerName: name,
          phone: phone,
          address: '7 Bode Thomas Street, Surulere, Lagos',
          items: [LineItem(name: 'Ankara', unitPrice: 6500, qty: 4), LineItem(name: 'Gown', unitPrice: 4000, qty: 3)],
          status: st,
          placedAt: daysAgo(ago, 9, 47),
          isNew: isNew,
        );
    final o1 = order('ORD-1012', 'Ngozi Obi', '0813 555 0191', OrderStatus.pending, 0, isNew: true);
    final o2 = order('ORD-1011', 'Mama Chidi Stores', '0805 555 0110', OrderStatus.processing, 1);
    o2.payments.add(Payment(
      id: _id(),
      invoiceId: '',
      invoiceNumber: '',
      orderId: o2.id,
      orderNumber: o2.number,
      customerName: o2.customerName,
      amount: o2.total,
      status: PaymentStatus.paid,
      date: daysAgo(1, 11, 2),
      receiptNo: 'R-0042-102',
    ));
    final o3 = order('ORD-1009', 'Kola Damola', '0803 555 0142', OrderStatus.cancelled, 4)..cancelReason = 'Out of Stock';
    orders
      ..clear()
      ..addAll([o1, o2, o3]);

    // Team.
    final now = DateTime.now();
    staff
      ..clear()
      ..addAll([
        StaffMember(id: _id(), name: account.ownerFullName, email: account.email, phone: account.businessPhone, role: StaffRole.owner, lastActive: now),
        StaffMember(id: _id(), name: 'Michael George', phone: '0807 555 0191', email: 'michael@mail.com', role: StaffRole.administrator, lastActive: now.subtract(const Duration(days: 1)), invoicesCreated: 12, paymentsHandled: 9),
        StaffMember(id: _id(), name: 'Segun Ajayi', phone: '0807 550 0191', email: 'segun@mail.com', role: StaffRole.administrator, lastActive: now.subtract(const Duration(days: 3)), invoicesCreated: 5, paymentsHandled: 5),
        StaffMember(id: _id(), name: 'Amaka Eze', phone: '0809 555 0122', email: 'amaka@mail.com', role: StaffRole.manager, lastActive: now.subtract(const Duration(days: 14)), invoicesCreated: 5, paymentsHandled: 5),
        StaffMember(id: _id(), name: 'Kola Damola', phone: '0803 555 0142', role: StaffRole.accountant, status: StaffStatus.deactivated, lastActive: now.subtract(const Duration(days: 30))),
        StaffMember(id: _id(), name: 'Mama Chioma Stores', email: 'chioma@mail.com', role: StaffRole.cashier, status: StaffStatus.invited, lastActive: now),
      ]);

    // Business profile (incomplete: docs missing, so the user can try the flow).
    profile = BusinessProfile(
      name: account.businessName,
      type: 'Foods & Refreshments',
      registrationNumber: 'RC1234567890',
      phone: '8035550142',
      email: account.email,
      address: '12 Allen Avenue, Ikeja, Lagos',
      currency: 'Nigeria Naira (NGN)',
      hasLogo: true,
      documents: {'CAC Certificate': 'CAC Certificate.png', 'Director’s ID': null, 'Utility Bill': null, 'Tax Clearance': null},
      bank: const BankAccount(bank: 'GTBank', number: '0123456789', name: 'MAMA NKECHI FOODS'),
      bankHistory: [
        BankChange('Account Number Changed', 'GTBank · ******* 6789', daysAgo(10)),
        BankChange('Bank Details Added', 'Access Bank · ******* 2210', daysAgo(60)),
      ],
    );
    cs.length; // customers reserved for future order linkage
  }
}

/// Backend sync hooks. Implementations report their own errors (the store
/// stays responsive and never awaits these).
abstract class BizRemote {
  Future<void> saveCustomer(Customer c);
  Future<void> saveInvoice(Invoice i);
  Future<void> saveQuotation(Quotation q);
  Future<void> updateStaff(StaffMember m);
  Future<void> removeStaff(StaffMember m);
  Future<void> markAllRead();
  Future<void> markRead(AppNotification n);
  Future<void> deleteCustomer(Customer c);
  Future<void> deleteInvoice(Invoice i);
  Future<void> deleteQuotation(Quotation q);
}
