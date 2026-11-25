# Bizpaddi backend — all endpoints

Generated from the Laravel route files of `bizpaddi-platform` (static parse, 2026-11-24). See [README](README.md) for the summary, gaps and payment notes.

Auth column: `public` = no middleware; `AdminAuth (session)` = business dashboard login (browser); `auth:sanctum, user_type:X` = API token for that user type.

## Part A — JSON API (`/api/...`, Sanctum token auth)

### Admin (119)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/admin/profile` | auth:sanctum, user_type:admin | AuthController@profile |
| POST | `/api/v1/admin/profile` | auth:sanctum, user_type:admin | AuthController@updateProfile |
| POST | `/api/v1/admin/profile/picture` | auth:sanctum, user_type:admin | AuthController@updateProfilePicture |
| DELETE | `/api/v1/admin/profile` | auth:sanctum, user_type:admin | AuthController@deleteAccount |
| POST | `/api/v1/admin/change-password` | auth:sanctum, user_type:admin | AuthController@changePassword |
| POST | `/api/v1/admin/logout` | auth:sanctum, user_type:admin | AuthController@logout |
| GET | `/api/v1/admin/dashboard` | auth:sanctum, user_type:admin | DashboardController@index |
| GET | `/api/v1/admin/clients` | auth:sanctum, user_type:admin | ClientController@index |
| POST | `/api/v1/admin/clients` | auth:sanctum, user_type:admin | ClientController@store |
| GET | `/api/v1/admin/clients/{client}` | auth:sanctum, user_type:admin | ClientController@show |
| PUT|PATCH | `/api/v1/admin/clients/{client}` | auth:sanctum, user_type:admin | ClientController@update |
| DELETE | `/api/v1/admin/clients/{client}` | auth:sanctum, user_type:admin | ClientController@destroy |
| GET | `/api/v1/admin/team-members` | auth:sanctum, user_type:admin | TeamMemberController@index |
| POST | `/api/v1/admin/team-members` | auth:sanctum, user_type:admin | TeamMemberController@store |
| GET | `/api/v1/admin/team-members/{team_member}` | auth:sanctum, user_type:admin | TeamMemberController@show |
| PUT|PATCH | `/api/v1/admin/team-members/{team_member}` | auth:sanctum, user_type:admin | TeamMemberController@update |
| DELETE | `/api/v1/admin/team-members/{team_member}` | auth:sanctum, user_type:admin | TeamMemberController@destroy |
| GET | `/api/v1/admin/departments` | auth:sanctum, user_type:admin | DepartmentController@index |
| POST | `/api/v1/admin/departments` | auth:sanctum, user_type:admin | DepartmentController@store |
| PUT|PATCH | `/api/v1/admin/departments/{department}` | auth:sanctum, user_type:admin | DepartmentController@update |
| DELETE | `/api/v1/admin/departments/{department}` | auth:sanctum, user_type:admin | DepartmentController@destroy |
| GET | `/api/v1/admin/roles` | auth:sanctum, user_type:admin | RoleController@index |
| POST | `/api/v1/admin/roles` | auth:sanctum, user_type:admin | RoleController@store |
| PUT|PATCH | `/api/v1/admin/roles/{role}` | auth:sanctum, user_type:admin | RoleController@update |
| DELETE | `/api/v1/admin/roles/{role}` | auth:sanctum, user_type:admin | RoleController@destroy |
| GET | `/api/v1/admin/permissions` | auth:sanctum, user_type:admin | PermissionController@index |
| POST | `/api/v1/admin/permissions` | auth:sanctum, user_type:admin | PermissionController@store |
| PUT|PATCH | `/api/v1/admin/permissions/{permission}` | auth:sanctum, user_type:admin | PermissionController@update |
| DELETE | `/api/v1/admin/permissions/{permission}` | auth:sanctum, user_type:admin | PermissionController@destroy |
| GET | `/api/v1/admin/leads` | auth:sanctum, user_type:admin | LeadController@index |
| POST | `/api/v1/admin/leads` | auth:sanctum, user_type:admin | LeadController@store |
| GET | `/api/v1/admin/leads/{lead}` | auth:sanctum, user_type:admin | LeadController@show |
| PUT|PATCH | `/api/v1/admin/leads/{lead}` | auth:sanctum, user_type:admin | LeadController@update |
| DELETE | `/api/v1/admin/leads/{lead}` | auth:sanctum, user_type:admin | LeadController@destroy |
| GET | `/api/v1/admin/contacts` | auth:sanctum, user_type:admin | ContactController@index |
| POST | `/api/v1/admin/contacts` | auth:sanctum, user_type:admin | ContactController@store |
| GET | `/api/v1/admin/contacts/{contact}` | auth:sanctum, user_type:admin | ContactController@show |
| PUT|PATCH | `/api/v1/admin/contacts/{contact}` | auth:sanctum, user_type:admin | ContactController@update |
| DELETE | `/api/v1/admin/contacts/{contact}` | auth:sanctum, user_type:admin | ContactController@destroy |
| GET | `/api/v1/admin/tickets` | auth:sanctum, user_type:admin | TicketController@index |
| GET | `/api/v1/admin/tickets/{ticket}` | auth:sanctum, user_type:admin | TicketController@show |
| PUT|PATCH | `/api/v1/admin/tickets/{ticket}` | auth:sanctum, user_type:admin | TicketController@update |
| DELETE | `/api/v1/admin/tickets/{ticket}` | auth:sanctum, user_type:admin | TicketController@destroy |
| GET | `/api/v1/admin/campaigns` | auth:sanctum, user_type:admin | CampaignController@index |
| POST | `/api/v1/admin/campaigns` | auth:sanctum, user_type:admin | CampaignController@store |
| GET | `/api/v1/admin/campaigns/{campaign}` | auth:sanctum, user_type:admin | CampaignController@show |
| PUT|PATCH | `/api/v1/admin/campaigns/{campaign}` | auth:sanctum, user_type:admin | CampaignController@update |
| DELETE | `/api/v1/admin/campaigns/{campaign}` | auth:sanctum, user_type:admin | CampaignController@destroy |
| GET | `/api/v1/admin/notifications` | auth:sanctum, user_type:admin | NotificationController@index |
| PATCH | `/api/v1/admin/notifications/{id}/read` | auth:sanctum, user_type:admin | NotificationController@markAsRead |
| POST | `/api/v1/admin/notifications/read-all` | auth:sanctum, user_type:admin | NotificationController@markAllAsRead |
| GET | `/api/v1/admin/settings` | auth:sanctum, user_type:admin | SettingController@index |
| POST | `/api/v1/admin/settings` | auth:sanctum, user_type:admin | SettingController@update |
| GET | `/api/v1/admin/accounting/invoices` | auth:sanctum, user_type:admin | InvoiceController@index |
| POST | `/api/v1/admin/accounting/invoices` | auth:sanctum, user_type:admin | InvoiceController@store |
| GET | `/api/v1/admin/accounting/invoices/{invoice}` | auth:sanctum, user_type:admin | InvoiceController@show |
| PUT|PATCH | `/api/v1/admin/accounting/invoices/{invoice}` | auth:sanctum, user_type:admin | InvoiceController@update |
| DELETE | `/api/v1/admin/accounting/invoices/{invoice}` | auth:sanctum, user_type:admin | InvoiceController@destroy |
| GET | `/api/v1/admin/accounting/quotes` | auth:sanctum, user_type:admin | QuoteController@index |
| POST | `/api/v1/admin/accounting/quotes` | auth:sanctum, user_type:admin | QuoteController@store |
| GET | `/api/v1/admin/accounting/quotes/{quote}` | auth:sanctum, user_type:admin | QuoteController@show |
| PUT|PATCH | `/api/v1/admin/accounting/quotes/{quote}` | auth:sanctum, user_type:admin | QuoteController@update |
| DELETE | `/api/v1/admin/accounting/quotes/{quote}` | auth:sanctum, user_type:admin | QuoteController@destroy |
| GET | `/api/v1/admin/accounting/service-orders` | auth:sanctum, user_type:admin | ServiceOrderController@index |
| POST | `/api/v1/admin/accounting/service-orders` | auth:sanctum, user_type:admin | ServiceOrderController@store |
| GET | `/api/v1/admin/accounting/service-orders/{service_order}` | auth:sanctum, user_type:admin | ServiceOrderController@show |
| PUT|PATCH | `/api/v1/admin/accounting/service-orders/{service_order}` | auth:sanctum, user_type:admin | ServiceOrderController@update |
| DELETE | `/api/v1/admin/accounting/service-orders/{service_order}` | auth:sanctum, user_type:admin | ServiceOrderController@destroy |
| GET | `/api/v1/admin/accounting/transactions` | auth:sanctum, user_type:admin | TransactionController@index |
| POST | `/api/v1/admin/accounting/transactions` | auth:sanctum, user_type:admin | TransactionController@store |
| GET | `/api/v1/admin/accounting/transactions/{transaction}` | auth:sanctum, user_type:admin | TransactionController@show |
| GET | `/api/v1/admin/accounting/currencies` | auth:sanctum, user_type:admin | CurrencyController@index |
| POST | `/api/v1/admin/accounting/currencies` | auth:sanctum, user_type:admin | CurrencyController@store |
| GET | `/api/v1/admin/accounting/currencies/{currencie}` | auth:sanctum, user_type:admin | CurrencyController@show |
| PUT|PATCH | `/api/v1/admin/accounting/currencies/{currencie}` | auth:sanctum, user_type:admin | CurrencyController@update |
| DELETE | `/api/v1/admin/accounting/currencies/{currencie}` | auth:sanctum, user_type:admin | CurrencyController@destroy |
| GET | `/api/v1/admin/accounting/balance-sheet` | auth:sanctum, user_type:admin | BalanceSheetController@index |
| GET | `/api/v1/admin/accounting/salaries` | auth:sanctum, user_type:admin | SalaryController@index |
| POST | `/api/v1/admin/accounting/salaries` | auth:sanctum, user_type:admin | SalaryController@store |
| GET | `/api/v1/admin/accounting/salaries/{salarie}` | auth:sanctum, user_type:admin | SalaryController@show |
| PUT|PATCH | `/api/v1/admin/accounting/salaries/{salarie}` | auth:sanctum, user_type:admin | SalaryController@update |
| DELETE | `/api/v1/admin/accounting/salaries/{salarie}` | auth:sanctum, user_type:admin | SalaryController@destroy |
| GET | `/api/v1/admin/contracts/templates` | auth:sanctum, user_type:admin | ContractTemplateController@index |
| POST | `/api/v1/admin/contracts/templates` | auth:sanctum, user_type:admin | ContractTemplateController@store |
| GET | `/api/v1/admin/contracts/templates/{template}` | auth:sanctum, user_type:admin | ContractTemplateController@show |
| PUT|PATCH | `/api/v1/admin/contracts/templates/{template}` | auth:sanctum, user_type:admin | ContractTemplateController@update |
| DELETE | `/api/v1/admin/contracts/templates/{template}` | auth:sanctum, user_type:admin | ContractTemplateController@destroy |
| GET | `/api/v1/admin/contracts/manage` | auth:sanctum, user_type:admin | ContractController@index |
| POST | `/api/v1/admin/contracts/manage` | auth:sanctum, user_type:admin | ContractController@store |
| GET | `/api/v1/admin/contracts/manage/{contract}` | auth:sanctum, user_type:admin | ContractController@show |
| PUT|PATCH | `/api/v1/admin/contracts/manage/{contract}` | auth:sanctum, user_type:admin | ContractController@update |
| DELETE | `/api/v1/admin/contracts/manage/{contract}` | auth:sanctum, user_type:admin | ContractController@destroy |
| GET | `/api/v1/admin/pm/projects` | auth:sanctum, user_type:admin | ProjectController@index |
| POST | `/api/v1/admin/pm/projects` | auth:sanctum, user_type:admin | ProjectController@store |
| GET | `/api/v1/admin/pm/projects/{project}` | auth:sanctum, user_type:admin | ProjectController@show |
| PUT|PATCH | `/api/v1/admin/pm/projects/{project}` | auth:sanctum, user_type:admin | ProjectController@update |
| DELETE | `/api/v1/admin/pm/projects/{project}` | auth:sanctum, user_type:admin | ProjectController@destroy |
| PATCH | `/api/v1/admin/pm/projects/{id}/status` | auth:sanctum, user_type:admin | ProjectController@updateStatus |
| GET | `/api/v1/admin/pm/milestones` | auth:sanctum, user_type:admin | MilestoneController@index |
| POST | `/api/v1/admin/pm/milestones` | auth:sanctum, user_type:admin | MilestoneController@store |
| GET | `/api/v1/admin/pm/milestones/{milestone}` | auth:sanctum, user_type:admin | MilestoneController@show |
| PUT|PATCH | `/api/v1/admin/pm/milestones/{milestone}` | auth:sanctum, user_type:admin | MilestoneController@update |
| DELETE | `/api/v1/admin/pm/milestones/{milestone}` | auth:sanctum, user_type:admin | MilestoneController@destroy |
| PATCH | `/api/v1/admin/pm/milestones/{id}/status` | auth:sanctum, user_type:admin | MilestoneController@updateStatus |
| GET | `/api/v1/admin/pm/tasks` | auth:sanctum, user_type:admin | TaskController@index |
| POST | `/api/v1/admin/pm/tasks` | auth:sanctum, user_type:admin | TaskController@store |
| GET | `/api/v1/admin/pm/tasks/{task}` | auth:sanctum, user_type:admin | TaskController@show |
| PUT|PATCH | `/api/v1/admin/pm/tasks/{task}` | auth:sanctum, user_type:admin | TaskController@update |
| DELETE | `/api/v1/admin/pm/tasks/{task}` | auth:sanctum, user_type:admin | TaskController@destroy |
| PATCH | `/api/v1/admin/pm/tasks/{id}/status` | auth:sanctum, user_type:admin | TaskController@updateStatus |
| GET | `/api/v1/admin/pm/work-logs` | auth:sanctum, user_type:admin | WorkLogController@index |
| GET | `/api/v1/admin/pm/work-logs/{work_log}` | auth:sanctum, user_type:admin | WorkLogController@show |
| PUT | `/api/v1/admin/pm/work-logs/{id}` | auth:sanctum, user_type:admin | WorkLogController@update |
| GET | `/api/v1/admin/pm/projects/{id}/chat` | auth:sanctum, user_type:admin | ProjectChatController@index |
| POST | `/api/v1/admin/pm/projects/{id}/chat` | auth:sanctum, user_type:admin | ProjectChatController@store |
| POST | `/api/v1/admin/pm/projects/{id}/chat/status` | auth:sanctum, user_type:admin | ProjectChatController@updateConversationStatus |
| PUT | `/api/v1/admin/pm/projects/chat/messages/{messageId}` | auth:sanctum, user_type:admin | ProjectChatController@updateMessage |
| DELETE | `/api/v1/admin/pm/projects/chat/messages/{messageId}` | auth:sanctum, user_type:admin | ProjectChatController@deleteMessage |
| POST | `/api/v1/admin/pm/projects/chat/messages/{messageId}/read` | auth:sanctum, user_type:admin | ProjectChatController@markAsRead |

### TeamPortal (74)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/team/profile` | auth:sanctum, user_type:team | AuthController@profile |
| POST | `/api/v1/team/profile` | auth:sanctum, user_type:team | AuthController@updateProfile |
| POST | `/api/v1/team/profile/picture` | auth:sanctum, user_type:team | AuthController@updateProfilePicture |
| DELETE | `/api/v1/team/profile` | auth:sanctum, user_type:team | AuthController@deleteAccount |
| POST | `/api/v1/team/change-password` | auth:sanctum, user_type:team | AuthController@changePassword |
| POST | `/api/v1/team/logout` | auth:sanctum, user_type:team | AuthController@logout |
| GET | `/api/v1/team/dashboard` | auth:sanctum, user_type:team | DashboardController@index |
| GET | `/api/v1/team/tasks` | auth:sanctum, user_type:team | TaskController@index |
| GET | `/api/v1/team/tasks/{task}` | auth:sanctum, user_type:team | TaskController@show |
| PATCH | `/api/v1/team/tasks/{id}/status` | auth:sanctum, user_type:team | TaskController@updateStatus |
| GET | `/api/v1/team/kanban` | auth:sanctum, user_type:team | KanbanController@index |
| POST | `/api/v1/team/kanban/update-order` | auth:sanctum, user_type:team | KanbanController@updateOrder |
| GET | `/api/v1/team/work-logs` | auth:sanctum, user_type:team | WorkLogController@index |
| GET | `/api/v1/team/work-logs/check-partial-status` | auth:sanctum, user_type:team | WorkLogController@checkPartialStatus |
| POST | `/api/v1/team/work-logs/check-in` | auth:sanctum, user_type:team | WorkLogController@checkIn |
| POST | `/api/v1/team/work-logs/start` | auth:sanctum, user_type:team | WorkLogController@checkIn |
| PUT | `/api/v1/team/work-logs/{id}/check-out` | auth:sanctum, user_type:team | WorkLogController@checkOut |
| PUT | `/api/v1/team/work-logs/{id}/stop` | auth:sanctum, user_type:team | WorkLogController@checkOut |
| PATCH | `/api/v1/team/work-logs/{id}/stop` | auth:sanctum, user_type:team | WorkLogController@checkOut |
| GET | `/api/v1/team/attendance` | auth:sanctum, user_type:team | AttendanceController@index |
| POST | `/api/v1/team/attendance/clock-in` | auth:sanctum, user_type:team | AttendanceController@clockIn |
| POST | `/api/v1/team/attendance/clock-out` | auth:sanctum, user_type:team | AttendanceController@clockOut |
| GET | `/api/v1/team/reports` | auth:sanctum, user_type:team | ReportController@index |
| POST | `/api/v1/team/reports` | auth:sanctum, user_type:team | ReportController@store |
| GET | `/api/v1/team/reports/{report}` | auth:sanctum, user_type:team | ReportController@show |
| GET | `/api/v1/team/projects` | auth:sanctum, user_type:team | ProjectController@index |
| GET | `/api/v1/team/projects/{project}` | auth:sanctum, user_type:team | ProjectController@show |
| GET | `/api/v1/team/projects/{id}/chat` | auth:sanctum, user_type:team | ProjectChatController@index |
| POST | `/api/v1/team/projects/{id}/chat` | auth:sanctum, user_type:team | ProjectChatController@store |
| POST | `/api/v1/team/projects/{id}/chat/status` | auth:sanctum, user_type:team | ProjectChatController@updateConversationStatus |
| PUT | `/api/v1/team/projects/chat/messages/{messageId}` | auth:sanctum, user_type:team | ProjectChatController@updateMessage |
| DELETE | `/api/v1/team/projects/chat/messages/{messageId}` | auth:sanctum, user_type:team | ProjectChatController@deleteMessage |
| POST | `/api/v1/team/projects/chat/messages/{messageId}/read` | auth:sanctum, user_type:team | ProjectChatController@markAsRead |
| GET | `/api/v1/team/chats` | auth:sanctum, user_type:team | ChatController@index |
| POST | `/api/v1/team/chats` | auth:sanctum, user_type:team | ChatController@store |
| GET | `/api/v1/team/chats/{id}` | auth:sanctum, user_type:team | ChatController@show |
| POST | `/api/v1/team/chats/{id}/messages` | auth:sanctum, user_type:team | ChatController@sendMessage |
| POST | `/api/v1/team/chats/{id}/close` | auth:sanctum, user_type:team | ChatController@close |
| DELETE | `/api/v1/team/chats/{id}` | auth:sanctum, user_type:team | ChatController@destroy |
| GET | `/api/v1/team/bank-accounts/banks` | auth:sanctum, user_type:team | BankAccountController@banks |
| GET | `/api/v1/team/bank-accounts` | auth:sanctum, user_type:team | BankAccountController@index |
| POST | `/api/v1/team/bank-accounts` | auth:sanctum, user_type:team | BankAccountController@store |
| PUT|PATCH | `/api/v1/team/bank-accounts/{bank_account}` | auth:sanctum, user_type:team | BankAccountController@update |
| DELETE | `/api/v1/team/bank-accounts/{bank_account}` | auth:sanctum, user_type:team | BankAccountController@destroy |
| POST | `/api/v1/team/bank-accounts/{id}/make-primary` | auth:sanctum, user_type:team | BankAccountController@makePrimary |
| GET | `/api/v1/team/performance` | auth:sanctum, user_type:team | PerformanceController@index |
| GET | `/api/v1/team/earnings` | auth:sanctum, user_type:team | EarningsController@index |
| GET | `/api/v1/team/earnings/{earning}` | auth:sanctum, user_type:team | EarningsController@show |
| GET | `/api/v1/team/clients` | auth:sanctum, user_type:team | ClientController@index |
| GET | `/api/v1/team/clients/{client}` | auth:sanctum, user_type:team | ClientController@show |
| GET | `/api/v1/team/quotes` | auth:sanctum, user_type:team | QuoteController@index |
| GET | `/api/v1/team/quotes/{quote}` | auth:sanctum, user_type:team | QuoteController@show |
| GET | `/api/v1/team/invoices` | auth:sanctum, user_type:team | InvoiceController@index |
| GET | `/api/v1/team/invoices/{invoice}` | auth:sanctum, user_type:team | InvoiceController@show |
| GET | `/api/v1/team/services` | auth:sanctum, user_type:team | ServiceController@index |
| GET | `/api/v1/team/services/categories` | auth:sanctum, user_type:team | ServiceController@categories |
| GET | `/api/v1/team/wallet` | auth:sanctum, user_type:team | WalletController@index |
| GET | `/api/v1/team/wallet/transactions` | auth:sanctum, user_type:team | WalletController@transactions |
| GET | `/api/v1/team/pm/dashboard` | auth:sanctum, user_type:team | PMDashboardController@index |
| GET | `/api/v1/team/pm/projects` | auth:sanctum, user_type:team | PMProjectController@index |
| GET | `/api/v1/team/pm/projects/{project}` | auth:sanctum, user_type:team | PMProjectController@show |
| GET | `/api/v1/team/pm/tasks/team-members` | auth:sanctum, user_type:team | PMTaskController@teamMembers |
| GET | `/api/v1/team/pm/tasks/options` | auth:sanctum, user_type:team | PMTaskController@options |
| GET | `/api/v1/team/pm/tasks` | auth:sanctum, user_type:team | PMTaskController@index |
| POST | `/api/v1/team/pm/tasks` | auth:sanctum, user_type:team | PMTaskController@store |
| GET | `/api/v1/team/pm/tasks/{task}` | auth:sanctum, user_type:team | PMTaskController@show |
| PUT|PATCH | `/api/v1/team/pm/tasks/{task}` | auth:sanctum, user_type:team | PMTaskController@update |
| DELETE | `/api/v1/team/pm/tasks/{task}` | auth:sanctum, user_type:team | PMTaskController@destroy |
| GET | `/api/v1/team/pm/milestones` | auth:sanctum, user_type:team | MilestoneController@index |
| POST | `/api/v1/team/pm/milestones` | auth:sanctum, user_type:team | MilestoneController@store |
| GET | `/api/v1/team/pm/milestones/{milestone}` | auth:sanctum, user_type:team | MilestoneController@show |
| PUT|PATCH | `/api/v1/team/pm/milestones/{milestone}` | auth:sanctum, user_type:team | MilestoneController@update |
| DELETE | `/api/v1/team/pm/milestones/{milestone}` | auth:sanctum, user_type:team | MilestoneController@destroy |
| GET | `/api/v1/team/pm/work-logs` | auth:sanctum, user_type:team | WorkLogController@index |

