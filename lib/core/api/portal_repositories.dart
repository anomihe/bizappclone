import 'api_client.dart';

/// Staff API — `/api/v1/team/*` (Sanctum token, user_type:team).
class TeamRepository {
  final ApiClient api;
  TeamRepository(this.api);

  static const _b = '/v1/team';

  // Profile & session
  Future<Map<String, dynamic>> profile() async => await api.get('$_b/profile') as Map<String, dynamic>;
  Future<void> updateProfile({required String name, String? phone}) => api.post('$_b/profile', {'name': name, 'phone': ?phone});
  Future<dynamic> uploadAvatar(List<int> bytes, String filename) => api.upload('$_b/profile/picture', fileField: 'avatar', bytes: bytes, filename: filename);
  Future<void> changePassword({required String current, required String password}) =>
      api.post('$_b/change-password', {'current_password': current, 'new_password': password, 'new_password_confirmation': password});
  Future<void> logout() => api.post('$_b/logout');
  Future<void> deleteAccount() => api.delete('$_b/profile');

  // Home
  Future<Map<String, dynamic>> dashboard() async => await api.get('$_b/dashboard') as Map<String, dynamic>;

  // My tasks
  Future<List<Map<String, dynamic>>> tasks() => api.getAllPages('$_b/tasks');
  Future<Map<String, dynamic>> task(Object id) async => await api.get('$_b/tasks/$id') as Map<String, dynamic>;
  Future<void> setTaskStatus(Object id, String status) => api.patch('$_b/tasks/$id/status', {'status': status});
  /// `{todo: [...], in_progress: [...], review: [...], done: [...]}`
  Future<Map<String, dynamic>> kanban() async => await api.get('$_b/kanban') as Map<String, dynamic>;
  Future<void> moveTasks(List<Map<String, dynamic>> tasks) => api.post('$_b/kanban/update-order', {'tasks': tasks});

  // Attendance
  Future<Map<String, dynamic>> attendance() async => await api.get('$_b/attendance') as Map<String, dynamic>;
  Future<Map<String, dynamic>> clockIn() async => await api.post('$_b/attendance/clock-in') as Map<String, dynamic>;
  Future<Map<String, dynamic>> clockOut() async => await api.post('$_b/attendance/clock-out') as Map<String, dynamic>;

  // Work sessions
  Future<Map<String, dynamic>> workLogs() async => await api.get('$_b/work-logs') as Map<String, dynamic>;
  Future<Map<String, dynamic>> startSession(Map<String, dynamic> body) async => await api.post('$_b/work-logs/check-in', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> endSession(Object id, Map<String, dynamic> body) async =>
      await api.put('$_b/work-logs/$id/check-out', body) as Map<String, dynamic>;

  // Daily reports
  Future<List<Map<String, dynamic>>> reports() => api.getAllPages('$_b/reports');
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> body) async => await api.post('$_b/reports', body) as Map<String, dynamic>;

