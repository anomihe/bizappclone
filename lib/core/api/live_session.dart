import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/biz_store.dart';
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
  Future<void> login(String email, String password) async {
    final result = await auth.login(email, password);
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