### ClientPortal (36)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/api/v1/client/login` | public | AuthController@login |
| POST | `/api/v1/client/register` | public | AuthController@register |
| POST | `/api/v1/client/forgot-password` | public | AuthController@forgotPassword |
| POST | `/api/v1/client/reset-password` | public | AuthController@resetPassword |
| GET | `/api/v1/client/legal-pages` | public | PublicController@getLegalPages |
| GET | `/api/v1/client/legal-pages/{slug}` | public | PublicController@getLegalPage |
| GET | `/api/v1/client/support-settings` | public | PublicController@getSupportSettings |
| GET | `/api/v1/client/service-categories` | public | ServiceCategoryController@index |
| GET | `/api/v1/client/service-categories/{id}` | public | ServiceCategoryController@show |
| GET | `/api/v1/client/profile` | auth:sanctum, user_type:client | AuthController@profile |
| POST | `/api/v1/client/logout` | auth:sanctum, user_type:client | AuthController@logout |
| POST | `/api/v1/client/update-device-token` | auth:sanctum, user_type:client | AuthController@updateFcmToken |
| POST | `/api/v1/client/update-profile` | auth:sanctum, user_type:client | AuthController@updateProfile |
| POST | `/api/v1/client/change-password` | auth:sanctum, user_type:client | AuthController@changePassword |
| POST | `/api/v1/client/profile/picture` | auth:sanctum, user_type:client | AuthController@updateProfilePicture |
| DELETE | `/api/v1/client/profile` | auth:sanctum, user_type:client | AuthController@deleteAccount |
| GET | `/api/v1/client/projects` | auth:sanctum, user_type:client | ProjectController@index |
| GET | `/api/v1/client/projects/{id}` | auth:sanctum, user_type:client | ProjectController@show |
| GET | `/api/v1/client/projects/{id}/chat` | auth:sanctum, user_type:client | ProjectChatController@index |
| POST | `/api/v1/client/projects/{id}/chat` | auth:sanctum, user_type:client | ProjectChatController@store |
| PUT | `/api/v1/client/projects/chat/messages/{messageId}` | auth:sanctum, user_type:client | ProjectChatController@updateMessage |
| DELETE | `/api/v1/client/projects/chat/messages/{messageId}` | auth:sanctum, user_type:client | ProjectChatController@deleteMessage |
| POST | `/api/v1/client/projects/chat/messages/{messageId}/read` | auth:sanctum, user_type:client | ProjectChatController@markAsRead |
| GET | `/api/v1/client/invoices` | auth:sanctum, user_type:client | InvoiceController@index |
| GET | `/api/v1/client/invoices/{id}` | auth:sanctum, user_type:client | InvoiceController@show |
| GET | `/api/v1/client/tickets` | auth:sanctum, user_type:client | TicketController@index |
| POST | `/api/v1/client/tickets` | auth:sanctum, user_type:client | TicketController@store |
| GET | `/api/v1/client/tickets/{id}` | auth:sanctum, user_type:client | TicketController@show |
| GET | `/api/v1/client/quotes` | auth:sanctum, user_type:client | QuoteController@index |
| GET | `/api/v1/client/quotes/{id}` | auth:sanctum, user_type:client | QuoteController@show |
| GET | `/api/v1/client/chats` | auth:sanctum, user_type:client | ChatController@index |
| POST | `/api/v1/client/chats` | auth:sanctum, user_type:client | ChatController@store |
| GET | `/api/v1/client/chats/{id}` | auth:sanctum, user_type:client | ChatController@show |
| POST | `/api/v1/client/chats/{id}/messages` | auth:sanctum, user_type:client | ChatController@sendMessage |
| POST | `/api/v1/client/chats/{id}/close` | auth:sanctum, user_type:client | ChatController@close |
| DELETE | `/api/v1/client/chats/{id}` | auth:sanctum, user_type:client | ChatController@destroy |

### SuperAdmin (6)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/superadmins` | auth:sanctum | SuperAdminController@index |
| POST | `/api/v1/superadmins` | auth:sanctum | SuperAdminController@store |
| GET | `/api/v1/superadmins/{superadmin}` | auth:sanctum | SuperAdminController@show |
| PUT|PATCH | `/api/v1/superadmins/{superadmin}` | auth:sanctum | SuperAdminController@update |
| DELETE | `/api/v1/superadmins/{superadmin}` | auth:sanctum | SuperAdminController@destroy |
| POST | `/api/v1/webhooks/billway` | public | TransactionController@handleWebhook |

### AI (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/ais` | auth:sanctum | AIController@index |
| POST | `/api/v1/ais` | auth:sanctum | AIController@store |
| GET | `/api/v1/ais/{ai}` | auth:sanctum | AIController@show |
| PUT|PATCH | `/api/v1/ais/{ai}` | auth:sanctum | AIController@update |
| DELETE | `/api/v1/ais/{ai}` | auth:sanctum | AIController@destroy |

### About (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/abouts` | auth:sanctum | AboutController@index |
| POST | `/api/v1/abouts` | auth:sanctum | AboutController@store |
| GET | `/api/v1/abouts/{about}` | auth:sanctum | AboutController@show |
| PUT|PATCH | `/api/v1/abouts/{about}` | auth:sanctum | AboutController@update |
| DELETE | `/api/v1/abouts/{about}` | auth:sanctum | AboutController@destroy |

### Accounting (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/accountings` | auth:sanctum | AccountingController@index |
| POST | `/api/v1/accountings` | auth:sanctum | AccountingController@store |
| GET | `/api/v1/accountings/{accounting}` | auth:sanctum | AccountingController@show |
| PUT|PATCH | `/api/v1/accountings/{accounting}` | auth:sanctum | AccountingController@update |
| DELETE | `/api/v1/accountings/{accounting}` | auth:sanctum | AccountingController@destroy |

### AiEmployees (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/aiemployees` | auth:sanctum | AiEmployeesController@index |
| POST | `/api/v1/aiemployees` | auth:sanctum | AiEmployeesController@store |
| GET | `/api/v1/aiemployees/{aiemployee}` | auth:sanctum | AiEmployeesController@show |
| PUT|PATCH | `/api/v1/aiemployees/{aiemployee}` | auth:sanctum | AiEmployeesController@update |
| DELETE | `/api/v1/aiemployees/{aiemployee}` | auth:sanctum | AiEmployeesController@destroy |

### Analytics (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/analytics` | auth:sanctum | AnalyticsController@index |
| POST | `/api/v1/analytics` | auth:sanctum | AnalyticsController@store |
| GET | `/api/v1/analytics/{analytic}` | auth:sanctum | AnalyticsController@show |
| PUT|PATCH | `/api/v1/analytics/{analytic}` | auth:sanctum | AnalyticsController@update |
| DELETE | `/api/v1/analytics/{analytic}` | auth:sanctum | AnalyticsController@destroy |

### Blog (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/blogs` | auth:sanctum | BlogController@index |
| POST | `/api/v1/blogs` | auth:sanctum | BlogController@store |
| GET | `/api/v1/blogs/{blog}` | auth:sanctum | BlogController@show |
| PUT|PATCH | `/api/v1/blogs/{blog}` | auth:sanctum | BlogController@update |
| DELETE | `/api/v1/blogs/{blog}` | auth:sanctum | BlogController@destroy |

### CMS (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/cms` | auth:sanctum | CMSController@index |
| POST | `/api/v1/cms` | auth:sanctum | CMSController@store |
| GET | `/api/v1/cms/{cm}` | auth:sanctum | CMSController@show |
| PUT|PATCH | `/api/v1/cms/{cm}` | auth:sanctum | CMSController@update |
| DELETE | `/api/v1/cms/{cm}` | auth:sanctum | CMSController@destroy |

### Careers (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/careers` | auth:sanctum | CareersController@index |
| POST | `/api/v1/careers` | auth:sanctum | CareersController@store |
| GET | `/api/v1/careers/{career}` | auth:sanctum | CareersController@show |
| PUT|PATCH | `/api/v1/careers/{career}` | auth:sanctum | CareersController@update |
| DELETE | `/api/v1/careers/{career}` | auth:sanctum | CareersController@destroy |

### Clients (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/clients` | auth:sanctum | ClientsController@index |
| POST | `/api/v1/clients` | auth:sanctum | ClientsController@store |
| GET | `/api/v1/clients/{client}` | auth:sanctum | ClientsController@show |
| PUT|PATCH | `/api/v1/clients/{client}` | auth:sanctum | ClientsController@update |
| DELETE | `/api/v1/clients/{client}` | auth:sanctum | ClientsController@destroy |

### Communications (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/communications` | auth:sanctum | CommunicationsController@index |
| POST | `/api/v1/communications` | auth:sanctum | CommunicationsController@store |
| GET | `/api/v1/communications/{communication}` | auth:sanctum | CommunicationsController@show |
| PUT|PATCH | `/api/v1/communications/{communication}` | auth:sanctum | CommunicationsController@update |
| DELETE | `/api/v1/communications/{communication}` | auth:sanctum | CommunicationsController@destroy |

### Contact (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/contacts` | auth:sanctum | ContactController@index |
| POST | `/api/v1/contacts` | auth:sanctum | ContactController@store |
| GET | `/api/v1/contacts/{contact}` | auth:sanctum | ContactController@show |
| PUT|PATCH | `/api/v1/contacts/{contact}` | auth:sanctum | ContactController@update |
| DELETE | `/api/v1/contacts/{contact}` | auth:sanctum | ContactController@destroy |

### Home (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/homes` | auth:sanctum | HomeController@index |
| POST | `/api/v1/homes` | auth:sanctum | HomeController@store |
| GET | `/api/v1/homes/{home}` | auth:sanctum | HomeController@show |
| PUT|PATCH | `/api/v1/homes/{home}` | auth:sanctum | HomeController@update |
| DELETE | `/api/v1/homes/{home}` | auth:sanctum | HomeController@destroy |

### Investor (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/investors` | auth:sanctum | InvestorController@index |
| POST | `/api/v1/investors` | auth:sanctum | InvestorController@store |
| GET | `/api/v1/investors/{investor}` | auth:sanctum | InvestorController@show |
| PUT|PATCH | `/api/v1/investors/{investor}` | auth:sanctum | InvestorController@update |
| DELETE | `/api/v1/investors/{investor}` | auth:sanctum | InvestorController@destroy |

### Legal (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/legals` | auth:sanctum | LegalController@index |
| POST | `/api/v1/legals` | auth:sanctum | LegalController@store |
| GET | `/api/v1/legals/{legal}` | auth:sanctum | LegalController@show |
| PUT|PATCH | `/api/v1/legals/{legal}` | auth:sanctum | LegalController@update |
| DELETE | `/api/v1/legals/{legal}` | auth:sanctum | LegalController@destroy |

### Portfolio (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/portfolios` | auth:sanctum | PortfolioController@index |
| POST | `/api/v1/portfolios` | auth:sanctum | PortfolioController@store |
| GET | `/api/v1/portfolios/{portfolio}` | auth:sanctum | PortfolioController@show |
| PUT|PATCH | `/api/v1/portfolios/{portfolio}` | auth:sanctum | PortfolioController@update |
| DELETE | `/api/v1/portfolios/{portfolio}` | auth:sanctum | PortfolioController@destroy |

### ProjectManagement (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/projectmanagements` | auth:sanctum | ProjectManagementController@index |
| POST | `/api/v1/projectmanagements` | auth:sanctum | ProjectManagementController@store |
| GET | `/api/v1/projectmanagements/{projectmanagement}` | auth:sanctum | ProjectManagementController@show |
| PUT|PATCH | `/api/v1/projectmanagements/{projectmanagement}` | auth:sanctum | ProjectManagementController@update |
| DELETE | `/api/v1/projectmanagements/{projectmanagement}` | auth:sanctum | ProjectManagementController@destroy |

### Services (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/services` | public | ServicesController@index |
| GET | `/api/v1/services/{service}` | public | ServicesController@show |
| POST | `/api/v1/services` | auth:sanctum | ServicesController@store |
| PUT|PATCH | `/api/v1/services/{service}` | auth:sanctum | ServicesController@update |
| DELETE | `/api/v1/services/{service}` | auth:sanctum | ServicesController@destroy |

### Settings (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/settings` | auth:sanctum | SettingsController@index |
| POST | `/api/v1/settings` | auth:sanctum | SettingsController@store |
| GET | `/api/v1/settings/{setting}` | auth:sanctum | SettingsController@show |
| PUT|PATCH | `/api/v1/settings/{setting}` | auth:sanctum | SettingsController@update |
| DELETE | `/api/v1/settings/{setting}` | auth:sanctum | SettingsController@destroy |

### SocialMedia (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/socialmedia` | auth:sanctum | SocialMediaController@index |
| POST | `/api/v1/socialmedia` | auth:sanctum | SocialMediaController@store |
| GET | `/api/v1/socialmedia/{socialmedia}` | auth:sanctum | SocialMediaController@show |
| PUT|PATCH | `/api/v1/socialmedia/{socialmedia}` | auth:sanctum | SocialMediaController@update |
| DELETE | `/api/v1/socialmedia/{socialmedia}` | auth:sanctum | SocialMediaController@destroy |

### Store (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/stores` | auth:sanctum | StoreController@index |
| POST | `/api/v1/stores` | auth:sanctum | StoreController@store |
| GET | `/api/v1/stores/{store}` | auth:sanctum | StoreController@show |
| PUT|PATCH | `/api/v1/stores/{store}` | auth:sanctum | StoreController@update |
| DELETE | `/api/v1/stores/{store}` | auth:sanctum | StoreController@destroy |

### Subsidiaries (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/api/v1/subsidiaries` | auth:sanctum | SubsidiariesController@index |
| POST | `/api/v1/subsidiaries` | auth:sanctum | SubsidiariesController@store |
| GET | `/api/v1/subsidiaries/{subsidiarie}` | auth:sanctum | SubsidiariesController@show |
| PUT|PATCH | `/api/v1/subsidiaries/{subsidiarie}` | auth:sanctum | SubsidiariesController@update |
| DELETE | `/api/v1/subsidiaries/{subsidiarie}` | auth:sanctum | SubsidiariesController@destroy |

### Core (routes/) (4)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/api/v1/auth/login` | public | UnifiedAuthController@login |
| POST | `/api/v1/auth/forgot-password` | public | UnifiedAuthController@forgotPassword |
| POST | `/api/v1/auth/reset-password` | public | UnifiedAuthController@resetPassword |
| GET | `/api/v1/domains/verify` | public | DomainVerificationController@verify |

## Part B — Web routes (browser pages, session cookies)

