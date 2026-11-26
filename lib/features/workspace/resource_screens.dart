import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/mappers.dart';
import '../../core/api/resources.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/calendar_sheet.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/select_field.dart';
import '../../core/widgets/ui_kit.dart';

typedef DetailBuilder = Widget Function(ResourceSpec spec, Map<String, dynamic> item);

String _errorText(Object e) => e is ApiException ? e.message : 'Something went wrong. Please try again.';

/// Name of the related record behind a picker field (client_id → client.name).
String relationName(Map<String, dynamic> item, ResourceField f) {
  final rel = switch (f.key) {
    'client_id' => item['client'],
    'manager_id' => item['manager'],
    'user_id' => item['user'],
    'assigned_to' => item['assignee'] ?? item['assigned_to_user'] ?? item['assignedTo'],
    _ => null,
  };
  final name = ResourceRepository.nameOf(rel);
  if (name.isNotEmpty) return name;
  final id = ApiMappers.str(item[f.key]);
  if (id.isEmpty) return '';
  final opts = f.kind == FieldKind.customer ? ResourceRepository.customerOptions() : ResourceRepository.staffOptions();
  return opts.where((o) => o.$1 == id).map((o) => o.$2).firstOrNull ?? '';
}

/// Human-readable value of [f] in [item] ('' when unset).
String displayValue(Map<String, dynamic> item, ResourceField f) {
  final v = item[f.key];
  switch (f.kind) {
    case FieldKind.toggle:
      return v == null ? '' : (v == true || v == 1 || v == '1' ? 'Yes' : 'No');
    case FieldKind.money:
      return v == null || '$v'.isEmpty ? '' : Fmt.money(ApiMappers.num0(v));
    case FieldKind.date:
      final d = ApiMappers.date(v);
      return d == null ? '' : Fmt.date(d);
    case FieldKind.dateTime:
      final d = ApiMappers.date(v);
      return d == null ? '' : Fmt.dateTime(d);
    case FieldKind.choice:
      final s = ApiMappers.str(v);
      return f.options.where((o) => o.$1 == s).map((o) => o.$2).firstOrNull ?? (s.isEmpty ? '' : genericStatus(s).label);
    case FieldKind.customer:
    case FieldKind.staff:
      return relationName(item, f);
    default:
      return ApiMappers.str(v);
  }
}

// ======================================================================= list

/// Searchable, filterable list of any [ResourceSpec].
class ResourceListScreen extends StatefulWidget {
  final ResourceSpec spec;

  /// Extra list filters, e.g. `{'project_id': 3}`; also preset on new records.
  final Map<String, dynamic>? query;
  final String? subtitle;
  final DetailBuilder? detailBuilder;

  const ResourceListScreen({super.key, required this.spec, this.query, this.subtitle, this.detailBuilder});

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  String _search = '';
  String? _status;

