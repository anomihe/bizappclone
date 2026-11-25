# Bizpaddi mobile — new API endpoints (draft spec)

**Status:** draft for review. Nothing in `bizpaddi-platform` has been changed.
**For:** the backend (Laravel) team.
**Why:** these are the mobile screens that are built but have no API to call. Each section names the screens that use it.
The current endpoint map and the security findings are in [README.md](README.md).

---

## 0. Conventions (same as the existing `/api/v1/admin/*` API)

- **Base path:** `/api/v1/admin` unless a section says otherwise.
- **Auth:** `auth:sanctum` + `user_type:admin` (a bearer token).
- **Response envelope:** `{ "success": true, "message": "…", "data": … }`.
- **Errors:** `422` returns `{ "success": false, "message": "…", "errors": { "field": ["…"] } }`. The app shows each message under its field.
- **Lists:** use the standard Laravel paginator (`data`, `current_page`, `last_page`, `per_page`, `total`). They accept `?page=`, `?per_page=` (max 100) and `?search=`.
- **Tenant scoping:** every model below belongs to the signed-in business.
  - Use a `BelongsToTenant` global scope and set `tenant_id` from `auth()->user()->tenant_id`.
  - **Never accept `tenant_id` from the request body.**
  - Use `$request->validated()`, never `$request->all()`.
  - Records from another business return `404`, not `403`.
- **Money:** a decimal with 2 places (e.g. `15000.00`). The currency is the business currency (NGN by default).
- **Dates:** ISO-8601 (e.g. `2026-11-24T10:30:00+01:00`). Date-only fields use `YYYY-MM-DD`.
- **Files:** `multipart/form-data`.
  - Images: jpg/png/webp, 5 MB max.
  - Documents: pdf/jpg/png, 5 MB max.
  - Store private files (KYC) on a private disk and return short-lived signed URLs. **Do not** serve them through the public `/storage/{path}` route.
- **Status fields:** lowercase snake_case strings, using the values listed in each section.

### Do these first (blockers from the security review)

The app won't go live until these are fixed. Details are in [README.md §4](README.md).

1. Remove or protect `GET /deploy-git-pull`, `/clear-cache`, `/test-500` and `/test-403`.
2. Protect `GET /storage/{path}`: private files need auth plus an ownership check.
3. Scope `clients` and `team-members` (and the dashboard counts) to the tenant.
4. Invoices, quotes and transactions: stop using `$request->all()`, and stop accepting `tenant_id` or `status: paid` from the client.
5. `admin/settings`: stop returning or accepting the platform secrets (Billway and FCM keys). See §15.
6. Milestones: add the tenant scope.

---

## 1. Sign-up and device check

