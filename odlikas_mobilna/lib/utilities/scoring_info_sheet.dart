import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

void showScoringInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _ScoringInfoSheet(),
  );
}

class _ScoringInfoSheet extends StatelessWidget {
  const _ScoringInfoSheet();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: sh * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.06, sw * 0.05, sw * 0.06, sw * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: sw * 0.05),
            Text(
              'Kako funkcioniraju bodovi?',
              style: GoogleFonts.inter(
                fontSize: sw * 0.055,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: sw * 0.04),
            _Row('🍅', 'Pomodoro sesije',
                'Svaka završena sesija od 25 minuta povećava tvoj streak score. Više sesija znači viši streak i više bodova.'),
            SizedBox(height: sw * 0.03),
            _Row('🔥', 'Streak score',
                'Streak score raste s brojem sesija i uzastopnim danima učenja. Prekid streaka resetira dnevni niz, ali sesije ostaju.'),
            SizedBox(height: sw * 0.03),
            _Row('📈', 'Poboljšanje prosjeka',
                'Svaki +1 bod na prosjeku ocjena od početka školske godine vrijedi ~12 bodova. Rast od 2.5 → 3.5 donosi više od stagnacije na 5.0.'),
            SizedBox(height: sw * 0.03),
            _Row('🏆', 'Formula bodova',
                'Ukupni bodovi = (streak score × 0.6) + (poboljšanje prosjeka × 30 × 0.4). Učenje i ocjene imaju podjednaku težinu.'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _Row(this.emoji, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: sw * 0.06)),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: sw * 0.008),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: sw * 0.033,
                  color: AppColors.tertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
