import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/biz_store.dart';
import '../utils/biometrics.dart';
import 'api_client.dart';
import 'mappers.dart';
import 'portal_repositories.dart';
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
  late final TeamRepository team = TeamRepository(api);
  late final ClientRepository client = ClientRepository(api);
  final BizStore store;

  /// Who is signed in: [AccountRole.owner] (business), [AccountRole.staff]
  /// or [AccountRole.customer]. Decides which home the app opens.
  AccountRole role = AccountRole.owner;

  /// Staff / customer profile (null for business owners, who use [BizStore.account]).
  final ValueNotifier<PortalAccount?> portalAccount = ValueNotifier(null);

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
    final r = AccountRole.fromApi(result.type);
    if (r == null) throw const ApiException('This account type can’t use the Bizpaddi app.');
    api.token = result.token;
    sessionExpired.value = false;
    await _open(r);
    await tokens.save(token: result.token, email: result.email, role: r.api);
  }

  /// Loads what the signed-in person sees: the business workspace, or their staff / customer profile.
  Future<void> _open(AccountRole r) async {
    role = r;
    LiveLinks.host = api.baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    if (r == AccountRole.owner) {
      portalAccount.value = null;
      await loadWorkspace();
      return;
    }
    store.remote = null;
    await refreshPortalProfile();
    final push = pushToken;
    if (push != null) unawaited(_optional(_registerPortalToken(push)));
  }

  Future<PortalAccount> refreshPortalProfile() async {
    final j = role == AccountRole.staff ? await team.profile() : await client.profile();
    final a = PortalAccount.fromJson(j, role);
    portalAccount.value = a;
    return a;
  }

  /// Re-opens a saved session (fingerprint / app restart). Throws if the token expired.
  Future<void> resume() async {
    final token = await tokens.readToken();
    if (token == null) throw const ApiException('Please log in again.', statusCode: 401);
    api.token = token;
    await _open(AccountRole.fromApi(await tokens.readRole() ?? 'admin') ?? AccountRole.owner);
  }

  Future<void> logout() async {
    try {
      final push = pushToken;
      if (api.token != null) {
        switch (role) {
          case AccountRole.owner:
            if (push != null) await business.removeDeviceToken(push);
            await business.logout();
          case AccountRole.staff:
            await team.logout();
          case AccountRole.customer:
            await client.logout();
        }
      }
    } on ApiException {
      // Token already invalid or offline — still sign out locally.
    }
    api.token = null;
    store.remote = null;
    portalAccount.value = null;
    await tokens.clearToken();
  }

  /// The reset link is per account type and we don't know it before login,
  /// so try business owner, then staff, then customer.
  Future<void> sendResetLink(String email) async {
    ApiException? last;
    for (final guard in const ['admin', 'team', 'client']) {
      try {
        await auth.forgotPassword(email, guard: guard);
        return;
      } on ApiException catch (e) {
        if (e.isNetwork) rethrow;
        last = e;
      }
    }
    throw last ?? const ApiException('We couldn’t send a reset link to that email.');
  }

  /// Sets a new password with the token from the reset email (tries each account type).
  Future<void> resetPassword({required String token, required String email, required String password}) async {
    ApiException? last;
    for (final guard in const ['admin', 'team', 'client']) {
      try {
        await auth.resetPassword(token: token, email: email, password: password, guard: guard);
        return;
      } on ApiException catch (e) {
        if (e.isNetwork || e.statusCode == 422) rethrow;
        last = e;
      }
    }
    throw last ?? const ApiException('This reset code is invalid or has expired.');
  }

  // ---------------------------------------------------------------- profile

  Future<void> updateProfile({required String name, required String phone}) async {
    if (role != AccountRole.owner) {
      if (role == AccountRole.staff) {
        await team.updateProfile(name: name, phone: phone);
      } else {
        await client.updateProfile(name: name, companyName: phone);
      }
      await refreshPortalProfile();
      return;
    }
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
    final j = switch (role) {
      AccountRole.owner => await business.uploadAvatar(bytes, filename),
      AccountRole.staff => await team.uploadAvatar(bytes, filename),
      AccountRole.customer => await client.uploadAvatar(bytes, filename),
    };
    final url = ApiMappers.str(j is Map ? j['avatar'] : null);
    if (role != AccountRole.owner) {
      portalAccount.value = portalAccount.value?.copyWith(avatarUrl: url.isEmpty ? null : url);
      return;
    }
    store.account.avatarUrl = url.isEmpty ? null : url;
    store.refresh();
  }

  Future<void> changePassword({required String current, required String password}) => switch (role) {
        AccountRole.owner => business.changePassword(current: current, password: password),
        AccountRole.staff => team.changePassword(current: current, password: password),
        AccountRole.customer => client.changePassword(current: current, password: password),
      };

  /// Deletes the signed-in account on the backend and signs out locally.
  Future<void> deleteAccount() async {
    switch (role) {
      case AccountRole.owner:
        await business.deleteAccount();
      case AccountRole.staff:
        await team.deleteAccount();
      case AccountRole.customer:
        await client.deleteAccount();
    }
    api.token = null;
    store.remote = null;
    portalAccount.value = null;
    await tokens.clearAll();
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
      _optional(business.paymentLinks()),
      _optional(business.business()),
      _optional(business.settlementAccount()),
      _optional(business.notificationPreferences()),
    ]);

    final links = parts[5] as List<Map<String, dynamic>>?;
    if (links != null) {
      store.invoices.removeWhere((i) => i.kind == DocKind.paymentLink);
      store.invoices.addAll(links.map((j) => ApiMappers.paymentLink(j, findCustomer: _customerById)));
      store.invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final biz = parts[6] as Map<String, dynamic>?;
    if (biz != null) {
      ApiMappers.applyBusiness(store.profile, biz);
      store.storefront.hasLogo = store.profile.hasLogo;
      store.account.businessName = store.profile.name.isEmpty ? store.account.businessName : store.profile.name;
    }
    final payout = parts[7] as Map<String, dynamic>?;
    if (payout != null) ApiMappers.applySettlement(store.profile, payout);
    final prefs = parts[8] as Map<String, dynamic>?;
    if (prefs != null) _applyPrefs(prefs);

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
    if (api.token == null) return;
    if (role == AccountRole.owner) {
      await _optional(business.addDeviceToken(token));
    } else {
      await _optional(_registerPortalToken(token));
    }
  }

  /// Customers have their own device-token route; staff have none on the API yet.
  Future<void> _registerPortalToken(String token) async {
    if (role == AccountRole.customer) {
      await client.addDeviceToken(token, defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    }
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

  Customer? _customerById(int? id) => store.customers.where((c) => c.serverId == id).firstOrNull;

  // ---------------------------------------------------------------- payment links

  /// Creates the link on the backend and adds it to the list.
  Future<Invoice> createPaymentLink(Invoice draft) async {
    final j = await business.createPaymentLink(ApiMappers.paymentLinkBody(draft));
    final link = ApiMappers.paymentLink(j, findCustomer: _customerById);
    link.customer ??= draft.customer;
    store.invoices.insert(0, link);
    store.refresh();
    return link;
  }

  /// Updates [old] in place (screens keep a reference to it).
  Invoice _replaceLink(Invoice old, Map<String, dynamic> j) {
    final fresh = ApiMappers.paymentLink(j, findCustomer: _customerById);
    old
      ..status = fresh.status
      ..dueDate = fresh.dueDate
      ..linkUrl = fresh.linkUrl ?? old.linkUrl;
    if (fresh.payments.isNotEmpty) {
      old.payments
        ..clear()
        ..addAll(fresh.payments);
    }
    store.refresh();
    return old;
  }

  Future<Invoice> refreshPaymentLink(Invoice link) async => _replaceLink(link, await business.paymentLink(link.serverId!));
  Future<Invoice> disablePaymentLink(Invoice link) async => _replaceLink(link, await business.disablePaymentLink(link.serverId!));
  Future<Invoice> enablePaymentLink(Invoice link) async => _replaceLink(link, await business.enablePaymentLink(link.serverId!));
  Future<Invoice> setPaymentLinkExpiry(Invoice link, DateTime? expiry) async =>
      _replaceLink(link, await business.updatePaymentLink(link.serverId!, {'expires_at': expiry?.toUtc().toIso8601String()}));

  // ---------------------------------------------------------------- credit notes & refunds

  /// Loads the invoice's credit notes and refunds from the backend.
  Future<void> refreshCreditsAndRefunds(Invoice i) async {
    if (i.serverId == null || i.kind != DocKind.invoice) return;
    final notes = await _optional(business.creditNotes(i.serverId!));
    final refunds = await _optional(business.refunds(i.serverId!));
    if (notes != null) {
      i.creditNotes
        ..clear()
        ..addAll(notes.map((j) => ApiMappers.creditNote(j, i.id)));
    }
    if (refunds != null) {
      i.refunds
        ..clear()
        ..addAll(refunds.map((j) => ApiMappers.refund(j, i.id)).whereType<RefundRequest>());
    }
    store.refresh();
  }

  Future<CreditNote> issueCreditNote(Invoice i, double amount, String reason) async {
    final note = ApiMappers.creditNote(await business.issueCreditNote(i.serverId!, amount, reason), i.id);
    i.creditNotes.add(note);
    store.refresh();
    return note;
  }

  Future<RefundRequest> requestRefund(Invoice i, double amount, String reason) async {
    final r = ApiMappers.refund(await business.requestRefund(i.serverId!, amount, reason), i.id)!;
    i.refunds.add(r);
    store.refresh();
    return r;
  }

  // ---------------------------------------------------------------- business profile & payout account

  Future<void> saveBusinessProfile() async {
    ApiMappers.applyBusiness(store.profile, await business.updateBusiness(ApiMappers.businessBody(store.profile)));
    store.account.businessName = store.profile.name;
    store.refresh();
  }

  Future<void> uploadBusinessLogo(List<int> bytes, String filename) async {
    final j = await business.uploadLogo(bytes, filename);
    final url = ApiMappers.str(j['logo_url']);
    store.profile
      ..logoUrl = url.isEmpty ? null : url
      ..hasLogo = url.isNotEmpty;
    store.storefront.hasLogo = url.isNotEmpty;
    store.refresh();
  }

  Future<void> refreshSettlementAccount() async {
    ApiMappers.applySettlement(store.profile, await business.settlementAccount());
    store.refresh();
  }

  Future<List<Map<String, dynamic>>> settlementBanks() => business.settlementBanks();
  Future<String> resolveBankAccount(String bankCode, String number) => business.resolveAccount(bankCode, number);

  /// Emails the owner a 6-digit code; returns where it went (masked email).
  Future<String> sendSettlementCode() async => ApiMappers.str((await business.sendSettlementOtp())['sent_to']);

  Future<void> saveSettlementAccount({required String bankCode, required String number, required String password, required String otp}) async {
    await business.saveSettlementAccount(bankCode: bankCode, number: number, password: password, otp: otp);
    ApiMappers.applySettlement(store.profile, await business.settlementAccount());
    store.refresh();
  }

  // ---------------------------------------------------------------- notification preferences & sessions

  static const _prefKeys = {
    'Payment received': 'payments',
    'Invoice overdue': 'invoices',
    'New storefront orders': 'orders',
    'Refund updates': 'refunds',
    'Tips and product news': 'product_updates',
  };

  void _applyPrefs(Map<String, dynamic> j) {
    for (final e in _prefKeys.entries) {
      if (j[e.value] is bool) store.notificationPrefs[e.key] = j[e.value] as bool;
    }
  }

  /// Saves one toggle (by its label in Settings).
  Future<void> setNotificationPref(String label, bool on) async {
    final key = _prefKeys[label];
    if (key == null) return;
    store.setNotificationPref(label, on);
    try {
      await business.saveNotificationPreferences({key: on});
    } on ApiException {
      store.setNotificationPref(label, !on);
      rethrow;
    }
  }

  Future<int> logoutOtherDevices() => business.logoutOtherDevices();

  // ---------------------------------------------------------------- Bizpaddi support chat (owners)

  Future<List<Map<String, dynamic>>> supportMessages() => business.supportMessages();
  Future<Map<String, dynamic>> sendSupportMessage(String message, {List<int>? bytes, String? filename}) =>
      business.sendSupportMessage(message, bytes: bytes, filename: filename);

  /// List endpoints omit line items; fetch them when an invoice is opened.
  Future<void> refreshInvoice(Invoice i) async {
    if (i.serverId == null || store.remote == null) return;
    try {
      final j = await business.invoice(i.serverId!);
      final items = (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(ApiMappers.lineItem).toList();
      if (items.isNotEmpty) i.items = items;
      i.totalOverride = ApiMappers.num0(j['total_amount']);
      store.refresh();
      if (i.status == InvoiceStatus.paid) unawaited(refreshCreditsAndRefunds(i));
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

/// Who is signed in. Each opens a different home in the same app.
enum AccountRole {
  owner('admin'),
  staff('team'),
  customer('client');

  /// The `type` the login API returns.
  final String api;
  const AccountRole(this.api);

  static AccountRole? fromApi(String type) => switch (type) {
        'admin' => AccountRole.owner,
        'team' => AccountRole.staff,
        'client' => AccountRole.customer,
        _ => null,
      };
}

/// Staff or customer profile from `GET /team/profile` or `GET /client/profile`.
class PortalAccount {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final AccountRole role;

  /// Staff: job role (e.g. `pm`, `bdm`) and department. Customer: company name.
  final String jobRole;
  final String department;
  final String companyName;
  final String? avatarUrl;

  const PortalAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.jobRole = '',
    this.department = '',
    this.companyName = '',
    this.avatarUrl,
  });

  String get firstName => name.trim().split(' ').first;

  /// Same rule as the backend's User::isProjectManager().
  bool get isProjectManager => role == AccountRole.staff && const ['pm', 'project_manager', 'project manager'].contains(jobRole.toLowerCase());

  factory PortalAccount.fromJson(Map<String, dynamic> j, AccountRole role) {
    final dept = j['department'];
    final avatar = ApiMappers.str(j['avatar']);
    return PortalAccount(
      id: ApiMappers.intOrNull(j['id']),
      name: ApiMappers.str(j['name']),
      email: ApiMappers.str(j['email']),
      phone: ApiMappers.str(j['phone']),
      role: role,
      jobRole: ApiMappers.str(j['role']),
      department: dept is Map ? ApiMappers.str(dept['name']) : ApiMappers.str(dept),
      companyName: ApiMappers.str(j['company_name']),
      avatarUrl: avatar.isEmpty ? null : avatar,
    );
  }

  PortalAccount copyWith({String? avatarUrl}) => PortalAccount(
        id: id,
        name: name,
        email: email,
        role: role,
        phone: phone,
        jobRole: jobRole,
        department: department,
        companyName: companyName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
