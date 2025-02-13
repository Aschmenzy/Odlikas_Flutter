import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class WeekDayHeader extends StatelessWidget {
  // Moving the weekdays list into the widget
  static const List<String> _weekDays = [
    'PON',
    'UTO',
    'SRI',
    'ČET',
    'PET',
    'SUB',
    'NED'
  ];

  const WeekDayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _weekDays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