  ResourceSpec get spec => widget.spec;
  bool get _canCreate => spec.canCreate && (spec.parentKey == null || widget.query?[spec.parentKey] != null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ResourceRepository.instance.list(spec, query: widget.query);
      if (mounted) setState(() => (_items = items, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(e));
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final builder = widget.detailBuilder ?? (s, i) => ResourceDetailScreen(spec: s, item: i);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => builder(spec, item)));
    _load();
  }

  Future<void> _create() async {
    final saved = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ResourceFormScreen(spec: spec, presets: widget.query)),
    );
    if (saved != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final items = _items;
    final statuses = spec.statusOf == null || items == null ? const <String>[] : items.map((m) => spec.statusOf!(m) ?? '').where((s) => s.isNotEmpty).toSet().toList();
    final q = _search.toLowerCase();
    final shown = (items ?? const <Map<String, dynamic>>[]).where((m) {
      if (_status != null && spec.statusOf?.call(m) != _status) return false;
      return q.isEmpty || '${spec.titleOf(m)} ${spec.subtitleOf(m)}'.toLowerCase().contains(q);
    }).toList();

    Widget content;
    if (_error != null && items == null) {
      content = ListView(children: [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Couldn’t load ${spec.title.toLowerCase()}',
          message: _error,
          action: CustomButton(text: 'Try again', width: 160, height: 44, onPressed: () {
            setState(() => _error = null);
            _load();
          }),
        ),
      ]);
    } else if (items == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (spec.notice != null) ...[InfoBanner(spec.notice!), const SizedBox(height: 12)],
            if (items.length > 4) ...[SearchField(hint: 'Search ${spec.title.toLowerCase()}', onChanged: (v) => setState(() => _search = v)), const SizedBox(height: 12)],
            if (statuses.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  SelectChip(label: 'All', selected: _status == null, onTap: () => setState(() => _status = null)),
                  for (final s in statuses) ...[
                    const SizedBox(width: 8),
                    SelectChip(label: genericStatus(s).label, selected: _status == s, onTap: () => setState(() => _status = s)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
            ],
            if (shown.isEmpty)
              EmptyState(
                icon: spec.icon,
                title: items.isEmpty ? 'No ${spec.title.toLowerCase()} yet' : 'Nothing matches',
                message: items.isEmpty ? spec.emptyMessage : 'Try a different search or filter.',
              )
            else
              for (final m in shown) ResourceTile(spec: spec, item: m, onTap: () => _open(m)),
            if (items.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${items.length} ${items.length == 1 ? spec.singular.toLowerCase() : spec.title.toLowerCase()}', textAlign: TextAlign.center, style: tx(context, 11.5, color: p.textMuted))),
          ],
        ),
      );
    }

    return InnerScaffold(
      title: spec.title,
      subtitle: widget.subtitle,
      scroll: false,
      bodyPadding: EdgeInsets.zero,
      bottom: _canCreate ? CustomButton(text: 'New ${spec.singular}', icon: const Icon(Icons.add, size: 18, color: Colors.white), onPressed: _create) : null,
      body: content,
    );
  }
}

/// One row: icon, title/subtitle, optional amount and status.
class ResourceTile extends StatelessWidget {
  final ResourceSpec spec;
  final Map<String, dynamic> item;
  final VoidCallback? onTap;
  const ResourceTile({super.key, required this.spec, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final status = spec.statusOf?.call(item);
    final amount = spec.amountOf?.call(item);
    final title = spec.titleOf(item);
    final subtitle = spec.subtitleOf(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BpCard(
        onTap: onTap,
        color: p.cardAlt,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(children: [
          LeadingIcon(spec.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.isEmpty ? spec.singular : title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 13.5, weight: FontWeight.w700)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 11.5, color: p.textMuted)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (amount != null && amount != 0) MoneyText(amount, size: 13.5),
            if (status != null && status.isNotEmpty) ...[
              if (amount != null && amount != 0) const SizedBox(height: 4),
              StatusPill(genericStatus(status), dot: true),
            ],
            if ((amount == null || amount == 0) && (status == null || status.isEmpty)) Icon(Icons.chevron_right, color: p.textMuted),
          ]),
        ]),
      ),
    );
  }
}

// ===================================================================== detail

/// Read view with status changes, edit and delete.
class ResourceDetailScreen extends StatefulWidget {
  final ResourceSpec spec;
  final Map<String, dynamic> item;

  /// Extra sections under the details (e.g. ticket conversation).
  final List<Widget> Function(BuildContext, Map<String, dynamic>)? extra;
  const ResourceDetailScreen({super.key, required this.spec, required this.item, this.extra});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  late Map<String, dynamic> _item = widget.item;
  bool _busy = false;