### Admin (566)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/login` | guest:admin | LoginController@showLoginForm |
| POST | `/dashboard/login` | guest:admin | LoginController@login |
| GET | `/dashboard/register` | guest:admin | RegisterController@showRegistrationForm |
| POST | `/dashboard/register/send-otp` | guest:admin | RegisterController@sendOtp |
| POST | `/dashboard/register/verify-otp` | guest:admin | RegisterController@verifyOtp |
| POST | `/dashboard/register` | guest:admin | RegisterController@register |
| GET | `/dashboard/forgot-password` | guest:admin | ForgotPasswordController@showLinkRequestForm |
| POST | `/dashboard/forgot-password` | guest:admin | ForgotPasswordController@sendResetLinkEmail |
| GET | `/dashboard/reset-password/{token}` | guest:admin | ForgotPasswordController@showResetForm |
| POST | `/dashboard/reset-password` | guest:admin | ForgotPasswordController@reset |
| GET | `/dashboard` | AdminAuth (session) | DashboardController@index |
| GET | `/dashboard/dashboard` | AdminAuth (session) | DashboardController@index |
| POST | `/dashboard/logout` | AdminAuth (session) | LoginController@logout |
| GET | `/dashboard/billing` | AdminAuth (session) | BusinessBillingController@index |
| POST | `/dashboard/billing/checkout` | AdminAuth (session) | BusinessBillingController@renewOrUpgrade |
| POST | `/dashboard/billing/topup` | AdminAuth (session) | BusinessBillingController@topupWallet |
| POST | `/dashboard/billing/switch-model` | AdminAuth (session) | BusinessBillingController@switchModel |
| GET | `/dashboard/billing/pay` | AdminAuth (session) | BusinessBillingController@pay |
| GET | `/dashboard/billing/check-status` | AdminAuth (session) | BusinessBillingController@checkStatus |
| GET|POST | `/dashboard/billing/verify-now` | AdminAuth (session) | BusinessBillingController@verifyNow |
| GET | `/dashboard/billing/callback` | AdminAuth (session) | BusinessBillingController@callback |
| GET | `/dashboard/storefront/products` | AdminAuth (session) | StorefrontController@index |
| GET | `/dashboard/storefront/products/create` | AdminAuth (session) | StorefrontController@create |
| POST | `/dashboard/storefront/products` | AdminAuth (session) | StorefrontController@store |
| GET | `/dashboard/storefront/products/{product}/edit` | AdminAuth (session) | StorefrontController@edit |
| PUT | `/dashboard/storefront/products/{product}` | AdminAuth (session) | StorefrontController@update |
| DELETE | `/dashboard/storefront/products/{product}` | AdminAuth (session) | StorefrontController@destroy |
| GET | `/dashboard/storefront/settings` | AdminAuth (session) | StorefrontController@settings |
| PUT | `/dashboard/storefront/settings` | AdminAuth (session) | StorefrontController@updateSettings |
| GET | `/dashboard/storefront/orders` | AdminAuth (session) | StoreOrderController@index |
| GET | `/dashboard/storefront/orders/{order}` | AdminAuth (session) | StoreOrderController@show |
| PATCH | `/dashboard/storefront/orders/{order}/status` | AdminAuth (session) | StoreOrderController@updateStatus |
| GET | `/dashboard/account/profile` | AdminAuth (session) | AdminProfileController@edit |
| PUT | `/dashboard/account/profile` | AdminAuth (session) | AdminProfileController@update |
| GET | `/dashboard/account/password` | AdminAuth (session) | AdminPasswordController@edit |
| PUT | `/dashboard/account/password` | AdminAuth (session) | AdminPasswordController@update |
| GET | `/dashboard/account/2fa` | AdminAuth (session) | TwoFactorAuthController@showSettings |
| POST | `/dashboard/account/2fa/confirm` | AdminAuth (session) | TwoFactorAuthController@confirm |
| POST | `/dashboard/account/2fa/disable` | AdminAuth (session) | TwoFactorAuthController@disable |
| GET | `/dashboard/administrators` | AdminAuth (session) | AdminManagementController@index |
| GET | `/dashboard/administrators/create` | AdminAuth (session) | AdminManagementController@create |
| POST | `/dashboard/administrators` | AdminAuth (session) | AdminManagementController@store |
| GET | `/dashboard/administrators/{administrator}` | AdminAuth (session) | AdminManagementController@show |
| GET | `/dashboard/administrators/{administrator}/edit` | AdminAuth (session) | AdminManagementController@edit |
| PUT|PATCH | `/dashboard/administrators/{administrator}` | AdminAuth (session) | AdminManagementController@update |
| DELETE | `/dashboard/administrators/{administrator}` | AdminAuth (session) | AdminManagementController@destroy |
| PATCH | `/dashboard/administrators/{administrator}/status` | AdminAuth (session) | AdminManagementController@updateStatus |
| GET | `/dashboard/notifications` | AdminAuth (session) | NotificationController@index |
| POST | `/dashboard/notifications/send` | AdminAuth (session) | NotificationController@send |
| POST | `/dashboard/notifications/team/send` | AdminAuth (session) | NotificationController@sendToTeam |
| GET | `/dashboard/passwords` | AdminAuth (session) | PasswordManagementController@index |
| POST | `/dashboard/passwords` | AdminAuth (session) | PasswordManagementController@update |
| GET | `/dashboard/clients` | AdminAuth (session) | ClientController@index |
| GET | `/dashboard/clients/create` | AdminAuth (session) | ClientController@create |
| POST | `/dashboard/clients` | AdminAuth (session) | ClientController@store |
| GET | `/dashboard/clients/{client}` | AdminAuth (session) | ClientController@show |
| GET | `/dashboard/clients/{client}/edit` | AdminAuth (session) | ClientController@edit |
| PUT|PATCH | `/dashboard/clients/{client}` | AdminAuth (session) | ClientController@update |
| DELETE | `/dashboard/clients/{client}` | AdminAuth (session) | ClientController@destroy |
| GET | `/dashboard/team-members` | AdminAuth (session) | TeamMemberController@index |
| GET | `/dashboard/team-members/create` | AdminAuth (session) | TeamMemberController@create |
| POST | `/dashboard/team-members` | AdminAuth (session) | TeamMemberController@store |
| GET | `/dashboard/team-members/{team_member}` | AdminAuth (session) | TeamMemberController@show |
| GET | `/dashboard/team-members/{team_member}/edit` | AdminAuth (session) | TeamMemberController@edit |
| PUT|PATCH | `/dashboard/team-members/{team_member}` | AdminAuth (session) | TeamMemberController@update |
| DELETE | `/dashboard/team-members/{team_member}` | AdminAuth (session) | TeamMemberController@destroy |
| PATCH | `/dashboard/team-members/{user}/status` | AdminAuth (session) | TeamMemberController@updateStatus |
| GET | `/dashboard/team-members/{user}/login-as` | AdminAuth (session) | TeamMemberController@impersonate |
| GET | `/dashboard/impersonate/stop` | AdminAuth (session) | TeamMemberController@stopImpersonate |
| GET | `/dashboard/team-performance` | AdminAuth (session) | TeamMemberController@performance |
| GET | `/dashboard/team-performance/export-pdf` | AdminAuth (session) | TeamMemberController@exportPdf |
| GET | `/dashboard/team-performance/assessment/{user}` | AdminAuth (session) | TeamMemberController@assessment |
| POST | `/dashboard/team-performance/send-weekly-review` | AdminAuth (session) | TeamMemberController@sendWeeklyReviewEmail |
| GET | `/dashboard/team-performance/preview-review-email/{user}` | AdminAuth (session) | TeamMemberController@previewWeeklyReviewEmail |
| GET | `/dashboard/team-emails/create` | AdminAuth (session) | TeamEmailController@create |
| POST | `/dashboard/team-emails` | AdminAuth (session) | TeamEmailController@send |
| GET | `/dashboard/departments` | AdminAuth (session) | DepartmentController@index |
| GET | `/dashboard/departments/create` | AdminAuth (session) | DepartmentController@create |
| POST | `/dashboard/departments` | AdminAuth (session) | DepartmentController@store |
| GET | `/dashboard/departments/{department}` | AdminAuth (session) | DepartmentController@show |
| GET | `/dashboard/departments/{department}/edit` | AdminAuth (session) | DepartmentController@edit |
| PUT|PATCH | `/dashboard/departments/{department}` | AdminAuth (session) | DepartmentController@update |
| DELETE | `/dashboard/departments/{department}` | AdminAuth (session) | DepartmentController@destroy |
| GET | `/dashboard/roles` | AdminAuth (session) | RoleController@index |
| GET | `/dashboard/roles/create` | AdminAuth (session) | RoleController@create |
| POST | `/dashboard/roles` | AdminAuth (session) | RoleController@store |
| GET | `/dashboard/roles/{role}` | AdminAuth (session) | RoleController@show |
| GET | `/dashboard/roles/{role}/edit` | AdminAuth (session) | RoleController@edit |
| PUT|PATCH | `/dashboard/roles/{role}` | AdminAuth (session) | RoleController@update |
| DELETE | `/dashboard/roles/{role}` | AdminAuth (session) | RoleController@destroy |
| GET | `/dashboard/team-utilities` | AdminAuth (session) | TeamUtilityController@index |
| POST | `/dashboard/team-utilities/purchase` | AdminAuth (session) | TeamUtilityController@purchase |
| GET | `/dashboard/vas/service/{serviceId}/categories` | AdminAuth (session) | TeamUtilityController@fetchServiceCategories |
| GET | `/dashboard/vas/service-category/{categoryId}/products` | AdminAuth (session) | TeamUtilityController@fetchCategoryProducts |
| GET | `/dashboard/team-utilities/success/{transaction}` | AdminAuth (session) | TeamUtilityController@success |
| GET | `/dashboard/accounting/invoices` | AdminAuth (session) | InvoiceController@index |
| GET | `/dashboard/accounting/invoices/create` | AdminAuth (session) | InvoiceController@create |
| POST | `/dashboard/accounting/invoices` | AdminAuth (session) | InvoiceController@store |
| GET | `/dashboard/accounting/invoices/{invoice}` | AdminAuth (session) | InvoiceController@show |
| GET | `/dashboard/accounting/invoices/{invoice}/edit` | AdminAuth (session) | InvoiceController@edit |
| PUT|PATCH | `/dashboard/accounting/invoices/{invoice}` | AdminAuth (session) | InvoiceController@update |
| DELETE | `/dashboard/accounting/invoices/{invoice}` | AdminAuth (session) | InvoiceController@destroy |
| POST | `/dashboard/accounting/invoices/{invoice}/send` | AdminAuth (session) | InvoiceController@send |
| POST | `/dashboard/accounting/invoices/{invoice}/mark-paid` | AdminAuth (session) | InvoiceController@markPaid |
| GET | `/dashboard/accounting/invoices/{invoice}/pdf` | AdminAuth (session) | InvoiceController@downloadPDF |
| GET | `/dashboard/accounting/service-orders` | AdminAuth (session) | ServiceOrderController@index |
| GET | `/dashboard/accounting/service-orders/create` | AdminAuth (session) | ServiceOrderController@create |
| POST | `/dashboard/accounting/service-orders` | AdminAuth (session) | ServiceOrderController@store |
| GET | `/dashboard/accounting/service-orders/{service_order}` | AdminAuth (session) | ServiceOrderController@show |
| GET | `/dashboard/accounting/service-orders/{service_order}/edit` | AdminAuth (session) | ServiceOrderController@edit |
| PUT|PATCH | `/dashboard/accounting/service-orders/{service_order}` | AdminAuth (session) | ServiceOrderController@update |
| DELETE | `/dashboard/accounting/service-orders/{service_order}` | AdminAuth (session) | ServiceOrderController@destroy |
| POST | `/dashboard/accounting/service-orders/{id}/convert-quote` | AdminAuth (session) | ServiceOrderController@convertToQuote |
| POST | `/dashboard/accounting/service-orders/{id}/convert-invoice` | AdminAuth (session) | ServiceOrderController@convertToInvoice |
| POST | `/dashboard/accounting/service-orders/{id}/convert-contract` | AdminAuth (session) | ServiceOrderController@convertToContract |
| GET | `/dashboard/accounting/quotes` | AdminAuth (session) | QuoteController@index |
| GET | `/dashboard/accounting/quotes/create` | AdminAuth (session) | QuoteController@create |
| POST | `/dashboard/accounting/quotes` | AdminAuth (session) | QuoteController@store |
| GET | `/dashboard/accounting/quotes/{quote}` | AdminAuth (session) | QuoteController@show |
| GET | `/dashboard/accounting/quotes/{quote}/edit` | AdminAuth (session) | QuoteController@edit |
| PUT|PATCH | `/dashboard/accounting/quotes/{quote}` | AdminAuth (session) | QuoteController@update |
| DELETE | `/dashboard/accounting/quotes/{quote}` | AdminAuth (session) | QuoteController@destroy |
| POST | `/dashboard/accounting/quotes/{quote}/send` | AdminAuth (session) | QuoteController@send |
| POST | `/dashboard/accounting/quotes/{quote}/approve` | AdminAuth (session) | QuoteController@approve |
| POST | `/dashboard/accounting/quotes/{quote}/convert` | AdminAuth (session) | QuoteController@convertToInvoice |
| GET | `/dashboard/accounting/quotes/{quote}/pdf` | AdminAuth (session) | QuoteController@downloadPDF |
| GET | `/dashboard/accounting/currencies` | AdminAuth (session) | CurrencyController@index |
| GET | `/dashboard/accounting/currencies/create` | AdminAuth (session) | CurrencyController@create |
| POST | `/dashboard/accounting/currencies` | AdminAuth (session) | CurrencyController@store |
| GET | `/dashboard/accounting/currencies/{currencie}` | AdminAuth (session) | CurrencyController@show |
| GET | `/dashboard/accounting/currencies/{currencie}/edit` | AdminAuth (session) | CurrencyController@edit |
| PUT|PATCH | `/dashboard/accounting/currencies/{currencie}` | AdminAuth (session) | CurrencyController@update |
| DELETE | `/dashboard/accounting/currencies/{currencie}` | AdminAuth (session) | CurrencyController@destroy |
| GET | `/dashboard/accounting/services` | AdminAuth (session) | ServiceController@index |
| GET | `/dashboard/accounting/services/create` | AdminAuth (session) | ServiceController@create |
| POST | `/dashboard/accounting/services` | AdminAuth (session) | ServiceController@store |
| GET | `/dashboard/accounting/services/{service}` | AdminAuth (session) | ServiceController@show |
| GET | `/dashboard/accounting/services/{service}/edit` | AdminAuth (session) | ServiceController@edit |
| PUT|PATCH | `/dashboard/accounting/services/{service}` | AdminAuth (session) | ServiceController@update |
| DELETE | `/dashboard/accounting/services/{service}` | AdminAuth (session) | ServiceController@destroy |
| GET | `/dashboard/accounting/service-categories` | AdminAuth (session) | ServiceCategoryController@index |
| GET | `/dashboard/accounting/service-categories/create` | AdminAuth (session) | ServiceCategoryController@create |
| POST | `/dashboard/accounting/service-categories` | AdminAuth (session) | ServiceCategoryController@store |
| GET | `/dashboard/accounting/service-categories/{service_categorie}` | AdminAuth (session) | ServiceCategoryController@show |
| GET | `/dashboard/accounting/service-categories/{service_categorie}/edit` | AdminAuth (session) | ServiceCategoryController@edit |
| PUT|PATCH | `/dashboard/accounting/service-categories/{service_categorie}` | AdminAuth (session) | ServiceCategoryController@update |
| DELETE | `/dashboard/accounting/service-categories/{service_categorie}` | AdminAuth (session) | ServiceCategoryController@destroy |
| GET | `/dashboard/accounting/transactions` | AdminAuth (session) | TransactionController@index |
| GET | `/dashboard/accounting/transactions/create` | AdminAuth (session) | TransactionController@create |
| POST | `/dashboard/accounting/transactions` | AdminAuth (session) | TransactionController@store |
| GET | `/dashboard/accounting/transactions/{transaction}` | AdminAuth (session) | TransactionController@show |
| GET | `/dashboard/accounting/transactions/{transaction}/edit` | AdminAuth (session) | TransactionController@edit |
| PUT|PATCH | `/dashboard/accounting/transactions/{transaction}` | AdminAuth (session) | TransactionController@update |
| DELETE | `/dashboard/accounting/transactions/{transaction}` | AdminAuth (session) | TransactionController@destroy |
| POST | `/dashboard/accounting/transactions/{transaction}/complete` | AdminAuth (session) | TransactionController@markComplete |
| GET | `/dashboard/accounting/accounts` | AdminAuth (session) | AccountController@index |
| GET | `/dashboard/accounting/accounts/create` | AdminAuth (session) | AccountController@create |
| POST | `/dashboard/accounting/accounts` | AdminAuth (session) | AccountController@store |
| GET | `/dashboard/accounting/accounts/{account}` | AdminAuth (session) | AccountController@show |
| GET | `/dashboard/accounting/accounts/{account}/edit` | AdminAuth (session) | AccountController@edit |
| PUT|PATCH | `/dashboard/accounting/accounts/{account}` | AdminAuth (session) | AccountController@update |
| DELETE | `/dashboard/accounting/accounts/{account}` | AdminAuth (session) | AccountController@destroy |
| POST | `/dashboard/accounting/accounts/{account}/update-balance` | AdminAuth (session) | AccountController@updateBalance |
| GET | `/dashboard/accounting/balance-sheet` | AdminAuth (session) | BalanceSheetController@index |
| GET | `/dashboard/accounting/feature-pricing` | AdminAuth (session) | FeaturePricingController@index |
| GET | `/dashboard/accounting/feature-pricing/create` | AdminAuth (session) | FeaturePricingController@create |
| POST | `/dashboard/accounting/feature-pricing` | AdminAuth (session) | FeaturePricingController@store |
| GET | `/dashboard/accounting/feature-pricing/{feature_pricing}` | AdminAuth (session) | FeaturePricingController@show |
| GET | `/dashboard/accounting/feature-pricing/{feature_pricing}/edit` | AdminAuth (session) | FeaturePricingController@edit |
| PUT|PATCH | `/dashboard/accounting/feature-pricing/{feature_pricing}` | AdminAuth (session) | FeaturePricingController@update |
| DELETE | `/dashboard/accounting/feature-pricing/{feature_pricing}` | AdminAuth (session) | FeaturePricingController@destroy |
| GET | `/dashboard/accounting/payroll` | AdminAuth (session) | StaffSalaryController@index |
| GET | `/dashboard/accounting/payroll/create` | AdminAuth (session) | StaffSalaryController@create |
| POST | `/dashboard/accounting/payroll` | AdminAuth (session) | StaffSalaryController@store |
| GET | `/dashboard/accounting/payroll/{payroll}` | AdminAuth (session) | StaffSalaryController@show |
| GET | `/dashboard/accounting/payroll/{payroll}/edit` | AdminAuth (session) | StaffSalaryController@edit |
| PUT|PATCH | `/dashboard/accounting/payroll/{payroll}` | AdminAuth (session) | StaffSalaryController@update |
| DELETE | `/dashboard/accounting/payroll/{payroll}` | AdminAuth (session) | StaffSalaryController@destroy |
| PATCH | `/dashboard/accounting/payroll/{payroll}/toggle-status` | AdminAuth (session) | StaffSalaryController@toggleStatus |
| GET | `/dashboard/accounting/salaries` | AdminAuth (session) | SalaryController@index |
| GET | `/dashboard/accounting/salaries/create` | AdminAuth (session) | SalaryController@create |
| POST | `/dashboard/accounting/salaries` | AdminAuth (session) | SalaryController@store |
| GET | `/dashboard/accounting/salaries/{salarie}` | AdminAuth (session) | SalaryController@show |
| GET | `/dashboard/accounting/salaries/{salarie}/edit` | AdminAuth (session) | SalaryController@edit |
| PUT|PATCH | `/dashboard/accounting/salaries/{salarie}` | AdminAuth (session) | SalaryController@update |
| DELETE | `/dashboard/accounting/salaries/{salarie}` | AdminAuth (session) | SalaryController@destroy |
| GET | `/dashboard/accounting/bank-transactions` | AdminAuth (session) | SafeHavenController@index |
| GET | `/dashboard/contracts/templates` | AdminAuth (session) | ContractTemplateController@index |
| GET | `/dashboard/contracts/templates/create` | AdminAuth (session) | ContractTemplateController@create |
| POST | `/dashboard/contracts/templates` | AdminAuth (session) | ContractTemplateController@store |
| GET | `/dashboard/contracts/templates/{template}/edit` | AdminAuth (session) | ContractTemplateController@edit |
| PUT | `/dashboard/contracts/templates/{template}` | AdminAuth (session) | ContractTemplateController@update |
| DELETE | `/dashboard/contracts/templates/{template}` | AdminAuth (session) | ContractTemplateController@destroy |
| GET | `/dashboard/contracts` | AdminAuth (session) | ContractController@index |
| GET | `/dashboard/contracts/create` | AdminAuth (session) | ContractController@create |
| POST | `/dashboard/contracts` | AdminAuth (session) | ContractController@store |
| GET | `/dashboard/contracts/expiring-soon` | AdminAuth (session) | ContractController@expiringSoon |
| POST | `/dashboard/contracts/load-template` | AdminAuth (session) | ContractController@loadTemplate |
| GET | `/dashboard/contracts/{contract}` | AdminAuth (session) | ContractController@show |
| GET | `/dashboard/contracts/{contract}/edit` | AdminAuth (session) | ContractController@edit |
| PUT | `/dashboard/contracts/{contract}` | AdminAuth (session) | ContractController@update |
| DELETE | `/dashboard/contracts/{contract}` | AdminAuth (session) | ContractController@destroy |
| GET | `/dashboard/contracts/{contract}/pdf` | AdminAuth (session) | ContractController@downloadPDF |
| GET | `/dashboard/contracts/{contract}/docx` | AdminAuth (session) | ContractController@downloadDocx |
| POST | `/dashboard/contracts/{contract}/signature` | AdminAuth (session) | ContractController@uploadSignature |
| POST | `/dashboard/contracts/{contract}/status` | AdminAuth (session) | ContractController@updateStatus |
| ANY | `/dashboard/hero-sliders/{any?}` | AdminAuth (session), EnsureSuperAdmin |  |
| GET | `/dashboard/featured-content` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@index |
| GET | `/dashboard/featured-content/create` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@create |
| POST | `/dashboard/featured-content` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@store |
| GET | `/dashboard/featured-content/{featured_content}` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@show |
| GET | `/dashboard/featured-content/{featured_content}/edit` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@edit |
| PUT|PATCH | `/dashboard/featured-content/{featured_content}` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@update |
| DELETE | `/dashboard/featured-content/{featured_content}` | AdminAuth (session), EnsureSuperAdmin | FeaturedContentController@destroy |
| GET | `/dashboard/testimonials` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@index |
| GET | `/dashboard/testimonials/create` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@create |
| POST | `/dashboard/testimonials` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@store |
| GET | `/dashboard/testimonials/{testimonial}` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@show |
| GET | `/dashboard/testimonials/{testimonial}/edit` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@edit |
| PUT|PATCH | `/dashboard/testimonials/{testimonial}` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@update |
| DELETE | `/dashboard/testimonials/{testimonial}` | AdminAuth (session), EnsureSuperAdmin | TestimonialController@destroy |
| GET | `/dashboard/leaders` | AdminAuth (session), EnsureSuperAdmin | LeaderController@index |
| GET | `/dashboard/leaders/create` | AdminAuth (session), EnsureSuperAdmin | LeaderController@create |
| POST | `/dashboard/leaders` | AdminAuth (session), EnsureSuperAdmin | LeaderController@store |
| GET | `/dashboard/leaders/{leader}` | AdminAuth (session), EnsureSuperAdmin | LeaderController@show |
| GET | `/dashboard/leaders/{leader}/edit` | AdminAuth (session), EnsureSuperAdmin | LeaderController@edit |
| PUT|PATCH | `/dashboard/leaders/{leader}` | AdminAuth (session), EnsureSuperAdmin | LeaderController@update |
| DELETE | `/dashboard/leaders/{leader}` | AdminAuth (session), EnsureSuperAdmin | LeaderController@destroy |
| GET | `/dashboard/timeline` | AdminAuth (session), EnsureSuperAdmin | TimelineController@index |
| GET | `/dashboard/timeline/create` | AdminAuth (session), EnsureSuperAdmin | TimelineController@create |
| POST | `/dashboard/timeline` | AdminAuth (session), EnsureSuperAdmin | TimelineController@store |
| GET | `/dashboard/timeline/{timeline}` | AdminAuth (session), EnsureSuperAdmin | TimelineController@show |
| GET | `/dashboard/timeline/{timeline}/edit` | AdminAuth (session), EnsureSuperAdmin | TimelineController@edit |
| PUT|PATCH | `/dashboard/timeline/{timeline}` | AdminAuth (session), EnsureSuperAdmin | TimelineController@update |
| DELETE | `/dashboard/timeline/{timeline}` | AdminAuth (session), EnsureSuperAdmin | TimelineController@destroy |
| GET | `/dashboard/awards` | AdminAuth (session), EnsureSuperAdmin | AwardController@index |
| GET | `/dashboard/awards/create` | AdminAuth (session), EnsureSuperAdmin | AwardController@create |
| POST | `/dashboard/awards` | AdminAuth (session), EnsureSuperAdmin | AwardController@store |
| GET | `/dashboard/awards/{award}` | AdminAuth (session), EnsureSuperAdmin | AwardController@show |
| GET | `/dashboard/awards/{award}/edit` | AdminAuth (session), EnsureSuperAdmin | AwardController@edit |
| PUT|PATCH | `/dashboard/awards/{award}` | AdminAuth (session), EnsureSuperAdmin | AwardController@update |
| DELETE | `/dashboard/awards/{award}` | AdminAuth (session), EnsureSuperAdmin | AwardController@destroy |
| GET | `/dashboard/projects` | AdminAuth (session), EnsureSuperAdmin | ProjectController@index |
| GET | `/dashboard/projects/create` | AdminAuth (session), EnsureSuperAdmin | ProjectController@create |
| POST | `/dashboard/projects` | AdminAuth (session), EnsureSuperAdmin | ProjectController@store |
| GET | `/dashboard/projects/{project}` | AdminAuth (session), EnsureSuperAdmin | ProjectController@show |
| GET | `/dashboard/projects/{project}/edit` | AdminAuth (session), EnsureSuperAdmin | ProjectController@edit |
| PUT|PATCH | `/dashboard/projects/{project}` | AdminAuth (session), EnsureSuperAdmin | ProjectController@update |
| DELETE | `/dashboard/projects/{project}` | AdminAuth (session), EnsureSuperAdmin | ProjectController@destroy |
| GET | `/dashboard/industries` | AdminAuth (session), EnsureSuperAdmin | IndustryController@index |
| GET | `/dashboard/industries/create` | AdminAuth (session), EnsureSuperAdmin | IndustryController@create |
| POST | `/dashboard/industries` | AdminAuth (session), EnsureSuperAdmin | IndustryController@store |
| GET | `/dashboard/industries/{industrie}` | AdminAuth (session), EnsureSuperAdmin | IndustryController@show |
| GET | `/dashboard/industries/{industrie}/edit` | AdminAuth (session), EnsureSuperAdmin | IndustryController@edit |
| PUT|PATCH | `/dashboard/industries/{industrie}` | AdminAuth (session), EnsureSuperAdmin | IndustryController@update |
| DELETE | `/dashboard/industries/{industrie}` | AdminAuth (session), EnsureSuperAdmin | IndustryController@destroy |
| GET | `/dashboard/posts` | AdminAuth (session), EnsureSuperAdmin | PostController@index |
| GET | `/dashboard/posts/create` | AdminAuth (session), EnsureSuperAdmin | PostController@create |
| POST | `/dashboard/posts` | AdminAuth (session), EnsureSuperAdmin | PostController@store |
| GET | `/dashboard/posts/{post}` | AdminAuth (session), EnsureSuperAdmin | PostController@show |
| GET | `/dashboard/posts/{post}/edit` | AdminAuth (session), EnsureSuperAdmin | PostController@edit |
| PUT|PATCH | `/dashboard/posts/{post}` | AdminAuth (session), EnsureSuperAdmin | PostController@update |
| DELETE | `/dashboard/posts/{post}` | AdminAuth (session), EnsureSuperAdmin | PostController@destroy |
| GET | `/dashboard/categories` | AdminAuth (session), EnsureSuperAdmin | CategoryController@index |
| GET | `/dashboard/categories/create` | AdminAuth (session), EnsureSuperAdmin | CategoryController@create |
| POST | `/dashboard/categories` | AdminAuth (session), EnsureSuperAdmin | CategoryController@store |
| GET | `/dashboard/categories/{categorie}` | AdminAuth (session), EnsureSuperAdmin | CategoryController@show |
| GET | `/dashboard/categories/{categorie}/edit` | AdminAuth (session), EnsureSuperAdmin | CategoryController@edit |
| PUT|PATCH | `/dashboard/categories/{categorie}` | AdminAuth (session), EnsureSuperAdmin | CategoryController@update |
| DELETE | `/dashboard/categories/{categorie}` | AdminAuth (session), EnsureSuperAdmin | CategoryController@destroy |
| GET | `/dashboard/jobs` | AdminAuth (session), EnsureSuperAdmin | JobController@index |
| GET | `/dashboard/jobs/create` | AdminAuth (session), EnsureSuperAdmin | JobController@create |
| POST | `/dashboard/jobs` | AdminAuth (session), EnsureSuperAdmin | JobController@store |
| GET | `/dashboard/jobs/{job}` | AdminAuth (session), EnsureSuperAdmin | JobController@show |
| GET | `/dashboard/jobs/{job}/edit` | AdminAuth (session), EnsureSuperAdmin | JobController@edit |
| PUT|PATCH | `/dashboard/jobs/{job}` | AdminAuth (session), EnsureSuperAdmin | JobController@update |
| DELETE | `/dashboard/jobs/{job}` | AdminAuth (session), EnsureSuperAdmin | JobController@destroy |
| GET | `/dashboard/applications/{application}/download-resume` | AdminAuth (session), EnsureSuperAdmin | ApplicationController@downloadResume |
| GET | `/dashboard/applications` | AdminAuth (session), EnsureSuperAdmin | ApplicationController@index |
| GET | `/dashboard/applications/{application}` | AdminAuth (session), EnsureSuperAdmin | ApplicationController@show |
| PUT|PATCH | `/dashboard/applications/{application}` | AdminAuth (session), EnsureSuperAdmin | ApplicationController@update |
| GET | `/dashboard/seo` | AdminAuth (session), EnsureSuperAdmin | SeoController@index |
| PUT | `/dashboard/seo` | AdminAuth (session), EnsureSuperAdmin | SeoController@update |
| GET | `/dashboard/navigation` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@index |
| GET | `/dashboard/navigation/create` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@create |
| POST | `/dashboard/navigation` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@store |
| GET | `/dashboard/navigation/{navigation}` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@show |
| GET | `/dashboard/navigation/{navigation}/edit` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@edit |
| PUT|PATCH | `/dashboard/navigation/{navigation}` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@update |
| DELETE | `/dashboard/navigation/{navigation}` | AdminAuth (session), EnsureSuperAdmin | NavigationItemController@destroy |
| GET | `/dashboard/home/stats` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@index |
| GET | `/dashboard/home/stats/create` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@create |
| POST | `/dashboard/home/stats` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@store |
| GET | `/dashboard/home/stats/{stat}` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@show |
| GET | `/dashboard/home/stats/{stat}/edit` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@edit |
| PUT|PATCH | `/dashboard/home/stats/{stat}` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@update |
| DELETE | `/dashboard/home/stats/{stat}` | AdminAuth (session), EnsureSuperAdmin | HomeStatsController@destroy |
| GET | `/dashboard/home/features` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@index |
| GET | `/dashboard/home/features/create` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@create |
| POST | `/dashboard/home/features` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@store |
| GET | `/dashboard/home/features/{feature}` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@show |
| GET | `/dashboard/home/features/{feature}/edit` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@edit |
| PUT|PATCH | `/dashboard/home/features/{feature}` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@update |
| DELETE | `/dashboard/home/features/{feature}` | AdminAuth (session), EnsureSuperAdmin | HomeFeaturesController@destroy |
| GET | `/dashboard/home/processes` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@index |
| GET | `/dashboard/home/processes/create` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@create |
| POST | `/dashboard/home/processes` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@store |
| GET | `/dashboard/home/processes/{processe}` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@show |
| GET | `/dashboard/home/processes/{processe}/edit` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@edit |
| PUT|PATCH | `/dashboard/home/processes/{processe}` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@update |
| DELETE | `/dashboard/home/processes/{processe}` | AdminAuth (session), EnsureSuperAdmin | HomeProcessesController@destroy |
| GET | `/dashboard/home/ctas` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@index |
| GET | `/dashboard/home/ctas/create` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@create |
| POST | `/dashboard/home/ctas` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@store |
| GET | `/dashboard/home/ctas/{cta}` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@show |
| GET | `/dashboard/home/ctas/{cta}/edit` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@edit |
| PUT|PATCH | `/dashboard/home/ctas/{cta}` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@update |
| DELETE | `/dashboard/home/ctas/{cta}` | AdminAuth (session), EnsureSuperAdmin | HomeCtaController@destroy |
| GET | `/dashboard/home/client-logos` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@index |
| GET | `/dashboard/home/client-logos/create` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@create |
| POST | `/dashboard/home/client-logos` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@store |
| GET | `/dashboard/home/client-logos/{client_logo}` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@show |
| GET | `/dashboard/home/client-logos/{client_logo}/edit` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@edit |
| PUT|PATCH | `/dashboard/home/client-logos/{client_logo}` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@update |
| DELETE | `/dashboard/home/client-logos/{client_logo}` | AdminAuth (session), EnsureSuperAdmin | ClientLogoController@destroy |
| GET | `/dashboard/home/trust-badges` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@index |
| GET | `/dashboard/home/trust-badges/create` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@create |
| POST | `/dashboard/home/trust-badges` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@store |
| GET | `/dashboard/home/trust-badges/{trust_badge}` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@show |
| GET | `/dashboard/home/trust-badges/{trust_badge}/edit` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@edit |
| PUT|PATCH | `/dashboard/home/trust-badges/{trust_badge}` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@update |
| DELETE | `/dashboard/home/trust-badges/{trust_badge}` | AdminAuth (session), EnsureSuperAdmin | TrustBadgeController@destroy |
| GET | `/dashboard/investor/financial-reports` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@index |
| GET | `/dashboard/investor/financial-reports/create` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@create |
| POST | `/dashboard/investor/financial-reports` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@store |
| GET | `/dashboard/investor/financial-reports/{financial_report}` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@show |
| GET | `/dashboard/investor/financial-reports/{financial_report}/edit` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@edit |
| PUT|PATCH | `/dashboard/investor/financial-reports/{financial_report}` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@update |
| DELETE | `/dashboard/investor/financial-reports/{financial_report}` | AdminAuth (session), EnsureSuperAdmin | FinancialReportController@destroy |
| GET | `/dashboard/investor/press-releases` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@index |
| GET | `/dashboard/investor/press-releases/create` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@create |
| POST | `/dashboard/investor/press-releases` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@store |
| GET | `/dashboard/investor/press-releases/{press_release}` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@show |
| GET | `/dashboard/investor/press-releases/{press_release}/edit` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@edit |
| PUT|PATCH | `/dashboard/investor/press-releases/{press_release}` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@update |
| DELETE | `/dashboard/investor/press-releases/{press_release}` | AdminAuth (session), EnsureSuperAdmin | InvestorPressReleaseController@destroy |
| GET | `/dashboard/investor/stock-data` | AdminAuth (session), EnsureSuperAdmin | StockDataController@index |
| GET | `/dashboard/investor/stock-data/create` | AdminAuth (session), EnsureSuperAdmin | StockDataController@create |
| POST | `/dashboard/investor/stock-data` | AdminAuth (session), EnsureSuperAdmin | StockDataController@store |
| GET | `/dashboard/investor/stock-data/{stock_data}` | AdminAuth (session), EnsureSuperAdmin | StockDataController@show |
| GET | `/dashboard/investor/stock-data/{stock_data}/edit` | AdminAuth (session), EnsureSuperAdmin | StockDataController@edit |
| PUT|PATCH | `/dashboard/investor/stock-data/{stock_data}` | AdminAuth (session), EnsureSuperAdmin | StockDataController@update |
| DELETE | `/dashboard/investor/stock-data/{stock_data}` | AdminAuth (session), EnsureSuperAdmin | StockDataController@destroy |
| GET | `/dashboard/investor/shareholder-meetings` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@index |
| GET | `/dashboard/investor/shareholder-meetings/create` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@create |
| POST | `/dashboard/investor/shareholder-meetings` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@store |
| GET | `/dashboard/investor/shareholder-meetings/{shareholder_meeting}` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@show |
| GET | `/dashboard/investor/shareholder-meetings/{shareholder_meeting}/edit` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@edit |
| PUT|PATCH | `/dashboard/investor/shareholder-meetings/{shareholder_meeting}` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@update |
| DELETE | `/dashboard/investor/shareholder-meetings/{shareholder_meeting}` | AdminAuth (session), EnsureSuperAdmin | ShareholderMeetingController@destroy |
| GET | `/dashboard/visitors` | AdminAuth (session), EnsureSuperAdmin | VisitorController@index |
| GET | `/dashboard/visitors/{visitor}` | AdminAuth (session), EnsureSuperAdmin | VisitorController@show |
| DELETE | `/dashboard/visitors/{visitor}` | AdminAuth (session), EnsureSuperAdmin | VisitorController@destroy |
| POST | `/dashboard/visitors/bulk-delete` | AdminAuth (session), EnsureSuperAdmin | VisitorController@bulkDelete |
| GET | `/dashboard/rate-limits/sync` | AdminAuth (session), EnsureSuperAdmin |  |
| ANY | `/dashboard/rate-limits/{any?}` | AdminAuth (session), EnsureSuperAdmin |  |
| POST | `/dashboard/system/run` | AdminAuth (session), EnsureSuperAdmin | SystemController@runCommand |
| ANY | `/dashboard/system/{any?}` | AdminAuth (session), EnsureSuperAdmin |  |
| GET | `/dashboard/services` | AdminAuth (session) | ServiceController@index |
| GET | `/dashboard/services/create` | AdminAuth (session) | ServiceController@create |
| POST | `/dashboard/services` | AdminAuth (session) | ServiceController@store |
| GET | `/dashboard/services/{service}` | AdminAuth (session) | ServiceController@show |
| GET | `/dashboard/services/{service}/edit` | AdminAuth (session) | ServiceController@edit |
| PUT|PATCH | `/dashboard/services/{service}` | AdminAuth (session) | ServiceController@update |
| DELETE | `/dashboard/services/{service}` | AdminAuth (session) | ServiceController@destroy |
| POST | `/dashboard/contact-submissions/bulk-delete` | AdminAuth (session) | ContactSubmissionController@bulkDestroy |
| GET | `/dashboard/contact-submissions` | AdminAuth (session) | ContactSubmissionController@index |
| GET | `/dashboard/contact-submissions/{contact_submission}` | AdminAuth (session) | ContactSubmissionController@show |
| GET | `/dashboard/contact-submissions/{contact_submission}/edit` | AdminAuth (session) | ContactSubmissionController@edit |
| PUT|PATCH | `/dashboard/contact-submissions/{contact_submission}` | AdminAuth (session) | ContactSubmissionController@update |
| DELETE | `/dashboard/contact-submissions/{contact_submission}` | AdminAuth (session) | ContactSubmissionController@destroy |
| GET | `/dashboard/leads` | AdminAuth (session) | LeadController@index |
| GET | `/dashboard/leads/create` | AdminAuth (session) | LeadController@create |
| POST | `/dashboard/leads` | AdminAuth (session) | LeadController@store |
| GET | `/dashboard/leads/{lead}` | AdminAuth (session) | LeadController@show |
| GET | `/dashboard/leads/{lead}/edit` | AdminAuth (session) | LeadController@edit |
| PUT|PATCH | `/dashboard/leads/{lead}` | AdminAuth (session) | LeadController@update |
| DELETE | `/dashboard/leads/{lead}` | AdminAuth (session) | LeadController@destroy |
| POST | `/dashboard/leads/{lead}/assign` | AdminAuth (session) | LeadController@assign |
| PATCH | `/dashboard/leads/{lead}/status` | AdminAuth (session) | LeadController@updateStatus |
| POST | `/dashboard/leads/{lead}/contact` | AdminAuth (session) | LeadController@markAsContacted |
| POST | `/dashboard/leads/{lead}/convert` | AdminAuth (session) | LeadController@convertToContact |
| GET | `/dashboard/leads/export/csv` | AdminAuth (session) | LeadController@exportCsv |
| GET | `/dashboard/leads/export/pdf` | AdminAuth (session) | LeadController@exportPdf |
| POST | `/dashboard/leads/import/csv` | AdminAuth (session) | LeadController@importCsv |
| GET | `/dashboard/tickets` | AdminAuth (session) | TicketController@index |
| GET | `/dashboard/tickets/create` | AdminAuth (session) | TicketController@create |
| POST | `/dashboard/tickets` | AdminAuth (session) | TicketController@store |
| GET | `/dashboard/tickets/{ticket}` | AdminAuth (session) | TicketController@show |
| GET | `/dashboard/tickets/{ticket}/edit` | AdminAuth (session) | TicketController@edit |
| PUT|PATCH | `/dashboard/tickets/{ticket}` | AdminAuth (session) | TicketController@update |
| DELETE | `/dashboard/tickets/{ticket}` | AdminAuth (session) | TicketController@destroy |
| POST | `/dashboard/tickets/{ticket}/reply` | AdminAuth (session) | TicketController@reply |
| GET | `/dashboard/campaigns` | AdminAuth (session) | CampaignController@index |
| GET | `/dashboard/campaigns/create` | AdminAuth (session) | CampaignController@create |
| POST | `/dashboard/campaigns` | AdminAuth (session) | CampaignController@store |
| GET | `/dashboard/campaigns/{campaign}` | AdminAuth (session) | CampaignController@show |
| GET | `/dashboard/campaigns/{campaign}/edit` | AdminAuth (session) | CampaignController@edit |
| PUT|PATCH | `/dashboard/campaigns/{campaign}` | AdminAuth (session) | CampaignController@update |
| DELETE | `/dashboard/campaigns/{campaign}` | AdminAuth (session) | CampaignController@destroy |
| POST | `/dashboard/campaigns/{campaign}/send` | AdminAuth (session) | CampaignController@send |
| GET | `/dashboard/contact-lists` | AdminAuth (session) | ContactListController@index |
| GET | `/dashboard/contact-lists/create` | AdminAuth (session) | ContactListController@create |
| POST | `/dashboard/contact-lists` | AdminAuth (session) | ContactListController@store |
| GET | `/dashboard/contact-lists/{contact_list}` | AdminAuth (session) | ContactListController@show |
| GET | `/dashboard/contact-lists/{contact_list}/edit` | AdminAuth (session) | ContactListController@edit |
| PUT|PATCH | `/dashboard/contact-lists/{contact_list}` | AdminAuth (session) | ContactListController@update |
| DELETE | `/dashboard/contact-lists/{contact_list}` | AdminAuth (session) | ContactListController@destroy |
| POST | `/dashboard/contact-lists/{contactList}/add-contacts` | AdminAuth (session) | ContactListController@addContacts |
| DELETE | `/dashboard/contact-lists/{contactList}/contacts/{contact}` | AdminAuth (session) | ContactListController@removeContact |
| POST | `/dashboard/contacts/bulk-delete` | AdminAuth (session) | ContactController@bulkDelete |
| GET | `/dashboard/contacts/bulk-send-email` | AdminAuth (session) | ContactController@bulkSendEmail |
| POST | `/dashboard/contacts/bulk-send-email` | AdminAuth (session) | ContactController@processBulkEmail |
| GET | `/dashboard/contacts/bulk-send-sms` | AdminAuth (session) | ContactController@bulkSendSms |
| POST | `/dashboard/contacts/bulk-send-sms` | AdminAuth (session) | ContactController@processBulkSms |
| POST | `/dashboard/contacts/import` | AdminAuth (session) | ContactController@import |
| GET | `/dashboard/contacts/export` | AdminAuth (session) | ContactController@export |
| GET | `/dashboard/contacts/export-pdf` | AdminAuth (session) | ContactController@exportPdf |
| GET | `/dashboard/contacts/{contact}/send-email` | AdminAuth (session) | ContactController@sendEmail |
| POST | `/dashboard/contacts/{contact}/send-email` | AdminAuth (session) | ContactController@processEmail |
| GET | `/dashboard/contacts/{contact}/send-sms` | AdminAuth (session) | ContactController@sendSms |
| POST | `/dashboard/contacts/{contact}/send-sms` | AdminAuth (session) | ContactController@processSms |
| GET | `/dashboard/contacts` | AdminAuth (session) | ContactController@index |
| GET | `/dashboard/contacts/create` | AdminAuth (session) | ContactController@create |
| POST | `/dashboard/contacts` | AdminAuth (session) | ContactController@store |
| GET | `/dashboard/contacts/{contact}` | AdminAuth (session) | ContactController@show |
| GET | `/dashboard/contacts/{contact}/edit` | AdminAuth (session) | ContactController@edit |
| PUT|PATCH | `/dashboard/contacts/{contact}` | AdminAuth (session) | ContactController@update |
| DELETE | `/dashboard/contacts/{contact}` | AdminAuth (session) | ContactController@destroy |
| GET | `/dashboard/lead-settings` | AdminAuth (session) | LeadSettingsController@index |
| POST | `/dashboard/lead-settings/types` | AdminAuth (session) | LeadSettingsController@storeType |
| PUT | `/dashboard/lead-settings/types/{type}` | AdminAuth (session) | LeadSettingsController@updateType |
| DELETE | `/dashboard/lead-settings/types/{type}` | AdminAuth (session) | LeadSettingsController@destroyType |
| POST | `/dashboard/lead-settings/budgets` | AdminAuth (session) | LeadSettingsController@storeBudget |
| PUT | `/dashboard/lead-settings/budgets/{budget}` | AdminAuth (session) | LeadSettingsController@updateBudget |
| DELETE | `/dashboard/lead-settings/budgets/{budget}` | AdminAuth (session) | LeadSettingsController@destroyBudget |
| POST | `/dashboard/lead-settings/timelines` | AdminAuth (session) | LeadSettingsController@storeTimeline |
| PUT | `/dashboard/lead-settings/timelines/{timeline}` | AdminAuth (session) | LeadSettingsController@updateTimeline |
| DELETE | `/dashboard/lead-settings/timelines/{timeline}` | AdminAuth (session) | LeadSettingsController@destroyTimeline |
| GET | `/dashboard/communication-channels` | AdminAuth (session) | CommunicationChannelController@index |
| GET | `/dashboard/communication-channels/create` | AdminAuth (session) | CommunicationChannelController@create |
| POST | `/dashboard/communication-channels` | AdminAuth (session) | CommunicationChannelController@store |
| GET | `/dashboard/communication-channels/{communication_channel}` | AdminAuth (session) | CommunicationChannelController@show |
| GET | `/dashboard/communication-channels/{communication_channel}/edit` | AdminAuth (session) | CommunicationChannelController@edit |
| PUT|PATCH | `/dashboard/communication-channels/{communication_channel}` | AdminAuth (session) | CommunicationChannelController@update |
| DELETE | `/dashboard/communication-channels/{communication_channel}` | AdminAuth (session) | CommunicationChannelController@destroy |
| GET | `/dashboard/communication-scripts` | AdminAuth (session) | CommunicationScriptController@index |
| GET | `/dashboard/communication-scripts/create` | AdminAuth (session) | CommunicationScriptController@create |
| POST | `/dashboard/communication-scripts` | AdminAuth (session) | CommunicationScriptController@store |
| GET | `/dashboard/communication-scripts/{communication_script}` | AdminAuth (session) | CommunicationScriptController@show |
| GET | `/dashboard/communication-scripts/{communication_script}/edit` | AdminAuth (session) | CommunicationScriptController@edit |
| PUT|PATCH | `/dashboard/communication-scripts/{communication_script}` | AdminAuth (session) | CommunicationScriptController@update |
| DELETE | `/dashboard/communication-scripts/{communication_script}` | AdminAuth (session) | CommunicationScriptController@destroy |
| POST | `/dashboard/communication-script-steps` | AdminAuth (session) | CommunicationScriptStepController@store |
| PUT | `/dashboard/communication-script-steps/{step}` | AdminAuth (session) | CommunicationScriptStepController@update |
| DELETE | `/dashboard/communication-script-steps/{step}` | AdminAuth (session) | CommunicationScriptStepController@destroy |
| POST | `/dashboard/communication-script-steps/reorder` | AdminAuth (session) | CommunicationScriptStepController@reorder |
| POST | `/dashboard/communication-script-steps/{step}/exceptions` | AdminAuth (session) | CommunicationScriptStepController@storeException |
| DELETE | `/dashboard/communication-script-exceptions/{exception}` | AdminAuth (session) | CommunicationScriptStepController@destroyException |
| GET | `/dashboard/email-templates` | AdminAuth (session) | EmailTemplateController@index |
| GET | `/dashboard/email-templates/create` | AdminAuth (session) | EmailTemplateController@create |
| POST | `/dashboard/email-templates` | AdminAuth (session) | EmailTemplateController@store |
| GET | `/dashboard/email-templates/{email_template}` | AdminAuth (session) | EmailTemplateController@show |
| GET | `/dashboard/email-templates/{email_template}/edit` | AdminAuth (session) | EmailTemplateController@edit |
| PUT|PATCH | `/dashboard/email-templates/{email_template}` | AdminAuth (session) | EmailTemplateController@update |
| DELETE | `/dashboard/email-templates/{email_template}` | AdminAuth (session) | EmailTemplateController@destroy |
| GET | `/dashboard/sms-templates` | AdminAuth (session) | SmsTemplateController@index |
| GET | `/dashboard/sms-templates/create` | AdminAuth (session) | SmsTemplateController@create |
| POST | `/dashboard/sms-templates` | AdminAuth (session) | SmsTemplateController@store |
| GET | `/dashboard/sms-templates/{sms_template}` | AdminAuth (session) | SmsTemplateController@show |
| GET | `/dashboard/sms-templates/{sms_template}/edit` | AdminAuth (session) | SmsTemplateController@edit |
| PUT|PATCH | `/dashboard/sms-templates/{sms_template}` | AdminAuth (session) | SmsTemplateController@update |
| DELETE | `/dashboard/sms-templates/{sms_template}` | AdminAuth (session) | SmsTemplateController@destroy |
| GET | `/dashboard/pm-projects` | AdminAuth (session) | PMProjectController@index |
| GET | `/dashboard/pm-projects/create` | AdminAuth (session) | PMProjectController@create |
| POST | `/dashboard/pm-projects` | AdminAuth (session) | PMProjectController@store |
| GET | `/dashboard/pm-projects/{pm_project}` | AdminAuth (session) | PMProjectController@show |
| GET | `/dashboard/pm-projects/{pm_project}/edit` | AdminAuth (session) | PMProjectController@edit |
| PUT|PATCH | `/dashboard/pm-projects/{pm_project}` | AdminAuth (session) | PMProjectController@update |
| DELETE | `/dashboard/pm-projects/{pm_project}` | AdminAuth (session) | PMProjectController@destroy |
| GET | `/dashboard/pm-projects/{pm_project}/milestones` | AdminAuth (session) | PMProjectController@milestones |
| GET | `/dashboard/pm-milestones` | AdminAuth (session) | PMMilestoneController@index |
| GET | `/dashboard/pm-milestones/create` | AdminAuth (session) | PMMilestoneController@create |
| POST | `/dashboard/pm-milestones` | AdminAuth (session) | PMMilestoneController@store |
| GET | `/dashboard/pm-milestones/{pm_milestone}` | AdminAuth (session) | PMMilestoneController@show |
| GET | `/dashboard/pm-milestones/{pm_milestone}/edit` | AdminAuth (session) | PMMilestoneController@edit |
| PUT|PATCH | `/dashboard/pm-milestones/{pm_milestone}` | AdminAuth (session) | PMMilestoneController@update |
| DELETE | `/dashboard/pm-milestones/{pm_milestone}` | AdminAuth (session) | PMMilestoneController@destroy |
| GET | `/dashboard/tasks/export-pdf` | AdminAuth (session) | TaskController@exportPdf |
| GET | `/dashboard/tasks/export-csv` | AdminAuth (session) | TaskController@exportCsv |
| GET | `/dashboard/tasks` | AdminAuth (session) | TaskController@index |
| GET | `/dashboard/tasks/create` | AdminAuth (session) | TaskController@create |
| POST | `/dashboard/tasks` | AdminAuth (session) | TaskController@store |
| GET | `/dashboard/tasks/{task}` | AdminAuth (session) | TaskController@show |
| GET | `/dashboard/tasks/{task}/edit` | AdminAuth (session) | TaskController@edit |
| PUT|PATCH | `/dashboard/tasks/{task}` | AdminAuth (session) | TaskController@update |
| DELETE | `/dashboard/tasks/{task}` | AdminAuth (session) | TaskController@destroy |
| GET | `/dashboard/kanban` | AdminAuth (session) | KanbanController@index |
| POST | `/dashboard/kanban` | AdminAuth (session) | KanbanController@index |
| POST | `/dashboard/kanban/update-order` | AdminAuth (session) | KanbanController@updateOrder |
| GET | `/dashboard/project-management/work-logs/export` | AdminAuth (session) | WorkLogController@exportPage |
| POST | `/dashboard/project-management/work-logs/bulk-checkout` | AdminAuth (session) | WorkLogController@bulkCheckout |
| GET | `/dashboard/project-management/work-logs/export-pdf` | AdminAuth (session) | WorkLogController@exportPdf |
| GET | `/dashboard/project-management/work-logs/export-csv` | AdminAuth (session) | WorkLogController@exportCsv |
| GET | `/dashboard/project-management/work-logs/{workLog}/pdf` | AdminAuth (session) | WorkLogController@exportSinglePdf |
| GET | `/dashboard/project-management/work-logs` | AdminAuth (session) | WorkLogController@index |
| GET | `/dashboard/project-management/work-logs/{workLog}` | AdminAuth (session) | WorkLogController@show |
| GET | `/dashboard/kpis` | AdminAuth (session) | KPIController@index |
| GET | `/dashboard/kpis/create` | AdminAuth (session) | KPIController@create |
| POST | `/dashboard/kpis` | AdminAuth (session) | KPIController@store |
| GET | `/dashboard/kpis/{kpi}` | AdminAuth (session) | KPIController@show |
| GET | `/dashboard/kpis/{kpi}/edit` | AdminAuth (session) | KPIController@edit |
| PUT|PATCH | `/dashboard/kpis/{kpi}` | AdminAuth (session) | KPIController@update |
| DELETE | `/dashboard/kpis/{kpi}` | AdminAuth (session) | KPIController@destroy |
| PATCH | `/dashboard/tasks/{task}/status` | AdminAuth (session) | TaskController@updateStatus |
| PATCH | `/dashboard/tasks/{task}/approval` | AdminAuth (session) | TaskController@updateApproval |
| GET | `/dashboard/team-monitoring` | AdminAuth (session) | TeamMonitoringController@index |
| GET | `/dashboard/bugs` | AdminAuth (session) | BugReportController@index |
| GET | `/dashboard/bugs/create` | AdminAuth (session) | BugReportController@create |
| POST | `/dashboard/bugs` | AdminAuth (session) | BugReportController@store |
| GET | `/dashboard/bugs/{bug}` | AdminAuth (session) | BugReportController@show |
| GET | `/dashboard/bugs/{bug}/edit` | AdminAuth (session) | BugReportController@edit |
| PUT|PATCH | `/dashboard/bugs/{bug}` | AdminAuth (session) | BugReportController@update |
| DELETE | `/dashboard/bugs/{bug}` | AdminAuth (session) | BugReportController@destroy |
| PATCH | `/dashboard/bugs/{bug}/status` | AdminAuth (session) | BugReportController@updateStatus |
| GET | `/dashboard/chat/{conversation?}` | AdminAuth (session) | ChatController@index |
| GET | `/dashboard/chat-api/conversations` | AdminAuth (session) | ChatController@getConversations |
| GET | `/dashboard/chat-api/conversations/{conversation}/messages` | AdminAuth (session) | ChatController@getMessages |
| POST | `/dashboard/chat-api/conversations/{conversation}/messages` | AdminAuth (session) | ChatController@sendMessage |
| POST | `/dashboard/chat-api/conversations/{conversation}/read` | AdminAuth (session) | ChatController@markAsRead |
| POST | `/dashboard/chat-api/conversations/start` | AdminAuth (session) | ChatController@startConversation |
| GET | `/dashboard/chat-api/unread-count` | AdminAuth (session) | ChatController@getUnreadCount |
| POST | `/dashboard/chat-api/groups` | AdminAuth (session) | ChatController@createGroup |
| POST | `/dashboard/chat-api/conversations/{conversation}/members/add` | AdminAuth (session) | ChatController@addGroupMember |
| POST | `/dashboard/chat-api/conversations/{conversation}/members/remove` | AdminAuth (session) | ChatController@removeGroupMember |
| GET | `/dashboard/comments-feed` | AdminAuth (session) | CommentFeedController@index |
| GET | `/dashboard/comments-feed/unread-count` | AdminAuth (session) | CommentFeedController@getUnreadCount |
| GET | `/dashboard/subsidiaries` | AdminAuth (session) | SubsidiaryController@index |
| GET | `/dashboard/subsidiaries/create` | AdminAuth (session) | SubsidiaryController@create |
| POST | `/dashboard/subsidiaries` | AdminAuth (session) | SubsidiaryController@store |
| GET | `/dashboard/subsidiaries/{subsidiarie}` | AdminAuth (session) | SubsidiaryController@show |
| GET | `/dashboard/subsidiaries/{subsidiarie}/edit` | AdminAuth (session) | SubsidiaryController@edit |
| PUT|PATCH | `/dashboard/subsidiaries/{subsidiarie}` | AdminAuth (session) | SubsidiaryController@update |
| DELETE | `/dashboard/subsidiaries/{subsidiarie}` | AdminAuth (session) | SubsidiaryController@destroy |
| GET | `/dashboard/legal-pages` | AdminAuth (session) | LegalPageController@index |
| GET | `/dashboard/legal-pages/create` | AdminAuth (session) | LegalPageController@create |
| POST | `/dashboard/legal-pages` | AdminAuth (session) | LegalPageController@store |
| GET | `/dashboard/legal-pages/{legal_page}` | AdminAuth (session) | LegalPageController@show |
| GET | `/dashboard/legal-pages/{legal_page}/edit` | AdminAuth (session) | LegalPageController@edit |
| PUT|PATCH | `/dashboard/legal-pages/{legal_page}` | AdminAuth (session) | LegalPageController@update |
| DELETE | `/dashboard/legal-pages/{legal_page}` | AdminAuth (session) | LegalPageController@destroy |
| GET | `/dashboard/settings` | AdminAuth (session) | SettingController@index |
| POST | `/dashboard/settings` | AdminAuth (session) | SettingController@update |
| GET | `/dashboard/settings/mail` | AdminAuth (session) | MailSettingsController@index |
| PUT | `/dashboard/settings/mail` | AdminAuth (session) | MailSettingsController@update |
| POST | `/dashboard/settings/mail/test` | AdminAuth (session) | MailSettingsController@sendTest |

