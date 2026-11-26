import 'package:flutter/material.dart';

class Customer {
  final String id;
  String name;
  String dialCode;
  String phone;
  String email;
  String notes;

  /// Backend id when synced with the Bizpaddi API.
  int? serverId;

  Customer({
    required this.id,
    required this.name,
    this.dialCode = '+234',
    required this.phone,
    this.email = '',
    this.notes = '',
  });
}

class LineItem {
  String name;
  double unitPrice;
  int qty;

  LineItem({required this.name, required this.unitPrice, required this.qty});

  double get total => unitPrice * qty;
  LineItem copy() => LineItem(name: name, unitPrice: unitPrice, qty: qty);
}

enum DocKind { invoice, paymentLink }

enum InvoiceStatus { draft, unpaid, partlyPaid, paid, overdue, cancelled, voided }

enum PaymentStatus { paid, pending, partlyPaid, failed, refunded }

enum QuotationStatus { draft, sent, accepted, expired }

enum RefundStage { requested, approved, confirmed, refunded }

class Payment {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final double amount;
  final String method;
  final String provider;
  final double providerCharge;
  final double serviceCharge;
  PaymentStatus status;
  final DateTime date;
  bool settled;
  final String receiptNo;

  /// Set when the payment came from a storefront order instead of an invoice.
  final String? orderId;
  final String? orderNumber;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    this.method = 'Bank Transfer',
    this.provider = 'Billway - Wema Bank',
    this.providerCharge = 325,
    this.serviceCharge = 225,
    required this.status,
    required this.date,
    this.settled = false,
    required this.receiptNo,
    this.orderId,
    this.orderNumber,
  });

  bool get isOrder => orderId != null;

  /// "Invoice #0042" or "Order ORD-1011".
  String get sourceLabel => isOrder ? 'Order $orderNumber' : 'Invoice $invoiceNumber';
  String get reference => receiptNo;
  double get youReceive => amount - providerCharge - serviceCharge;
  bool get paidByCustomer => status == PaymentStatus.paid || status == PaymentStatus.partlyPaid || status == PaymentStatus.refunded;
}

class CreditNote {
  final String id;
  final String number;
  final String invoiceId;
  final double amount;
  final String reason;
  final DateTime date;

  CreditNote({
    required this.id,
    required this.number,
    required this.invoiceId,
    required this.amount,
    required this.reason,
    required this.date,
  });
}

class RefundRequest {
  final String id;
  final String invoiceId;
  final double amount;
  final String reason;
  RefundStage stage;
  final DateTime createdAt;

  RefundRequest({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.reason,
    this.stage = RefundStage.requested,
    required this.createdAt,
  });
}

class Invoice {
  final String id;
  String number;
  DocKind kind;
  Customer? customer;

  /// Payment links may be addressed to a free-text name instead of a saved customer.
  String? customerNameOverride;
  String customerPhone;

  /// Payment links get their own short sequence ("#0001").
  String linkNumber;
  List<LineItem> items;
  double discount;

  /// Tax from the backend (the app itself does not add tax to invoices).
  double taxAmount;

  /// Server-reported total, used until the line items are loaded (lists
  /// arrive without items).
  double? totalOverride;

  /// Backend id when synced with the Bizpaddi API.
  int? serverId;
  DateTime? dueDate;
  bool allowPartPayment;
  String notes;
  InvoiceStatus _status;
  final DateTime createdAt;
  final List<Payment> payments;
  final List<CreditNote> creditNotes;
  final List<RefundRequest> refunds;

  Invoice({
    required this.id,
    required this.number,
    this.kind = DocKind.invoice,
    this.customer,
    this.customerNameOverride,
    this.customerPhone = '',
    this.linkNumber = '',
    required this.items,
    this.discount = 0,
    this.taxAmount = 0,
    this.totalOverride,
    this.serverId,
    this.dueDate,
    this.allowPartPayment = false,
    this.notes = '',
    InvoiceStatus status = InvoiceStatus.draft,
    required this.createdAt,
    List<Payment>? payments,
    List<CreditNote>? creditNotes,
    List<RefundRequest>? refunds,
  })  : _status = status, // ignore: prefer_initializing_formals
        payments = payments ?? [],
        creditNotes = creditNotes ?? [],
        refunds = refunds ?? [];

