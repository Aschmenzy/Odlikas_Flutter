import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class MonthHeader extends StatelessWidget {
  static const List<String> monthNames = [
    'SIJEČANJ',
    'VELJAČA',
    'OŽUJAK',
    'TRAVANJ',
    'SVIBANJ',
    'LIPANJ',
    'SRPANJ',
    'KOLOVOZ',
    'RUJAN',
    'LISTOPAD',
    'STUDENI',
    'PROSINAC'
  ];

  final DateTime focusedDate;
  final double screenWidth;

  const MonthHeader({
    super.key,
    required this.focusedDate,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: screenWidth * 0.05),
        Text(
          "${monthNames[focusedDate.month - 1]} ",
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.09,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
