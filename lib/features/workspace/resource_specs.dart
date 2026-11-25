import 'package:flutter/material.dart';
import '../../core/api/mappers.dart';
import '../../core/api/resources.dart';
import '../../core/utils/format.dart';

/// Field definitions mirror the Laravel validation rules in
/// Modules/Admin/Http/Controllers/Api/* (bizpaddi-platform).
class Specs {
  static String _s(dynamic v) => ApiMappers.str(v);
  static String _date(dynamic v) {
    final d = ApiMappers.date(v);
    return d == null ? '' : Fmt.date(d);
  }

  static String _join(List<String> parts) => parts.where((p) => p.trim().isNotEmpty).join(' · ');
  static String _ago(int days) => DateTime.now().subtract(Duration(days: days)).toIso8601String();
  static String _ahead(int days) => DateTime.now().add(Duration(days: days)).toIso8601String();

  static const _taskStatuses = [('todo', 'To do'), ('in_progress', 'In progress'), ('review', 'In review'), ('done', 'Done')];
  static const _priorities = [('low', 'Low'), ('medium', 'Medium'), ('high', 'High'), ('urgent', 'Urgent')];
  static const _projectStatuses = [('pending', 'Pending'), ('active', 'Active'), ('on_hold', 'On hold'), ('completed', 'Completed'), ('cancelled', 'Cancelled')];

  // ------------------------------------------------------------ CRM

  static final leads = ResourceSpec(
    id: 'leads',
    title: 'Leads',
    singular: 'Lead',
    path: '/v1/admin/leads',
    icon: Icons.person_search_outlined,
    emptyMessage: 'Capture people interested in buying, then follow them up until they convert.',
    fields: const [
      ResourceField('name', 'Name', required: true),
      ResourceField('company', 'Company'),
      ResourceField('email', 'Email', kind: FieldKind.email),
      ResourceField('phone', 'Phone', kind: FieldKind.phone),
      ResourceField('status', 'Stage', kind: FieldKind.choice, options: [('new', 'New'), ('contacted', 'Contacted'), ('qualified', 'Qualified'), ('converted', 'Converted'), ('lost', 'Lost')]),
      ResourceField('source', 'Source', hint: 'e.g. WhatsApp, Instagram, walk-in'),
      ResourceField('score', 'Score (0–100)', kind: FieldKind.number),
      ResourceField('assigned_to', 'Assigned to', kind: FieldKind.staff),
      ResourceField('notes', 'Notes', kind: FieldKind.multiline),
    ],
    titleOf: (m) => _s(m['name']),
    subtitleOf: (m) => _join([_s(m['company']), _s(m['source']), ResourceRepository.nameOf(m['assigned_to_user'] ?? m['assigned_to'])]),
    statusOf: (m) => _s(m['status']).isEmpty ? 'new' : _s(m['status']),
    demo: () => [
      {'id': 1, 'name': 'Bisi Adeyemi', 'company': 'Bisi Bakes', 'phone': '08031112222', 'status': 'new', 'source': 'Instagram', 'score': 60, 'created_at': _ago(1)},
      {'id': 2, 'name': 'Chuka Obi', 'company': 'Obi Logistics', 'email': 'chuka@obilog.ng', 'status': 'qualified', 'source': 'Referral', 'score': 80, 'created_at': _ago(4)},
      {'id': 3, 'name': 'Halima Bello', 'status': 'contacted', 'source': 'WhatsApp', 'score': 45, 'created_at': _ago(7)},
    ],
  );