### TeamPortal (230)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/team/login` | guest:web | AuthController@showLoginForm |
| POST | `/dashboard/team/login` | guest:web | AuthController@login |
| GET | `/dashboard/team/account-status` | auth:web, CheckUserStatus | DashboardController@accountStatus |
| POST | `/dashboard/team/logout` | auth:web, CheckUserStatus | AuthController@logout |
| GET | `/dashboard/team/exit-to-admin` | auth:web, CheckUserStatus | TeamMemberController@stopImpersonate |
| GET | `/dashboard/team/dashboard` | auth:web, CheckUserStatus | DashboardController@index |
| GET | `/dashboard/team/api/overdue-tasks-count` | auth:web, CheckUserStatus | DashboardController@getOverdueTasksCount |
| GET | `/dashboard/team` | auth:web, CheckUserStatus | closure |
| GET | `/dashboard/team/profile` | auth:web, CheckUserStatus | ProfileController@index |
| GET | `/dashboard/team/profile/edit` | auth:web, CheckUserStatus | ProfileController@edit |
| PUT | `/dashboard/team/profile` | auth:web, CheckUserStatus | ProfileController@update |
| GET | `/dashboard/team/profile/password` | auth:web, CheckUserStatus | ProfileController@edit |
| GET | `/dashboard/team/my-tasks` | auth:web, CheckUserStatus | TaskController@index |
| GET | `/dashboard/team/kanban` | auth:web, CheckUserStatus | KanbanController@index |
| POST | `/dashboard/team/kanban/filter` | auth:web, CheckUserStatus | KanbanController@index |
| POST | `/dashboard/team/kanban/update-order` | auth:web, CheckUserStatus | KanbanController@updateOrder |
| GET | `/dashboard/team/tasks/{task}` | auth:web, CheckUserStatus | TaskController@show |
| PATCH | `/dashboard/team/tasks/{task}/status` | auth:web, CheckUserStatus | TaskController@updateStatus |
| DELETE | `/dashboard/team/tasks/{task}` | auth:web, CheckUserStatus | TaskController@destroy |
| GET | `/dashboard/team/reports` | auth:web, CheckUserStatus | ReportController@index |
| GET | `/dashboard/team/reports/create` | auth:web, CheckUserStatus | ReportController@create |
| POST | `/dashboard/team/reports` | auth:web, CheckUserStatus | ReportController@store |
| GET | `/dashboard/team/reports/{report}` | auth:web, CheckUserStatus | ReportController@show |
| GET | `/dashboard/team/reports/{report}/edit` | auth:web, CheckUserStatus | ReportController@edit |
| PUT|PATCH | `/dashboard/team/reports/{report}` | auth:web, CheckUserStatus | ReportController@update |
| DELETE | `/dashboard/team/reports/{report}` | auth:web, CheckUserStatus | ReportController@destroy |
| GET | `/dashboard/team/work-logs` | auth:web, CheckUserStatus | WorkLogController@index |
| GET | `/dashboard/team/work-logs/check-partial-status` | auth:web, CheckUserStatus | WorkLogController@checkPartialStatus |
| POST | `/dashboard/team/work-logs/check-in` | auth:web, CheckUserStatus | WorkLogController@checkIn |
| GET | `/dashboard/team/work-logs/{workLog}` | auth:web, CheckUserStatus | WorkLogController@show |
| PUT | `/dashboard/team/work-logs/{workLog}/check-out` | auth:web, CheckUserStatus | WorkLogController@checkOut |
| GET | `/dashboard/team/bank-accounts` | auth:web, CheckUserStatus | BankAccountController@index |
| GET | `/dashboard/team/bank-accounts/create` | auth:web, CheckUserStatus | BankAccountController@create |
| POST | `/dashboard/team/bank-accounts` | auth:web, CheckUserStatus | BankAccountController@store |
| DELETE | `/dashboard/team/bank-accounts/{bank_account}` | auth:web, CheckUserStatus | BankAccountController@destroy |
| POST | `/dashboard/team/bank-accounts/{bankAccount}/make-primary` | auth:web, CheckUserStatus | BankAccountController@makePrimary |
| GET | `/dashboard/team/clients` | auth:web, CheckUserStatus | ClientController@index |
| GET | `/dashboard/team/clients/{client}` | auth:web, CheckUserStatus | ClientController@show |
| GET | `/dashboard/team/quotes` | auth:web, CheckUserStatus | QuoteController@index |
| GET | `/dashboard/team/quotes/{quote}` | auth:web, CheckUserStatus | QuoteController@show |
| GET | `/dashboard/team/invoices` | auth:web, CheckUserStatus | InvoiceController@index |
| GET | `/dashboard/team/invoices/{invoice}` | auth:web, CheckUserStatus | InvoiceController@show |
| GET | `/dashboard/team/services` | auth:web, CheckUserStatus | ServiceController@index |
| GET | `/dashboard/team/services/{service}` | auth:web, CheckUserStatus | ServiceController@show |
| GET | `/dashboard/team/performance` | auth:web, CheckUserStatus | PerformanceController@index |
| GET | `/dashboard/team/earnings` | auth:web, CheckUserStatus | PaymentController@index |
| GET | `/dashboard/team/earnings/{id}` | auth:web, CheckUserStatus | PaymentController@show |
| POST | `/dashboard/team/attendance/clock-in` | auth:web, CheckUserStatus | AttendanceController@clockIn |
| POST | `/dashboard/team/attendance/clock-out` | auth:web, CheckUserStatus | AttendanceController@clockOut |
| GET | `/dashboard/team/my-projects` | auth:web, CheckUserStatus | ProjectController@index |
| GET | `/dashboard/team/projects/{project}` | auth:web, CheckUserStatus | ProjectController@show |
| GET | `/dashboard/team/projects/{project}/chat` | auth:web, CheckUserStatus | ProjectChatController@index |
| POST | `/dashboard/team/projects/{project}/chat` | auth:web, CheckUserStatus | ProjectChatController@store |
| GET | `/dashboard/team/chat/{conversation?}` | auth:web, CheckUserStatus | ChatController@index |
| GET | `/dashboard/team/chat-api/conversations` | auth:web, CheckUserStatus | ChatController@getConversations |
| GET | `/dashboard/team/chat-api/conversations/{conversation}/messages` | auth:web, CheckUserStatus | ChatController@getMessages |
| POST | `/dashboard/team/chat-api/conversations/{conversation}/messages` | auth:web, CheckUserStatus | ChatController@sendMessage |
| POST | `/dashboard/team/chat-api/conversations/{conversation}/read` | auth:web, CheckUserStatus | ChatController@markAsRead |
| POST | `/dashboard/team/chat-api/conversations/start` | auth:web, CheckUserStatus | ChatController@startConversation |
| GET | `/dashboard/team/chat-api/unread-count` | auth:web, CheckUserStatus | ChatController@getUnreadCount |
| POST | `/dashboard/team/chat-api/groups` | auth:web, CheckUserStatus | ChatController@createGroup |
| POST | `/dashboard/team/chat-api/conversations/{conversation}/members/add` | auth:web, CheckUserStatus | ChatController@addGroupMember |
| POST | `/dashboard/team/chat-api/conversations/{conversation}/members/remove` | auth:web, CheckUserStatus | ChatController@removeGroupMember |
| GET | `/dashboard/team/comments-feed` | auth:web, CheckUserStatus | CommentFeedController@index |
| GET | `/dashboard/team/comments-feed/unread-count` | auth:web, CheckUserStatus | CommentFeedController@getUnreadCount |
| GET | `/dashboard/team/bdm/dashboard` | auth:web, CheckUserStatus | DashboardController@index |
| GET | `/dashboard/team/bdm/clients` | auth:web, CheckUserStatus | ClientController@index |
| GET | `/dashboard/team/bdm/clients/create` | auth:web, CheckUserStatus | ClientController@create |
| POST | `/dashboard/team/bdm/clients` | auth:web, CheckUserStatus | ClientController@store |
| GET | `/dashboard/team/bdm/clients/{client}` | auth:web, CheckUserStatus | ClientController@show |
| GET | `/dashboard/team/bdm/clients/{client}/edit` | auth:web, CheckUserStatus | ClientController@edit |
| PUT|PATCH | `/dashboard/team/bdm/clients/{client}` | auth:web, CheckUserStatus | ClientController@update |
| DELETE | `/dashboard/team/bdm/clients/{client}` | auth:web, CheckUserStatus | ClientController@destroy |
| POST | `/dashboard/team/bdm/quotes/{quote}/send` | auth:web, CheckUserStatus | QuoteController@send |
| POST | `/dashboard/team/bdm/quotes/{quote}/approve` | auth:web, CheckUserStatus | QuoteController@approve |
| POST | `/dashboard/team/bdm/quotes/{quote}/convert-invoice` | auth:web, CheckUserStatus | QuoteController@convertToInvoice |
| GET | `/dashboard/team/bdm/quotes/{quote}/pdf` | auth:web, CheckUserStatus | QuoteController@downloadPDF |
| GET | `/dashboard/team/bdm/quotes` | auth:web, CheckUserStatus | QuoteController@index |
| GET | `/dashboard/team/bdm/quotes/create` | auth:web, CheckUserStatus | QuoteController@create |
| POST | `/dashboard/team/bdm/quotes` | auth:web, CheckUserStatus | QuoteController@store |
| GET | `/dashboard/team/bdm/quotes/{quote}` | auth:web, CheckUserStatus | QuoteController@show |
| GET | `/dashboard/team/bdm/quotes/{quote}/edit` | auth:web, CheckUserStatus | QuoteController@edit |
| PUT|PATCH | `/dashboard/team/bdm/quotes/{quote}` | auth:web, CheckUserStatus | QuoteController@update |
| DELETE | `/dashboard/team/bdm/quotes/{quote}` | auth:web, CheckUserStatus | QuoteController@destroy |
| POST | `/dashboard/team/bdm/invoices/{invoice}/send` | auth:web, CheckUserStatus | InvoiceController@send |
| POST | `/dashboard/team/bdm/invoices/{invoice}/mark-paid` | auth:web, CheckUserStatus | InvoiceController@markPaid |
| GET | `/dashboard/team/bdm/invoices/{invoice}/pdf` | auth:web, CheckUserStatus | InvoiceController@downloadPDF |
| GET | `/dashboard/team/bdm/invoices` | auth:web, CheckUserStatus | InvoiceController@index |
| GET | `/dashboard/team/bdm/invoices/create` | auth:web, CheckUserStatus | InvoiceController@create |
| POST | `/dashboard/team/bdm/invoices` | auth:web, CheckUserStatus | InvoiceController@store |
| GET | `/dashboard/team/bdm/invoices/{invoice}` | auth:web, CheckUserStatus | InvoiceController@show |
| GET | `/dashboard/team/bdm/invoices/{invoice}/edit` | auth:web, CheckUserStatus | InvoiceController@edit |
| PUT|PATCH | `/dashboard/team/bdm/invoices/{invoice}` | auth:web, CheckUserStatus | InvoiceController@update |
| DELETE | `/dashboard/team/bdm/invoices/{invoice}` | auth:web, CheckUserStatus | InvoiceController@destroy |
| POST | `/dashboard/team/bdm/service-orders/{service_order}/convert-quote` | auth:web, CheckUserStatus | ServiceOrderController@convertToQuote |
| POST | `/dashboard/team/bdm/service-orders/{service_order}/convert-invoice` | auth:web, CheckUserStatus | ServiceOrderController@convertToInvoice |
| POST | `/dashboard/team/bdm/service-orders/{service_order}/convert-contract` | auth:web, CheckUserStatus | ServiceOrderController@convertToContract |
| GET | `/dashboard/team/bdm/service-orders` | auth:web, CheckUserStatus | ServiceOrderController@index |
| GET | `/dashboard/team/bdm/service-orders/create` | auth:web, CheckUserStatus | ServiceOrderController@create |
| POST | `/dashboard/team/bdm/service-orders` | auth:web, CheckUserStatus | ServiceOrderController@store |
| GET | `/dashboard/team/bdm/service-orders/{service_order}` | auth:web, CheckUserStatus | ServiceOrderController@show |
| GET | `/dashboard/team/bdm/service-orders/{service_order}/edit` | auth:web, CheckUserStatus | ServiceOrderController@edit |
| PUT|PATCH | `/dashboard/team/bdm/service-orders/{service_order}` | auth:web, CheckUserStatus | ServiceOrderController@update |
| DELETE | `/dashboard/team/bdm/service-orders/{service_order}` | auth:web, CheckUserStatus | ServiceOrderController@destroy |
| GET | `/dashboard/team/bdm/contracts/expiring-soon` | auth:web, CheckUserStatus | ContractController@expiringSoon |
| GET | `/dashboard/team/bdm/contracts/load-template` | auth:web, CheckUserStatus | ContractController@loadTemplate |
| GET | `/dashboard/team/bdm/contracts/{contract}/pdf` | auth:web, CheckUserStatus | ContractController@downloadPDF |
| GET | `/dashboard/team/bdm/contracts/{contract}/docx` | auth:web, CheckUserStatus | ContractController@downloadDocx |
| POST | `/dashboard/team/bdm/contracts/{contract}/signature` | auth:web, CheckUserStatus | ContractController@uploadSignature |
| PATCH | `/dashboard/team/bdm/contracts/{contract}/status` | auth:web, CheckUserStatus | ContractController@updateStatus |
| GET | `/dashboard/team/bdm/contracts` | auth:web, CheckUserStatus | ContractController@index |
| GET | `/dashboard/team/bdm/contracts/create` | auth:web, CheckUserStatus | ContractController@create |
| POST | `/dashboard/team/bdm/contracts` | auth:web, CheckUserStatus | ContractController@store |
| GET | `/dashboard/team/bdm/contracts/{contract}` | auth:web, CheckUserStatus | ContractController@show |
| GET | `/dashboard/team/bdm/contracts/{contract}/edit` | auth:web, CheckUserStatus | ContractController@edit |
| PUT|PATCH | `/dashboard/team/bdm/contracts/{contract}` | auth:web, CheckUserStatus | ContractController@update |
| DELETE | `/dashboard/team/bdm/contracts/{contract}` | auth:web, CheckUserStatus | ContractController@destroy |
| GET | `/dashboard/team/bdm/projects` | auth:web, CheckUserStatus | ProjectController@index |
| GET | `/dashboard/team/bdm/projects/create` | auth:web, CheckUserStatus | ProjectController@create |
| POST | `/dashboard/team/bdm/projects` | auth:web, CheckUserStatus | ProjectController@store |
| GET | `/dashboard/team/bdm/projects/{project}` | auth:web, CheckUserStatus | ProjectController@show |
| GET | `/dashboard/team/bdm/projects/{project}/edit` | auth:web, CheckUserStatus | ProjectController@edit |
| PUT|PATCH | `/dashboard/team/bdm/projects/{project}` | auth:web, CheckUserStatus | ProjectController@update |
| DELETE | `/dashboard/team/bdm/projects/{project}` | auth:web, CheckUserStatus | ProjectController@destroy |
| GET | `/dashboard/team/bdm/services` | auth:web, CheckUserStatus | ServiceController@index |
| GET | `/dashboard/team/bdm/services/create` | auth:web, CheckUserStatus | ServiceController@create |
| POST | `/dashboard/team/bdm/services` | auth:web, CheckUserStatus | ServiceController@store |
| GET | `/dashboard/team/bdm/services/{service}` | auth:web, CheckUserStatus | ServiceController@show |
| GET | `/dashboard/team/bdm/services/{service}/edit` | auth:web, CheckUserStatus | ServiceController@edit |
| PUT|PATCH | `/dashboard/team/bdm/services/{service}` | auth:web, CheckUserStatus | ServiceController@update |
| DELETE | `/dashboard/team/bdm/services/{service}` | auth:web, CheckUserStatus | ServiceController@destroy |
| POST | `/dashboard/team/bdm/tickets/{ticket}/reply` | auth:web, CheckUserStatus | TicketController@reply |
| GET | `/dashboard/team/bdm/tickets` | auth:web, CheckUserStatus | TicketController@index |
| GET | `/dashboard/team/bdm/tickets/{ticket}` | auth:web, CheckUserStatus | TicketController@show |
| PUT|PATCH | `/dashboard/team/bdm/tickets/{ticket}` | auth:web, CheckUserStatus | TicketController@update |
| DELETE | `/dashboard/team/bdm/tickets/{ticket}` | auth:web, CheckUserStatus | TicketController@destroy |
| GET | `/dashboard/team/bdm/leads` | auth:web, CheckUserStatus | LeadController@index |
| GET | `/dashboard/team/bdm/leads/create` | auth:web, CheckUserStatus | LeadController@create |
| POST | `/dashboard/team/bdm/leads` | auth:web, CheckUserStatus | LeadController@store |
| GET | `/dashboard/team/bdm/leads/{lead}` | auth:web, CheckUserStatus | LeadController@show |
| GET | `/dashboard/team/bdm/leads/{lead}/edit` | auth:web, CheckUserStatus | LeadController@edit |
| PUT | `/dashboard/team/bdm/leads/{lead}` | auth:web, CheckUserStatus | LeadController@update |
| DELETE | `/dashboard/team/bdm/leads/{lead}` | auth:web, CheckUserStatus | LeadController@destroy |
| GET | `/dashboard/team/bdm/deals` | auth:web, CheckUserStatus | LeadController@kanban |
| POST | `/dashboard/team/bdm/leads/{lead}/status` | auth:web, CheckUserStatus | LeadController@updateStatus |
| POST | `/dashboard/team/bdm/leads/{lead}/log-activity` | auth:web, CheckUserStatus | LeadController@logActivity |
| GET | `/dashboard/team/bdm/lead-sources` | auth:web, CheckUserStatus | LeadSourceController@index |
| GET | `/dashboard/team/bdm/lead-sources/create` | auth:web, CheckUserStatus | LeadSourceController@create |
| POST | `/dashboard/team/bdm/lead-sources` | auth:web, CheckUserStatus | LeadSourceController@store |
| GET | `/dashboard/team/bdm/lead-sources/{lead_source}/edit` | auth:web, CheckUserStatus | LeadSourceController@edit |
| PUT|PATCH | `/dashboard/team/bdm/lead-sources/{lead_source}` | auth:web, CheckUserStatus | LeadSourceController@update |
| DELETE | `/dashboard/team/bdm/lead-sources/{lead_source}` | auth:web, CheckUserStatus | LeadSourceController@destroy |
| GET | `/dashboard/team/bdm/communications/contacts/export` | auth:web, CheckUserStatus | ContactController@export |
| GET | `/dashboard/team/bdm/communications/contacts/export-pdf` | auth:web, CheckUserStatus | ContactController@exportPdf |
| POST | `/dashboard/team/bdm/communications/contacts/import` | auth:web, CheckUserStatus | ContactController@import |
| GET | `/dashboard/team/bdm/communications/contacts/{contact}/send-email` | auth:web, CheckUserStatus | ContactController@sendEmail |
| GET | `/dashboard/team/bdm/communications/contacts/{contact}/send-sms` | auth:web, CheckUserStatus | ContactController@sendSms |
| POST | `/dashboard/team/bdm/communications/contacts/{contact}/process-email` | auth:web, CheckUserStatus | ContactController@processEmail |
| POST | `/dashboard/team/bdm/communications/contacts/{contact}/process-sms` | auth:web, CheckUserStatus | ContactController@processSms |
| GET | `/dashboard/team/bdm/communications/contacts/bulk-send-email` | auth:web, CheckUserStatus | ContactController@bulkSendEmail |
| GET | `/dashboard/team/bdm/communications/contacts/bulk-send-sms` | auth:web, CheckUserStatus | ContactController@bulkSendSms |
| POST | `/dashboard/team/bdm/communications/contacts/bulk-delete` | auth:web, CheckUserStatus | ContactController@bulkDelete |
| GET | `/dashboard/team/bdm/communications/campaigns` | auth:web, CheckUserStatus | CampaignController@index |
| GET | `/dashboard/team/bdm/communications/campaigns/create` | auth:web, CheckUserStatus | CampaignController@create |
| POST | `/dashboard/team/bdm/communications/campaigns` | auth:web, CheckUserStatus | CampaignController@store |
| GET | `/dashboard/team/bdm/communications/campaigns/{campaign}` | auth:web, CheckUserStatus | CampaignController@show |
| GET | `/dashboard/team/bdm/communications/campaigns/{campaign}/edit` | auth:web, CheckUserStatus | CampaignController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/campaigns/{campaign}` | auth:web, CheckUserStatus | CampaignController@update |
| DELETE | `/dashboard/team/bdm/communications/campaigns/{campaign}` | auth:web, CheckUserStatus | CampaignController@destroy |
| GET | `/dashboard/team/bdm/communications/contact-lists` | auth:web, CheckUserStatus | ContactListController@index |
| GET | `/dashboard/team/bdm/communications/contact-lists/create` | auth:web, CheckUserStatus | ContactListController@create |
| POST | `/dashboard/team/bdm/communications/contact-lists` | auth:web, CheckUserStatus | ContactListController@store |
| GET | `/dashboard/team/bdm/communications/contact-lists/{contact_list}` | auth:web, CheckUserStatus | ContactListController@show |
| GET | `/dashboard/team/bdm/communications/contact-lists/{contact_list}/edit` | auth:web, CheckUserStatus | ContactListController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/contact-lists/{contact_list}` | auth:web, CheckUserStatus | ContactListController@update |
| DELETE | `/dashboard/team/bdm/communications/contact-lists/{contact_list}` | auth:web, CheckUserStatus | ContactListController@destroy |
| GET | `/dashboard/team/bdm/communications/contacts` | auth:web, CheckUserStatus | ContactController@index |
| GET | `/dashboard/team/bdm/communications/contacts/create` | auth:web, CheckUserStatus | ContactController@create |
| POST | `/dashboard/team/bdm/communications/contacts` | auth:web, CheckUserStatus | ContactController@store |
| GET | `/dashboard/team/bdm/communications/contacts/{contact}` | auth:web, CheckUserStatus | ContactController@show |
| GET | `/dashboard/team/bdm/communications/contacts/{contact}/edit` | auth:web, CheckUserStatus | ContactController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/contacts/{contact}` | auth:web, CheckUserStatus | ContactController@update |
| DELETE | `/dashboard/team/bdm/communications/contacts/{contact}` | auth:web, CheckUserStatus | ContactController@destroy |
| GET | `/dashboard/team/bdm/communications/communication-scripts` | auth:web, CheckUserStatus | CommunicationScriptController@index |
| GET | `/dashboard/team/bdm/communications/communication-scripts/create` | auth:web, CheckUserStatus | CommunicationScriptController@create |
| POST | `/dashboard/team/bdm/communications/communication-scripts` | auth:web, CheckUserStatus | CommunicationScriptController@store |
| GET | `/dashboard/team/bdm/communications/communication-scripts/{communication_script}` | auth:web, CheckUserStatus | CommunicationScriptController@show |
| GET | `/dashboard/team/bdm/communications/communication-scripts/{communication_script}/edit` | auth:web, CheckUserStatus | CommunicationScriptController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/communication-scripts/{communication_script}` | auth:web, CheckUserStatus | CommunicationScriptController@update |
| DELETE | `/dashboard/team/bdm/communications/communication-scripts/{communication_script}` | auth:web, CheckUserStatus | CommunicationScriptController@destroy |
| GET | `/dashboard/team/bdm/communications/email-templates` | auth:web, CheckUserStatus | EmailTemplateController@index |
| GET | `/dashboard/team/bdm/communications/email-templates/create` | auth:web, CheckUserStatus | EmailTemplateController@create |
| POST | `/dashboard/team/bdm/communications/email-templates` | auth:web, CheckUserStatus | EmailTemplateController@store |
| GET | `/dashboard/team/bdm/communications/email-templates/{email_template}` | auth:web, CheckUserStatus | EmailTemplateController@show |
| GET | `/dashboard/team/bdm/communications/email-templates/{email_template}/edit` | auth:web, CheckUserStatus | EmailTemplateController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/email-templates/{email_template}` | auth:web, CheckUserStatus | EmailTemplateController@update |
| DELETE | `/dashboard/team/bdm/communications/email-templates/{email_template}` | auth:web, CheckUserStatus | EmailTemplateController@destroy |
| GET | `/dashboard/team/bdm/communications/sms-templates` | auth:web, CheckUserStatus | SmsTemplateController@index |
| GET | `/dashboard/team/bdm/communications/sms-templates/create` | auth:web, CheckUserStatus | SmsTemplateController@create |
| POST | `/dashboard/team/bdm/communications/sms-templates` | auth:web, CheckUserStatus | SmsTemplateController@store |
| GET | `/dashboard/team/bdm/communications/sms-templates/{sms_template}` | auth:web, CheckUserStatus | SmsTemplateController@show |
| GET | `/dashboard/team/bdm/communications/sms-templates/{sms_template}/edit` | auth:web, CheckUserStatus | SmsTemplateController@edit |
| PUT|PATCH | `/dashboard/team/bdm/communications/sms-templates/{sms_template}` | auth:web, CheckUserStatus | SmsTemplateController@update |
| DELETE | `/dashboard/team/bdm/communications/sms-templates/{sms_template}` | auth:web, CheckUserStatus | SmsTemplateController@destroy |
| GET | `/dashboard/team/pm/dashboard` | auth:web, CheckUserStatus, CheckProjectManager | DashboardController@index |
| GET | `/dashboard/team/pm/projects` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@index |
| GET | `/dashboard/team/pm/projects/{project}` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@show |
| PUT | `/dashboard/team/pm/projects/{project}` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@update |
| GET | `/dashboard/team/pm/projects/{project}/team` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@team |
| POST | `/dashboard/team/pm/projects/{project}/team` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@addTeamMember |
| DELETE | `/dashboard/team/pm/projects/{project}/team/{user}` | auth:web, CheckUserStatus, CheckProjectManager | ProjectController@removeTeamMember |
| GET | `/dashboard/team/pm/projects/{project}/tasks/create` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@create |
| POST | `/dashboard/team/pm/projects/{project}/tasks` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@store |
| GET | `/dashboard/team/pm/projects/{project}/tasks/{task}/edit` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@edit |
| PUT | `/dashboard/team/pm/projects/{project}/tasks/{task}` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@update |
| DELETE | `/dashboard/team/pm/projects/{project}/tasks/{task}` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@destroy |
| POST | `/dashboard/team/pm/projects/{project}/tasks/bulk-assign` | auth:web, CheckUserStatus, CheckProjectManager | TaskController@bulkAssign |
| GET | `/dashboard/team/qa/dashboard` | auth:web, CheckUserStatus | QaDashboardController@index |
| GET | `/dashboard/team/qa` | auth:web, CheckUserStatus |  |
| GET | `/dashboard/team/qa/bugs` | auth:web, CheckUserStatus | BugReportController@index |
| GET | `/dashboard/team/qa/bugs/create` | auth:web, CheckUserStatus | BugReportController@create |
| POST | `/dashboard/team/qa/bugs` | auth:web, CheckUserStatus | BugReportController@store |
| GET | `/dashboard/team/qa/bugs/{bug}` | auth:web, CheckUserStatus | BugReportController@show |
| PATCH | `/dashboard/team/qa/bugs/{bug}/status` | auth:web, CheckUserStatus | BugReportController@updateStatus |
| GET | `/dashboard/team/qa/bugs/{bug}/edit` | auth:web, CheckUserStatus | BugReportController@edit |
| PUT | `/dashboard/team/qa/bugs/{bug}` | auth:web, CheckUserStatus | BugReportController@update |
| DELETE | `/dashboard/team/qa/bugs/{bug}` | auth:web, CheckUserStatus | BugReportController@destroy |
| GET | `/dashboard/team/qa/test-cases` | auth:web, CheckUserStatus | QaTestCaseController@index |
| GET | `/dashboard/team/qa/test-cases/{task}` | auth:web, CheckUserStatus | QaTestCaseController@show |
| PATCH | `/dashboard/team/qa/test-cases/{task}/status` | auth:web, CheckUserStatus | QaTestCaseController@updateStatus |

### SuperAdmin (84)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/super-admin/login` | guest:admin | SuperAdminAuthController@showLoginForm |
| POST | `/super-admin/login` | guest:admin | SuperAdminAuthController@login |
| POST | `/super-admin/logout` | public | SuperAdminAuthController@logout |
| GET | `/super-admin` | auth:admin | SuperAdminDashboardController@index |
| GET | `/super-admin/dashboard` | auth:admin | SuperAdminDashboardController@index |
| GET | `/super-admin/tenants` | auth:admin | TenantController@index |
| GET | `/super-admin/tenants/create` | auth:admin | TenantController@create |
| POST | `/super-admin/tenants` | auth:admin | TenantController@store |
| GET | `/super-admin/tenants/{tenant}` | auth:admin | TenantController@show |
| GET | `/super-admin/tenants/{tenant}/edit` | auth:admin | TenantController@edit |
| PUT|PATCH | `/super-admin/tenants/{tenant}` | auth:admin | TenantController@update |
| DELETE | `/super-admin/tenants/{tenant}` | auth:admin | TenantController@destroy |
| POST | `/super-admin/tenants/{tenant}/status` | auth:admin | TenantController@toggleStatus |
| POST | `/super-admin/tenants/{tenant}/extend-trial` | auth:admin | TenantController@extendTrial |
| POST | `/super-admin/tenants/{tenant}/impersonate` | auth:admin | TenantController@impersonate |
| GET | `/super-admin/stop-impersonating` | auth:admin | TenantController@stopImpersonating |
| GET | `/super-admin/plans` | auth:admin | PlanController@index |
| GET | `/super-admin/plans/create` | auth:admin | PlanController@create |
| POST | `/super-admin/plans` | auth:admin | PlanController@store |
| GET | `/super-admin/plans/{plan}` | auth:admin | PlanController@show |
| GET | `/super-admin/plans/{plan}/edit` | auth:admin | PlanController@edit |
| PUT|PATCH | `/super-admin/plans/{plan}` | auth:admin | PlanController@update |
| DELETE | `/super-admin/plans/{plan}` | auth:admin | PlanController@destroy |
| GET | `/super-admin/feature-rates` | auth:admin | PlatformFeatureRateController@index |
| PUT | `/super-admin/feature-rates` | auth:admin | PlatformFeatureRateController@updateAll |
| POST | `/super-admin/feature-rates` | auth:admin | PlatformFeatureRateController@store |
| GET | `/super-admin/transactions` | auth:admin | TransactionController@index |
| GET | `/super-admin/transactions/{payment}` | auth:admin | TransactionController@show |
| GET | `/super-admin/settings` | auth:admin | SettingsController@index |
| POST | `/super-admin/settings` | auth:admin | SettingsController@update |
| GET | `/super-admin/website-content` | auth:admin | WebsiteContentController@index |
| POST | `/super-admin/website-content` | auth:admin | WebsiteContentController@update |
| GET | `/super-admin/administrators` | auth:admin | AdminManagementController@index |
| GET | `/super-admin/administrators/create` | auth:admin | AdminManagementController@create |
| POST | `/super-admin/administrators` | auth:admin | AdminManagementController@store |
| GET | `/super-admin/administrators/{administrator}` | auth:admin | AdminManagementController@show |
| GET | `/super-admin/administrators/{administrator}/edit` | auth:admin | AdminManagementController@edit |
| PUT|PATCH | `/super-admin/administrators/{administrator}` | auth:admin | AdminManagementController@update |
| DELETE | `/super-admin/administrators/{administrator}` | auth:admin | AdminManagementController@destroy |
| GET | `/super-admin/seo` | auth:admin | SeoController@index |
| PUT | `/super-admin/seo` | auth:admin | SeoController@update |
| GET | `/super-admin/rate-limits/sync` | auth:admin | RateLimitController@sync |
| GET | `/super-admin/rate-limits` | auth:admin | RateLimitController@index |
| GET | `/super-admin/rate-limits/{rate_limit}/edit` | auth:admin | RateLimitController@edit |
| PUT|PATCH | `/super-admin/rate-limits/{rate_limit}` | auth:admin | RateLimitController@update |
| DELETE | `/super-admin/rate-limits/{rate_limit}` | auth:admin | RateLimitController@destroy |
| GET | `/super-admin/system` | auth:admin | SystemController@index |
| POST | `/super-admin/system/run` | auth:admin | SystemController@runCommand |
| GET | `/admin/login` | guest:admin | PlatformAdminAuthController@showLoginForm |
| POST | `/admin/login` | guest:admin | PlatformAdminAuthController@login |
| POST | `/admin/logout` | public | PlatformAdminAuthController@logout |
| GET | `/admin` | auth:admin | closure |
| GET | `/admin/dashboard` | auth:admin | closure |
| GET | `/admin/tenants` | auth:admin | TenantController@index |
| GET | `/admin/tenants/create` | auth:admin | TenantController@create |
| POST | `/admin/tenants` | auth:admin | TenantController@store |
| GET | `/admin/tenants/{tenant}` | auth:admin | TenantController@show |
| GET | `/admin/tenants/{tenant}/edit` | auth:admin | TenantController@edit |
| PUT|PATCH | `/admin/tenants/{tenant}` | auth:admin | TenantController@update |
| DELETE | `/admin/tenants/{tenant}` | auth:admin | TenantController@destroy |
| GET | `/admin/plans` | auth:admin | PlanController@index |
| GET | `/admin/plans/create` | auth:admin | PlanController@create |
| POST | `/admin/plans` | auth:admin | PlanController@store |
| GET | `/admin/plans/{plan}` | auth:admin | PlanController@show |
| GET | `/admin/plans/{plan}/edit` | auth:admin | PlanController@edit |
| PUT|PATCH | `/admin/plans/{plan}` | auth:admin | PlanController@update |
| DELETE | `/admin/plans/{plan}` | auth:admin | PlanController@destroy |
| GET | `/admin/transactions` | auth:admin | TransactionController@index |
| GET | `/admin/transactions/create` | auth:admin | TransactionController@create |
| POST | `/admin/transactions` | auth:admin | TransactionController@store |
| GET | `/admin/transactions/{transaction}` | auth:admin | TransactionController@show |
| GET | `/admin/transactions/{transaction}/edit` | auth:admin | TransactionController@edit |
| PUT|PATCH | `/admin/transactions/{transaction}` | auth:admin | TransactionController@update |
| DELETE | `/admin/transactions/{transaction}` | auth:admin | TransactionController@destroy |
| GET | `/admin/administrators` | auth:admin | AdminManagementController@index |
| GET | `/admin/administrators/create` | auth:admin | AdminManagementController@create |
| POST | `/admin/administrators` | auth:admin | AdminManagementController@store |
| GET | `/admin/administrators/{administrator}` | auth:admin | AdminManagementController@show |
| GET | `/admin/administrators/{administrator}/edit` | auth:admin | AdminManagementController@edit |
| PUT|PATCH | `/admin/administrators/{administrator}` | auth:admin | AdminManagementController@update |
| DELETE | `/admin/administrators/{administrator}` | auth:admin | AdminManagementController@destroy |
| GET | `/admin/website-content` | auth:admin | WebsiteContentController@index |
| POST | `/admin/website-content` | auth:admin | WebsiteContentController@update |
| GET | `/admin/{path}` | public | closure |

