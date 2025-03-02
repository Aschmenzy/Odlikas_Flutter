import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isWithinCurrentMonth;
  final bool isHoliday, isTest;
  final VoidCallback? onTap;

  const DayCell({
    required this.date,
    required this.isWithinCurrentMonth,
    required this.isTest,
    required this.onTap,
    required this.isHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Container(
          width: screenSize.width * 0.1,
          height: screenSize.height * 0.4,
          decoration: BoxDecoration(
            color: isTest
                ? AppColors.accent
                : (isHoliday
                    ? const Color.fromRGBO(23, 148, 210, 1)
                    : Colors.white),
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                spreadRadius: 1,
                blurRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                "${date.day}",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isHoliday || isTest
                      ? Colors.white
                      : (isWithinCurrentMonth
                          ? Colors.black
                          : Color.fromRGBO(113, 113, 113, 1)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
