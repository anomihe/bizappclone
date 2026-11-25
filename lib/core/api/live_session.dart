import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/biz_store.dart';
import '../utils/biometrics.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'mappers.dart';
import 'repositories.dart';
import 'token_store.dart';

/// Signed-in connection to the Bizpaddi backend.
///
/// Screens call this for auth (login, resume, logout, reset link) and the few
/// actions that need a result back (inviting staff). Everything else flows
/// through [BizStore], which pushes changes here via [BizRemote].
class LiveSession implements BizRemote {
  /// Replaceable for tests.
  static LiveSession instance = LiveSession();

  final ApiClient api;
  final TokenStore tokens;
  late final AuthRepository auth = AuthRepository(api);
  late final BusinessRepository business = BusinessRepository(api);
  final BizStore store;

  /// Becomes true when the backend rejects the token; the shell sends the
  /// user back to log in.
  final ValueNotifier<bool> sessionExpired = ValueNotifier(false);

  /// Last background-sync error, for a snackbar.
  final ValueNotifier<String?> syncError = ValueNotifier(null);

  LiveSession({ApiClient? api, TokenStore? tokens, BizStore? store})
      : api = api ?? ApiClient(),
        tokens = tokens ?? SecureTokenStore(),
        store = store ?? BizStore.instance {
    this.api.onUnauthorized = () {
      this.api.token = null;
      this.tokens.clearToken();
      this.store.remote = null;
      sessionExpired.value = true;
    };
  }

  /// Tests can force live mode without a build-time API_BASE_URL.
  @visibleForTesting
  static bool? debugEnabledOverride;

  static bool get enabled => debugEnabledOverride ?? ApiConfig.isLive;

  // ---------------------------------------------------------------- auth

  Future<bool> hasSavedSession() async => (await tokens.readToken()) != null;
  Future<String?> savedEmail() => tokens.readEmail();

  /// Logs in a business owner and loads their workspace.
  ///
  /// Throws [TwoFactorRequired] when the account has two-factor login on;
  /// finish with [completeTwoFactor].
  Future<void> login(String email, String password) async {
    await _signIn(await auth.login(email, password));
  }

  /// Second login step with the authenticator (or recovery) code.
  Future<void> completeTwoFactor(String challengeToken, String code) async {
    await _signIn(await auth.twoFactorChallenge(challengeToken, code));
  }

  /// Creates a business (3-step sign-up) and signs straight in.
  Future<void> register({
    required String companyName,
    required String firstName,
    required String lastName,
    required String email,
    required String dialCode,
    required String phone,
    required String password,
    required String otp,
  }) async {
    final result = await auth.register(
      companyName: companyName,
      firstName: firstName,
      lastName: lastName,
      email: email,
      dialCode: dialCode,
      phone: phone,
      password: password,
      otp: otp,
    );
    await _signIn(result);
    store.account.businessName = companyName.trim();
    store.refresh();
  }

  Future<void> sendSignupCode(String email, {String? companyName}) => auth.registerSendOtp(email, companyName: companyName);
  Future<void> verifySignupCode(String email, String code) => auth.registerVerifyOtp(email, code);

  Future<void> _signIn(LoginResult result) async {
    if (result.type != ApiConfig.accountType) {
      // Staff and customers have their own portals; don't keep their token.
      throw ApiException(result.type == 'team'
          ? 'This is a staff account. Staff use the Bizpaddi Team app or bizpaddi.com.'
          : 'This is a customer account. Customers use the client portal on bizpaddi.com.');
    }
    api.token = result.token;
    await tokens.save(token: result.token, email: result.email);
    sessionExpired.value = false;
    await loadWorkspace();
  }

  /// Re-opens a saved session (fingerprint / app restart). Throws if the token expired.
  Future<void> resume() async {
    final token = await tokens.readToken();
    if (token == null) throw const ApiException('Please log in again.', statusCode: 401);
    api.token = token;
    await loadWorkspace();
  }

  Future<void> logout() async {
    try {
      final push = pushToken;
      if (api.token != null && push != null) await business.removeDeviceToken(push);
      if (api.token != null) await business.logout();
    } on ApiException {
      // Token already invalid or offline — still sign out locally.
    }
    api.token = null;
    store.remote = null;
    await tokens.clearToken();
  }

