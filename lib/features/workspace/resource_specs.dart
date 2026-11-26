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
  );
}
