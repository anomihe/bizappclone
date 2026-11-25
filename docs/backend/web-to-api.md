# Website features the app needs → JSON API routes

**For:** the backend (Laravel) team.

> **Status (2026-11-25): built on the branch `feature/mobile-api` in `bizpaddi-platform`.** It isn't committed or merged yet. No website controller was changed.
>
> **What the branch adds:**
> - New API controllers:
>   - `app/Http/Controllers/Api/MobileRegisterController.php`
>   - `Modules/Admin/Http/Controllers/Api/{TwoFactorController, DeviceTokenController, KycController, BillingController}.php`
>   - `Modules/Admin/Http/Controllers/Api/Store/{ProductController, StorefrontController, OrderController}.php`
>   - `Modules/Admin/Http/Controllers/Api/Accounting/Concerns/SavesDocumentItems.php`
> - New routes in `routes/api.php` and `Modules/Admin/routes/api.php`.
> - Test: `tests/Feature/Api/MobileApiTest.php`.
>
> **Existing files changed:**
> - The API `InvoiceController` and `QuoteController`:
>   - `store` and `update` now validate like the web form and save the items.
>   - They no longer accept `$request->all()`, `tenant_id` or `status: paid`.
>   - They gain `send`, `mark-paid`, `pdf`, `approve` and `convert`.
> - `UnifiedAuthController@login` now stops at the 2FA step for admins who have 2FA on, and `POST /auth/2fa-challenge` was added.
> - `Admin::$hidden` now includes the 2FA secret and recovery codes.
>
> **Testing:** everything passes `php -l`. The new test couldn't be run on the machine that wrote it (no `vendor/`), so run `php artisan test --filter=MobileApiTest` before merging.
>
> **Small changes from the plan below:**
> - Product update is `POST /store/products/{id}`, because multipart can't use PUT.
> - The app may set invoice status to `draft`, `sent` or `cancelled`, and quote status to `draft`, `sent`, `rejected` or `expired`.
> - Paid only happens through mark-paid; approved only through approve.

These features already work on `app.bizpaddi.com/dashboard/*`, but only as web pages:
- They use a session cookie and a CSRF token for auth.
- They reply with HTML views or redirects that carry flash messages, not data.

The phone app can't use them: it signs in with a Sanctum bearer token, and it needs JSON back. Scraping HTML would break with every page change.

**The fix is small.** For each feature, add a thin route under `/api/v1/admin/*` (`auth:sanctum` + `user_type:admin`). It should:
- call the **same model methods** the web controller already uses (`calculateTotals()`, `markAsPaid()`, `convertToInvoice()`, `chargeOrAuthorizeAction()`, the mail classes and so on);
- return `{ success, message, data }` the way the existing API does.

No business logic needs to change. Field names below are copied from the web controllers' `validate()` rules, so web and app stay identical.

The new endpoints in [api-spec.md](api-spec.md) are for features that don't exist anywhere yet.

---

## 1. Sign-up (3 steps, email code)

Web: `Modules/Admin/Http/Controllers/Auth/RegisterController.php`. Its routes are `POST /dashboard/register/send-otp`, `/verify-otp` and `/dashboard/register`.

| API route (new) | Body (same as web) | Returns |
|---|---|---|
| `POST /api/v1/auth/register/send-otp` | `{ email, company_name? }` | `{ success, message }` (`422` bad or used email, `429` too many) |
| `POST /api/v1/auth/register/verify-otp` | `{ email, otp_code }` | `{ success, message }` |
| `POST /api/v1/auth/register` | `{ company_name, first_name, last_name, email, phone_country_code?, phone?, password, password_confirmation, otp_code, agree_terms: true, plan? }` | `201 { token, type: "admin", user, tenant }` |

Notes:
- **What can be shared:** the controller already returns JSON for `sendOtp` and `verifyOtp`. Only the session fallback and the final step need work.
  - Move `validateEmailDomain()` into a shared class.
  - Keep the OTP in the cache only. An API call has no session.
- **The final step** currently ends with `Auth::guard('admin')->login()` and a redirect. The API version should do this instead:
  - return a Sanctum token: `$admin->createToken('mobile')`;
  - send back `tenant.billing_model`;
  - when a paid plan was chosen, set `needs_plan_activation: true`.
- **Required app change:** the app's Register screen currently asks for a **phone** code. It has to change to this email-first, 3-step flow (see "App work" at the end).

## 2. Invoices

Web: `Modules/Admin/Http/Controllers/InvoiceController.php`.