  ResourceSpec get spec => widget.spec;
  Object get _id => _item['id'];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!spec.canShow) return;
    try {
      final fresh = await ResourceRepository.instance.show(spec, _id);
      if (mounted && fresh.isNotEmpty) setState(() => _item = {..._item, ...fresh});
    } catch (_) {
      // Keep the list copy; the user can still act on it.
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showToast(context, done);
    } catch (e) {
      if (mounted) showToast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String s) => _run(() async {
        await ResourceRepository.instance.setStatus(spec, _id, s);
        setState(() => _item = {..._item, 'status': s});
      }, 'Marked as ${genericStatus(s).label.toLowerCase()}');

  Future<void> _edit() async {
    final saved = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => ResourceFormScreen(spec: spec, item: _item)));
    if (saved != null && mounted) {
      setState(() => _item = {..._item, ...saved});
      _refresh();
    }
  }

  Future<void> _delete() async {
    final title = spec.titleOf(_item);
    final ok = await showConfirmSheet(
      context,
      title: 'Delete ${title.isEmpty ? 'this ${spec.singular.toLowerCase()}' : title}?',
      message: 'This can’t be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ResourceRepository.instance.delete(spec, _id);
      if (!mounted) return;
      showToast(context, '${spec.singular} deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, _errorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final status = spec.statusOf?.call(_item);
    final amount = spec.amountOf?.call(_item);
    final rows = [for (final f in spec.fields) if (f.kind != FieldKind.multiline && displayValue(_item, f).isNotEmpty) f];
    final texts = [for (final f in spec.fields) if (f.kind == FieldKind.multiline && displayValue(_item, f).isNotEmpty) f];

    return InnerScaffold(
      title: spec.titleOf(_item).isEmpty ? spec.singular : spec.titleOf(_item),
      subtitle: spec.subtitleOf(_item).isEmpty ? null : spec.subtitleOf(_item),
      titleTrailing: status == null || status.isEmpty ? null : StatusPill(genericStatus(status), dot: true),
      actions: [
        if (spec.canDelete) CircleIconButton(icon: Icons.delete_outline, color: p.error, tooltip: 'Delete', onTap: _busy ? null : _delete),
      ],
      bottom: spec.canEdit ? CustomButton(text: 'Edit ${spec.singular}', variant: ButtonVariant.outline, onPressed: _busy ? null : _edit) : null,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (amount != null && amount != 0) ...[
          Text('Amount', style: tx(context, 12, color: p.textSecondary)),
          const SizedBox(height: 2),
          MoneyText(amount, size: 24),
          const SizedBox(height: 16),
        ],
        if (spec.statusActions != null) ...[
          const SectionLabel('Status'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in spec.statusActions!)
              SelectChip(label: genericStatus(s).label, selected: status == s, onTap: _busy || status == s ? () {} : () => _setStatus(s)),
          ]),
          const SizedBox(height: 16),
        ],
        if (rows.isNotEmpty)
          BpCard(
            color: p.cardAlt,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                InfoRow(label: rows[i].label, value: displayValue(_item, rows[i])),
              ],
            ]),
          ),
        for (final f in texts) ...[
          const SizedBox(height: 16),
          SectionLabel(f.label),
          Text(displayValue(_item, f), style: tx(context, 13.5, height: 1.45)),
        ],
        ...?widget.extra?.call(context, _item),
      ]),
    );
  }
}

// ======================================================================= form

/// Create / edit form generated from [ResourceSpec.fields].
/// Pops with the saved record.
class ResourceFormScreen extends StatefulWidget {
  final ResourceSpec spec;
  final Map<String, dynamic>? item;

  /// Values sent with every save but not shown (e.g. `project_id`).
  final Map<String, dynamic>? presets;
  const ResourceFormScreen({super.key, required this.spec, this.item, this.presets});

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _text = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  Map<String, String> _serverErrors = const {};
  bool _saving = false;

  ResourceSpec get spec => widget.spec;
  bool get _editing => widget.item != null;
  Iterable<ResourceField> get _fields => spec.fields.where((f) => !f.readOnly);

