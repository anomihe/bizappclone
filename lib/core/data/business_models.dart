import 'package:flutter/material.dart';
import 'models.dart';

// ------------------------------------------------------------------ store

class ProductCategory {
  final String id;
  String name;
  ProductCategory({required this.id, required this.name});
}

enum StockStatus { inStock, lowStock, outOfStock }

class Product {
  final String id;
  String name;
  String unitLabel; // e.g. "5 yards/piece"
  String sku;
  double price;
  double discount;
  String? categoryId;
  int quantity;
  String description;

  /// Placeholder photos (index into a colour palette) until image upload exists.
  List<int> photos;
  bool showOnStorefront;

  Product({
    required this.id,
    required this.name,
    this.unitLabel = '',
    required this.sku,
    required this.price,
    this.discount = 0,
    this.categoryId,
    this.quantity = 0,
    this.description = '',
    List<int>? photos,
    this.showOnStorefront = true,
  }) : photos = photos ?? [];

  double get salePrice => (price - discount).clamp(0, double.infinity).toDouble();
  StockStatus get stock => quantity <= 0 ? StockStatus.outOfStock : (quantity <= 5 ? StockStatus.lowStock : StockStatus.inStock);
}

class Storefront {
  String name;
  String description;
  String dialCode;
  String phone;
  String email;
  String slug;
  String? customDomain;
  bool hasLogo;
  bool hasBanner;

  Storefront({
    required this.name,
    required this.description,
    this.dialCode = '+234',
    required this.phone,
    required this.email,
    required this.slug,
    this.customDomain,
    this.hasLogo = false,
    this.hasBanner = false,
  });

  String get link => 'bizpaddi.com/s/$slug';
}

// ------------------------------------------------------------------ orders

/// pending = placed, awaiting payment; processing = paid, being prepared.
enum OrderStatus { pending, processing, completed, cancelled }

class Order {
  final String id;
  final String number;
  final String customerName;
  final String phone;
  final String address;
  final List<LineItem> items;
  OrderStatus status;
  final DateTime placedAt;
  final List<Payment> payments;
  String? cancelReason;
  bool isNew;

  Order({
    required this.id,
    required this.number,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    this.status = OrderStatus.pending,
    required this.placedAt,
    List<Payment>? payments,
    this.cancelReason,
    this.isNew = false,
  }) : payments = payments ?? [];

  double get total => items.fold(0, (s, i) => s + i.total);
}

// ------------------------------------------------------------------ team

enum StaffRole { owner, administrator, manager, cashier, accountant }

enum StaffStatus { active, deactivated, invited }

enum Permission { dashboard, payments, invoices, quotations, paymentLinks, customers }

const permissionLabels = {
  Permission.dashboard: 'Dashboard totals',
  Permission.payments: 'Payments and transactions',
  Permission.invoices: 'Invoices',
  Permission.quotations: 'Quotations',
  Permission.paymentLinks: 'Payment links',
  Permission.customers: 'Customers',
};

String roleLabel(StaffRole r) => switch (r) {
      StaffRole.owner => 'Owner',
      StaffRole.administrator => 'Administrator',
      StaffRole.manager => 'Manager',
      StaffRole.cashier => 'Cashier',
      StaffRole.accountant => 'Accountant',
    };

/// Sensible defaults when a role is picked; the owner can still tweak them.
Set<Permission> defaultPermissions(StaffRole r) => switch (r) {
      StaffRole.owner || StaffRole.administrator || StaffRole.manager => Permission.values.toSet(),
      StaffRole.cashier => {Permission.payments, Permission.invoices, Permission.paymentLinks, Permission.customers},
      StaffRole.accountant => {Permission.dashboard, Permission.payments, Permission.invoices},
    };

class StaffMember {
  final String id;
  String name;
  String phone;
  String email;
  StaffRole role;
  StaffStatus status;
  Set<Permission> permissions;
  DateTime lastActive;
  int invoicesCreated;
  int paymentsHandled;

  /// Backend id when synced with the Bizpaddi API.
  int? serverId;

  /// Role name as the backend stores it (e.g. "bdm"), when it has no app equivalent.
  String? backendRole;

  StaffMember({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    required this.role,
    this.status = StaffStatus.active,
    Set<Permission>? permissions,
    required this.lastActive,
    this.invoicesCreated = 0,
    this.paymentsHandled = 0,
  }) : permissions = permissions ?? defaultPermissions(role);

