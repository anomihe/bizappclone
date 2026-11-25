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
}

/// Shared auth — `/api/v1/auth/*` (public).
class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<LoginResult> login(String email, String password) async {
    final data = await api.post('/v1/auth/login', {'email': email.trim(), 'password': password}) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return LoginResult(
      token: data['token'] as String,
      id: (user['id'] as num).toInt(),
      name: '${user['name'] ?? ''}',
      email: '${user['email'] ?? email}',
      type: '${user['type'] ?? ''}',
    );
  }

  /// Emails a reset **link** (the backend has no 6-digit reset code).
  Future<void> forgotPassword(String email) =>
      api.post('/v1/auth/forgot-password', {'email': email.trim(), 'guard': ApiConfig.accountType});

  /// Completes a reset with the token from the emailed link.
  Future<void> resetPassword({required String token, required String email, required String password}) => api.post('/v1/auth/reset-password', {
        'token': token,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        'guard': ApiConfig.accountType,
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

  // Quotations
  Future<List<Map<String, dynamic>>> quotes() => api.getAllPages('$_acc/quotes');
  Future<Map<String, dynamic>> quote(int id) async => await api.get('$_acc/quotes/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> body) async => await api.post('$_acc/quotes', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateQuote(int id, Map<String, dynamic> body) async =>
      await api.put('$_acc/quotes/$id', body) as Map<String, dynamic>;
  Future<void> deleteQuote(int id) => api.delete('$_acc/quotes/$id');

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
}