**Screens:** Register → Verify phone (OTP) → Choose plan → Registration success. Login → "Verify your device".
**Base path:** `/api/v1/auth`. These routes are public and need rate limits.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/auth/register/options` | — | `{ categories: [{id, name}], currencies: [{code, name, symbol}] }` |
| POST | `/auth/register/send-otp` | `{ phone }` (E.164) | `{ expires_in: 300, resend_in: 60 }` |
| POST | `/auth/register` | `{ business_name, email, phone, category_id, currency, password, otp }` | `201 { token, type: "admin", user, tenant }` |
| POST | `/auth/verify-device` | `{ verification_id, code, device_name }` | `{ token, type, user }` |
| POST | `/auth/verify-device/resend` | `{ verification_id }` | `{ expires_in, resend_in }` |

Rules:
- **Registration:**
  - `register` creates the tenant, the admin user and a **7-day trial** in one transaction.
  - The OTP is 6 digits, expires after 5 minutes, and is tied to the phone.
  - `send-otp` is limited to 3 sends per phone per 10 minutes.
  - Email must be unique across admin users. Password needs at least 8 characters, including a letter and a number.
- **Device check (optional — only if you want it):**
  - When the device isn't recognised, `POST /auth/login` returns `200 { requires_device_verification: true, verification_id, masked_phone }` and no token.
  - Mark a device as known with a hash of `device_name` plus the platform.
  - Lock after 5 wrong codes.

---

## 2. Invoices and quotations (fixes and actions)

**Screens:** Create invoice/quote, Invoice details, Quotation details, Document preview.

### 2a. Fix the existing create and update endpoints

`POST`/`PUT /accounting/invoices` and `/accounting/quotes` must accept and **store** line items. The server calculates the totals:

```json
{
  "client_id": 11,
  "items": [{ "name": "Ankara fabric", "unit_price": 5000, "quantity": 3 }],
  "discount": 1000,
  "due_date": "2026-12-01",          // invoices
  "allow_part_payment": true,        // invoices
  "add_vat": true,                   // quotes: adds 7.5% on (subtotal - discount)
  "validity_days": 14,               // quotes: 7 | 14 | 30
  "notes": "Thanks for your business"
}
```

- **Response:** the document with `items[]`, `subtotal`, `discount`, `tax_amount`, `total_amount`, `amount_paid`, `balance`, `status`, `invoice_number`/`quote_number`, `pay_url`, and `virtual_account` (invoices only, `null` until sent).
- Only `draft` documents can be edited.
- **Status values:**
  - Invoices: `draft`, `unpaid`, `partly_paid`, `paid`, `overdue`, `cancelled`, `voided`.
  - Quotes: `draft`, `sent`, `accepted`, `expired`.

### 2b. New actions

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/accounting/invoices/{id}/send` | `{ channels?: ["email","sms","whatsapp"] }` | invoice (`draft` → `unpaid`, with `virtual_account {bank, account_number, account_name}` and `pay_url`) |
| POST | `/accounting/invoices/{id}/remind` | — | `{ sent_at }` |
| POST | `/accounting/invoices/{id}/mark-paid` | `{ amount, method: "cash"\|"transfer"\|"pos"\|"other", paid_at, note? }` | invoice (adds a transaction with `source: "manual"`) |
| POST | `/accounting/invoices/{id}/void` | `{ reason }` | invoice (`voided`) |
| GET | `/accounting/invoices/{id}/pdf` | — | `application/pdf` (or `{ url }`, a signed link valid for 10 minutes) |
| POST | `/accounting/quotes/{id}/send` | `{ channels? }` | quote (`sent`, `valid_till` = now + `validity_days`) |
| POST | `/accounting/quotes/{id}/accept` | — | quote (`accepted`) |
| POST | `/accounting/quotes/{id}/convert` | `{ due_date? }` | `201` new draft invoice with the quote's items |
| GET | `/accounting/quotes/{id}/pdf` | — | PDF or `{ url }` |

Rules:
- **Remind:** limit to once per invoice every 24 hours (`429` otherwise).
- **Mark paid:**
  - `amount` must not exceed `balance`. A part payment is only allowed when `allow_part_payment` is true.
  - This is the **only** way a business records a payment itself. Remove the raw `POST /accounting/transactions` endpoint or make it super-admin only.
- **Void:** only allowed when nothing has been paid. Otherwise the business must use a credit note or refund (§4).
- **Overdue:** may be computed when the invoice is read (an unpaid invoice past `due_date` reads as `overdue`).

---

## 3. Payment links