### ClientPortal (47)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/client/login` | guest:client | AuthController@showLoginForm |
| POST | `/dashboard/client/login` | guest:client | AuthController@login |
| GET | `/dashboard/client/register` | guest:client | AuthController@showRegisterForm |
| POST | `/dashboard/client/register` | guest:client | AuthController@register |
| GET | `/dashboard/client/forgot-password` | guest:client | AuthController@showLinkRequestForm |
| POST | `/dashboard/client/forgot-password` | guest:client | AuthController@sendResetLinkEmail |
| GET | `/dashboard/client/reset-password/{token}` | guest:client | AuthController@showResetForm |
| POST | `/dashboard/client/reset-password` | guest:client | AuthController@reset |
| POST | `/dashboard/client/logout` | ClientAuth | AuthController@logout |
| GET | `/dashboard/client/dashboard` | ClientAuth | DashboardController@index |
| GET | `/dashboard/client` | ClientAuth | closure |
| GET | `/dashboard/client/projects` | ClientAuth | ProjectController@index |
| GET | `/dashboard/client/projects/{project}` | ClientAuth | ProjectController@show |
| GET | `/dashboard/client/projects/{project}/chat` | ClientAuth | ClientProjectChatController@index |
| POST | `/dashboard/client/projects/{project}/chat` | ClientAuth | ClientProjectChatController@store |
| POST | `/dashboard/client/tasks/{id}/approve` | ClientAuth | TaskController@approve |
| POST | `/dashboard/client/tasks/{id}/reject` | ClientAuth | TaskController@reject |
| GET | `/dashboard/client/invoices` | ClientAuth | InvoiceController@index |
| GET | `/dashboard/client/invoices/{invoice}` | ClientAuth | InvoiceController@show |
| GET | `/dashboard/client/invoices/{invoice}/pdf` | ClientAuth | InvoiceController@downloadPDF |
| GET | `/dashboard/client/invoices/{invoice}/pay` | ClientAuth | InvoiceController@pay |
| POST | `/dashboard/client/invoices/{invoice}/confirm-payment` | ClientAuth | InvoiceController@confirmPayment |
| GET | `/dashboard/client/invoices/{invoice}/check-status` | ClientAuth | InvoiceController@checkPaymentStatus |
| GET | `/dashboard/client/transactions` | ClientAuth | TransactionController@index |
| GET | `/dashboard/client/transactions/{transaction}` | ClientAuth | TransactionController@show |
| GET | `/dashboard/client/tickets` | ClientAuth | TicketController@index |
| GET | `/dashboard/client/tickets/create` | ClientAuth | TicketController@create |
| POST | `/dashboard/client/tickets` | ClientAuth | TicketController@store |
| GET | `/dashboard/client/tickets/{ticket}` | ClientAuth | TicketController@show |
| GET | `/dashboard/client/tickets/{ticket}/edit` | ClientAuth | TicketController@edit |
| PUT|PATCH | `/dashboard/client/tickets/{ticket}` | ClientAuth | TicketController@update |
| DELETE | `/dashboard/client/tickets/{ticket}` | ClientAuth | TicketController@destroy |
| POST | `/dashboard/client/tickets/{ticket}/reply` | ClientAuth | TicketController@reply |
| GET | `/dashboard/client/profile` | ClientAuth | ProfileController@edit |
| PUT | `/dashboard/client/profile` | ClientAuth | ProfileController@update |
| GET | `/dashboard/client/services` | ClientAuth | ServiceCatalogController@index |
| GET | `/dashboard/client/services/{service}` | ClientAuth | ServiceCatalogController@show |
| GET | `/dashboard/client/services/{service}/order` | ClientAuth | ServiceCatalogController@configure |
| GET | `/dashboard/client/contracts` | ClientAuth | ContractController@index |
| GET | `/dashboard/client/contracts/{id}` | ClientAuth | ContractController@show |
| GET | `/dashboard/client/quotes` | ClientAuth | QuoteController@index |
| GET | `/dashboard/client/quotes/{id}` | ClientAuth | QuoteController@show |
| GET | `/dashboard/client/quotes/{id}/pdf` | ClientAuth | QuoteController@downloadPDF |
| GET | `/dashboard/client/quotes/{id}/pay` | ClientAuth | QuoteController@pay |
| GET | `/dashboard/client/orders` | ClientAuth | ServiceOrderController@index |
| POST | `/dashboard/client/orders` | ClientAuth | ServiceOrderController@store |
| GET | `/dashboard/client/orders/{order}` | ClientAuth | ServiceOrderController@show |