  // Money
  Future<Map<String, dynamic>> wallet() async => await api.get('$_b/wallet') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> walletTransactions() => api.getAllPages('$_b/wallet/transactions');
  Future<List<Map<String, dynamic>>> earnings() => api.getAllPages('$_b/earnings');
  Future<List<Map<String, dynamic>>> bankAccounts() async =>
      ApiClient.parsePage(await api.get('$_b/bank-accounts')).$1;
  Future<List<Map<String, dynamic>>> banks() async => ApiClient.parsePage(await api.get('$_b/bank-accounts/banks')).$1;
  Future<Map<String, dynamic>> addBankAccount(String bankCode, String number) async =>
      await api.post('$_b/bank-accounts', {'bank_code': bankCode, 'account_number': number}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateBankAccount(Object id, String bankCode, String number) async =>
      await api.put('$_b/bank-accounts/$id', {'bank_code': bankCode, 'account_number': number}) as Map<String, dynamic>;
  Future<void> removeBankAccount(Object id) => api.delete('$_b/bank-accounts/$id');

  // Performance
  Future<Map<String, dynamic>> performance() async => await api.get('$_b/performance') as Map<String, dynamic>;

  // Projects I work on (+ chat via ProjectChatRepository)
  Future<List<Map<String, dynamic>>> projects() => api.getAllPages('$_b/projects');
  Future<Map<String, dynamic>> project(Object id) async => await api.get('$_b/projects/$id') as Map<String, dynamic>;

  // Project manager only (403 for other staff)
  Future<Map<String, dynamic>> pmDashboard() async => await api.get('$_b/pm/dashboard') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> pmProjects() => api.getAllPages('$_b/pm/projects');
  Future<Map<String, dynamic>> pmProject(Object id) async => await api.get('$_b/pm/projects/$id') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> pmTasks({Object? projectId}) => api.getAllPages('$_b/pm/tasks', query: {'project_id': ?projectId});
  Future<List<Map<String, dynamic>>> pmTeamMembers() async => ApiClient.parsePage(await api.get('$_b/pm/tasks/team-members')).$1;
  Future<Map<String, dynamic>> pmCreateTask(Map<String, dynamic> body) async => await api.post('$_b/pm/tasks', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> pmUpdateTask(Object id, Map<String, dynamic> body) async => await api.put('$_b/pm/tasks/$id', body) as Map<String, dynamic>;
  Future<void> pmDeleteTask(Object id) => api.delete('$_b/pm/tasks/$id');
  Future<List<Map<String, dynamic>>> pmMilestones({Object? projectId}) => api.getAllPages('$_b/pm/milestones', query: {'project_id': ?projectId});
  Future<Map<String, dynamic>> pmCreateMilestone(Map<String, dynamic> body) async => await api.post('$_b/pm/milestones', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> pmUpdateMilestone(Object id, Map<String, dynamic> body) async =>
      await api.put('$_b/pm/milestones/$id', body) as Map<String, dynamic>;
  Future<void> pmDeleteMilestone(Object id) => api.delete('$_b/pm/milestones/$id');
  Future<List<Map<String, dynamic>>> pmWorkLogs({Object? userId}) => api.getAllPages('$_b/pm/work-logs', query: {'user_id': ?userId});
  Future<List<Map<String, dynamic>>> clients() => api.getAllPages('$_b/clients');
  Future<List<Map<String, dynamic>>> invoices() => api.getAllPages('$_b/invoices');
  Future<Map<String, dynamic>> invoice(Object id) async => await api.get('$_b/invoices/$id') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> quotes() => api.getAllPages('$_b/quotes');
  Future<Map<String, dynamic>> quote(Object id) async => await api.get('$_b/quotes/$id') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> services() async => ApiClient.parsePage(await api.get('$_b/services')).$1;

  // Support chats with the business
  Future<List<Map<String, dynamic>>> chats() async => ApiClient.parsePage(await api.get('$_b/chats')).$1;
  Future<Map<String, dynamic>> chat(Object id) async => await api.get('$_b/chats/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> startChat(String subject, String message) async =>
      await api.post('$_b/chats', {'subject': subject, 'message': message}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> sendChatMessage(Object id, String message, {List<int>? bytes, String? filename}) async => bytes == null
      ? await api.post('$_b/chats/$id/messages', {'message': message}) as Map<String, dynamic>
      : await api.multipart('$_b/chats/$id/messages', fields: {'message': message}, files: {'attachment': (bytes, filename ?? 'photo.jpg')}) as Map<String, dynamic>;
  Future<void> closeChat(Object id) => api.post('$_b/chats/$id/close');
  Future<void> deleteChat(Object id) => api.delete('$_b/chats/$id');
}

/// Customer API — `/api/v1/client/*` (Sanctum token, user_type:client).
class ClientRepository {
  final ApiClient api;
  ClientRepository(this.api);

  static const _b = '/v1/client';

  // Profile & session
  Future<Map<String, dynamic>> profile() async => await api.get('$_b/profile') as Map<String, dynamic>;
  Future<void> updateProfile({required String name, String? companyName}) => api.post('$_b/update-profile', {'name': name, 'company_name': ?companyName});
  Future<dynamic> uploadAvatar(List<int> bytes, String filename) => api.upload('$_b/profile/picture', fileField: 'avatar', bytes: bytes, filename: filename);
  Future<void> changePassword({required String current, required String password}) =>
      api.post('$_b/change-password', {'current_password': current, 'new_password': password, 'new_password_confirmation': password});
  Future<void> logout() => api.post('$_b/logout');
  Future<void> deleteAccount() => api.delete('$_b/profile');
  Future<void> addDeviceToken(String token, String deviceType) => api.post('$_b/update-device-token', {'fcm_token': token, 'device_type': deviceType});

  // Money
  Future<List<Map<String, dynamic>>> invoices() => api.getAllPages('$_b/invoices');
  Future<Map<String, dynamic>> invoice(Object id) async => await api.get('$_b/invoices/$id') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> quotes() => api.getAllPages('$_b/quotes');
  Future<Map<String, dynamic>> quote(Object id) async => await api.get('$_b/quotes/$id') as Map<String, dynamic>;

  // Projects (+ chat via ProjectChatRepository)
  Future<List<Map<String, dynamic>>> projects() => api.getAllPages('$_b/projects');
  Future<Map<String, dynamic>> project(Object id) async => await api.get('$_b/projects/$id') as Map<String, dynamic>;

  // Support
  Future<List<Map<String, dynamic>>> tickets() => api.getAllPages('$_b/tickets');
  Future<Map<String, dynamic>> ticket(Object id) async => await api.get('$_b/tickets/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> openTicket(String subject, String message, String priority) async =>
      await api.post('$_b/tickets', {'subject': subject, 'message': message, 'priority': priority}) as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> chats() async => ApiClient.parsePage(await api.get('$_b/chats')).$1;
  Future<Map<String, dynamic>> chat(Object id) async => await api.get('$_b/chats/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> startChat(String subject, String message) async =>
      await api.post('$_b/chats', {'subject': subject, 'message': message}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> sendChatMessage(Object id, String message, {List<int>? bytes, String? filename}) async => bytes == null
      ? await api.post('$_b/chats/$id/messages', {'message': message}) as Map<String, dynamic>
      : await api.multipart('$_b/chats/$id/messages', fields: {'message': message}, files: {'attachment': (bytes, filename ?? 'photo.jpg')}) as Map<String, dynamic>;
  Future<void> closeChat(Object id) => api.post('$_b/chats/$id/close');
  Future<void> deleteChat(Object id) => api.delete('$_b/chats/$id');

  // Catalogue & info (support settings and legal pages are public)
  Future<List<Map<String, dynamic>>> serviceCategories() async => ApiClient.parsePage(await api.get('$_b/service-categories')).$1;
  Future<Map<String, dynamic>> supportSettings() async => await api.get('$_b/support-settings') as Map<String, dynamic>;
  Future<List<Map<String, dynamic>>> legalPages() async => ApiClient.parsePage(await api.get('$_b/legal-pages')).$1;
  Future<Map<String, dynamic>> legalPage(String slug) async => await api.get('$_b/legal-pages/$slug') as Map<String, dynamic>;
}
