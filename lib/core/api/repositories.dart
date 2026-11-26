import 'api_client.dart';
import 'api_config.dart';

/// Result of `POST /api/v1/auth/login`.
class LoginResult {
  final String token;
  final int id;
  final String name;
  final String email;

  /// `admin` (business owner), `team` (staff) or `client` (customer).
  final String type;
  const LoginResult({required this.token, required this.id, required this.name, required this.email, required this.type});

  factory LoginResult.fromJson(Map<String, dynamic> data, {String fallbackEmail = ''}) {
    final user = data['user'] as Map<String, dynamic>;
    return LoginResult(
      token: data['token'] as String,
      id: (user['id'] as num).toInt(),
      name: '${user['name'] ?? ''}',
      email: '${user['email'] ?? fallbackEmail}',
      type: '${user['type'] ?? ''}',
    );
  }
}

/// Login stopped at the 2FA step: send the authenticator code with [challengeToken].
class TwoFactorRequired implements Exception {
  final String challengeToken;
  const TwoFactorRequired(this.challengeToken);
}

/// Shared auth — `/api/v1/auth/*` (public).
class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  /// Throws [TwoFactorRequired] when the account has two-factor login on.
  Future<LoginResult> login(String email, String password) async {
    final data = await api.post('/v1/auth/login', {'email': email.trim(), 'password': password}) as Map<String, dynamic>;
    if (data['requires_2fa'] == true) throw TwoFactorRequired('${data['challenge_token']}');
    return LoginResult.fromJson(data, fallbackEmail: email.trim());
  }

  /// Second login step: authenticator code or a recovery code.
  Future<LoginResult> twoFactorChallenge(String challengeToken, String code) async {
    final data = await api.post('/v1/auth/2fa-challenge', {'challenge_token': challengeToken, 'code': code.trim()}) as Map<String, dynamic>;
    return LoginResult.fromJson(data);
  }

  // Sign-up: email → 6-digit code → details (same as app.bizpaddi.com/dashboard/register).
  Future<void> registerSendOtp(String email, {String? companyName}) =>
      api.post('/v1/auth/register/send-otp', {'email': email.trim(), 'company_name': ?companyName});
  Future<void> registerVerifyOtp(String email, String code) =>
      api.post('/v1/auth/register/verify-otp', {'email': email.trim(), 'otp_code': code});

  Future<LoginResult> register({
    required String companyName,
    required String firstName,
    required String lastName,
    required String email,
    required String dialCode,
    required String phone,
    required String password,
    required String otp,
  }) async {
    final data = await api.post('/v1/auth/register', {
      'company_name': companyName.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'phone_country_code': dialCode,
      'phone': phone.trim(),
      'password': password,
      'password_confirmation': password,
      'otp_code': otp,
      'agree_terms': true,
      'device_name': 'bizpaddi-mobile',
    }) as Map<String, dynamic>;
    return LoginResult.fromJson(data, fallbackEmail: email.trim());
  }

  /// Emails a reset **link** (the backend has no 6-digit reset code).
  Future<void> forgotPassword(String email, {String guard = ApiConfig.accountType}) =>
      api.post('/v1/auth/forgot-password', {'email': email.trim(), 'guard': guard});

  /// Completes a reset with the token from the emailed link.
  Future<void> resetPassword({required String token, required String email, required String password, String guard = ApiConfig.accountType}) =>
      api.post('/v1/auth/reset-password', {
        'token': token,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        'guard': guard,
      });
}

/// Business owner API — `/api/v1/admin/*` (Sanctum token, user_type:admin).
class BusinessRepository {
  final ApiClient api;
  BusinessRepository(this.api);

  static const _base = '/v1/admin';
  static const _acc = '$_base/accounting';

  // Profile & session
  Future<Map<String, dynamic>> profile() async => await api.get('$_base/profile') as Map<String, dynamic>;
  /// Only name and phone are editable (email is fixed on the backend).
  Future<Map<String, dynamic>> updateProfile({required String name, String? phone}) async =>
      await api.post('$_base/profile', {'name': name, 'phone': ?phone}) as Map<String, dynamic>;
  Future<void> changePassword({required String current, required String password}) => api.post('$_base/change-password', {
        'current_password': current,
        'new_password': password,
        'new_password_confirmation': password,
      });
  Future<dynamic> uploadAvatar(List<int> bytes, String filename) =>
      api.upload('$_base/profile/picture', fileField: 'avatar', bytes: bytes, filename: filename);
  Future<void> logout() => api.post('$_base/logout');
  Future<void> deleteAccount() => api.delete('$_base/profile');