### AiEmployees (33)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/aiemployees/dashboard` | AdminAuth | AiDashboardController@index |
| POST | `/dashboard/aiemployees/dashboard/task` | AdminAuth | AiDashboardController@processTask |
| GET | `/dashboard/aiemployees/dashboard/task/{id}/poll` | AdminAuth | AiDashboardController@pollTask |
| POST | `/dashboard/aiemployees/dashboard/actions/{id}/approve` | AdminAuth | AiDashboardController@approveAction |
| POST | `/dashboard/aiemployees/dashboard/actions/{id}/reject` | AdminAuth | AiDashboardController@rejectAction |
| GET | `/dashboard/aiemployees/pending-actions` | AdminAuth | AiDashboardController@pendingActions |
| POST | `/dashboard/aiemployees/pending-actions/bulk-approve` | AdminAuth | AiDashboardController@bulkApprove |
| POST | `/dashboard/aiemployees/pending-actions/bulk-reject` | AdminAuth | AiDashboardController@bulkReject |
| POST | `/dashboard/aiemployees/employees/{employee}/toggle-status` | AdminAuth | AiEmployeeController@toggleStatus |
| GET | `/dashboard/aiemployees/employees` | AdminAuth | AiEmployeeController@index |
| GET | `/dashboard/aiemployees/employees/create` | AdminAuth | AiEmployeeController@create |
| POST | `/dashboard/aiemployees/employees` | AdminAuth | AiEmployeeController@store |
| GET | `/dashboard/aiemployees/employees/{employee}` | AdminAuth | AiEmployeeController@show |
| GET | `/dashboard/aiemployees/employees/{employee}/edit` | AdminAuth | AiEmployeeController@edit |
| PUT|PATCH | `/dashboard/aiemployees/employees/{employee}` | AdminAuth | AiEmployeeController@update |
| DELETE | `/dashboard/aiemployees/employees/{employee}` | AdminAuth | AiEmployeeController@destroy |
| POST | `/dashboard/aiemployees/run-routines` | AdminAuth | AiDashboardController@runRoutines |
| POST | `/dashboard/aiemployees/tasks/{task}/retry` | AdminAuth | AiTaskController@retry |
| POST | `/dashboard/aiemployees/tasks/{task}/stop` | AdminAuth | AiTaskController@stop |
| GET | `/dashboard/aiemployees/tasks` | AdminAuth | AiTaskController@index |
| GET | `/dashboard/aiemployees/tasks/create` | AdminAuth | AiTaskController@create |
| POST | `/dashboard/aiemployees/tasks` | AdminAuth | AiTaskController@store |
| GET | `/dashboard/aiemployees/tasks/{task}` | AdminAuth | AiTaskController@show |
| GET | `/dashboard/aiemployees/tasks/{task}/edit` | AdminAuth | AiTaskController@edit |
| PUT|PATCH | `/dashboard/aiemployees/tasks/{task}` | AdminAuth | AiTaskController@update |
| DELETE | `/dashboard/aiemployees/tasks/{task}` | AdminAuth | AiTaskController@destroy |
| GET | `/dashboard/aiemployees/knowledge` | AdminAuth | AiKnowledgeController@index |
| GET | `/dashboard/aiemployees/knowledge/create` | AdminAuth | AiKnowledgeController@create |
| POST | `/dashboard/aiemployees/knowledge` | AdminAuth | AiKnowledgeController@store |
| GET | `/dashboard/aiemployees/knowledge/{knowledge}` | AdminAuth | AiKnowledgeController@show |
| GET | `/dashboard/aiemployees/knowledge/{knowledge}/edit` | AdminAuth | AiKnowledgeController@edit |
| PUT|PATCH | `/dashboard/aiemployees/knowledge/{knowledge}` | AdminAuth | AiKnowledgeController@update |
| DELETE | `/dashboard/aiemployees/knowledge/{knowledge}` | AdminAuth | AiKnowledgeController@destroy |

