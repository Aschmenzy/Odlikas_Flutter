import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/services/payment_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isCanceling = false;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Otkaži pretplatu',
          style: GoogleFonts.inter(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Jesi li siguran da želiš otkazati Odlikaš+? Izgubit ćeš pristup svim premium značajkama.',
          style: GoogleFonts.inter(color: AppColors.tertiary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Zadrži pretplatu',
              style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Otkaži',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCanceling = true);
    try {
      await PaymentService().cancelSubscription();

      final box = Hive.box('User');
      await box.put('isOdlikasPlus', false);

      final email = box.get('email') as String?;
      if (email != null) {
        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(email)
            .set({'odlikasPlus': false}, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pretplata je otkazana.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('[Subscription] cancel error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri otkazivanju pretplate. Pokušaj ponovno.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCanceling = false);
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pretplata',
          style: GoogleFonts.inter(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
            fontSize: sw * 0.05,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.07),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sh * 0.03),
            Row(
              children: [
                Text(
                  'Odlikaš+',
                  style: GoogleFonts.inter(
                    fontSize: sw * 0.075,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: sw * 0.03),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.03,
                    vertical: sh * 0.004,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A9C59).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AKTIVNO',
                    style: GoogleFonts.inter(
                      fontSize: sw * 0.03,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A9C59),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: sh * 0.03),
            _InfoRow(label: 'Plan', value: 'Odlikaš+ Mjesečna', sw: sw, sh: sh),
            _InfoRow(label: 'Cijena', value: '€10,00 / mjesec', sw: sw, sh: sh),
            _InfoRow(label: 'Status', value: 'Aktivno', sw: sw, sh: sh, valueColor: const Color(0xFF1A9C59)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: sh * 0.065,
              child: OutlinedButton(
                onPressed: _isCanceling ? null : _confirmCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCanceling
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2.5),
                      )
                    : Text(
                        'Otkaži pretplatu',
                        style: GoogleFonts.inter(
                          fontSize: sw * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double sw;
  final double sh;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.sw,
    required this.sh,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: sh * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: sw * 0.042,
              color: AppColors.tertiary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: sw * 0.042,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
