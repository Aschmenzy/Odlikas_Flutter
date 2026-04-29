# Stripe Paywall — Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two endpoints (`CreateSubscription`, `Confirm`) to the ASP.NET backend that integrate with Stripe to enable Odlikaš+ monthly subscriptions.

**Architecture:** `PaymentController` inherits from `ApiBaseController` (same pattern as all existing controllers). `CreateSubscription` creates a Stripe Customer + Subscription and returns the `clientSecret` for the Flutter payment sheet. `Confirm` verifies the subscription is active in Stripe and writes `IsOdlikasPlus = true` to Postgres. Firestore is written by Flutter, not by this backend.

**Tech Stack:** ASP.NET Core, Stripe.net NuGet, Entity Framework Core (`AppDbContext.StudentCache`), existing `ApiBaseController.TryGetEmail()` pattern.

---

### Task 1: Install Stripe.net and configure API key

**Files:**
- Modify: `Program.cs` (add `StripeConfiguration.ApiKey` line)

- [ ] **Step 1: Add Stripe.net NuGet package**

Run in the backend project root:
```bash
dotnet add package Stripe.net
```

Expected output ends with: `Successfully installed 'Stripe.net x.x.x'`

- [ ] **Step 2: Configure Stripe API key in Program.cs**

Find where other configuration is read in `Program.cs` (look for `builder.Configuration[...]` calls). Add this line **before** `builder.Build()`:

```csharp
Stripe.StripeConfiguration.ApiKey = builder.Configuration["STRIPE_SECRET_KEY"];
```

Add the using at the top of the file if not already present:
```csharp
using Stripe;
```

- [ ] **Step 3: Add secret key to local dev secrets**

Run (for local development only — do NOT commit this value):
```bash
dotnet user-secrets set "STRIPE_SECRET_KEY" "sk_test_YOUR_KEY_HERE"
```

Replace `sk_test_YOUR_KEY_HERE` with the actual `sk_test_...` key from the Stripe dashboard (Developers → API keys → Secret key).

- [ ] **Step 4: Verify the project still builds**

```bash
dotnet build
```

Expected: `Build succeeded.` with 0 errors.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: add Stripe.net package and configure API key"
```

---

### Task 2: Create PaymentController with CreateSubscription endpoint

**Files:**
- Create: `Controllers/PaymentController.cs`

- [ ] **Step 1: Create the controller file**

Create `Controllers/PaymentController.cs` with the following content:

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;

[ApiController]
[Route("api/[controller]")]
public class PaymentController : ApiBaseController
{
    private const string PriceId = "price_1TRFoiQGIIBW5gARkmRIihj7";
    private readonly AppDbContext _db;

    public PaymentController(AppDbContext db)
    {
        _db = db;
    }

    [HttpPost("CreateSubscription")]
    public async Task<IActionResult> CreateSubscription()
    {
        if (!TryGetEmail(out var email)) return Unauthorized();

        // Find or create Stripe customer for this email
        var customerService = new CustomerService();
        var customers = await customerService.ListAsync(new CustomerListOptions
        {
            Email = email,
            Limit = 1,
        });

        var customer = customers.Any()
            ? customers.First()
            : await customerService.CreateAsync(new CustomerCreateOptions { Email = email });

        // Create subscription — default_incomplete so we get a PaymentIntent to collect
        var subscriptionService = new SubscriptionService();
        var subscription = await subscriptionService.CreateAsync(new SubscriptionCreateOptions
        {
            Customer = customer.Id,
            Items = new List<SubscriptionItemOptions>
            {
                new() { Price = PriceId }
            },
            PaymentBehavior = "default_incomplete",
            Expand = new List<string> { "latest_invoice.payment_intent" },
        });

        var clientSecret = subscription.LatestInvoice.PaymentIntent.ClientSecret;

        return Ok(new
        {
            clientSecret,
            subscriptionId = subscription.Id,
        });
    }
}
```

> **Note on AppDbContext injection:** Check how other controllers inject `AppDbContext` — if they use a different constructor pattern or base class injection, follow that instead.

- [ ] **Step 2: Build to verify no errors**

```bash
dotnet build
```

Expected: `Build succeeded.` with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add Controllers/PaymentController.cs
git commit -m "feat: add PaymentController with CreateSubscription endpoint"
```

---

### Task 3: Add Confirm endpoint to PaymentController

**Files:**
- Modify: `Controllers/PaymentController.cs`

- [ ] **Step 1: Add the ConfirmRequest record**

At the bottom of `PaymentController.cs` (outside the class), add:

```csharp
public record ConfirmRequest(string SubscriptionId);
```

- [ ] **Step 2: Add the Confirm action to PaymentController**

Inside the `PaymentController` class, after `CreateSubscription`, add:

```csharp
[HttpPost("Confirm")]
public async Task<IActionResult> Confirm([FromBody] ConfirmRequest request)
{
    if (!TryGetEmail(out var email)) return Unauthorized();
    if (string.IsNullOrEmpty(request?.SubscriptionId))
        return BadRequest(new { error = "subscriptionId required" });

    // Verify subscription is active in Stripe
    var subscriptionService = new SubscriptionService();
    Subscription subscription;
    try
    {
        subscription = await subscriptionService.GetAsync(request.SubscriptionId);
    }
    catch (StripeException)
    {
        return NotFound(new { error = "Subscription not found" });
    }

    if (subscription.Status != "active" && subscription.Status != "trialing")
        return BadRequest(new { error = $"Subscription status is {subscription.Status}" });

    // Update Postgres
    var student = await _db.StudentCache.FirstOrDefaultAsync(s => s.Email == email);
    if (student != null)
    {
        student.IsOdlikasPlus = true;
        student.OdlikasPlusSince = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    return Ok(new { success = true });
}
```

> **Note on Email property:** Verify the exact property name on `StudentCache` used for email comparison (it may be `Email`, `StudentEmail`, or similar — check the model).

- [ ] **Step 3: Build to verify no errors**

```bash
dotnet build
```

Expected: `Build succeeded.` with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add Controllers/PaymentController.cs
git commit -m "feat: add Confirm endpoint to PaymentController"
```

---

### Task 4: Deploy and configure Fly.io secret

**Files:** none (env config only)

- [ ] **Step 1: Set the Stripe secret key on Fly.io**

```bash
fly secrets set STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
```

Replace with actual `sk_test_...` key. This triggers a redeploy automatically.

- [ ] **Step 2: Verify deployment**

```bash
fly logs
```

Wait for `Starting clean up of the web process` to complete. Check no startup errors.

- [ ] **Step 3: Smoke test CreateSubscription with curl**

Replace `YOUR_BEARER_TOKEN` with a valid token from a test login:

```bash
curl -X POST https://YOUR_FLY_APP.fly.dev/api/Payment/CreateSubscription \
  -H "Authorization: Bearer YOUR_BEARER_TOKEN" \
  -H "Content-Type: application/json"
```

Expected response:
```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "subscriptionId": "sub_xxx"
}
```

- [ ] **Step 4: Done — backend is ready for Flutter integration**
