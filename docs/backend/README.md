# Bizpaddi backend (bizpaddi-platform) — endpoint map for the mobile app

Extracted on 2026-11-24 by reading the Laravel route files in `bizpaddi-platform`
(Laravel 12, Sanctum, modular). **Read-only: nothing in that repo was changed or run.**
`php artisan route:list` was not used (no `vendor/`), so routes were parsed statically;
paths, prefixes, `apiResource` expansions and middleware were spot-checked by hand.

- Full list (1,499 endpoints): [`endpoints.md`](endpoints.md) · spreadsheet-friendly: [`endpoints.tsv`](endpoints.tsv)
- Website features to expose as JSON (same logic, new routes): [`web-to-api.md`](web-to-api.md)
- Draft spec for endpoints that don't exist anywhere yet: [`api-spec.md`](api-spec.md)
- Part A = JSON API under `/api/...` (Sanctum bearer token) — what a mobile app can call.
- Part B = web routes (browser pages, session cookie + CSRF) — **not** callable from the app.

## 1. Mobile-ready API today

| Area | Base path | Auth | What's there |
|---|---|---|---|
| Shared auth | `/api/v1/auth/login`, `forgot-password`, `reset-password` | public | One login for client / team / admin (`guard` param) |
| Business owner ("admin") | `/api/v1/admin/*` (119) | `auth:sanctum` + `user_type:admin` | Profile, dashboard, clients, team members, roles/permissions, leads, contacts, tickets, campaigns, notifications, settings, **accounting** (invoices, quotes, service orders, transactions, currencies, balance sheet, salaries), contracts, project management |
| Staff | `/api/v1/team/*` (74) | `user_type:team` | Tasks, kanban, work logs, attendance, reports, projects/chat, bank accounts, wallet, earnings, PM tools |
| End customer | `/api/v1/client/*` (36) | `user_type:client` (register/login public) | Profile, projects/chat, invoices, quotes, tickets, chats, device token |
| Webhooks | `POST /webhooks/safehaven`, `POST /api/v1/webhooks/billway` | public (signature checked in controller) | Payment confirmation |

Most other modules only expose the scaffold `apiResource` stub (e.g. `/api/v1/blogs`) — not real features.

## 2. What the mobile app needs vs. what exists

The app is built for the **business owner** (tenant admin). Mapping its screens:

| Mobile feature | Backend today | Gap |
|---|---|---|
| Log in, forgot/reset password | ✅ `/api/v1/auth/*` | Device OTP ("Verify your device") not in API |
| **Sign up** (business) + phone OTP | ⚠️ web only: `/dashboard/register`, `/register/send-otp`, `/register/verify-otp` | Needs API versions |
| Dashboard / KPIs | ✅ `GET /api/v1/admin/dashboard` | Check it returns collected / outstanding / overdue / settled |
| Invoices, quotes | ✅ `/api/v1/admin/accounting/invoices`, `/quotes` | Send, PDF, mark-paid, convert-quote are **web only** |
| Customers | ✅ `/api/v1/admin/clients` | — |
| Team (invite, roles, permissions) | ✅ `/api/v1/admin/team-members`, `/roles`, `/permissions` | Deactivate/invite flow to confirm |
| Payments list / details / receipt | ⚠️ `/api/v1/admin/accounting/transactions` | Settlement status, provider charges, receipt data to confirm |
| **Payment links** | ❌ none | New |
| **Credit notes / refunds** | ❌ none | New |
| **Products, categories, storefront settings, custom domain** | ⚠️ web only: `/dashboard/storefront/*`, `/dashboard/categories` | Needs API |
| **Store orders** (list, details, cancel/status) | ⚠️ web only: `/dashboard/storefront/orders` | Needs API |
| **Business profile + KYC documents** | ⚠️ web only: `/dashboard/kyc` | Needs API |
| **Bank & settlement account** (business) | ❌ (only staff `/api/v1/team/bank-accounts`) | New for tenant |
| Reports | ❌ | New (or extend dashboard) |
| **Plan, trial, wallet, top-up** | ⚠️ web only: `/dashboard/billing/*` | See §3 — store rules decide the design |
| Push notifications | ✅ notifications list; device token exists for **client** only | Add for admin |

## 3. Payments: can the app use in-app purchase?

Today **all** money moves through Billway / SafeHaven **virtual bank accounts**
(bank transfer → webhook or status poll marks it paid). There are two very different kinds of payment:

**a) Your users' customers paying them** (invoices, payment links, store orders).
These are real-world goods and services, paid by people outside the app.
In-app purchase is **not allowed** for this (Apple 3.1.3(e); Google exempts physical goods/services)
— and it would take 15–30% of your users' revenue. **Keep Billway.** ✅ No change needed.

**b) Your users paying Bizpaddi** (subscription plans, PAYG wallet top-ups).
These unlock features *inside* the app, so the stores treat them as digital goods:

- **Apple 3.1.1** — if you sell a subscription or wallet credits *in the iOS app*, it must be Apple IAP.
  You cannot show the Billway virtual-account checkout for these on iOS.