  Future<void> sendResetLink(String email) => auth.forgotPassword(email);

  /// Sets a new password with the token from the reset email.
  Future<void> resetPassword({required String token, required String email, required String password}) =>
      auth.resetPassword(token: token, email: email, password: password);

  // ---------------------------------------------------------------- profile

  Future<void> updateProfile({required String name, required String phone}) async {
    await business.updateProfile(name: name, phone: phone);
    store.account
      ..ownerFullName = name
      ..ownerFirstName = name.split(' ').first
      ..businessName = name
      ..businessPhone = phone
      ..phone = ApiMappers.splitPhone(phone).$2;
    store.refresh();
  }

  Future<void> uploadAvatar(List<int> bytes, String filename) async {
    final j = await business.uploadAvatar(bytes, filename);
    final url = ApiMappers.str(j is Map ? j['avatar'] : null);
    store.account.avatarUrl = url.isEmpty ? null : url;
    store.refresh();
  }

  Future<void> changePassword({required String current, required String password}) => business.changePassword(current: current, password: password);

  /// Deletes the owner account on the backend and signs out locally.
  Future<void> deleteAccount() async {
    await business.deleteAccount();
    api.token = null;
    store.remote = null;
    await tokens.clearToken();
  }

  // ---------------------------------------------------------------- loading

  /// Pulls everything the app shows and replaces the in-memory workspace.
  Future<void> loadWorkspace() async {
    final results = await Future.wait([
      business.profile(),
      business.clients(),
      business.invoices(),
      business.quotes(),
      business.transactions(),
      business.teamMembers(),
      business.notifications(),
    ]);
    final profile = results[0] as Map<String, dynamic>;
    final customers = (results[1] as List<Map<String, dynamic>>).map(ApiMappers.customer).toList();
    final byClientId = {for (final c in customers) c.serverId: c};
    Customer? findCustomer(int? id) => byClientId[id];

    final invoices = (results[2] as List<Map<String, dynamic>>).map((j) => ApiMappers.invoice(j, findCustomer: findCustomer)).toList();
    final byInvoiceId = {for (final i in invoices) i.serverId: i};
    final quotations = (results[3] as List<Map<String, dynamic>>).map((j) => ApiMappers.quotation(j, findCustomer: findCustomer)).toList();

    // Attach real transactions to their invoices (replacing the synthetic
    // "marked paid" entry); keep the rest as standalone payments.
    final other = <Payment>[];
    for (final j in (results[4] as List<Map<String, dynamic>>).where(ApiMappers.isIncoming)) {
      final p = ApiMappers.payment(j, findInvoice: (id) => byInvoiceId[id]);
      final inv = invoices.where((i) => i.id == p.invoiceId).firstOrNull;
      if (inv == null) {
        other.add(p);
      } else {
        inv.payments.removeWhere((x) => x.id.endsWith('-paid'));
        inv.payments.add(p);
      }
    }

    final name = ApiMappers.str(profile['name']);
    final (dial, phone) = ApiMappers.splitPhone(ApiMappers.str(profile['phone']));
    final account = Account(
      ownerFirstName: name.split(' ').first,
      ownerFullName: name,
      // The admin profile API has no business name yet; show the owner's name.
      businessName: name,
      businessPhone: ApiMappers.str(profile['phone']),
      email: ApiMappers.str(profile['email']),
      dialCode: dial,
      phone: phone,
      // Plan / trial state isn't exposed by the API; hide the plan banner.
      plan: PlanStatus.active,
      verified: true,
      avatarUrl: ApiMappers.str(profile['avatar']).isEmpty ? null : ApiMappers.str(profile['avatar']),
      userId: ApiMappers.intOrNull(profile['id']),
    );

    store.applyLiveData(
      account: account,
      customers: customers,
      invoices: invoices,
      quotations: quotations,
      otherPayments: other,
      staff: (results[5] as List<Map<String, dynamic>>).map(ApiMappers.staff).toList(),
      notifications: (results[6] as List<Map<String, dynamic>>).map(ApiMappers.notification).toList(),
    );
    store.remote = this;
    LiveLinks.host = api.baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    store.account.biometricsEnabled = await Biometrics.isEnabled();
    await loadStoreAndCompliance();
    final push = pushToken;
    if (push != null) unawaited(_optional(business.addDeviceToken(push)));
  }