  static bool _isText(FieldKind k) => const {FieldKind.text, FieldKind.multiline, FieldKind.email, FieldKind.phone, FieldKind.number, FieldKind.money}.contains(k);

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? const <String, dynamic>{};
    for (final f in _fields) {
      final v = item[f.key];
      if (_isText(f.kind)) {
        var s = ApiMappers.str(v);
        if (f.kind == FieldKind.money && s.endsWith('.00')) s = s.substring(0, s.length - 3);
        _text[f.key] = TextEditingController(text: s);
      } else {
        _values[f.key] = switch (f.kind) {
          FieldKind.toggle => v == null ? !_editing : (v == true || v == 1 || v == '1'),
          FieldKind.date || FieldKind.dateTime => ApiMappers.date(v),
          FieldKind.choice => ApiMappers.str(v).isEmpty ? (f.options.isEmpty ? null : f.options.first.$1) : ApiMappers.str(v),
          _ => ApiMappers.str(v).isEmpty ? null : ApiMappers.str(v),
        };
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _localError(ResourceField f) {
    if (_isText(f.kind)) {
      final v = _text[f.key]!.text.trim();
      if (f.required && v.isEmpty) return 'Required';
      if (v.isNotEmpty && f.kind == FieldKind.email && !Fmt.isEmail(v)) return 'Invalid email address';
      if (v.isNotEmpty && (f.kind == FieldKind.money || f.kind == FieldKind.number) && num.tryParse(v.replaceAll(',', '')) == null) return 'Enter a number';
      return null;
    }
    if (f.required && _values[f.key] == null) return 'Required';
    return null;
  }

  bool get _valid => _fields.every((f) => _localError(f) == null);

  Map<String, dynamic> _body() {
    final body = <String, dynamic>{...?widget.presets};
    for (final f in _fields) {
      if (_isText(f.kind)) {
        final v = _text[f.key]!.text.trim();
        if (v.isEmpty) {
          if (_editing) body[f.key] = null;
          continue;
        }
        body[f.key] = switch (f.kind) {
          FieldKind.money || FieldKind.number => num.parse(v.replaceAll(',', '')),
          _ => v,
        };
      } else {
        final v = _values[f.key];
        if (v == null) {
          if (_editing) body[f.key] = null;
          continue;
        }
        body[f.key] = switch (f.kind) {
          FieldKind.date => ApiMappers.ymd(v as DateTime),
          FieldKind.dateTime => '${ApiMappers.ymd(v as DateTime)} ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}:00',
          FieldKind.customer || FieldKind.staff => int.tryParse('$v') ?? v,
          _ => v,
        };
      }
    }
    return body;
  }

  /// Adds customer / staff names the API reply leaves out, so lists can show them.
  Map<String, dynamic> _withRelations(Map<String, dynamic> saved) {
    final out = {...saved};
    for (final f in _fields.where((f) => f.kind == FieldKind.customer || f.kind == FieldKind.staff)) {
      final name = relationName(out, f);
      if (name.isEmpty) continue;
      final rel = {'name': name};
      switch (f.key) {
        case 'client_id':
          out['client'] = rel;
        case 'manager_id':
          out['manager'] = rel;
        case 'user_id':
          out['user'] = rel;
        case 'assigned_to':
          out['assignee'] = rel;
          out['assigned_to_user'] = rel;
      }
    }
    return out;
  }

  Future<void> _save() async {
    setState(() => (_saving = true, _serverErrors = const {}));
    try {
      final body = _body();
      final repo = ResourceRepository.instance;
      var saved = _editing ? await repo.update(spec, widget.item!['id'], body) : await repo.create(spec, body);
      saved = _withRelations({...body, ...saved});
      if (!mounted) return;
      showToast(context, _editing ? '${spec.singular} updated' : '${spec.singular} added');
      Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => (_saving = false, _serverErrors = e.fieldErrors.map((k, v) => MapEntry(k, v.first))));
      showToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showToast(context, _errorText(e));
    }
  }

  Future<void> _pickDate(ResourceField f) async {
    final current = _values[f.key] as DateTime?;
    final d = await showDatePickerSheet(context, initial: current ?? DateTime.now(), title: f.label, firstDate: DateTime(2000));
    if (d == null || !mounted) return;
    if (f.kind == FieldKind.date) {
      setState(() => _values[f.key] = d);
      return;
    }
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()));
    setState(() => _values[f.key] = DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
  }