**Screens:** New payment link, Payment link details, the Payment links list in the Invoices tab.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/payment-links` | `?status=active\|pending\|paid\|expired\|disabled` | paginated links |
| POST | `/payment-links` | `{ purpose, amount, client_id?, customer_name?, customer_phone?, expires_at?, allow_part_payment? }` | `201` link |
| GET | `/payment-links/{id}` | — | link with `payments[]` |
| PATCH | `/payment-links/{id}` | `{ expires_at?, purpose? }` | link |
| POST | `/payment-links/{id}/disable` | — | link (`disabled`) |
| POST | `/payment-links/{id}/enable` | — | link |

- **Link fields:** `id`, `number` (its own sequence, e.g. `"0001"`), `purpose`, `amount`, `amount_paid`, `client` (`{id, name}` or `null`), `customer_name`, `customer_phone`, `url` (e.g. `https://bizpaddi.com/pay/{slug}`), `status`, `expires_at`, `created_at`, `payments[]`.
- **Status rules:** `paid` once `amount_paid >= amount`; `expired` once `expires_at` has passed; `pending` while a transfer is awaiting confirmation.
- **Public pay page:** the customer-facing page is web-only, e.g. `GET /api/v1/pay/{slug}`. Its payments arrive through the existing Billway webhook.

---

## 4. Credit notes and refunds

**Screens:** Credit note screens and Refund screens, opened from Invoice details.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/accounting/credit-notes` | `?invoice_id=` | paginated |
| POST | `/accounting/invoices/{id}/credit-notes` | `{ amount, reason }` | `201 { id, number: "CN-0001", invoice_id, amount, reason, created_at }` |
| GET | `/accounting/credit-notes/{id}` | — | credit note |
| GET | `/accounting/credit-notes/{id}/pdf` | — | PDF or `{ url }` |
| GET | `/accounting/refunds` | `?invoice_id=&stage=` | paginated |
| POST | `/accounting/invoices/{id}/refunds` | `{ amount, reason, transaction_id? }` | `201` refund (`stage: requested`) |
| GET | `/accounting/refunds/{id}` | — | refund with `timeline[] {stage, at}` |
| POST | `/accounting/refunds/{id}/cancel` | — | refund (only while `requested`) |

- **Amount limit:** a credit note or refund can't exceed the refundable balance: `amount_paid − credited − refunds requested so far`.
- **Refund stages** (shown as a timeline in the app):
  1. `requested` (by the business)
  2. `approved` (by a Bizpaddi admin, in the web back office)
  3. `confirmed` (Billway accepted it)
  4. `refunded` (Billway webhook: the customer has the money)
- **Who moves the stages:** the business can't move a refund past `requested`.
- **Push notifications:** send one at each stage (see §11).

---

## 5. Payments, receipts and settlement details

**Screens:** Payments tab, Payment details, Receipt, and the Home KPIs ("Settled to your account", "Pending payments").

Add these fields to the existing `GET /accounting/transactions` and `/{id}`:

```json
{
  "status": "paid | pending | partly_paid | failed | refunded",
  "direction": "incoming | outgoing",
  "method": "bank_transfer | card | ussd | cash | pos | other",
  "provider": "Billway - Wema Bank",
  "provider_charge": 325.00,
  "service_charge": 225.00,
  "net_amount": 14450.00,
  "settled": true,
  "settled_at": "2026-11-24T12:00:00+01:00",
  "receipt_number": "RCT-000123",
  "invoice_id": 42, "payment_link_id": null, "order_id": null,
  "customer": { "id": 11, "name": "Ada Obi" }
}
```

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/accounting/transactions/{id}/receipt` | — | PDF or `{ url }` |
| POST | `/accounting/transactions/{id}/receipt/send` | `{ channels? }` | `{ sent_at }` |

List filters on transactions: `?status=`, `?settled=0|1`, `?from=`, `?to=`, `?direction=incoming`.

---

## 6. Business profile and KYC

