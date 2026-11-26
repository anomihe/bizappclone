import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/data/biz_store.dart';

/// Sample business for the screen and flow tests only (the app itself shows
/// only what the backend returns). Mirrors the Figma copy.
var _seq = 100;
String _id() => 'sample-${_seq++}';

extension SampleWorkspace on BizStore {
  /// Fills the store with a sample business, as if the backend had loaded it.
  void loadSampleWorkspace() {
    if (invoices.isEmpty && customers.isEmpty) _seed();
    hasRememberedUser = true;
    refresh();
  }

  static Account sampleAccount() => Account(
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
    account = SampleWorkspace.sampleAccount();
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

/// Signs the session in as a staff member or customer for screen tests
/// (their data then comes from the fake backend).
extension TestAccount on LiveSession {
  void useTestAccount(AccountRole r) {
    role = r;
    portalAccount.value = switch (r) {
      AccountRole.owner => null,
      AccountRole.staff => const PortalAccount(id: 5, name: 'Amaka Eze', email: 'amaka@shop.ng', role: AccountRole.staff, phone: '0803', jobRole: 'pm', department: 'Production'),
      AccountRole.customer => const PortalAccount(id: 11, name: 'Chidi Okafor', email: 'chidi@mail.com', role: AccountRole.customer, companyName: 'Mama Chidi Stores'),
    };
  }
}
