# Stripe Paywall — Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Odlikaš+ paywall to the Flutter app — a full-screen paywall page from Settings and a bottom sheet modal shown whenever a free user hits a gated feature.

**Architecture:** `PaymentService` wraps the two backend calls. `PaywallPage` is the full-screen version. `PaywallModal` is the bottom sheet with a static `show(context)` helper for calling from anywhere. On payment success: backend updates Postgres, Flutter writes Firestore and updates Hive. Two existing pages are gated: subject selection (2nd subject tap) and AI chatbot (5 message session limit).

**Tech Stack:** `flutter_stripe ^11.0.0`, `DioClient` (existing), `HiveFlutter` (existing), `cloud_firestore` (existing), `AppColors`/`GoogleFonts.inter` design system.

---

### Task 1: Add flutter_stripe, configure Android, init in main.dart

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/kotlin/com/example/odlikas_mobilna/MainActivity.kt`
- Modify: `.env`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add flutter_stripe to pubspec.yaml**

Open `pubspec.yaml`. After the `safe_device: ^1.3.0` line, add:

```yaml
  flutter_stripe: ^11.0.0
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

Expected: resolves without errors.

- [ ] **Step 3: Update MainActivity.kt to FlutterFragmentActivity**

`flutter_stripe` requires `FlutterFragmentActivity` instead of `FlutterActivity` for the payment sheet to render on Android.

Open `android/app/src/main/kotlin/com/example/odlikas_mobilna/MainActivity.kt` and replace the entire file content with:

```kotlin
package com.example.odlikas_mobilna

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

- [ ] **Step 4: Add Stripe publishable key to .env**

Open the `.env` file in the project root. Add this line (get the `pk_test_...` key from Stripe dashboard → Developers → API keys → Publishable key):

```
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
```

- [ ] **Step 5: Init Stripe in main.dart**

Open `lib/main.dart`. Add the import at the top:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
```

In the `main()` function, after `await dotenv.load(fileName: ".env");` and before `runApp(...)`, add:

```dart
Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
await Stripe.instance.applySettings();
```

The relevant section of `main()` should now look like:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();
  await Hive.initFlutter();
  // ... rest unchanged
```

- [ ] **Step 6: Run on device to verify no crash on startup**

```bash
flutter run
```

Expected: app launches normally, no exception on startup.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/kotlin/com/example/odlikas_mobilna/MainActivity.kt .env lib/main.dart
git commit -m "feat: add flutter_stripe, init on startup, update MainActivity"
```

---

### Task 2: Create PaymentService

**Files:**
- Create: `lib/services/payment_service.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/payment_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/services/payment_service.dart';

void main() {
  test('PaymentService exposes createSubscription and confirm', () {
    final service = PaymentService();
    expect(service.createSubscription, isA<Function>());
    expect(service.confirm, isA<Function>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/payment_service_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'payment_service.dart'`

- [ ] **Step 3: Create lib/services/payment_service.dart**

```dart
import 'package:odlikas_mobilna/database/api/dio_client.dart';

class PaymentService {
  Future<({String clientSecret, String subscriptionId})> createSubscription() async {
    final response = await DioClient.instance.post('/api/Payment/CreateSubscription');
    return (
      clientSecret: response.data['clientSecret'] as String,
      subscriptionId: response.data['subscriptionId'] as String,
    );
  }

  Future<void> confirm(String subscriptionId) async {
    await DioClient.instance.post('/api/Payment/Confirm', data: {
      'subscriptionId': subscriptionId,
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/payment_service_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/payment_service.dart test/services/payment_service_test.dart
git commit -m "feat: add PaymentService for Stripe subscription endpoints"
```

---

### Task 3: Create PaywallPage (full-screen)

**Files:**
- Create: `lib/pages/PaywallPage/paywall_page.dart`

- [ ] **Step 1: Create the directory and file**