| API route | Web route it wraps | Body | Returns |
|---|---|---|---|
| `POST /api/v1/admin/accounting/invoices` (**replace** the current API `store`) | `POST /dashboard/accounting/invoices` | see below | invoice with `items`, totals |
| `PUT /api/v1/admin/accounting/invoices/{id}` (**replace**) | `PUT /dashboard/accounting/invoices/{id}` | same, without `order_id` | invoice |
| `POST /api/v1/admin/accounting/invoices/{id}/send` | `POST …/invoices/{id}/send` | — | invoice (`status: "sent"`) |
| `POST /api/v1/admin/accounting/invoices/{id}/mark-paid` | `POST …/invoices/{id}/mark-paid` | — | invoice (`status: "paid"`) |
| `GET /api/v1/admin/accounting/invoices/{id}/pdf` | `GET …/invoices/{id}/pdf` | — | `application/pdf` |

Create and update body, using the web rules:
```json
{
  "client_id": 11,                         // or client_name + client_email when there's no saved customer
  "client_name": "Ada Obi", "client_email": "ada@…", "client_phone": "…", "client_address": "…",
  "issue_date": "2026-11-25", "due_date": "2026-12-02",
  "currency_id": null, "tax_rate": 0, "discount_amount": 1000,
  "notes": "…", "terms_conditions": "…",
  "items": [{ "title": "Ankara fabric", "description": "3 yards", "quantity": 3, "unit_price": 5000, "service_id": null }]
}
```

Things to carry over or watch:
- **Billing charge:** `store` charges the business through `chargeOrAuthorizeAction('invoice_generation')`. When it isn't allowed, the API should return `402 { message, code: "billing_required" }` instead of redirecting to billing. The app then shows the plan screen.
- **Required fields:** `items.*.description` is **required** on the web, and `client_email` is required when there's no `client_id`. The app sends the item name as both `title` and `description` unless the user adds a description.
- **Mark paid** has no amount: it marks the whole invoice paid. Part payments still need the `{ amount, method, paid_at }` version in [api-spec.md §2b](api-spec.md).
- **Send** emails the customer only. It doesn't create a virtual account.

## 3. Quotations

Web: `Modules/Admin/Http/Controllers/QuoteController.php`.

| API route | Web route it wraps | Returns |
|---|---|---|
| `POST`/`PUT /api/v1/admin/accounting/quotes[/{id}]` (**replace**) | `POST`/`PUT /dashboard/accounting/quotes[/{id}]` | quote with items, totals |
| `POST /api/v1/admin/accounting/quotes/{id}/send` | `POST …/quotes/{id}/send` | quote (`sent`) |
| `POST /api/v1/admin/accounting/quotes/{id}/approve` | `POST …/quotes/{id}/approve` | quote (approved) |
| `POST /api/v1/admin/accounting/quotes/{id}/convert` | `POST …/quotes/{id}/convert` | `201` the new invoice |
| `GET /api/v1/admin/accounting/quotes/{id}/pdf` | `GET …/quotes/{id}/pdf` | PDF |

- **Body:** the same as invoices, except `valid_until` (a date) replaces `due_date`. Items can carry `feature_price_id`.
- **Billing charge:** `quote_generation`.
- **App mapping:** the app's "VAT 7.5%" maps to `tax_rate: 7.5`, and "valid for 7/14/30 days" maps to `valid_until = issue_date + N`.

## 4. Store: products, settings, orders

Web: `StorefrontController.php` and `StoreOrderController.php`.

| API route | Web route it wraps | Body / query | Returns |
|---|---|---|---|
| `GET /api/v1/admin/store/products` | `GET /dashboard/storefront/products` | `?search=&status=active\|inactive&category=` | paginated products + `stats {total, active, out_stock}` + `categories[]` |
| `POST /api/v1/admin/store/products` | `POST …/products` | multipart: `name, category?, price, sale_price?, stock_quantity, description?, is_active?, image?` | `201` product |
| `POST /api/v1/admin/store/products/{id}` (`_method=PUT`, multipart) | `PUT …/products/{id}` | same | product |
| `DELETE /api/v1/admin/store/products/{id}` | `DELETE …/products/{id}` | — | `204` |
| `GET /api/v1/admin/storefront` | `GET /dashboard/storefront/settings` | — | `{ store_name, store_tagline, store_description, store_phone, store_email, store_banner, currency, slug, url, custom_domain, has_custom_domain_plan, domain_status }` |
| `POST /api/v1/admin/storefront` (multipart) | `PUT /dashboard/storefront/settings` | `store_name, store_tagline?, store_description?, store_phone?, store_email?, currency, custom_domain?, store_banner?` | storefront |
| `GET /api/v1/admin/store/orders` | `GET /dashboard/storefront/orders` | `?status=&search=` | paginated orders with `items` + `stats` |
| `GET /api/v1/admin/store/orders/{id}` | `GET …/orders/{id}` | — | order with `items.product`, `virtual_account` |
| `PATCH /api/v1/admin/store/orders/{id}/status` | `PATCH …/orders/{id}/status` | `{ status: pending\|paid\|processing\|completed\|cancelled, notes?, notify_customer? }` | order |

