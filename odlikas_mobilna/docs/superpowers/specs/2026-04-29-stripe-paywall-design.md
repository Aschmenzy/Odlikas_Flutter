# Stripe Paywall — Odlikaš+ Design Spec

## Overview

Add a monthly subscription paywall for Odlikaš+ features. Stripe runs in test mode for the competition demo. Payment confirmation is client-side (no webhook — see demo limitations below).

**Price ID:** `price_1TRFoiQGIIBW5gARkmRIihj7`

---

## Architecture

### Backend (ASP.NET Core)

Two new endpoints in a new `PaymentController`:

#### `POST /api/Payment/CreateSubscription`
- **Auth:** Bearer token required
- **Body:** none — email is read from session via `TryGetEmail()`
- **Logic:**
  1. Call `TryGetEmail(out var email)` — return `401` if fails
  2. Look up or create a Stripe Customer for that email (`Customers.Create` / `Customers.List`)
  2. Create a Stripe Subscription with `price_1TRFoiQGIIBW5gARkmRIihj7` and `payment_behavior: default_incomplete`, `expand: ['latest_invoice.payment_intent']`
  3. Return `{ clientSecret, subscriptionId }` from `subscription.LatestInvoice.PaymentIntent.ClientSecret`
- **Returns:** `200 { clientSecret: string, subscriptionId: string }`
- **Errors:** `400` if email missing, `500` on Stripe error

#### `POST /api/Payment/Confirm`
- **Auth:** Bearer token required
- **Body:** `{ "subscriptionId": "sub_..." }`
- **Logic:**
  1. Call `TryGetEmail(out var email)` — return `401` if fails
  2. Verify subscription exists in Stripe and status is `active` or `trialing`
  3. In Postgres: set `StudentCache.IsOdlikasPlus = true` and `StudentCache.OdlikasPlusSince = DateTime.UtcNow` where email matches
  4. Return `200 { success: true }` — Firestore write is done by Flutter after receiving this response
- **Returns:** `200 { success: true }`
- **Errors:** `400` if subscriptionId missing, `404` if subscription not found in Stripe, `500` on failure

### Backend config (env vars on Fly.io)
- `STRIPE_SECRET_KEY` = `sk_test_...`
- Price ID hardcoded as a constant in `PaymentController`

### NuGet package
- `Stripe.net`

---

### Flutter

#### New files

**`lib/services/payment_service.dart`**
- `Future<({String clientSecret, String subscriptionId})> createSubscription()` — calls `POST /api/Payment/CreateSubscription` (no body, auth header only)
- `Future<void> confirm(String subscriptionId)` — calls `POST /api/Payment/Confirm`

**`lib/pages/PaywallPage/paywall_page.dart`**
- Full-screen page pushed from Settings
- Shows Odlikaš+ feature list, price (€2.99/month), "Pretplati se" button
- On button tap: calls `createSubscription` → `Stripe.initPaymentSheet` → `presentPaymentSheet` → calls `confirm` → updates Hive `isOdlikasPlus = true` → pops with success snackbar

**`lib/pages/PaywallPage/paywall_modal.dart`**
- Bottom sheet version of the paywall
- Same flow as `paywall_page.dart` but displayed as a modal
- Static helper: `PaywallModal.show(context)` — can be called from anywhere

#### Package to add
- `flutter_stripe: ^11.x` (latest)

#### Stripe init
- In `main.dart`, before `runApp`: `Stripe.publishableKey = 'pk_test_...'`

#### Existing files changed

| File | Change |
|---|---|
| `pubspec.yaml` | Add `flutter_stripe` |
| `main.dart` | Set `Stripe.publishableKey` on startup |
| `settings_page.dart` | Add "Nadogradi na Odlikaš+" `SettingsTile` (hidden if already Odlikaš+) |
| `subject_selection_page.dart` | On 2nd subject tap → `PaywallModal.show(context)` instead of just snackbar |
| `ai_chatbot_page.dart` | When message limit hit → `PaywallModal.show(context)` |

---

## Data Flow

```
User taps "Nadogradi"
  → PaymentService.createSubscription()
    → POST /api/Payment/CreateSubscription  (no body, Bearer token only)
    → backend: TryGetEmail() → find/create Stripe Customer → create Subscription
    → returns { clientSecret, subscriptionId }
  → Stripe.initPaymentSheet(clientSecret)
  → Stripe.presentPaymentSheet()       ← user enters 4242 4242 4242 4242
  → PaymentService.confirm(subscriptionId)
    → POST /api/Payment/Confirm
    → backend: verify Stripe → update Postgres (IsOdlikasPlus, OdlikasPlusSince)
    → returns 200
  → Flutter writes { odlikasPlus: true, purchasedAt } to Firestore studentProfiles/{email}
  → Hive.put('isOdlikasPlus', true)
  → pop/dismiss paywall + show success snackbar
```

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| `createSubscription` network/backend error | Snackbar "Greška pri pokretanju plaćanja", sheet never opens |
| User cancels payment sheet | Silent dismiss, no error |
| Card declined | Stripe sheet shows its own error UI |
| `confirm` fails after payment succeeds | Update Hive optimistically anyway (user not stuck), log error |

---

## Feature Gates Using Paywall

| Location | Trigger |
|---|---|
| `subject_selection_page.dart` | Tap 2nd subject when free user |
| `ai_chatbot_page.dart` | Hit daily message limit (free tier) |
| Settings | "Nadogradi na Odlikaš+" tile always visible to free users |

---

## Backend Implementation Notes

- **Email source:** Use `TryGetEmail(out var email)` inherited from `ApiBaseController`. Do NOT trust request body. `CreateSubscription` takes no request body — just the `Authorization` header.
  ```csharp
  if (!TryGetEmail(out var email)) return Unauthorized();
  ```
- **Student entity:** `StudentCache` — `AppDbContext.StudentCache`. Properties already exist: `IsOdlikasPlus` (bool) and `OdlikasPlusSince` (DateTime?). No migration needed.
- **Firebase Admin SDK:** `FirebaseAdmin v3.1.0` already installed. No new NuGet packages beyond `Stripe.net`.

---

## Demo Limitations (not production-ready)

- No Stripe webhook — confirmation is client-side only
- Optimistic Hive update if `/Confirm` fails — Postgres/Firestore may be out of sync
- No subscription cancellation or management flow in-app
- No subscription status check on app resume/login
- Price ID hardcoded in backend (not in env/config)
- No in-app receipt screen

Full list tracked in `memory/project_production_todo.md`.