**Screens:** Business profile, Edit business profile, verification documents, the Home "Verify your business" banner.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/business` | — | `{ name, type, registration_number, phone, email, address, currency, logo_url, verification_status }` |
| PUT | `/business` | `{ name, type, registration_number, phone, email, address, currency }` | business |
| POST | `/business/logo` | multipart `logo` | `{ logo_url }` |
| GET | `/business/verification` | — | `{ status: "incomplete"\|"in_review"\|"verified"\|"rejected", documents: [{ key, label, status: "missing"\|"uploaded"\|"approved"\|"rejected", file_name, uploaded_at, rejection_reason }] }` |
| POST | `/business/documents/{key}` | multipart `file` | document |
| DELETE | `/business/documents/{key}` | — | `204` (only while not `in_review`) |
| POST | `/business/verification/submit` | — | verification (`in_review`) |

- **Document keys:** `government_id`, `cac_certificate`, `proof_of_address`.
- **Submit:** returns `422` if any document is missing or the profile is incomplete.
- **Storage:** private disk; the back office reviews the documents.
- **Profile:** add `tenant { name, verification_status, plan_status }` to `GET /profile`, so the app can stop showing the owner's name as the business name.

---

## 7. Bank and settlement account

**Screens:** Bank and settlement (add or change, with a password or fingerprint check, a phone OTP and the change history).

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/banks` | — | `[{ code, name }]` (cached) |
| POST | `/settlement-account/resolve` | `{ bank_code, account_number }` | `{ account_name }` |
| GET | `/settlement-account` | — | `{ account: { bank_code, bank_name, account_number_masked, account_name } \| null, history: [{ title, detail, created_at }] }` |
| POST | `/settlement-account/send-otp` | — | `{ expires_in, masked_phone }` |
| PUT | `/settlement-account` | `{ bank_code, account_number, password, otp }` | settlement account |

Rules (this endpoint decides where the business's money goes, so it's the most sensitive one here):
- **Re-authentication:** `PUT` requires **both** the current password and the phone OTP. Return `422` on the field that's wrong.
- **Bank account check:** match `account_name` against the KYC business name, or flag the change for review.
- **Alerts and payout hold:** email and push the owner on every change. Hold payouts for 24 hours after a change.
- **Masking:** never return the full account number after it's saved.
- **Rate limit:** 5 `resolve` calls per minute.

---

## 8. Storefront, categories and products

**Screens:** Store, Edit storefront, Custom domain, Categories, Product form.

### Storefront

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/storefront` | — | `{ name, description, phone, email, slug, url, logo_url, banner_url, custom_domain }` |
| PUT | `/storefront` | `{ name, description, phone, email, slug }` | storefront |
| GET | `/storefront/slug-available` | `?slug=` | `{ available, suggestion? }` |
| POST | `/storefront/logo` | multipart `logo` | `{ logo_url }` |
| POST | `/storefront/banner` | multipart `banner` | `{ banner_url }` |
| GET | `/storefront/domain` | — | `{ domain, status: "pending_dns"\|"verifying"\|"active"\|"failed", dns_records: [{ type, host, value }] }` or `null` |
| PUT | `/storefront/domain` | `{ domain }` | domain |
| POST | `/storefront/domain/verify` | — | domain |
| DELETE | `/storefront/domain` | — | `204` |

- **Slugs:** lowercase letters, numbers and `-`, 3–40 characters, unique, and not on a reserved-word list.

### Categories and products

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/store/categories` | — | `[{ id, name, products_count }]` |
| POST | `/store/categories` | `{ name }` | `201` category |
| PUT | `/store/categories/{id}` | `{ name }` | category |
| DELETE | `/store/categories/{id}` | — | `204` (products become uncategorised) |
| GET | `/store/products` | `?search=&category_id=&stock=in\|low\|out` | paginated products |
| POST | `/store/products` | `{ name, unit_label?, sku?, price, discount?, category_id?, quantity, description?, show_on_storefront }` | `201` product |
| GET | `/store/products/{id}` | — | product |
| PUT | `/store/products/{id}` | same as POST | product |
| DELETE | `/store/products/{id}` | — | `204` |
| POST | `/store/products/{id}/images` | multipart `image` (up to 5 per product) | `{ id, url }` |
| DELETE | `/store/products/{id}/images/{imageId}` | — | `204` |

