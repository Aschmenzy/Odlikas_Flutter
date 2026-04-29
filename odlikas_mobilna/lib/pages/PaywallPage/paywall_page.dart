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
    } catch (e) {
      debugPrint('[Paywall] createSubscription error: $e');
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
              '€10,00 / mjesec',
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
                  disabledBackgroundColor: AppColors.tertiary.withValues(alpha: 0.3),
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