  String get customerName => customerNameOverride ?? customer?.name ?? 'No customer';
  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get total => items.isEmpty && totalOverride != null
      ? totalOverride!
      : (subtotal - discount + taxAmount).clamp(0, double.infinity).toDouble();
  double get paid => payments
      .where((p) => p.paidByCustomer)
      .fold(0, (s, p) => s + p.amount);
  double get refunded => refunds
      .where((r) => r.stage == RefundStage.refunded)
      .fold(0, (s, r) => s + r.amount);
  double get credited => creditNotes.fold(0, (s, c) => s + c.amount);
  double get balance => (total - paid).clamp(0, double.infinity).toDouble();
  double get refundableBalance => (paid - credited - refunds.fold<double>(0, (s, r) => s + r.amount))
      .clamp(0, double.infinity)
      .toDouble();
  /// Live: the customer-portal pay page the backend also emails (customers sign in there).
  /// Before it is saved (no server id) the link is a placeholder.
  String get payLink => LiveLinks.host != null && serverId != null
      ? '${LiveLinks.host}/dashboard/client/invoices/$serverId/pay'
      : 'bizpaddi.com/pay/i${id.hashCode.abs() % 900 + 100}';

  /// Payment link title: what it is for ("Gucci Bags").
  String get purpose => items.isEmpty ? 'Payment link' : items.first.name;

  /// Status is derived for unpaid invoices so "overdue" flips on its own.
  InvoiceStatus get status {
    if (_status == InvoiceStatus.unpaid || _status == InvoiceStatus.partlyPaid) {
      if (paid >= total && total > 0) return InvoiceStatus.paid;
      if (dueDate != null && dueDate!.isBefore(DateTime.now()) && paid < total) {
        return InvoiceStatus.overdue;
      }
      return paid > 0 ? InvoiceStatus.partlyPaid : InvoiceStatus.unpaid;
    }
    return _status;
  }

  set status(InvoiceStatus s) => _status = s;
}

class Quotation {
  final String id;
  String number;
  Customer? customer;
  List<LineItem> items;
  double discount;

  /// See [Invoice.totalOverride].
  double? totalOverride;
  int? serverId;
  String notes;
  QuotationStatus _status;
  DateTime? validTill;
  final DateTime createdAt;

  /// Adds 7.5% VAT on top of the discounted subtotal.
  bool addVat;

  /// 7, 14 or 30 days from sending.
  int validityDays;

  static const vatRate = 0.075;

  Quotation({
    required this.id,
    required this.number,
    this.customer,
    required this.items,
    this.discount = 0,
    this.totalOverride,
    this.serverId,
    this.notes = '',
    QuotationStatus status = QuotationStatus.draft,
    this.validTill,
    required this.createdAt,
    this.addVat = false,
    this.validityDays = 7,
  }) : _status = status; // ignore: prefer_initializing_formals

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get net => (subtotal - discount).clamp(0, double.infinity).toDouble();
  double get vat => addVat ? net * vatRate : 0;
  double get total => items.isEmpty && totalOverride != null ? totalOverride! : net + vat;
  /// The quote page on the customer portal (placeholder until saved).
  String get link => LiveLinks.host != null && serverId != null
      ? '${LiveLinks.host}/dashboard/client/quotes/$serverId'
      : 'bizpaddi.com/q/${id.hashCode.abs() % 900 + 100}';

  /// Sent quotations flip to expired on their own once the validity ends.
  QuotationStatus get status {
    if (_status == QuotationStatus.sent && validTill != null && validTill!.isBefore(DateTime.now())) {
      return QuotationStatus.expired;
    }
    return _status;
  }