Differences from the app's screens:
- **Categories:** a product's `category` is free text, and there is no categories table per business. (`/dashboard/categories` is super-admin only and shared by everyone.) The app's Categories screen can list `categories[]` and rename them, by updating the products that use the name. A real categories table is optional.
- **Images:** a product has one image (`image_url`), while the app allows several photos. The app can limit this to one.
- **Price fields:** the app's "discount" maps to `sale_price = price − discount`. `quantity` maps to `stock_quantity`, and `show_on_storefront` maps to `is_active`.
- **Order statuses:** the backend has a separate `paid` status. The app shows `paid` and `processing` the same way, and cancelling uses the same status endpoint (`cancelled` + `notes` as the reason).
- **Billing charge:** product create and update charge `product_create`, so return `402` as for invoices.
- **Custom domain:** it's set through `custom_domain` (only on plans that include it). The DNS status comes from `CustomDomainVerificationService::getFullStatus()`, so return that as `domain_status`.

## 5. KYC documents

Web: `Modules/KYC/Http/Controllers/KycController.php`.

| API route | Web route it wraps | Body | Returns |
|---|---|---|---|
| `GET /api/v1/admin/kyc` | `GET /dashboard/kyc` | — | `{ tenant_status, documents: [{ document_type, document_number, status, rejection_reason, updated_at }] }` |
| `POST /api/v1/admin/kyc` | `POST /dashboard/kyc/upload` | multipart `document_type: cac_certificate\|director_id\|utility_bill\|tax_clearance`, `document_number?`, `document_file` | document (`status: pending`) |

- **Document list:** the app currently shows "Government ID / CAC Certificate / Proof of Business Address". It will change to the backend's four types: CAC certificate, director ID, utility bill and tax clearance.
- **Security:** see the findings below. Documents are stored on the **public** disk.

## 6. Plan and wallet (Billway)

Web: `BusinessBillingController.php`.

| API route | Web route it wraps | Body | Returns |
|---|---|---|---|
| `GET /api/v1/admin/billing` | `GET /dashboard/billing` | — | `{ billing_model: payg\|subscription, wallet_balance, subscription { plan, status, ends_at, seats }, active_seats, plans[], recent_payments[], wallet_transactions[], rates[] }` |
| `POST /api/v1/admin/billing/topup` | `POST /dashboard/billing/topup` | `{ amount }` (minimum 500) | `{ checkout_url, reference }` |
| `POST /api/v1/admin/billing/checkout` | `POST /dashboard/billing/checkout` | `{ plan_id, seats? }` | `{ checkout_url, reference }` |
| `POST /api/v1/admin/billing/switch-model` | `POST /dashboard/billing/switch-model` | `{ billing_model }` | billing |
| `GET /api/v1/admin/billing/status` | `GET /dashboard/billing/check-status` (already JSON) | `?reference=` | `{ status: successful\|pending }` |

**App Store rules:** the app can only *open* Billway checkout for wallet top-ups and plans if you choose the companion-app route, and that's allowed on **Android only**. On iOS, Apple doesn't allow sending users to an outside payment page for digital services (see [README §3](README.md)). The read-only `GET /billing` works on both.

## 7. Push notification token

Web: `POST /fcm-token` goes to `App\Http\Controllers\Api\FcmTokenController@store`. It sits under the **web** middleware, so it only accepts session logins.

| API route | Body | Returns |
|---|---|---|
| `POST /api/v1/admin/device-tokens` | `{ token, platform?, device_name? }` | `{ success }` |
| `DELETE /api/v1/admin/device-tokens` | `{ token }` | `204` |

- **Reuse:** the same `FcmToken::firstOrCreate([...])`, but with `auth('sanctum')->user()`.
- **New:** the `DELETE` route, so a token stops receiving pushes after logout.

