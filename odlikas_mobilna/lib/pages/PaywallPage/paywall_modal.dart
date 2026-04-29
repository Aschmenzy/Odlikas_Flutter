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
            'Nadogradi na Odlikaš+ za €10,00/mj i otključaj sve značajke.',
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
                      'Pretplati se — €10,00/mj',
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