  set status(QuotationStatus s) => _status = s;
}

enum NotificationType { payment, invoice, system }

class AppNotification {
  final String title;
  final String body;
  final DateTime time;
  final NotificationType type;
  bool read;
  final String? serverId;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.read = false,
    this.serverId,
  });
}

enum PlanStatus { trial, endingSoon, grace, expired, active }

class Account {
  String ownerFirstName;
  String ownerFullName;
  String businessName;
  String businessPhone;
  String email;
  String dialCode;
  String phone;
  String category;
  String currency;
  PlanStatus plan;
  int trialDaysLeft;
  bool verified;
  bool biometricsEnabled;

  /// Profile photo URL (live mode) and backend user id.
  String? avatarUrl;
  int? userId;

  Account({
    required this.ownerFirstName,
    required this.ownerFullName,
    required this.businessName,
    required this.businessPhone,
    required this.email,
    this.dialCode = '+234',
    required this.phone,
    this.category = 'Food & Drinks',
    this.currency = 'Naira (NGN)',
    this.plan = PlanStatus.trial,
    this.trialDaysLeft = 7,
    this.verified = false,
    this.biometricsEnabled = false,
    this.avatarUrl,
    this.userId,
  });
}

/// Visual mapping for every status pill in the app.
class StatusStyle {
  final String label;
  final Color color;
  const StatusStyle(this.label, this.color);

  static const _green = Color(0xFF0E8A5F);
  static const _amber = Color(0xFFD48806);
  static const _red = Color(0xFFDC2626);
  static const _blue = Color(0xFF2563EB);
  static const _grey = Color(0xFF6B7280);

  static StatusStyle invoice(InvoiceStatus s) => switch (s) {
        InvoiceStatus.draft => const StatusStyle('Draft', _grey),
        InvoiceStatus.unpaid => const StatusStyle('Unpaid', _amber),
        InvoiceStatus.partlyPaid => const StatusStyle('Partly Paid', _amber),
        InvoiceStatus.paid => const StatusStyle('Paid', _green),
        InvoiceStatus.overdue => const StatusStyle('Overdue', _red),
        InvoiceStatus.cancelled => const StatusStyle('Cancelled', _red),
        InvoiceStatus.voided => const StatusStyle('Void', _grey),
      };

  static StatusStyle payment(PaymentStatus s) => switch (s) {
        PaymentStatus.paid => const StatusStyle('Paid', _green),
        PaymentStatus.pending => const StatusStyle('Pending', _amber),
        PaymentStatus.partlyPaid => const StatusStyle('Partly Paid', _amber),
        PaymentStatus.failed => const StatusStyle('Failed', _red),
        PaymentStatus.refunded => const StatusStyle('Refunded', _blue),
      };

  static StatusStyle quotation(QuotationStatus s) => switch (s) {
        QuotationStatus.draft => const StatusStyle('Draft', _grey),
        QuotationStatus.sent => const StatusStyle('Sent', _blue),
        QuotationStatus.accepted => const StatusStyle('Accepted', _green),
        QuotationStatus.expired => const StatusStyle('Expired', _grey),
      };

  static StatusStyle refund(RefundStage s) => switch (s) {
        RefundStage.requested => const StatusStyle('Awaiting Approval', _amber),
        RefundStage.approved => const StatusStyle('Approved', _green),
        RefundStage.confirmed => const StatusStyle('Approved', _green),
        RefundStage.refunded => const StatusStyle('Refunded', _blue),
      };

  static const waiting = StatusStyle('Waiting', _amber);
  static const settled = StatusStyle('Settled', _green);
  static const notYet = StatusStyle('Not Yet', _grey);
  static const paid = StatusStyle('Paid', _green);
  static const current = StatusStyle('Current', _green);
}

/// Host (no scheme) of the live backend for links shared with customers;
/// null until signed in. Set by LiveSession.
class LiveLinks {
  static String? host;
}