- **Google Play** — same principle: Play Billing for in-app digital subscriptions/credits.

Options:

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **A. Companion app** (Apple 3.1.3(f) "free stand-alone companion to a paid web tool") | No buying in the app. Plans/wallet are bought on bizpaddi.com (Billway, as today). The app just reflects the account's status. | No store fees, no backend payment work, Billway stays | App must not show purchase buttons **or** tell users to go buy on the web (iOS). "Start My Free Trial" (free) is fine; "View Plan / Renew Now / top up" must change on iOS |
| **B. In-app purchase** | Plans (auto-renewing subscriptions) and wallet top-ups (consumables) sold through Apple/Google. Backend verifies receipts and listens to store notifications. | Smoothest upgrade flow, works with the current designs | Apple/Google fee (15% small-business/subscription rate, otherwise 30%); store products per plan & price; new backend endpoints + webhooks; PAYG micro-fees through IAP credits are awkward |
| **C. Hybrid** | A now, B later | Ship fast | Two passes |

**Recommendation:** start with **A** (companion app) — it keeps Billway and needs no backend payment work —
and revisit **B** if in-app upgrades matter for conversion. Either way, payments for your users' customers stay on Billway.

> Store rules change; confirm against the current App Store Review Guidelines (3.1) and
> Google Play Payments policy before submission.

## 4. Security issues found (not changed — please review)

| Where | Problem |
|---|---|
| `GET /deploy-git-pull` | **No auth.** Anyone can make production run `git reset --hard origin/main` and `migrate --force`. Remove or protect immediately. |
| `GET /storage/{path}` | **No auth.** Serves files from `storage/app/private/*` (resumes, possibly KYC documents) to anyone who knows/guesses the path. |
| `GET /clear-cache`, `/test-500`, `/test-403` | Public debug/ops endpoints. |
| **`/api/v1/admin/clients*`, `/api/v1/admin/team-members*`** | **Cross-business data leak.** `Client` and `User` have no `BelongsToTenant` scope and the controllers don't filter, so any business owner can list, view, edit and delete **every business's** customers and staff. Dashboard `total_clients` / `recent_clients` are also unscoped. |
| `InvoiceController`, `QuoteController`, `TransactionController` (`store`/`update`) | **Mass assignment of `$request->all()`** with `tenant_id` fillable: a business can create/move records into another business by sending `tenant_id`, and can record fake transactions (payments). Use validated fields and never accept `tenant_id`/`status: paid` from the client. |

## 5. Backend gaps that limit the app