Create `lib/pages/PaywallPage/paywall_page.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/services/payment_service.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _isLoading = false;

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final result = await PaymentService().createSubscription();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: result.clientSecret,
          merchantDisplayName: 'Odlikaš',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Payment sheet succeeded — confirm with backend
      try {
        await PaymentService().confirm(result.subscriptionId);
      } catch (_) {
        // Non-fatal: update locally even if confirm fails
      }

      // Write to Firestore
      final box = Hive.box('User');
      final email = box.get('email') as String?;
      if (email != null) {
        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(email)
            .set({'odlikasPlus': true, 'purchasedAt': Timestamp.now()},
                SetOptions(merge: true));
      }

      // Update Hive
      await box.put('isOdlikasPlus', true);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dobrodošao u Odlikaš+!'),
          backgroundColor: Color(0xFF1A9C59),
          duration: Duration(seconds: 3),
        ),
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.error.localizedMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri pokretanju plaćanja. Pokušaj ponovno.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.07),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sh * 0.03),
            Text(
              'Odlikaš+',
              style: GoogleFonts.inter(
                fontSize: sw * 0.09,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: sh * 0.008),
            Text(
              '€2,99 / mjesec',
              style: GoogleFonts.inter(
                fontSize: sw * 0.055,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: sh * 0.04),
            _FeatureRow(icon: Icons.notifications_active_outlined, text: 'Do 5 praćenih predmeta'),
            _FeatureRow(icon: Icons.smart_toy_outlined, text: 'Neograničeni AI chatbot'),
            _FeatureRow(icon: Icons.devices_outlined, text: 'Sinkronizacija s tablet prikazom'),
            _FeatureRow(icon: Icons.timer_outlined, text: 'Sinkronizacija Pomodoro timera'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: sh * 0.065,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.tertiary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Pretplati se',
                        style: GoogleFonts.inter(
                          fontSize: sw * 0.047,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: sh * 0.015),
            Center(
              child: Text(
                'Testni način — neće se naplaćivati stvarni novac',
                style: GoogleFonts.inter(
                  fontSize: sw * 0.032,
                  color: AppColors.tertiary,
                ),
              ),
            ),
            SizedBox(height: sh * 0.04),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: sw * 0.065),
          SizedBox(width: sw * 0.04),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: sw * 0.042,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Hot reload on device and verify the page renders**

Navigate to `PaywallPage` temporarily by adding a test route in `main.dart` (revert after):

```dart
'/paywall': (_) => const PaywallPage(),
```

Then navigate to it and verify the UI looks correct before removing the test route.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/PaywallPage/paywall_page.dart
git commit -m "feat: add PaywallPage full-screen upgrade page"
```

---

### Task 4: Create PaywallModal (bottom sheet)

**Files:**
- Create: `lib/pages/PaywallPage/paywall_modal.dart`

- [ ] **Step 1: Create lib/pages/PaywallPage/paywall_modal.dart**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/services/payment_service.dart';

class PaywallModal extends StatefulWidget {
  const PaywallModal({super.key});