  static final contacts = ResourceSpec(
    id: 'contacts',
    title: 'Contacts',
    singular: 'Contact',
    path: '/v1/admin/contacts',
    icon: Icons.contacts_outlined,
    emptyMessage: 'Your mailing list for campaigns. Add people who agreed to hear from you.',
    fields: const [
      ResourceField('first_name', 'First name', required: true),
      ResourceField('last_name', 'Last name'),
      ResourceField('email', 'Email', kind: FieldKind.email, required: true),
      ResourceField('phone', 'Phone', kind: FieldKind.phone),
      ResourceField('company', 'Company'),
      ResourceField('role', 'Job title'),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('active', 'Subscribed'), ('unsubscribed', 'Unsubscribed'), ('bounced', 'Bounced')]),
    ],
    titleOf: (m) => _join([_s(m['first_name']), _s(m['last_name'])]).replaceAll(' · ', ' '),
    subtitleOf: (m) => _join([_s(m['email']), _s(m['company'])]),
    statusOf: (m) => _s(m['status']).isEmpty ? 'active' : _s(m['status']),
    demo: () => [
      {'id': 1, 'first_name': 'Ada', 'last_name': 'Obi', 'email': 'ada@gmail.com', 'company': 'Ada Couture', 'status': 'active'},
      {'id': 2, 'first_name': 'Tunde', 'last_name': 'Bakare', 'email': 'tunde@mail.com', 'status': 'unsubscribed'},
    ],
  );

  static final campaigns = ResourceSpec(
    id: 'campaigns',
    title: 'Campaigns',
    singular: 'Campaign',
    path: '/v1/admin/campaigns',
    icon: Icons.campaign_outlined,
    emptyMessage: 'Email your contacts about offers, new stock and events.',
    fields: const [
      ResourceField('name', 'Campaign name', required: true),
      ResourceField('subject', 'Email subject', required: true),
      ResourceField('from_name', 'From name'),
      ResourceField('from_email', 'From email', kind: FieldKind.email),
      ResourceField('reply_to', 'Reply-to email', kind: FieldKind.email),
      ResourceField('content', 'Message', kind: FieldKind.multiline, required: true),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('draft', 'Draft'), ('scheduled', 'Scheduled'), ('sent', 'Sent')]),
      ResourceField('scheduled_at', 'Send on', kind: FieldKind.date),
    ],
    titleOf: (m) => _s(m['name']),
    subtitleOf: (m) {
      final sent = ApiMappers.intOrNull(m['total_sent']) ?? 0;
      final opened = ApiMappers.intOrNull(m['total_opened']) ?? 0;
      return sent > 0 ? '$sent sent · $opened opened' : _s(m['subject']);
    },
    statusOf: (m) => _s(m['status']).isEmpty ? 'draft' : _s(m['status']),
    demo: () => [
      {'id': 1, 'name': 'December sale', 'subject': '20% off all Ankara this week', 'status': 'sent', 'total_sent': 120, 'total_opened': 54},
      {'id': 2, 'name': 'New arrivals', 'subject': 'Fresh lace just landed', 'status': 'draft'},
    ],
  );

  // ------------------------------------------------------------ support

  static final tickets = ResourceSpec(
    id: 'tickets',
    title: 'Support Tickets',
    singular: 'Ticket',
    path: '/v1/admin/tickets',
    icon: Icons.support_agent,
    canCreate: false, // customers open tickets from the client portal
    emptyMessage: 'When customers ask for help from their portal, their tickets show up here.',
    fields: const [
      ResourceField('subject', 'Subject', readOnly: true),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('open', 'Open'), ('in_progress', 'In progress'), ('resolved', 'Resolved'), ('closed', 'Closed')]),
      ResourceField('priority', 'Priority', kind: FieldKind.choice, options: _priorities),
    ],
    titleOf: (m) => _s(m['subject']),
    subtitleOf: (m) => _join([ResourceRepository.nameOf(m['client']), _date(m['created_at'])]),
    statusOf: (m) => _s(m['status']).isEmpty ? 'open' : _s(m['status']),
    demo: () => [
      {'id': 1, 'subject': 'I paid but the invoice still shows unpaid', 'status': 'open', 'priority': 'high', 'client': {'name': 'Mama Chidi Stores'}, 'created_at': _ago(0),
        'messages': [{'message': 'I transferred ₦37,000 yesterday but it still says unpaid.', 'created_at': _ago(0)}]},
      {'id': 2, 'subject': 'Can I change my delivery address?', 'status': 'resolved', 'priority': 'low', 'client': {'name': 'Ada Obi'}, 'created_at': _ago(3)},
    ],
  );

  // ------------------------------------------------------------ operations

  static final services = ResourceSpec(
    id: 'services',
    title: 'Services',
    singular: 'Service',
    // The backend route is named service-orders but manages the services catalogue.
    path: '/v1/admin/accounting/service-orders',
    icon: Icons.design_services_outlined,
    emptyMessage: 'List the services you offer with a starting price, so invoices and quotes are quicker to fill.',
    fields: const [
      ResourceField('name', 'Service name', required: true),
      ResourceField('description', 'Description', kind: FieldKind.multiline),
      ResourceField('base_price', 'Starting price', kind: FieldKind.money),
      ResourceField('unit', 'Unit', hint: 'e.g. per hour, per item, per event'),
      ResourceField('is_active', 'Offered now', kind: FieldKind.toggle),
    ],
    titleOf: (m) => _s(m['name']),
    subtitleOf: (m) => _join([_s(m['unit']), m['is_active'] == false || m['is_active'] == 0 ? 'Not offered' : '']),
    amountOf: (m) => ApiMappers.num0(m['base_price']),
    demo: () => [
      {'id': 1, 'name': 'Custom tailoring', 'base_price': '15000.00', 'unit': 'per outfit', 'is_active': true},
      {'id': 2, 'name': 'Event catering', 'base_price': '250000.00', 'unit': 'per event', 'is_active': true},
    ],
  );

  static final salaries = ResourceSpec(
    id: 'salaries',
    title: 'Payroll',
    singular: 'Salary payment',
    path: '/v1/admin/accounting/salaries',
    icon: Icons.payments_outlined,
    notice: 'This records a salary payment in your books. It does not send money.',
    emptyMessage: 'Record what you pay your staff so your books and reports stay accurate.',
    fields: const [
      ResourceField('user_id', 'Staff member', kind: FieldKind.staff, required: true),
      ResourceField('amount', 'Amount', kind: FieldKind.money, required: true),
      ResourceField('payment_date', 'Payment date', kind: FieldKind.date, required: true),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('pending', 'Pending'), ('successful', 'Paid'), ('failed', 'Failed')]),
      ResourceField('bank_name', 'Bank'),
      ResourceField('account_number', 'Account number', kind: FieldKind.number),
      ResourceField('account_name', 'Account name'),
      ResourceField('reference', 'Reference'),
      ResourceField('description', 'Note', kind: FieldKind.multiline),
    ],
    titleOf: (m) => ResourceRepository.nameOf(m['user']).isEmpty ? 'Salary payment' : ResourceRepository.nameOf(m['user']),
    subtitleOf: (m) => _join([_date(m['payment_date']), _s(m['bank_name'])]),
    amountOf: (m) => ApiMappers.num0(m['amount']),
    statusOf: (m) => _s(m['status']).isEmpty ? 'pending' : _s(m['status']),
    demo: () => [
      {'id': 1, 'user': {'name': 'Amaka Eze'}, 'amount': '120000.00', 'payment_date': _ago(5), 'status': 'successful', 'bank_name': 'GTBank'},
      {'id': 2, 'user': {'name': 'Segun Ajayi'}, 'amount': '150000.00', 'payment_date': _ago(5), 'status': 'pending', 'bank_name': 'Access Bank'},
    ],
  );

  static final departments = ResourceSpec(
    id: 'departments',
    title: 'Departments',
    singular: 'Department',
    path: '/v1/admin/departments',
    canShow: false, // no GET /departments/{id} route
    icon: Icons.account_tree_outlined,
    emptyMessage: 'Group your staff, e.g. Sales, Kitchen, Delivery.',
    fields: const [
      ResourceField('name', 'Name', required: true),
      ResourceField('description', 'Description', kind: FieldKind.multiline),
      ResourceField('is_active', 'Active', kind: FieldKind.toggle),
    ],
    titleOf: (m) => _s(m['name']),
    subtitleOf: (m) => _s(m['description']),
    statusOf: (m) => m['is_active'] == false || m['is_active'] == 0 ? 'inactive' : 'active',
    demo: () => [
      {'id': 1, 'name': 'Sales', 'description': 'Shop floor and online orders', 'is_active': true},
      {'id': 2, 'name': 'Production', 'description': 'Tailoring and finishing', 'is_active': true},
    ],
  );

  static final currencies = ResourceSpec(
    id: 'currencies',
    title: 'Currencies',
    singular: 'Currency',
    path: '/v1/admin/accounting/currencies',
    icon: Icons.currency_exchange,
    // Read-only: the currency table is shared by every business on the platform.
    canCreate: false,
    canEdit: false,
    canDelete: false,
    notice: 'Currencies are managed by Bizpaddi for all businesses.',
    emptyMessage: 'No currencies available.',
    fields: const [
      ResourceField('code', 'Code', readOnly: true),
      ResourceField('name', 'Name', readOnly: true),
      ResourceField('symbol', 'Symbol', readOnly: true),
      ResourceField('exchange_rate', 'Exchange rate', readOnly: true),
    ],
    titleOf: (m) => _join([_s(m['code']), _s(m['name'])]),
    subtitleOf: (m) => _join([_s(m['symbol']), _s(m['exchange_rate']).isEmpty ? '' : 'Rate ${_s(m['exchange_rate'])}']),
    demo: () => [
      {'id': 1, 'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦', 'exchange_rate': '1.00'},
      {'id': 2, 'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'exchange_rate': '1550.00'},
      {'id': 3, 'code': 'GHS', 'name': 'Ghana Cedi', 'symbol': '₵', 'exchange_rate': '102.00'},
    ],
  );

  // ------------------------------------------------------------ contracts

  static final contracts = ResourceSpec(
    id: 'contracts',
    title: 'Contracts',
    singular: 'Contract',
    path: '/v1/admin/contracts/manage',
    icon: Icons.history_edu_outlined,
    emptyMessage: 'Keep agreements with customers and suppliers in one place.',
    fields: const [
      ResourceField('title', 'Title', required: true),
      ResourceField('contract_type', 'Type', kind: FieldKind.choice, options: [('service', 'Service agreement'), ('supply', 'Supply'), ('employment', 'Employment'), ('nda', 'NDA'), ('other', 'Other')]),
      ResourceField('party_name', 'Other party', required: true),
      ResourceField('party_email', 'Other party email', kind: FieldKind.email),
      ResourceField('value', 'Contract value', kind: FieldKind.money),
      ResourceField('start_date', 'Start date', kind: FieldKind.date),
      ResourceField('end_date', 'End date', kind: FieldKind.date),
      ResourceField('auto_renew', 'Renews automatically', kind: FieldKind.toggle),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('draft', 'Draft'), ('sent', 'Sent'), ('signed', 'Signed'), ('active', 'Active'), ('expired', 'Expired'), ('cancelled', 'Cancelled')]),
      ResourceField('content', 'Contract text', kind: FieldKind.multiline),
      ResourceField('terms', 'Terms', kind: FieldKind.multiline),
      ResourceField('notes', 'Internal notes', kind: FieldKind.multiline),
    ],
    titleOf: (m) => _s(m['title']),
    subtitleOf: (m) => _join([_s(m['party_name']).isEmpty ? ResourceRepository.nameOf(m['client']) : _s(m['party_name']), _date(m['end_date']).isEmpty ? '' : 'Ends ${_date(m['end_date'])}']),
    amountOf: (m) => ApiMappers.num0(m['value']),
    statusOf: (m) => _s(m['status']).isEmpty ? 'draft' : _s(m['status']),
    demo: () => [
      {'id': 1, 'title': 'Monthly supply — Ankara fabric', 'contract_type': 'supply', 'party_name': 'Kano Textiles Ltd', 'value': '450000.00', 'status': 'active', 'start_date': _ago(40), 'end_date': _ahead(320)},
      {'id': 2, 'title': 'Wedding catering — Obi family', 'contract_type': 'service', 'party_name': 'Ada Obi', 'value': '1200000.00', 'status': 'sent', 'start_date': _ahead(20)},
    ],
  );

  static final contractTemplates = ResourceSpec(
    id: 'contract-templates',
    title: 'Contract Templates',
    singular: 'Template',
    path: '/v1/admin/contracts/templates',
    icon: Icons.file_copy_outlined,
    emptyMessage: 'Save wording you reuse so new contracts take seconds.',
    fields: const [
      ResourceField('name', 'Template name', required: true),
      ResourceField('contract_type', 'Type', kind: FieldKind.choice, options: [('service', 'Service agreement'), ('supply', 'Supply'), ('employment', 'Employment'), ('nda', 'NDA'), ('other', 'Other')]),
      ResourceField('description', 'Description'),
      ResourceField('content', 'Template text', kind: FieldKind.multiline, required: true),
      ResourceField('default_terms', 'Default terms', kind: FieldKind.multiline),
      ResourceField('is_active', 'Available for new contracts', kind: FieldKind.toggle),
    ],
    titleOf: (m) => _s(m['name']),
    subtitleOf: (m) => _join([_s(m['contract_type']), _s(m['description'])]),
    demo: () => [
      {'id': 1, 'name': 'Standard service agreement', 'contract_type': 'service', 'content': 'This agreement is between {business} and {party}…', 'is_active': true},
    ],
  );

  // ------------------------------------------------------------ project management

  static final projects = ResourceSpec(
    id: 'projects',
    title: 'Projects',
    singular: 'Project',
    path: '/v1/admin/pm/projects',
    icon: Icons.work_outline,
    statusActions: _projectStatuses.map((e) => e.$1).toList(),
    emptyMessage: 'Track jobs for customers — tasks, milestones and team chat in one place.',
    fields: const [
      ResourceField('name', 'Project name', required: true),
      ResourceField('client_id', 'Customer', kind: FieldKind.customer, required: true),
      ResourceField('manager_id', 'Project manager', kind: FieldKind.staff, required: true),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: _projectStatuses),
      ResourceField('start_date', 'Start date', kind: FieldKind.date),
      ResourceField('due_date', 'Due date', kind: FieldKind.date),
      ResourceField('budget', 'Budget', kind: FieldKind.money),
      ResourceField('hourly_rate', 'Hourly rate', kind: FieldKind.money),
      ResourceField('description', 'Description', kind: FieldKind.multiline),
    ],
    titleOf: (m) => _s(m['name']).isEmpty ? _s(m['title']) : _s(m['name']),
    subtitleOf: (m) => _join([ResourceRepository.nameOf(m['client']), _date(m['due_date']).isEmpty ? '' : 'Due ${_date(m['due_date'])}']),
    amountOf: (m) => ApiMappers.num0(m['budget']),
    statusOf: (m) => _s(m['status']).isEmpty ? 'pending' : _s(m['status']),
    demo: () => [
      {'id': 1, 'name': 'Obi wedding outfits', 'client': {'name': 'Ada Obi'}, 'manager': {'name': 'Amaka Eze'}, 'status': 'active', 'start_date': _ago(10), 'due_date': _ahead(14), 'budget': '850000.00', 'description': '12 outfits for the bridal party.'},
      {'id': 2, 'name': 'School uniforms — 200 sets', 'client': {'name': 'Mama Chioma Stores'}, 'manager': {'name': 'Segun Ajayi'}, 'status': 'pending', 'due_date': _ahead(40), 'budget': '1200000.00'},
    ],
  );

  static final milestones = ResourceSpec(
    id: 'milestones',
    title: 'Milestones',
    singular: 'Milestone',
    path: '/v1/admin/pm/milestones',
    icon: Icons.flag_outlined,
    statusActions: const ['pending', 'completed'],
    parentKey: 'project_id',
    emptyMessage: 'Break the project into checkpoints, e.g. "Fabric bought", "First fitting".',
    fields: const [
      ResourceField('title', 'Title', required: true),
      ResourceField('description', 'Description', kind: FieldKind.multiline),
      ResourceField('due_date', 'Due date', kind: FieldKind.date),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('pending', 'Pending'), ('completed', 'Completed')]),
    ],
    titleOf: (m) => _s(m['title']),
    subtitleOf: (m) => _date(m['due_date']).isEmpty ? '' : 'Due ${_date(m['due_date'])}',
    statusOf: (m) => _s(m['status']).isEmpty ? 'pending' : _s(m['status']),
    demo: () => [
      {'id': 1, 'project_id': 1, 'title': 'Fabric bought', 'status': 'completed', 'due_date': _ago(5)},
      {'id': 2, 'project_id': 1, 'title': 'First fitting', 'status': 'pending', 'due_date': _ahead(4)},
    ],
  );

  static final tasks = ResourceSpec(
    id: 'tasks',
    title: 'Tasks',
    singular: 'Task',
    path: '/v1/admin/pm/tasks',
    icon: Icons.task_alt,
    statusActions: _taskStatuses.map((e) => e.$1).toList(),
    parentKey: 'project_id',
    emptyMessage: 'Add the jobs to be done and who does them.',
    fields: const [
      ResourceField('title', 'Task', required: true),
      ResourceField('assigned_to', 'Assigned to', kind: FieldKind.staff),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: _taskStatuses),
      ResourceField('priority', 'Priority', kind: FieldKind.choice, options: _priorities),
      ResourceField('due_date', 'Due date', kind: FieldKind.date),
      ResourceField('requires_client_approval', 'Customer must approve', kind: FieldKind.toggle),
      ResourceField('description', 'Details', kind: FieldKind.multiline),
    ],
    titleOf: (m) => _s(m['title']),
    subtitleOf: (m) => _join([ResourceRepository.nameOf(m['assignee']), _s(m['priority']), _date(m['due_date']).isEmpty ? '' : 'Due ${_date(m['due_date'])}']),
    statusOf: (m) => _s(m['status']).isEmpty ? 'todo' : _s(m['status']),
    demo: () => [
      {'id': 1, 'project_id': 1, 'title': 'Take bridesmaids’ measurements', 'status': 'done', 'priority': 'high', 'assignee': {'name': 'Amaka Eze'}},
      {'id': 2, 'project_id': 1, 'title': 'Cut and sew 6 gowns', 'status': 'in_progress', 'priority': 'medium', 'assignee': {'name': 'Amaka Eze'}, 'due_date': _ahead(6)},
      {'id': 3, 'project_id': 2, 'title': 'Confirm sizes list', 'status': 'todo', 'priority': 'low'},
    ],
  );

  static final workLogs = ResourceSpec(
    id: 'work-logs',
    title: 'Work Logs',
    singular: 'Work log',
    path: '/v1/admin/pm/work-logs',
    icon: Icons.schedule,
    canCreate: false, // staff log their own work from the team app
    canDelete: false,
    emptyMessage: 'When staff check in and out, their work logs show up here.',
    fields: const [
      ResourceField('start_time', 'Started', kind: FieldKind.dateTime),
      ResourceField('end_time', 'Finished', kind: FieldKind.dateTime),
      ResourceField('planned_tasks', 'Planned', kind: FieldKind.multiline),
      ResourceField('actual_tasks', 'Done', kind: FieldKind.multiline),
      ResourceField('challenges', 'Challenges', kind: FieldKind.multiline),
      ResourceField('resources_needed', 'Needs', kind: FieldKind.multiline),
      ResourceField('status', 'Status', kind: FieldKind.choice, options: [('in_progress', 'In progress'), ('completed', 'Completed')]),
    ],
    titleOf: (m) => ResourceRepository.nameOf(m['user']).isEmpty ? 'Work log' : ResourceRepository.nameOf(m['user']),
    subtitleOf: (m) {
      final start = ApiMappers.date(m['start_time']);
      final end = ApiMappers.date(m['end_time']);
      if (start == null) return '';
      final hours = end == null ? null : end.difference(start).inMinutes / 60;
      return _join([Fmt.relativeDay(start), hours == null ? 'Still working' : '${hours.toStringAsFixed(1)} h']);
    },
    statusOf: (m) => _s(m['status']).isEmpty ? (m['end_time'] == null ? 'in_progress' : 'completed') : _s(m['status']),
    demo: () => [
      {'id': 1, 'user': {'name': 'Amaka Eze'}, 'start_time': DateTime.now().subtract(const Duration(hours: 9)).toIso8601String(), 'end_time': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), 'status': 'completed', 'actual_tasks': 'Finished 2 gowns'},
      {'id': 2, 'user': {'name': 'Segun Ajayi'}, 'start_time': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(), 'status': 'in_progress', 'planned_tasks': 'Deliveries to Ikeja'},
    ],
  );
}
