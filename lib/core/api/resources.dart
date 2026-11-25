import 'package:flutter/material.dart';
import '../data/biz_store.dart';
import 'live_session.dart';
import 'mappers.dart';

/// Generic CRUD support for the simple `/api/v1/admin/*` resources (leads,
/// contacts, contracts, projects, …). Each resource is described by a
/// [ResourceSpec]; the shared list/form screens render it.

enum FieldKind { text, multiline, email, phone, number, money, date, dateTime, choice, toggle, customer, staff }

class ResourceField {
  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final List<(String, String)> options; // (value, label) for choice
  final String? hint;

  /// Shown in the form but not sent (server-computed).
  final bool readOnly;

  const ResourceField(this.key, this.label, {this.kind = FieldKind.text, this.required = false, this.options = const [], this.hint, this.readOnly = false});
}

class ResourceSpec {
  final String id;
  final String title;
  final String singular;

  /// API path under `/api`, e.g. `/v1/admin/leads`.
  final String path;
  final IconData icon;
  final List<ResourceField> fields;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  final num? Function(Map<String, dynamic>)? amountOf;
  final String? Function(Map<String, dynamic>)? statusOf;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  /// Has `GET {path}/{id}` (departments don't).
  final bool canShow;

  /// Has `PATCH {path}/{id}/status`.
  final List<String>? statusActions;

  /// Records belong to a parent (e.g. `project_id`); create only from inside it.
  final String? parentKey;
  final String emptyMessage;
  final String? notice;
  final List<Map<String, dynamic>> Function() demo;

  const ResourceSpec({
    required this.id,
    required this.title,
    required this.singular,
    required this.path,
    required this.icon,
    required this.fields,
    required this.titleOf,
    required this.subtitleOf,
    this.amountOf,
    this.statusOf,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.canShow = true,
    this.statusActions,
    this.parentKey,
    required this.emptyMessage,
    this.notice,
    required this.demo,
  });
}

/// Colour + label for any backend status string.
StatusStyle genericStatus(String raw) {
  final s = raw.toLowerCase();
  const green = Color(0xFF0E8A5F), amber = Color(0xFFD48806), red = Color(0xFFDC2626), blue = Color(0xFF2563EB), grey = Color(0xFF6B7280);
  final label = s.isEmpty ? '—' : s.split(RegExp(r'[_\s]+')).map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  final color = switch (s) {
    'active' || 'completed' || 'done' || 'converted' || 'won' || 'paid' || 'successful' || 'signed' || 'resolved' || 'closed' || 'sent' => green,
    'pending' || 'todo' || 'new' || 'open' || 'draft' || 'contacted' || 'scheduled' || 'on_hold' || 'review' || 'in_progress' || 'processing' => amber,
    'qualified' || 'proposal' || 'medium' => blue,
    'cancelled' || 'canceled' || 'lost' || 'failed' || 'bounced' || 'terminated' || 'urgent' || 'high' || 'expired' || 'suspended' => red,
    _ => grey,
  };
  return StatusStyle(label, color);
}

/// CRUD over the API (live) or an in-memory sample set (demo).
class ResourceRepository {
  static ResourceRepository instance = ResourceRepository();

  final _demo = <String, List<Map<String, dynamic>>>{};
  var _seq = 5000;

  bool get _live => LiveSession.enabled;

  List<Map<String, dynamic>> _demoFor(ResourceSpec s) => _demo.putIfAbsent(s.id, () => s.demo().map((m) => {...m}).toList());

  Future<List<Map<String, dynamic>>> list(ResourceSpec s, {Map<String, dynamic>? query}) async {
    if (_live) return LiveSession.instance.api.getAllPages(s.path, query: query);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _demoFor(s).where((m) => query == null || query.entries.every((q) => '${m[q.key]}' == '${q.value}')).toList();
  }

  Future<Map<String, dynamic>> show(ResourceSpec s, Object id) async {
    if (_live) return Map<String, dynamic>.from(await LiveSession.instance.api.get('${s.path}/$id') as Map);
    return _demoFor(s).firstWhere((m) => '${m['id']}' == '$id', orElse: () => {});
  }

  Future<Map<String, dynamic>> create(ResourceSpec s, Map<String, dynamic> body) async {
    if (_live) return Map<String, dynamic>.from(await LiveSession.instance.api.post(s.path, body) as Map);
    final m = {...body, 'id': _seq++, 'created_at': DateTime.now().toIso8601String()};
    _demoFor(s).insert(0, m);
    return m;
  }

  Future<Map<String, dynamic>> update(ResourceSpec s, Object id, Map<String, dynamic> body) async {
    if (_live) return Map<String, dynamic>.from(await LiveSession.instance.api.put('${s.path}/$id', body) as Map);
    final list = _demoFor(s);
    final i = list.indexWhere((m) => '${m['id']}' == '$id');
    if (i >= 0) list[i] = {...list[i], ...body};
    return i >= 0 ? list[i] : body;
  }

  Future<void> delete(ResourceSpec s, Object id) async {
    if (_live) {
      await LiveSession.instance.api.delete('${s.path}/$id');
      return;
    }
    _demoFor(s).removeWhere((m) => '${m['id']}' == '$id');
  }

  /// `PATCH {path}/{id}/status` (projects, milestones, tasks).
  Future<void> setStatus(ResourceSpec s, Object id, String status) async {
    if (_live) {
      await LiveSession.instance.api.patch('${s.path}/$id/status', {'status': status});
      return;
    }
    final m = _demoFor(s).firstWhere((m) => '${m['id']}' == '$id', orElse: () => {});
    m['status'] = status;
  }

  /// Options for customer / staff pickers, keyed by backend id when live.
  static List<(String, String)> customerOptions() => [
        for (final c in BizStore.instance.customers) ('${c.serverId ?? c.id}', c.name),
      ];

  static List<(String, String)> staffOptions() => [
        for (final m in BizStore.instance.staff.where((m) => m.role != StaffRole.owner)) ('${m.serverId ?? m.id}', m.name),
      ];

  static String nameOf(dynamic rel) => rel is Map ? ApiMappers.str(rel['name'] ?? rel['title']) : '';
}