- **Product fields:** the fields above, plus `id`, `sale_price` (= price − discount), `stock_status` (`in_stock`; `low_stock` at 5 or fewer; `out_of_stock` at 0) and `images[] {id, url}`.
- **SKU:** generated when left blank.
- **Discount:** must be between 0 and `price`.

---

## 9. Store orders

**Screens:** Orders, Order details, and the Home "New orders to fulfil" card.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/store/orders` | `?status=pending\|processing\|completed\|cancelled&search=&new=1` | paginated orders |
| GET | `/store/orders/{id}` | — | order (marks it as seen) |
| PATCH | `/store/orders/{id}/status` | `{ status: "processing"\|"completed" }` | order |
| POST | `/store/orders/{id}/cancel` | `{ reason }` | order (`cancelled`) |

- **Order fields:** `id`, `number` (e.g. `ORD-1011`), `customer_name`, `phone`, `address`, `items[] {product_id, name, unit_price, quantity}`, `total`, `status`, `is_new`, `cancel_reason`, `placed_at`, `payments[]`.
- **Status flow:** `pending` (awaiting payment) → `processing` (paid; set automatically by the payment webhook) → `completed`.
- **Cancelling:** only allowed while `pending` or `processing`. Cancelling a paid order starts a refund (§4).
- **Stock:** reduce stock when an order is paid, and put it back when the order is cancelled.

---

## 10. Reports and Home KPIs

**Screens:** the Reports tab and the Home KPIs. Today the app works these out on the phone from every invoice and transaction, which gets slow as a business grows.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/reports/summary` | `?from=YYYY-MM-DD&to=YYYY-MM-DD` | see below |
| GET | `/reports/export` | `?type=sales\|payments\|invoices&format=csv\|pdf&from=&to=` | file (or `{ url }`, a signed link) |

```json
{
  "revenue": 1250000.00, "collected": 980000.00, "outstanding": 270000.00, "overdue": 45000.00,
  "settled": 900000.00, "waiting_to_settle": 80000.00, "collection_rate": 0.78,
  "invoices": { "draft": 2, "unpaid": 5, "partly_paid": 1, "paid": 30, "overdue": 2 },
  "payments": { "successful": 40, "pending": 3, "failed": 1 },
  "customers": { "total": 52, "new": 6 },
  "orders": { "count": 18, "value": 310000.00 },
  "trend": [{ "period": "2026-11-01", "revenue": 120000.00 }]
}
```

- **Trend periods:** days when the range is up to 31 days, months otherwise.
- **Dashboard:** fix `GET /dashboard` so `total_clients` and `recent_clients` count only this business.

---

## 11. Push notifications

**Screens:** Settings → Push notifications toggles. Also used by every event above (payment received, refund stage changed, new order).

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/device-tokens` | `{ token, platform: "android"\|"ios", device_name }` | `201` |
| DELETE | `/device-tokens` | `{ token }` | `204` (the app calls this on logout) |
| GET | `/notification-preferences` | — | `{ payments: true, invoices: true, orders: true, refunds: true, product_updates: false }` |
| PUT | `/notification-preferences` | the same keys | preferences |

- **Token cleanup:** a token belongs to one user. Delete tokens that FCM reports as invalid.
- **Notification payload:** `data` should include `type` and `id` (e.g. `{type: "invoice", id: 42}`) so the app can open the right screen.

---

## 12. Plan, trial and wallet

**Screens:** Home plan banner (trial, ending soon, grace, expired), Choose plan, More → Wallet & Billings.

The design depends on the payments decision in [README.md §3](README.md) (companion app vs in-app purchase). These read-only endpoints are needed **either way**:

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/billing/subscription` | — | `{ plan: { code, name, price, interval }, status: "trial"\|"active"\|"ending_soon"\|"grace"\|"expired", trial_ends_at, current_period_end, days_left }` |
| GET | `/billing/plans` | — | `[{ code, name, price, interval, features[], store_product_ids: { apple, google } }]` |
| GET | `/billing/wallet` | — | `{ balance, currency }` |
| GET | `/billing/wallet/transactions` | paginated | `[{ id, type: "credit"\|"debit", amount, description, created_at }]` |