### ProjectManagement (17)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/project-management` | public | closure |
| GET | `/projectmanagements` | public | ProjectManagementController@index |
| GET | `/projectmanagements/create` | public | ProjectManagementController@create |
| POST | `/projectmanagements` | public | ProjectManagementController@store |
| GET | `/projectmanagements/{projectmanagement}` | public | ProjectManagementController@show |
| GET | `/projectmanagements/{projectmanagement}/edit` | public | ProjectManagementController@edit |
| PUT|PATCH | `/projectmanagements/{projectmanagement}` | public | ProjectManagementController@update |
| DELETE | `/projectmanagements/{projectmanagement}` | public | ProjectManagementController@destroy |
| POST | `/comments` | public | CommentController@store |
| DELETE | `/comments/{comment}` | public | CommentController@destroy |
| POST | `/attachments` | public | AttachmentController@store |
| GET | `/attachments/{attachment}/download` | public | AttachmentController@download |
| DELETE | `/attachments/{attachment}` | public | AttachmentController@destroy |
| POST | `/time-logs/start` | public | TimeLogController@start |
| POST | `/time-logs/{timeLog}/stop` | public | TimeLogController@stop |
| POST | `/time-logs` | public | TimeLogController@store |
| DELETE | `/time-logs/{time_log}` | public | TimeLogController@destroy |