## 8. Two-factor login (the "Verify your device" step)

Web: `TwoFactorAuthController.php`. This is TOTP from an authenticator app, not an SMS code.

| API route | Wraps | Body | Returns |
|---|---|---|---|
| `POST /api/v1/auth/login` (change) | `LoginController` 2FA check | unchanged | when 2FA is on: `{ requires_2fa: true, challenge_token }` and **no** access token |
| `POST /api/v1/auth/2fa-challenge` | `POST /auth/2fa-challenge` | `{ challenge_token, code }` (TOTP or recovery code) | `{ token, type, user }` |
| `GET /api/v1/admin/2fa` | `GET /dashboard/account/2fa` | — | `{ enabled, secret?, otpauth_url? }` |
| `POST /api/v1/admin/2fa/confirm` | `POST …/2fa/confirm` | `{ code }` | `{ recovery_codes[] }` |
| `POST /api/v1/admin/2fa/disable` | `POST …/2fa/disable` | `{ password }` | `{ enabled: false }` |

- **Required app change:** the app's "Verify your device" screen expects a code sent by SMS or email. It would need to say "Enter the code from your authenticator app".
- **Setup state:** the setup secret is kept in the session on the web. The API version should keep it in the cache, keyed by user.

---

## Not on the website either

These still need the new endpoints in [api-spec.md](api-spec.md):
- payment links (§3)
- credit notes and refunds (§4)
- business bank / settlement account (§7)
- per-business reports (§10)
- sessions (§13)
- support ticket replies (§14)
- a part-payment version of mark-paid (§2b)

## New security findings (in addition to [README §4](README.md))

| Where | Problem |
|---|---|
| `GET /dashboard/accounting/bank-transactions` (`SafeHavenController`) | Uses the **platform's** `safehaven_settlement_account_number` setting. Any business owner can see Bizpaddi's own bank account transactions. |
| `POST /api/v1/auth/login` (`UnifiedAuthController`) | **Skips 2FA.** The web login stops at the 2FA challenge, but the API login returns a token straight away. That makes 2FA pointless for anyone who uses the API. |
| `KycController@upload` | Stores KYC documents on the **public** disk (`kyc_documents/{tenant}/…`), where anyone with the URL can read them. It also falls back to `Tenant::first()` when there's no tenant, which writes into another business's KYC. |
| `BusinessBillingController::getTenantId()` | Falls back to tenant `1` when it can't find one. Billing actions can then land on the wrong business. |
| `StoreOrderController::getTenantId()` (web) | Same fallback to tenant `1`. |
| `TwoFactorAuthController@confirm` (web) | Saves the 2FA columns with `$user->update([...])`, but they aren't in `Admin::$fillable`, so Laravel silently drops them. **Turning on 2FA on the website doesn't actually turn it on.** The new API version uses `forceFill`; the web controller still needs the same fix. |
| `BillingController@status` (web `check-status`) | Looks up any business's payment by reference, with no tenant check. The API version only sees the signed-in business's payments. |

---

## App work (done; tested in `test/mobile_api_test.dart`)

| Area | App change |
|---|---|
| Sign-up | Register is now email → 6-digit code → details (company, first and last name, phone, password), matching app.bizpaddi.com/dashboard/register. |
| Invoices and quotes | The app sends `title`/`description`/`issue_date`/`valid_until`/`tax_rate`. Invoice details: Email to customer, Mark as paid, Download PDF (share sheet). Quote details: Email, Download PDF, Mark as Accepted (→ approve), Convert to Invoice (on the server). A `402` offers Wallet & Billing. |
| Store | Products with one photo and a free-text category, the storefront form (banner, tagline), custom domain with a DNS/SSL check, and orders (mark delivered, cancel with reason). |
| KYC | The four backend document types, uploaded by camera, photo or PDF, with a review status for each document. Home shows "Verify your business" until KYC is approved. |
| Billing | More → Wallet & Billing: balance, plan, plans, rates and activity. Top-up and plan activation (bank transfer details, then "I've sent the money") are Android only; iOS is read-only. |
| Push | `LiveSession.registerPushToken()` sends the token after login and deletes it on logout. **Still to do:** add Firebase (`firebase_messaging` plus `google-services.json` / `GoogleService-Info.plist`) and call it with the FCM token. |
| 2FA | Authenticator-code step after login (or a recovery code), plus Security → Two-step verification (QR code, setup key, recovery codes, turn off). |