  Widget _field(ResourceField f) {
    final p = context.p;
    final label = f.required ? f.label : '${f.label} (optional)';
    final error = _serverErrors[f.key];
    void refresh(_) => setState(() {});

    Widget withError(Widget child) => error == null
        ? child
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            child,
            const SizedBox(height: 4),
            Text(error, style: tx(context, 11.5, color: p.error)),
          ]);

    switch (f.kind) {
      case FieldKind.text:
      case FieldKind.multiline:
      case FieldKind.email:
      case FieldKind.phone:
      case FieldKind.number:
      case FieldKind.money:
        final c = _text[f.key]!;
        final local = c.text.trim().isEmpty ? null : _localError(f);
        return CustomTextField(
          label: label,
          hint: f.hint ?? 'Enter ${f.label.toLowerCase()}',
          controller: c,
          maxLines: f.kind == FieldKind.multiline ? 4 : 1,
          prefixText: f.kind == FieldKind.money ? '₦ ' : null,
          textCapitalization: f.kind == FieldKind.text || f.kind == FieldKind.multiline ? TextCapitalization.sentences : TextCapitalization.none,
          keyboardType: switch (f.kind) {
            FieldKind.email => TextInputType.emailAddress,
            FieldKind.phone => TextInputType.phone,
            FieldKind.number || FieldKind.money => const TextInputType.numberWithOptions(decimal: true),
            FieldKind.multiline => TextInputType.multiline,
            _ => TextInputType.text,
          },
          errorText: error ?? local,
          onChanged: refresh,
        );
      case FieldKind.toggle:
        return withError(BpCard(
          color: p.cardAlt,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            Expanded(child: Text(f.label, style: tx(context, 13.5, weight: FontWeight.w600))),
            Switch(value: _values[f.key] == true, onChanged: (v) => setState(() => _values[f.key] = v)),
          ]),
        ));
      case FieldKind.date:
      case FieldKind.dateTime:
        final d = _values[f.key] as DateTime?;
        return withError(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickDate(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border, width: 1.2)),
              child: Row(children: [
                Expanded(child: Text(d == null ? 'Choose date' : (f.kind == FieldKind.date ? Fmt.date(d) : Fmt.dateTime(d)), style: tx(context, 14, color: d == null ? p.textMuted : p.text))),
                if (d != null && !f.required)
                  InkWell(onTap: () => setState(() => _values[f.key] = null), child: Icon(Icons.close, size: 18, color: p.textMuted))
                else
                  Icon(Icons.calendar_today_outlined, size: 18, color: p.textSecondary),
              ]),
            ),
          ),
        ]));
      case FieldKind.choice:
      case FieldKind.customer:
      case FieldKind.staff:
        final options = switch (f.kind) {
          FieldKind.customer => ResourceRepository.customerOptions(),
          FieldKind.staff => ResourceRepository.staffOptions(),
          _ => f.options,
        };
        final current = options.where((o) => o.$1 == _values[f.key]).map((o) => o.$2).firstOrNull;
        if (options.isEmpty) {
          return withError(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: tx(context, 12.5, weight: FontWeight.w600, color: p.textSecondary)),
            const SizedBox(height: 6),
            InfoBanner(f.kind == FieldKind.customer ? 'Add a customer first.' : 'Add a staff member in Team first.'),
          ]));
        }
        return withError(SelectField(
          label: label,
          hint: 'Choose ${f.label.toLowerCase()}',
          value: current,
          options: [for (final o in options) o.$2],
          onChanged: (picked) => setState(() => _values[f.key] = options.firstWhere((o) => o.$2 == picked).$1),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Edit ${spec.singular}' : 'New ${spec.singular}';
    return InnerScaffold(
      title: title,
      bottom: CustomButton(text: _editing ? 'Save' : 'Save ${spec.singular}', isLoading: _saving, onPressed: _valid && !_saving ? _save : null),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (spec.notice != null) ...[InfoBanner(spec.notice!), const SizedBox(height: 14)],
        for (final f in _fields) ...[_field(f), const SizedBox(height: 14)],
      ]),
    );
  }
}