### Core (routes/) (16)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/lang/{locale}` | public | LanguageController@switch |
| GET | `/register` | public | closure |
| POST | `/register` | guest:admin | RegisterController@register |
| GET | `/login` | public | closure |
| GET | `/auth/2fa-challenge` | public | TwoFactorAuthController@showChallenge |
| POST | `/auth/2fa-challenge` | public | TwoFactorAuthController@verifyChallenge |
| GET | `/test-500` | public | closure |
| GET | `/test-403` | public | closure |
| POST | `/broadcasting/auth` | public | closure |
| GET | `/notifications` | public | NotificationController@index |
| POST | `/notifications/mark-all-read` | public | NotificationController@markAllAsRead |
| POST | `/notifications/{id}/read` | public | NotificationController@markAsRead |
| POST | `/fcm-token` | public | FcmTokenController@store |
| GET | `/storage/{path}` | public | closure |
| GET | `/clear-cache` | public | closure |
| GET | `/deploy-git-pull` | public | closure |

### AI (13)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/ai/chat/start` | public | ChatController@start |
| POST | `/ai/chat/send` | public | ChatController@send |
| GET | `/dashboard/ai/settings` | AdminAuth | AISettingController@index |
| POST | `/dashboard/ai/settings` | AdminAuth | AISettingController@update |
| GET | `/dashboard/ai/chats` | AdminAuth | ChatHistoryController@index |
| GET | `/dashboard/ai/chats/{id}` | AdminAuth | ChatHistoryController@show |
| GET | `/dashboard/ai/models` | AdminAuth | AIModelController@index |
| GET | `/dashboard/ai/models/create` | AdminAuth | AIModelController@create |
| POST | `/dashboard/ai/models` | AdminAuth | AIModelController@store |
| GET | `/dashboard/ai/models/{model}` | AdminAuth | AIModelController@show |
| GET | `/dashboard/ai/models/{model}/edit` | AdminAuth | AIModelController@edit |
| PUT|PATCH | `/dashboard/ai/models/{model}` | AdminAuth | AIModelController@update |
| DELETE | `/dashboard/ai/models/{model}` | AdminAuth | AIModelController@destroy |

### Contact (13)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/contact` | public | ContactController@index |
| GET | `/start-project` | public | LeadController@create |
| POST | `/contact` | public | ContactController@store |
| POST | `/start-project` | public | LeadController@store |
| GET | `/fintech` | public | FintechLandingPageController@index |
| POST | `/fintech` | public | FintechLandingPageController@store |
| GET | `/contacts` | auth, verified | ContactController@index |
| GET | `/contacts/create` | auth, verified | ContactController@create |
| POST | `/contacts` | auth, verified | ContactController@store |
| GET | `/contacts/{contact}` | auth, verified | ContactController@show |
| GET | `/contacts/{contact}/edit` | auth, verified | ContactController@edit |
| PUT|PATCH | `/contacts/{contact}` | auth, verified | ContactController@update |
| DELETE | `/contacts/{contact}` | auth, verified | ContactController@destroy |

### Home (11)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/` | public | HomeController@index |
| GET | `/features` | public | HomeController@features |
| GET | `/pricing` | public | HomeController@pricing |
| GET | `/faq` | public | HomeController@faq |
| GET | `/homes` | auth, verified | HomeController@index |
| GET | `/homes/create` | auth, verified | HomeController@create |
| POST | `/homes` | auth, verified | HomeController@store |
| GET | `/homes/{home}` | auth, verified | HomeController@show |
| GET | `/homes/{home}/edit` | auth, verified | HomeController@edit |
| PUT|PATCH | `/homes/{home}` | auth, verified | HomeController@update |
| DELETE | `/homes/{home}` | auth, verified | HomeController@destroy |

### Legal (10)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/privacy-policy` | public | LegalController@page |
| GET | `/terms-conditions` | public | LegalController@page |
| GET | `/legal/{slug}` | public | LegalController@page |
| GET | `/legals` | auth, verified | LegalController@index |
| GET | `/legals/create` | auth, verified | LegalController@create |
| POST | `/legals` | auth, verified | LegalController@store |
| GET | `/legals/{legal}` | auth, verified | LegalController@show |
| GET | `/legals/{legal}/edit` | auth, verified | LegalController@edit |
| PUT|PATCH | `/legals/{legal}` | auth, verified | LegalController@update |
| DELETE | `/legals/{legal}` | auth, verified | LegalController@destroy |

### Accounting (9)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/webhooks/safehaven` | public | WebhookController@handleSafeHaven |
| GET | `/accounting` | public | closure |
| GET | `/accountings` | public | AccountingController@index |
| GET | `/accountings/create` | public | AccountingController@create |
| POST | `/accountings` | public | AccountingController@store |
| GET | `/accountings/{accounting}` | public | AccountingController@show |
| GET | `/accountings/{accounting}/edit` | public | AccountingController@edit |
| PUT|PATCH | `/accountings/{accounting}` | public | AccountingController@update |
| DELETE | `/accountings/{accounting}` | public | AccountingController@destroy |

### About (8)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/about` | public | AboutController@index |
| GET | `/abouts` | auth, verified | AboutController@index |
| GET | `/abouts/create` | auth, verified | AboutController@create |
| POST | `/abouts` | auth, verified | AboutController@store |
| GET | `/abouts/{about}` | auth, verified | AboutController@show |
| GET | `/abouts/{about}/edit` | auth, verified | AboutController@edit |
| PUT|PATCH | `/abouts/{about}` | auth, verified | AboutController@update |
| DELETE | `/abouts/{about}` | auth, verified | AboutController@destroy |

### Store (8)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/store/{slug}` | public | StoreController@tenantStore |
| GET | `/store/{slug}/cart` | public | CartController@index |
| POST | `/store/{slug}/cart/add` | public | CartController@add |
| POST | `/store/{slug}/cart/update` | public | CartController@update |
| POST | `/store/{slug}/cart/remove` | public | CartController@remove |
| GET | `/store/{slug}/checkout` | public | CheckoutController@show |
| POST | `/store/{slug}/checkout` | public | CheckoutController@process |
| GET | `/store/{slug}/order-confirmation/{orderNumber}` | public | CheckoutController@confirmation |

### Analytics (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/analytics` | auth, verified | AnalyticsController@index |
| GET | `/analytics/create` | auth, verified | AnalyticsController@create |
| POST | `/analytics` | auth, verified | AnalyticsController@store |
| GET | `/analytics/{analytic}` | auth, verified | AnalyticsController@show |
| GET | `/analytics/{analytic}/edit` | auth, verified | AnalyticsController@edit |
| PUT|PATCH | `/analytics/{analytic}` | auth, verified | AnalyticsController@update |
| DELETE | `/analytics/{analytic}` | auth, verified | AnalyticsController@destroy |

### Blog (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/blog` | public | BlogController@index |
| GET | `/blogs/{blog}` | public | BlogController@show |
| GET | `/blogs/create` | auth, verified | BlogController@create |
| POST | `/blogs` | auth, verified | BlogController@store |
| GET | `/blogs/{blog}/edit` | auth, verified | BlogController@edit |
| PUT | `/blogs/{blog}` | auth, verified | BlogController@update |
| DELETE | `/blogs/{blog}` | auth, verified | BlogController@destroy |

### CMS (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/cms` | auth, verified | CMSController@index |
| GET | `/cms/create` | auth, verified | CMSController@create |
| POST | `/cms` | auth, verified | CMSController@store |
| GET | `/cms/{cm}` | auth, verified | CMSController@show |
| GET | `/cms/{cm}/edit` | auth, verified | CMSController@edit |
| PUT|PATCH | `/cms/{cm}` | auth, verified | CMSController@update |
| DELETE | `/cms/{cm}` | auth, verified | CMSController@destroy |

### Careers (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/careers` | public | CareersController@index |
| GET | `/careers/create` | public | CareersController@create |
| POST | `/careers` | public | CareersController@store |
| GET | `/careers/{career}` | public | CareersController@show |
| GET | `/careers/{career}/edit` | public | CareersController@edit |
| PUT|PATCH | `/careers/{career}` | public | CareersController@update |
| DELETE | `/careers/{career}` | public | CareersController@destroy |

### Clients (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/clients` | auth, verified | ClientsController@index |
| GET | `/clients/create` | auth, verified | ClientsController@create |
| POST | `/clients` | auth, verified | ClientsController@store |
| GET | `/clients/{client}` | auth, verified | ClientsController@show |
| GET | `/clients/{client}/edit` | auth, verified | ClientsController@edit |
| PUT|PATCH | `/clients/{client}` | auth, verified | ClientsController@update |
| DELETE | `/clients/{client}` | auth, verified | ClientsController@destroy |

### Communications (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/communications` | auth, verified | CommunicationsController@index |
| GET | `/communications/create` | auth, verified | CommunicationsController@create |
| POST | `/communications` | auth, verified | CommunicationsController@store |
| GET | `/communications/{communication}` | auth, verified | CommunicationsController@show |
| GET | `/communications/{communication}/edit` | auth, verified | CommunicationsController@edit |
| PUT|PATCH | `/communications/{communication}` | auth, verified | CommunicationsController@update |
| DELETE | `/communications/{communication}` | auth, verified | CommunicationsController@destroy |

### Portfolio (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/portfolio` | public | PortfolioController@index |
| GET | `/portfolios/{portfolio}` | public | PortfolioController@show |
| GET | `/portfolios/create` | auth, verified | PortfolioController@create |
| POST | `/portfolios` | auth, verified | PortfolioController@store |
| GET | `/portfolios/{portfolio}/edit` | auth, verified | PortfolioController@edit |
| PUT | `/portfolios/{portfolio}` | auth, verified | PortfolioController@update |
| DELETE | `/portfolios/{portfolio}` | auth, verified | PortfolioController@destroy |

### Services (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/services` | public | ServicesController@index |
| GET | `/services/create` | public | ServicesController@create |
| POST | `/services` | public | ServicesController@store |
| GET | `/services/{service}` | public | ServicesController@show |
| GET | `/services/{service}/edit` | public | ServicesController@edit |
| PUT|PATCH | `/services/{service}` | public | ServicesController@update |
| DELETE | `/services/{service}` | public | ServicesController@destroy |

### Settings (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/settings` | auth, verified | SettingsController@index |
| GET | `/settings/create` | auth, verified | SettingsController@create |
| POST | `/settings` | auth, verified | SettingsController@store |
| GET | `/settings/{setting}` | auth, verified | SettingsController@show |
| GET | `/settings/{setting}/edit` | auth, verified | SettingsController@edit |
| PUT|PATCH | `/settings/{setting}` | auth, verified | SettingsController@update |
| DELETE | `/settings/{setting}` | auth, verified | SettingsController@destroy |

### Subsidiaries (7)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/subsidiaries` | auth, verified | SubsidiariesController@index |
| GET | `/subsidiaries/create` | auth, verified | SubsidiariesController@create |
| POST | `/subsidiaries` | auth, verified | SubsidiariesController@store |
| GET | `/subsidiaries/{subsidiarie}` | auth, verified | SubsidiariesController@show |
| GET | `/subsidiaries/{subsidiarie}/edit` | auth, verified | SubsidiariesController@edit |
| PUT|PATCH | `/subsidiaries/{subsidiarie}` | auth, verified | SubsidiariesController@update |
| DELETE | `/subsidiaries/{subsidiarie}` | auth, verified | SubsidiariesController@destroy |

### Investor (6)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/investor-relations` | public | InvestorController@index |
| GET | `/investor-relations/financial-reports` | public | InvestorController@financialReports |
| GET | `/investor-relations/press-releases` | public | InvestorController@pressReleases |
| GET | `/investor-relations/press-releases/{slug}` | public | InvestorController@showPressRelease |
| GET | `/investor-relations/stock-data` | public | InvestorController@stockData |
| GET | `/investor-relations/shareholder-meetings` | public | InvestorController@shareholderMeetings |

### Mcp (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/mcp` | public | McpController@handle |
| GET | `/dashboard/mcp` | AdminAuth | McpController@index |
| GET | `/dashboard/mcp/ai-generator` | AdminAuth | McpController@aiGenerator |
| POST | `/dashboard/mcp/generate` | AdminAuth | McpController@generateFromPrompt |
| POST | `/dashboard/mcp/execute` | AdminAuth | McpController@executeAction |

### SocialMedia (5)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/social-media` | AdminAuth | SocialMediaController@index |
| GET | `/dashboard/social-media/inbox` | AdminAuth | SocialMediaController@inbox |
| GET | `/dashboard/social-media/calendar` | AdminAuth | SocialMediaController@calendar |
| GET | `/dashboard/social-media/analytics` | AdminAuth | SocialMediaController@analytics |
| GET | `/admin/social-media/{path?}` | public | closure |

### KYC (4)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/dashboard/kyc` | AdminAuth | KycController@index |
| POST | `/dashboard/kyc/upload` | AdminAuth | KycController@upload |
| GET | `/super-admin/kyc` | auth:admin | SuperAdminKycController@index |
| POST | `/super-admin/kyc/{document}/verify` | auth:admin | SuperAdminKycController@verify |