  /// Store, orders, storefront, KYC and billing. Each part is optional so an
  /// older backend (without these routes) still opens the workspace.
  Future<void> loadStoreAndCompliance() async {
    final parts = await Future.wait([
      _optional(business.products()),
      _optional(business.orders()),
      _optional(business.storefront()),
      _optional(business.kyc()),
      _optional(business.billing()),
    ]);

    final productsJson = parts[0] as List<Map<String, dynamic>>?;
    if (productsJson != null) {
      final products = productsJson.map(ApiMappers.product).toList();
      final names = <String>{
        for (final j in productsJson)
          if (ApiMappers.str(j['category']).isNotEmpty && ApiMappers.str(j['category']) != 'General') ApiMappers.str(j['category']).trim(),
      };
      // Keep empty categories the owner added in this session.
      final kept = store.categories.where((c) => !names.any((n) => ApiMappers.categoryId(n) == c.id)).toList();
      store.categories
        ..clear()
        ..addAll([for (final n in names) ProductCategory(id: ApiMappers.categoryId(n), name: n), ...kept]);
      store.products
        ..clear()
        ..addAll(products);
    }
    final ordersJson = parts[1] as List<Map<String, dynamic>>?;
    if (ordersJson != null) {
      store.orders
        ..clear()
        ..addAll(ordersJson.map(ApiMappers.order));
    }
    final storefront = parts[2] as Map<String, dynamic>?;
    if (storefront != null) ApiMappers.applyStorefront(store.storefront, storefront);
    final kyc = parts[3] as Map<String, dynamic>?;
    if (kyc != null) {
      ApiMappers.applyKyc(store.profile, kyc);
      // Drives the Home "Verify your business" banner.
      store.account.verified = store.profile.verification == VerificationStatus.verified;
    }
    final billing = parts[4] as Map<String, dynamic>?;
    if (billing != null) {
      this.billing.value = billing;
      store.account.plan = ApiMappers.planStatus(billing);
    }
    store.refresh();
  }

  /// Runs [f]; a missing route (404/405) or other API error returns null.
  Future<T?> _optional<T>(Future<T> f) async {
    try {
      return await f;
    } on ApiException {
      return null;
    }
  }

  // ---------------------------------------------------------------- push

  /// Firebase Messaging token, set by the push setup once it is configured.
  String? pushToken;

  Future<void> registerPushToken(String token) async {
    pushToken = token;
    if (api.token != null) await _optional(business.addDeviceToken(token));
  }

  // ---------------------------------------------------------------- billing

  /// Last `GET /admin/billing` response (plan, wallet, plans, history).
  final ValueNotifier<Map<String, dynamic>?> billing = ValueNotifier(null);

  Future<Map<String, dynamic>> refreshBilling() async {
    final j = await business.billing();
    billing.value = j;
    store.account.plan = ApiMappers.planStatus(j);
    store.refresh();
    return j;
  }

  // ---------------------------------------------------------------- invoices & quotes

  Invoice _applyInvoice(Invoice i, Map<String, dynamic> j) {
    final fresh = ApiMappers.invoice(j, findCustomer: (id) => store.customers.where((c) => c.serverId == id).firstOrNull);
    i
      ..status = fresh.status
      ..totalOverride = fresh.totalOverride;
    if (fresh.items.isNotEmpty) i.items = fresh.items;
    // Marked paid: record what was still owed (earlier part payments stay).
    final owed = i.balance;
    if (fresh.status == InvoiceStatus.paid && owed > 0) {
      final when = fresh.payments.firstOrNull?.date ?? DateTime.now();
      i.payments.add(Payment(
        id: '${i.id}-paid',
        invoiceId: i.id,
        invoiceNumber: i.number,
        customerName: i.customerName,
        amount: owed,
        method: 'Marked paid',
        providerCharge: 0,
        serviceCharge: 0,
        status: PaymentStatus.paid,
        date: when,
        settled: true,
        receiptNo: i.number,
      ));
    }
    store.refresh();
    return i;
  }

  /// Emails the invoice to the customer.
  Future<void> emailInvoice(Invoice i) async {
    final id = await _invoiceId(i);
    _applyInvoice(i, await business.sendInvoice(id));
  }