  bool get isAdmin => role == StaffRole.administrator;
}

// ------------------------------------------------------------------ business

enum VerificationStatus { incomplete, inReview, verified }

class BankAccount {
  final String bank;
  final String number;
  final String name;
  const BankAccount({required this.bank, required this.number, required this.name});
  String get masked => '******* ${number.substring(number.length - 4)}';
}

class BankChange {
  final String title;
  final String detail;
  final DateTime date;
  const BankChange(this.title, this.detail, this.date);
}

class BusinessProfile {
  String name;
  String type;
  String registrationNumber;
  String dialCode;
  String phone;
  String email;
  String address;
  String currency;
  bool hasLogo;
  VerificationStatus verification;

  /// Document key → uploaded file name (null = not uploaded).
  final Map<String, String?> documents;
  BankAccount? bank;
  final List<BankChange> bankHistory;

  BusinessProfile({
    required this.name,
    this.type = '',
    this.registrationNumber = '',
    this.dialCode = '+234',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.currency = 'Nigeria Naira (NGN)',
    this.hasLogo = false,
    this.verification = VerificationStatus.incomplete,
    Map<String, String?>? documents,
    this.bank,
    List<BankChange>? bankHistory,
  })  : documents = documents ?? {'Government ID': null, 'CAC Certificate': null, 'Proof of Business Address': null},
        bankHistory = bankHistory ?? [];

  bool get infoComplete => [name, type, registrationNumber, phone, email, address].every((v) => v.trim().isNotEmpty);
  bool get documentsComplete => documents.values.every((v) => v != null);
}

// ------------------------------------------------------------------ status styles

class BizStatus {
  static const _green = Color(0xFF0E8A5F);
  static const _amber = Color(0xFFD48806);
  static const _red = Color(0xFFDC2626);
  static const _blue = Color(0xFF2563EB);
  static const _grey = Color(0xFF6B7280);

  static StatusStyle stock(StockStatus s) => switch (s) {
        StockStatus.inStock => const StatusStyle('In Stock', _green),
        StockStatus.lowStock => const StatusStyle('Low Stock', _amber),
        StockStatus.outOfStock => const StatusStyle('Out of Stock', _red),
      };

  static StatusStyle order(OrderStatus s) => switch (s) {
        OrderStatus.pending => const StatusStyle('Pending', _amber),
        OrderStatus.processing => const StatusStyle('Paid', _green),
        OrderStatus.completed => const StatusStyle('Completed', _blue),
        OrderStatus.cancelled => const StatusStyle('Cancelled', _red),
      };

  /// Inner badge on the order header ("Awaiting Payment", "Processing").
  static StatusStyle orderStage(OrderStatus s) => switch (s) {
        OrderStatus.pending => const StatusStyle('Awaiting Payment', _amber),
        OrderStatus.processing => const StatusStyle('Processing', _green),
        OrderStatus.completed => const StatusStyle('Delivered', _blue),
        OrderStatus.cancelled => const StatusStyle('Cancelled', _red),
      };

  static StatusStyle staff(StaffStatus s) => switch (s) {
        StaffStatus.active => const StatusStyle('Active', _green),
        StaffStatus.deactivated => const StatusStyle('Deactivated', _grey),
        StaffStatus.invited => const StatusStyle('Invited', _amber),
      };

  static StatusStyle verification(VerificationStatus s) => switch (s) {
        VerificationStatus.incomplete => const StatusStyle('Incomplete', _amber),
        VerificationStatus.inReview => const StatusStyle('In Review', _amber),
        VerificationStatus.verified => const StatusStyle('Completed', _green),
      };

  /// Payment links: Active / Pending / Paid / Expired / Disabled.
  static StatusStyle link(Invoice i) {
    if (i.status == InvoiceStatus.cancelled) return const StatusStyle('Disabled', _grey);
    if (i.status == InvoiceStatus.paid) return const StatusStyle('Paid', _green);
    if (i.status == InvoiceStatus.overdue) return const StatusStyle('Expired', _grey);
    if (i.payments.any((p) => p.status == PaymentStatus.pending) || i.status == InvoiceStatus.partlyPaid) {
      return const StatusStyle('Pending', _amber);
    }
    return const StatusStyle('Active', _blue);
  }

  static const uploaded = StatusStyle('Uploaded', _green);
  static const notUploaded = StatusStyle('Not uploaded', _amber);
  static const owner = StatusStyle('Owner', _grey);
}