**Only if you choose in-app purchase (option B)**, add these:

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/billing/iap/verify` | `{ platform: "ios"\|"android", product_id, transaction_id? (iOS), purchase_token? (Android) }` | subscription |
| POST | `/billing/iap/restore` | `{ platform, receipts[] }` | subscription |
| POST | `/api/v1/webhooks/app-store` | App Store Server Notifications v2 (signed JWS) | `200` |
| POST | `/api/v1/webhooks/google-play` | Real-time developer notifications (Pub/Sub push) | `200` |

- **Verifying purchases:** verify on the server with the App Store Server API and the Google Play Developer API. Never trust the purchase details the app sends.
- **One subscription per business:** store `original_transaction_id` / `purchase_token` against the tenant, so one purchase can't unlock several businesses.

---

## 13. Sessions

**Screen:** Security → "Log out of other devices". The app hides this button until these endpoints exist.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/sessions` | — | `[{ id, device_name, last_used_at, current: bool }]` (Sanctum tokens) |
| DELETE | `/sessions/{id}` | — | `204` |
| POST | `/sessions/logout-others` | — | `{ revoked: 3 }` (keeps the current token) |

---

## 14. Support ticket replies

**Screen:** Support ticket details. Today the conversation is read-only because there's no reply endpoint.

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/tickets/{id}/replies` | `{ message }` or multipart `message` + `attachment` | `201 { id, message, sender_type: "admin", attachment_url, created_at }` |

- **Ticket status:** a reply moves `open` → `in_progress`.
- **Subject:** `PUT /tickets/{id}` should either accept `subject` or return `422` for it. Today it ignores the field without saying so.

---

## 15. Business settings and roles (replacing the unsafe endpoints)

The app doesn't use these until they're fixed.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/business-settings` | — | `{ invoice_prefix, next_invoice_number, default_due_days, default_notes, vat_rate, receipt_footer }` |
| PUT | `/business-settings` | the same keys | settings |

- **Platform settings:** move them (the Billway and FCM keys) behind a super-admin guard. Remove them from `admin/settings`.
- **Roles and permissions:** to support them in the app, make them **per business** (Spatie "teams" mode with `team_id = tenant_id`). After that, the app needs:
  - `GET /roles` (with permissions)
  - `POST /roles`
  - `PUT /roles/{id}`
  - `DELETE /roles/{id}`
  - `GET /permissions` (read-only, the fixed list)

---

## Summary

| § | Area | New endpoints | Priority |
|---|---|---|---|
| 0 | Security fixes | — (changes to existing endpoints) | **P0** |
| 2 | Invoices and quotes: line items + 9 actions | 9 (+2 fixed) | **P1** |
| 5 | Transaction fields + receipts | 2 | **P1** |
| 11 | Push device tokens + preferences | 4 | **P1** |
| 3 | Payment links | 6 | P2 |
| 4 | Credit notes and refunds | 8 | P2 |
| 6 | Business profile and KYC | 7 | P2 |
| 7 | Bank and settlement | 5 | P2 |
| 1 | Sign-up (+ optional device check) | 3 (+2) | P2 |
| 10 | Reports | 2 | P3 |
| 13 | Sessions | 3 | P3 |
| 14 | Ticket replies | 1 | P3 |
| 8 | Storefront, categories, products | 20 | P3 |
| 9 | Store orders | 4 | P3 |
| 12 | Plan and wallet (+ IAP if chosen) | 4 (+4) | P3, after the payments decision |
| 15 | Business settings (+ per-business roles) | 2 (+5) | P3 |
| | **Total** | **80 core + 11 optional** | |

When each endpoint is ready, the app side is small: the screens already exist and run on sample data. Each section needs a repository method, a mapper and a test against the fake backend, following the same pattern as the endpoints already connected.