  Future<void> markInvoicePaid(Invoice i) async {
    final id = await _invoiceId(i);
    _applyInvoice(i, await business.markInvoicePaid(id));
  }

  Future<List<int>> invoicePdf(Invoice i) async => business.invoicePdf(await _invoiceId(i));

  /// Saves first if the invoice hasn't reached the server yet.
  Future<int> _invoiceId(Invoice i) async {
    if (i.serverId == null) await saveInvoice(i);
    final id = i.serverId;
    if (id == null) throw ApiException(syncError.value ?? 'This invoice isn’t saved to Bizpaddi yet. Please try again.');
    return id;
  }

  Future<int> _quoteId(Quotation q) async {
    if (q.serverId == null) await saveQuotation(q);
    final id = q.serverId;
    if (id == null) throw ApiException(syncError.value ?? 'This quotation isn’t saved to Bizpaddi yet. Please try again.');
    return id;
  }

  Future<void> emailQuotation(Quotation q) async {
    final j = await business.sendQuote(await _quoteId(q));
    q.status = ApiMappers.quoteStatus(ApiMappers.str(j['status']));
    store.refresh();
  }

  Future<List<int>> quotationPdf(Quotation q) async => business.quotePdf(await _quoteId(q));

  /// Converts on the server and adds the new invoice to the list.
  Future<Invoice> convertQuotation(Quotation q) async {
    final j = await business.convertQuote(await _quoteId(q));
    final inv = ApiMappers.invoice(j, findCustomer: (id) => store.customers.where((c) => c.serverId == id).firstOrNull);
    inv.customer ??= q.customer;
    q.status = QuotationStatus.accepted;
    store.invoices.insert(0, inv);
    store.refresh();
    return inv;
  }

  // ---------------------------------------------------------------- store

  /// Creates or updates a product; [image] replaces its photo.
  Future<Product> saveProduct(Product p, {List<int>? image, String? filename, bool removeImage = false}) async {
    final fields = ApiMappers.productFields(p, category: store.categoryById(p.categoryId)?.name);
    if (removeImage) fields['remove_image'] = '1';
    final j = await business.saveProduct(p.serverId, fields, image: image, filename: filename);
    final fresh = ApiMappers.product(j);
    p
      ..serverId = fresh.serverId
      ..imageUrl = fresh.imageUrl;
    if (!store.products.contains(p)) store.products.insert(0, p);
    store.refresh();
    return p;
  }

  Future<void> deleteProduct(Product p) async {
    if (p.serverId != null) await business.deleteProduct(p.serverId!);
    store.products.remove(p);
    store.refresh();
  }

  /// Renames a category by updating every product that uses it.
  Future<void> renameCategory(ProductCategory c, String name) async {
    final newId = ApiMappers.categoryId(name);
    final affected = store.products.where((p) => p.categoryId == c.id).toList();
    final idx = store.categories.indexOf(c);
    final renamed = ProductCategory(id: newId, name: name.trim());
    if (idx >= 0) store.categories[idx] = renamed;
    for (final p in affected) {
      p.categoryId = newId;
      await saveProduct(p);
    }
    store.refresh();
  }

  /// `processing` | `completed` | `cancelled` (with [reason]).
  Future<void> setOrderStatus(Order o, String status, {String? reason}) async {
    if (o.serverId == null) return;
    final j = await business.setOrderStatus(o.serverId!, status, notes: reason);
    final fresh = ApiMappers.order(j);
    o
      ..status = fresh.status
      ..backendStatus = fresh.backendStatus
      ..isNew = false;
    if (status == 'cancelled') o.cancelReason = reason;
    store.refresh();
  }

  Future<void> saveStorefront({List<int>? banner, String? filename, String? customDomain}) async {
    final fields = ApiMappers.storefrontFields(store.storefront);
    if (customDomain != null) fields['custom_domain'] = customDomain;
    final j = await business.saveStorefront(fields, banner: banner, filename: filename);
    ApiMappers.applyStorefront(store.storefront, j);
    store.refresh();
  }

  /// Re-reads the storefront including the custom-domain DNS/SSL check.
  Future<void> checkDomain() async {
    ApiMappers.applyStorefront(store.storefront, await business.storefront(checkDomain: true));
    store.refresh();
  }

  // ---------------------------------------------------------------- KYC

