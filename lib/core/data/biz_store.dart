import 'package:flutter/foundation.dart';
import 'business_models.dart';
import 'models.dart';

export 'business_models.dart';
export 'models.dart';

/// In-memory copy of the signed-in business, loaded from the backend by
/// LiveSession; changes are pushed back through [remote]. Screens only talk to this class.
class BizStore extends ChangeNotifier {
  BizStore._();
  static final BizStore instance = BizStore._();

  /// Empty until the backend loads the signed-in account.
  Account account = Account(ownerFirstName: '', ownerFullName: '', businessName: '', businessPhone: '', email: '', phone: '', plan: PlanStatus.active, verified: true);
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
  /// null when signed out. Mutations are pushed to it in the background.
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