| Endpoint | Gap |
|---|---|
| `POST /api/v1/admin/accounting/invoices` | Ignores `items` (line items aren't saved), doesn't compute totals, doesn't create a virtual account — an invoice made from the app has no items and can't be paid by transfer. The app sends `items` + totals anyway so it works once the API stores them. |
| `POST/PUT quotes` | Same as invoices (no items). |
| Clients / team members | `password` is required. The app generates one: customers can reset theirs; for staff the owner is shown the temporary password once. Customer **email is required**. |
| Auth | No device OTP, no admin sign-up API, password reset is an emailed link (not a code). |
| Profile | No business (tenant) name, plan/trial status or KYC status in the API. |
| Push | No device-token endpoint for business owners (only clients). |

## 6. Mobile integration status

The app talks to **https://app.bizpaddi.com** by default ([api_config.dart](../../lib/core/api/api_config.dart)). Override at build time:

```
flutter run --dart-define=API_BASE_URL=https://staging.example.com   # another server
flutter run --dart-define=DEMO_MODE=true                             # sample data, no network
```

Tests always run on demo data (`test/flutter_test_config.dart`) unless a test turns live mode on with a fake backend.

Live mode (code in `lib/core/api/`):

| Feature | Status |
|---|---|
| Log in (email + password, business accounts only), Welcome back, fingerprint resume, log out, expired-token handling | ✅ live |
| Forgot password → reset link email | ✅ live |
| Sign up | Shows "create your business at app.bizpaddi.com" (no API) |
| Customers (list, create, edit, delete) | ✅ live — **blocked by the cross-business leak above** |
| Invoices (list, details + items, create, edit, void, delete draft) | ✅ live — items not stored by the API yet |
| Quotations (list, create, edit, accept, delete) | ✅ live — items not stored by the API yet |
| Payments (from transactions; only incoming money) | ✅ live, read-only |
| Team (list, invite with temp password, change role, deactivate, remove) | ✅ live — **blocked by the cross-business leak above** |
| Notifications (list, tap to mark one read, mark all read) | ✅ live |
| My Profile (name, phone, photo upload), change password, delete account | ✅ live (More → Account) |
| Reset password with the code/link from the email | ✅ live ("I have a reset code") |
| Reports → Account overview (`/dashboard` stats) | ✅ live |
| Leads, Contacts, Campaigns | ✅ live — list, create, edit, delete (More → Customers & Marketing) |
| Support tickets | ✅ live — list, view conversation, change status/priority, delete (no reply endpoint in the API) |
| Projects (+ status), Tasks (+ status), Milestones (+ status) | ✅ live — tasks/milestones are created inside a project (`project_id`) |
| Project chat (team / customer): messages, photo attachments, edit within 5 min, delete, mark read, pause/close | ✅ live |
| Work logs | ✅ live — list, view, edit (staff create them from the team app) |
| Contracts, Contract templates | ✅ live — list, create, edit, delete |
| Departments, Services catalogue (`service-orders` route), Payroll records (`salaries`) | ✅ live — payroll only records the payment, it doesn't send money |
| Balance sheet | ✅ live, read-only |
| Currencies | ✅ live, read-only (shared by all businesses) |
| **Not wired on purpose** | `settings` (exposes Billway/FCM secrets — see §4), roles & permissions editing (global, not per business) |
| Home KPIs | Computed in the app from invoices + transactions (the dashboard API returns agency stats) |
| Storefront & products, orders, KYC, plan/wallet, invoice/quote actions, sign-up, 2FA | ✅ live once `feature/mobile-api` is deployed (see [web-to-api.md](web-to-api.md)) |
| Payment links, credit notes/refunds, business bank/settlement, business-profile editing, per-person staff permissions, support chat for owners | Hidden in live mode (no backend yet); demo only |

### One app, three portals

The login API reports who is signing in (`type`), and the app opens the matching home. The role is saved with the token, so "Welcome back" reopens the same home.

| Who | Home | Uses | Screens |
|---|---|---|---|
| Business owner (`admin`) | Home · Payments · Invoices · Customers · More | `/api/v1/admin/*` | Everything above |
| Staff (`team`) | Home · Tasks · Work · Pay · More | `/api/v1/team/*` (all 74 routes) | Dashboard with clock in/out; my tasks by status (moving a task to Done is project-manager only); work sessions (check-in plan / check-out report); attendance; daily reports; wallet, earnings and the salary bank account (verified by the backend); performance; my projects with team and customer chat; messages to the business; profile, photo, password, delete account |
| Staff project manager (`role: pm`) | The staff tabs, plus a "Project manager" section in More | `/api/v1/team/pm/*`, `clients`, `invoices`, `quotes`, `services` | Projects I manage with stats; create, assign, edit and delete tasks; milestones; the team's work sessions; customers, invoices, quotations and services (read-only) |
| Customer (`client`) | Home · Invoices · Projects · Support · More | `/api/v1/client/*` (all 36 routes; self sign-up not used) | What they owe; invoices and quotations with items; **Pay Now** opens the customer-portal pay page; projects with the team chat; support tickets; messages to the business; services; contact support (email, phone, WhatsApp from the support settings); terms and privacy; profile, photo, password, delete account |

Not used:
- **Customer self sign-up** (`POST /client/register`). It creates a customer that doesn't belong to any business, so customers are invited by the business instead.
- **Staff push tokens.** There's no staff device-token route.

Forgot / reset password tries each account type (owner, then staff, then customer), because the app doesn't know which one it is before login.

**Demo mode:** log in with an email that starts with `staff` or `customer` to preview those apps on sample data.

#### Backend gaps found while connecting the portals (not changed)

| Where | Problem |
|---|---|
| `POST /client/tickets` | `SupportTicket::$fillable` has no `message` or `ticket_id`, so the customer's description and the ticket number are **dropped**. Only the subject, priority and status are saved. |
| Tickets (all portals) | There's no reply thread: customers can't see an answer in the app. |
| `GET /team/wallet` | The balance is a placeholder: it adds up every transaction, both money in and money out. |
| `POST /client/register` | Public, and it creates a customer with no business (`tenant_id`). Anyone can create logins. |
| `WorkLogController@checkOut` (project managers) | It counts closed tasks with `status = 'completed'`, but tasks use `done`, so that count is always 0. |
| Customer pay | The API has no pay endpoint (virtual account or status), so the app opens the web pay page, where the customer must sign in again. |

Login tokens are stored in the iOS Keychain / Android Keystore (`flutter_secure_storage`).
Tests use a fake backend shaped like the Laravel controllers: `test/api_test.dart`, `test/live_flow_test.dart`, `test/workspace_test.dart`, `test/mobile_api_test.dart`, `test/portal_test.dart`.

> ⚠️ Don't ship live mode to real businesses until the two security issues marked above are fixed on the backend.

### More backend issues found while wiring the rest (not changed)

| Where | Problem |
|---|---|
| `GET/PUT /api/v1/admin/settings` | Settings aren't scoped to the business and include `billway_secret_key`, `billway_webhook_secret`, `fcm_server_key` — any business owner can read **and overwrite** the platform payment keys. The app doesn't call it. |
| Roles, permissions, currencies | Global tables (Spatie / shared): one business editing them changes every business. The app only reads currencies. |
| Milestones | Model has no business scope, so milestones of another business can be listed and opened by id. |
| `accounting/service-orders` | Route name says orders but it manages the **services catalogue** model. |
| Tickets | No admin reply endpoint; `update` silently ignores `subject`. |
| Dashboard | `total_clients` / `recent_clients` count every business's customers (not shown in the app). |