  // Dashboard (agency-oriented stats; the app computes its own KPIs from invoices + transactions)
  Future<Map<String, dynamic>> dashboard() async => await api.get('$_base/dashboard') as Map<String, dynamic>;

  // Customers (clients)
  Future<List<Map<String, dynamic>>> clients() => api.getAllPages('$_base/clients');
  Future<Map<String, dynamic>> client(int id) async => await api.get('$_base/clients/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> body) async => await api.post('$_base/clients', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateClient(int id, Map<String, dynamic> body) async =>
      await api.put('$_base/clients/$id', body) as Map<String, dynamic>;
  Future<void> deleteClient(int id) => api.delete('$_base/clients/$id');

  // Invoices
  Future<List<Map<String, dynamic>>> invoices() => api.getAllPages('$_acc/invoices');
  Future<Map<String, dynamic>> invoice(int id) async => await api.get('$_acc/invoices/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> body) async => await api.post('$_acc/invoices', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateInvoice(int id, Map<String, dynamic> body) async =>
      await api.put('$_acc/invoices/$id', body) as Map<String, dynamic>;
  Future<void> deleteInvoice(int id) => api.delete('$_acc/invoices/$id');
  /// Emails the invoice to the customer.
  Future<Map<String, dynamic>> sendInvoice(int id) async => await api.post('$_acc/invoices/$id/send') as Map<String, dynamic>;
  /// Marks the whole invoice paid (records a transaction on the backend).
  Future<Map<String, dynamic>> markInvoicePaid(int id) async => await api.post('$_acc/invoices/$id/mark-paid') as Map<String, dynamic>;
  Future<List<int>> invoicePdf(int id) => api.getBytes('$_acc/invoices/$id/pdf');

  // Quotations
  Future<List<Map<String, dynamic>>> quotes() => api.getAllPages('$_acc/quotes');
  Future<Map<String, dynamic>> quote(int id) async => await api.get('$_acc/quotes/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> body) async => await api.post('$_acc/quotes', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateQuote(int id, Map<String, dynamic> body) async =>
      await api.put('$_acc/quotes/$id', body) as Map<String, dynamic>;
  Future<void> deleteQuote(int id) => api.delete('$_acc/quotes/$id');
  Future<Map<String, dynamic>> sendQuote(int id) async => await api.post('$_acc/quotes/$id/send') as Map<String, dynamic>;
  Future<Map<String, dynamic>> approveQuote(int id) async => await api.post('$_acc/quotes/$id/approve') as Map<String, dynamic>;
  /// Returns the new invoice.
  Future<Map<String, dynamic>> convertQuote(int id) async => await api.post('$_acc/quotes/$id/convert') as Map<String, dynamic>;
  Future<List<int>> quotePdf(int id) => api.getBytes('$_acc/quotes/$id/pdf');

  // Payments (transactions) — read only from the app
  Future<List<Map<String, dynamic>>> transactions() => api.getAllPages('$_acc/transactions');
  Future<Map<String, dynamic>> transaction(int id) async => await api.get('$_acc/transactions/$id') as Map<String, dynamic>;

  // Team
  Future<List<Map<String, dynamic>>> teamMembers() => api.getAllPages('$_base/team-members');
  Future<Map<String, dynamic>> createTeamMember(Map<String, dynamic> body) async =>
      await api.post('$_base/team-members', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateTeamMember(int id, Map<String, dynamic> body) async =>
      await api.put('$_base/team-members/$id', body) as Map<String, dynamic>;
  Future<void> deleteTeamMember(int id) => api.delete('$_base/team-members/$id');

  // Balance sheet: {assets|liabilities|equity: {accounts: [...], total}}
  Future<Map<String, dynamic>> balanceSheet() async => await api.get('$_acc/balance-sheet') as Map<String, dynamic>;

  // Project chat. type: internal_team (staff) or client_team (with the customer).
  Future<Map<String, dynamic>> projectChat(Object projectId, String type) async =>
      await api.get('$_base/pm/projects/$projectId/chat', query: {'type': type}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> sendProjectMessage(Object projectId, String type, String content, {List<int>? bytes, String? filename}) async {
    if (bytes != null) {
      return await api.upload('$_base/pm/projects/$projectId/chat',
          fields: {'type': type, 'content': content}, fileField: 'attachment', bytes: bytes, filename: filename ?? 'photo.jpg') as Map<String, dynamic>;
    }
    return await api.post('$_base/pm/projects/$projectId/chat', {'type': type, 'content': content}) as Map<String, dynamic>;
  }

  Future<void> setChatStatus(Object projectId, String type, String status) =>
      api.post('$_base/pm/projects/$projectId/chat/status', {'type': type, 'status': status});
  Future<void> editProjectMessage(Object id, String content) => api.put('$_base/pm/projects/chat/messages/$id', {'content': content});
  Future<void> deleteProjectMessage(Object id) => api.delete('$_base/pm/projects/chat/messages/$id');
  Future<void> markProjectMessageRead(Object id) => api.post('$_base/pm/projects/chat/messages/$id/read');

  // Notifications
  Future<List<Map<String, dynamic>>> notifications() async => ApiClient.parsePage(await api.get('$_base/notifications')).$1;
  Future<void> markNotificationRead(String id) => api.patch('$_base/notifications/$id/read');
  Future<void> markAllNotificationsRead() => api.post('$_base/notifications/read-all');

  // Store: products (one image; category is free text), storefront, orders
  Future<List<Map<String, dynamic>>> products() => api.getAllPages('$_base/store/products', query: {'per_page': 100});
  Future<Map<String, dynamic>> saveProduct(int? id, Map<String, String> fields, {List<int>? image, String? filename}) async =>
      await api.multipart(id == null ? '$_base/store/products' : '$_base/store/products/$id',
          fields: fields, files: {if (image != null) 'image': (image, filename ?? 'product.jpg')}) as Map<String, dynamic>;
  Future<void> deleteProduct(int id) => api.delete('$_base/store/products/$id');

  Future<Map<String, dynamic>> storefront({bool checkDomain = false}) async =>
      await api.get('$_base/storefront', query: {'check_domain': checkDomain ? 1 : 0}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> saveStorefront(Map<String, String> fields, {List<int>? banner, String? filename}) async =>
      await api.multipart('$_base/storefront', fields: fields, files: {if (banner != null) 'store_banner': (banner, filename ?? 'banner.jpg')})
          as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> orders() => api.getAllPages('$_base/store/orders', query: {'per_page': 100});
  Future<Map<String, dynamic>> order(int id) async => await api.get('$_base/store/orders/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> setOrderStatus(int id, String status, {String? notes}) async =>
      await api.patch('$_base/store/orders/$id/status', {'status': status, 'notes': ?notes, 'notify_customer': true}) as Map<String, dynamic>;

  // KYC documents
  Future<Map<String, dynamic>> kyc() async => await api.get('$_base/kyc') as Map<String, dynamic>;
  Future<Map<String, dynamic>> uploadKyc(String type, List<int> bytes, String filename, {String? number}) async =>
      await api.multipart('$_base/kyc', fields: {'document_type': type, 'document_number': ?number}, files: {'document_file': (bytes, filename)})
          as Map<String, dynamic>;

  // Plan & wallet (Billway bank transfer)
  Future<Map<String, dynamic>> billing() async => await api.get('$_base/billing') as Map<String, dynamic>;
  Future<Map<String, dynamic>> topUp(double amount) async => await api.post('$_base/billing/topup', {'amount': amount}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> checkoutPlan(int planId, {int? seats}) async =>
      await api.post('$_base/billing/checkout', {'plan_id': planId, 'seats': ?seats}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> paymentStatus(String reference) async =>
      await api.get('$_base/billing/status', query: {'reference': reference}) as Map<String, dynamic>;
  Future<void> switchBillingModel(String model) => api.post('$_base/billing/switch-model', {'billing_model': model});

  // Push notifications
  Future<void> addDeviceToken(String token) => api.post('$_base/device-tokens', {'token': token});
  Future<void> removeDeviceToken(String token) => api.send('DELETE', '$_base/device-tokens', body: {'token': token});

  // Two-factor login
  Future<Map<String, dynamic>> twoFactor() async => await api.get('$_base/2fa') as Map<String, dynamic>;
  Future<List<String>> confirmTwoFactor(String code) async {
    final j = await api.post('$_base/2fa/confirm', {'code': code}) as Map<String, dynamic>;
    return (j['recovery_codes'] as List? ?? const []).map((e) => '$e').toList();
  }
  Future<void> disableTwoFactor(String password) => api.post('$_base/2fa/disable', {'password': password});

  // Payment links (customers pay at {base}/pay/{slug})
  Future<List<Map<String, dynamic>>> paymentLinks() async => ApiClient.parsePage(await api.get('$_base/payment-links')).$1;
  Future<Map<String, dynamic>> paymentLink(int id) async => await api.get('$_base/payment-links/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> createPaymentLink(Map<String, dynamic> body) async => await api.post('$_base/payment-links', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updatePaymentLink(int id, Map<String, dynamic> body) async =>
      await api.patch('$_base/payment-links/$id', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> disablePaymentLink(int id) async => await api.post('$_base/payment-links/$id/disable') as Map<String, dynamic>;
  Future<Map<String, dynamic>> enablePaymentLink(int id) async => await api.post('$_base/payment-links/$id/enable') as Map<String, dynamic>;

  // Credit notes & refunds
  Future<List<Map<String, dynamic>>> creditNotes(int invoiceId) async =>
      ApiClient.parsePage(await api.get('$_acc/credit-notes', query: {'invoice_id': invoiceId})).$1;
  Future<Map<String, dynamic>> issueCreditNote(int invoiceId, double amount, String reason) async =>
      await api.post('$_acc/invoices/$invoiceId/credit-notes', {'amount': amount, 'reason': reason}) as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> refunds(int invoiceId) async => ApiClient.parsePage(await api.get('$_acc/refunds', query: {'invoice_id': invoiceId})).$1;
  Future<Map<String, dynamic>> requestRefund(int invoiceId, double amount, String reason) async =>
      await api.post('$_acc/invoices/$invoiceId/refunds', {'amount': amount, 'reason': reason}) as Map<String, dynamic>;
  Future<void> cancelRefund(int id) => api.post('$_acc/refunds/$id/cancel');

  // Business profile, logo, payout account
  Future<Map<String, dynamic>> business() async => await api.get('$_base/business') as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateBusiness(Map<String, dynamic> body) async => await api.put('$_base/business', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> uploadLogo(List<int> bytes, String filename) async =>
      await api.upload('$_base/business/logo', fileField: 'logo', bytes: bytes, filename: filename) as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> settlementBanks() async => ApiClient.parsePage(await api.get('$_base/banks')).$1;
  Future<String> resolveAccount(String bankCode, String number) async {
    final j = await api.post('$_base/settlement-account/resolve', {'bank_code': bankCode, 'account_number': number}) as Map<String, dynamic>;
    return '${j['account_name'] ?? ''}';
  }
  Future<Map<String, dynamic>> settlementAccount() async => await api.get('$_base/settlement-account') as Map<String, dynamic>;
  Future<Map<String, dynamic>> sendSettlementOtp() async => await api.post('$_base/settlement-account/send-otp') as Map<String, dynamic>;
  Future<Map<String, dynamic>> saveSettlementAccount({required String bankCode, required String number, required String password, required String otp}) async =>
      await api.put('$_base/settlement-account', {'bank_code': bankCode, 'account_number': number, 'password': password, 'otp': otp}) as Map<String, dynamic>;

  // Notification preferences & sessions
  Future<Map<String, dynamic>> notificationPreferences() async => await api.get('$_base/notification-preferences') as Map<String, dynamic>;
  Future<void> saveNotificationPreferences(Map<String, bool> prefs) => api.put('$_base/notification-preferences', prefs);
  Future<int> logoutOtherDevices() async {
    final j = await api.post('$_base/sessions/logout-others') as Map<String, dynamic>;
    return (j['revoked'] as num?)?.toInt() ?? 0;
  }

  // Chat with Bizpaddi support; replies to customer tickets
  Future<List<Map<String, dynamic>>> supportMessages() async => ApiClient.parsePage(await api.get('$_base/support/messages')).$1;
  Future<Map<String, dynamic>> sendSupportMessage(String message, {List<int>? bytes, String? filename}) async => bytes == null
      ? await api.post('$_base/support/messages', {'message': message}) as Map<String, dynamic>
      : await api.multipart('$_base/support/messages', fields: {'message': message}, files: {'attachment': (bytes, filename ?? 'photo.jpg')}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> replyToTicket(Object id, String message) async =>
      await api.post('$_base/tickets/$id/replies', {'message': message}) as Map<String, dynamic>;
}