  /// Show the paywall as a bottom sheet. Returns true if the user upgraded.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallModal(),
    );
    return result == true;
  }

  @override
  State<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends State<PaywallModal> {
  bool _isLoading = false;

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final result = await PaymentService().createSubscription();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: result.clientSecret,
          merchantDisplayName: 'Odlikaš',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      try {
        await PaymentService().confirm(result.subscriptionId);
      } catch (_) {}

      final box = Hive.box('User');
      final email = box.get('email') as String?;
      if (email != null) {
        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(email)
            .set({'odlikasPlus': true, 'purchasedAt': Timestamp.now()},
                SetOptions(merge: true));
      }
      await box.put('isOdlikasPlus', true);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (mounted) Navigator.pop(context, false);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.error.localizedMessage}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri pokretanju plaćanja. Pokušaj ponovno.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        sw * 0.07,
        sh * 0.025,
        sw * 0.07,
        sh * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: sh * 0.025),
          Text(
            'Ovo je Odlikaš+ značajka',
            style: GoogleFonts.inter(
              fontSize: sw * 0.055,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            'Nadogradi na Odlikaš+ za €2,99/mj i otključaj sve značajke.',
            style: GoogleFonts.inter(
              fontSize: sw * 0.04,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: sh * 0.03),
          SizedBox(
            width: double.infinity,
            height: sh * 0.065,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.tertiary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Pretplati se — €2,99/mj',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          SizedBox(height: sh * 0.01),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Ne hvala',
                style: GoogleFonts.inter(
                  fontSize: sw * 0.038,
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/pages/PaywallPage/paywall_modal.dart
git commit -m "feat: add PaywallModal bottom sheet with static show() helper"
```

---

### Task 5: Wire up Settings tile

**Files:**
- Modify: `lib/pages/SettingsPages/settings_page.dart`

- [ ] **Step 1: Add imports to settings_page.dart**

At the top of `lib/pages/SettingsPages/settings_page.dart`, add:

```dart
import 'package:odlikas_mobilna/pages/PaywallPage/paywall_page.dart';
```

- [ ] **Step 2: Add isOdlikasPlus field and load it in _loadUserData**

In `_SettingsPageState`, add this field next to `isDyslexic`:

```dart
bool _isOdlikasPlus = false;
```

In `_loadUserData()`, after opening the Hive box, add:

```dart
final box = await Hive.openBox('User');
userEmail = box.get('email');
setState(() {
  _isOdlikasPlus = box.get('isOdlikasPlus') as bool? ?? false;
});
```

> **Note:** `_loadUserData` already opens the 'User' box — add the `_isOdlikasPlus` read inside the same box.open call.

- [ ] **Step 3: Add the Nadogradi tile in the build method**

In the `build` method, find the `SettingsTile` for "Obavijesti" and add the upgrade tile **before** it, guarded by `!_isOdlikasPlus`:

```dart
if (!_isOdlikasPlus)
  SettingsTile(
    label: 'Nadogradi na Odlikaš+',
    path: 'assets/images/odlikas_plus_upload_90x90.png',
    onTap: () async {
      final upgraded = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      );
      if (upgraded == true) {
        setState(() => _isOdlikasPlus = true);
      }
    },
  ),
```

- [ ] **Step 4: Run on device and verify the tile appears for a free user and disappears after upgrading**

Manual test: launch app → Settings → confirm "Nadogradi na Odlikaš+" tile is visible. Tap it → PaywallPage opens.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/SettingsPages/settings_page.dart
git commit -m "feat: add Nadogradi na Odlikas+ tile in settings for free users"
```

---

### Task 6: Gate subject selection page

**Files:**
- Modify: `lib/pages/OnboardingPage/subject_selection_page.dart`

- [ ] **Step 1: Add imports and isOdlikasPlus field**

Add at the top of `subject_selection_page.dart`:

```dart
import 'package:odlikas_mobilna/pages/PaywallPage/paywall_modal.dart';
```

In `_SubjectSelectionPageState`, add these fields:

```dart
bool _isOdlikasPlus = false;
```

- [ ] **Step 2: Load isOdlikasPlus in initState**

Replace `initState` with:

```dart
@override
void initState() {
  super.initState();
  _gradesFuture = ApiService().fetchGrades();
  _loadOdlikasPlus();
}

Future<void> _loadOdlikasPlus() async {
  final box = await Hive.openBox('User');
  setState(() {
    _isOdlikasPlus = box.get('isOdlikasPlus') as bool? ?? false;
  });
}
```

- [ ] **Step 3: Gate the subject tap**

Find the `onTap` handler inside the `GestureDetector` in the `ListView` builder. Replace it:

```dart
onTap: () async {
  final isAlreadySelected = _selectedSubjectId != null &&
      _selectedSubjectId != subject.subjectId;

  if (isAlreadySelected && !_isOdlikasPlus) {
    final upgraded = await PaywallModal.show(context);
    if (upgraded) setState(() => _isOdlikasPlus = true);
    return;
  }

  setState(() {
    _selectedSubjectId = subject.subjectId;
    _selectedSubjectName = subject.subjectName;
  });
},
```

- [ ] **Step 4: Manual test on device**

1. Log in as a free user (verify `isOdlikasPlus` is false in Hive)
2. Navigate to subject selection
3. Tap one subject — it selects normally ✓
4. Tap a different subject — PaywallModal appears ✓
5. Tap "Ne hvala" — modal closes, original subject still selected ✓

- [ ] **Step 5: Commit**

```bash
git add lib/pages/OnboardingPage/subject_selection_page.dart
git commit -m "feat: gate subject selection paywall for free users"
```

---

### Task 7: Gate AI chatbot (5 message session limit)

**Files:**
- Modify: `lib/pages/AiChatbotPage/ai_chatbot_page.dart`

- [ ] **Step 1: Add import and isOdlikasPlus field**

Add at the top of `ai_chatbot_page.dart`:

```dart
import 'package:odlikas_mobilna/pages/PaywallPage/paywall_modal.dart';
```

In `_AiChatbotPageState`, add these fields:

```dart
static const int _freeMessageLimit = 5;
bool _isOdlikasPlus = false;
```

- [ ] **Step 2: Load isOdlikasPlus in initState**

Replace `initState` with:

```dart
@override
void initState() {
  super.initState();
  _messages.add(Message(
    text: 'Što mogu učiniti za tebe danas? Pitaj me o ocjenama, rasporedu, testovima ili profilu.',
    isUser: false,
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
  ));
  _loadOdlikasPlus();
}

Future<void> _loadOdlikasPlus() async {
  final box = await Hive.openBox('User');
  setState(() {
    _isOdlikasPlus = box.get('isOdlikasPlus') as bool? ?? false;
  });
}
```

- [ ] **Step 3: Add limit check at the top of _sendMessage**

At the very start of `_sendMessage()`, before the `if (_promptController.text.isEmpty) return;` line, add:

```dart
final userMessageCount = _messages.where((m) => m.isUser).length;
if (!_isOdlikasPlus && userMessageCount >= _freeMessageLimit) {
  final upgraded = await PaywallModal.show(context);
  if (upgraded) setState(() => _isOdlikasPlus = true);
  return;
}
```

- [ ] **Step 4: Manual test on device**

1. Open AI chatbot as a free user
2. Send 5 messages — all go through normally ✓
3. Try to send a 6th message — PaywallModal appears ✓
4. Tap "Ne hvala" — modal closes, no message sent ✓

- [ ] **Step 5: Commit**

```bash
git add lib/pages/AiChatbotPage/ai_chatbot_page.dart
git commit -m "feat: gate AI chatbot at 5 messages/session for free users"
```

---

### End-to-end test (after backend is deployed)

- [ ] **Step 1: Full payment flow test**

1. Open Settings → tap "Nadogradi na Odlikaš+"
2. PaywallPage opens
3. Tap "Pretplati se" — Stripe payment sheet opens
4. Enter test card: `4242 4242 4242 4242`, any future date, any CVC
5. Confirm — sheet closes
6. Success snackbar "Dobrodošao u Odlikaš+!" appears
7. Navigate back to Settings — "Nadogradi" tile is gone ✓
8. Open subject selection — can tap multiple subjects freely ✓
9. Open AI chatbot — can send more than 5 messages ✓

- [ ] **Step 2: Cancellation test**

1. Open paywall → tap "Pretplati se" → tap X on the Stripe sheet
2. Sheet closes silently, no snackbar ✓

- [ ] **Step 3: Network error test**

1. Disable network, open paywall, tap "Pretplati se"
2. Snackbar "Greška pri pokretanju plaćanja. Pokušaj ponovno." appears ✓