  Future<void> uploadKyc(String label, List<int> bytes, String filename) async {
    final type = kycDocumentTypes.entries.firstWhere((e) => e.value == label).key;
    await business.uploadKyc(type, bytes, filename);
    ApiMappers.applyKyc(store.profile, await business.kyc());
    store.refresh();
  }

  /// List endpoints omit line items; fetch them when an invoice is opened.
  Future<void> refreshInvoice(Invoice i) async {
    if (i.serverId == null || store.remote == null) return;
    try {
      final j = await business.invoice(i.serverId!);
      final items = (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(ApiMappers.lineItem).toList();
      if (items.isNotEmpty) i.items = items;
      i.totalOverride = ApiMappers.num0(j['total_amount']);
      store.refresh();
    } on ApiException catch (e) {
      _report(e);
    }
  }

  // ---------------------------------------------------------------- staff invites

  /// Creates a staff login. The API requires a password, so one is generated;
  /// returns it so the owner can share it (shown once).
  Future<String> inviteStaff(StaffMember m) async {
    final password = generatePassword();
    final j = await business.createTeamMember(ApiMappers.staffBody(m, password: password));
    m.serverId = ApiMappers.intOrNull(j['id']);
    m.status = StaffStatus.active;
    store.staff.add(m);
    store.refresh();
    return password;
  }

  static String generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final r = Random.secure();
    final body = List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
    return '$body#${r.nextInt(90) + 10}';
  }

  // ---------------------------------------------------------------- BizRemote (background sync)

  void _report(Object e) => syncError.value = e is ApiException ? e.message : 'Couldn’t save to Bizpaddi. Please try again.';

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      _report(e);
    }
  }

  @override
  Future<void> saveCustomer(Customer c) => _guard(() async {
        if (c.serverId == null) {
          // Customers get a client-portal login; they can reset the password themselves.
          final j = await business.createClient(ApiMappers.customerBody(c, password: generatePassword()));
          c.serverId = ApiMappers.intOrNull(j['id']);
        } else {
          await business.updateClient(c.serverId!, ApiMappers.customerBody(c));
        }
      });

  @override
  Future<void> saveInvoice(Invoice i) => _guard(() async {
        final body = ApiMappers.invoiceBody(i);
        if (i.serverId == null) {
          final j = await business.createInvoice(body);
          i.serverId = ApiMappers.intOrNull(j['id']);
          final number = ApiMappers.str(j['invoice_number']);
          if (number.isNotEmpty) i.number = number;
          store.refresh();
        } else {
          await business.updateInvoice(i.serverId!, body);
        }
      });

  @override
  Future<void> saveQuotation(Quotation q) => _guard(() async {
        final body = ApiMappers.quotationBody(q);
        if (q.serverId == null) {
          final j = await business.createQuote(body);
          q.serverId = ApiMappers.intOrNull(j['id']);
          final number = ApiMappers.str(j['quote_number']);
          if (number.isNotEmpty) q.number = number;
          store.refresh();
        } else {
          await business.updateQuote(q.serverId!, body);
        }
        // Accepting is its own endpoint on the backend.
        if (q.status == QuotationStatus.accepted) await business.approveQuote(q.serverId!);
      });

  @override
  Future<void> updateStaff(StaffMember m) => _guard(() async {
        if (m.serverId != null) await business.updateTeamMember(m.serverId!, ApiMappers.staffBody(m));
      });

  @override
  Future<void> removeStaff(StaffMember m) => _guard(() async {
        if (m.serverId != null) await business.deleteTeamMember(m.serverId!);
      });

  @override
  Future<void> markAllRead() => _guard(business.markAllNotificationsRead);

  @override
  Future<void> markRead(AppNotification n) => _guard(() async {
        if (n.serverId != null) await business.markNotificationRead(n.serverId!);
      });

  @override
  Future<void> deleteCustomer(Customer c) => _guard(() async {
        if (c.serverId != null) await business.deleteClient(c.serverId!);
      });

  @override
  Future<void> deleteInvoice(Invoice i) => _guard(() async {
        if (i.serverId != null) await business.deleteInvoice(i.serverId!);
      });

  @override
  Future<void> deleteQuotation(Quotation q) => _guard(() async {
        if (q.serverId != null) await business.deleteQuote(q.serverId!);
      });
}
