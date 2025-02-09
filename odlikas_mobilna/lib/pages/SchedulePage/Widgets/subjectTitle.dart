import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class SubjectTile extends StatelessWidget {
  final int periodNumber;
  final String subject;
  final bool isFirst; //
  final bool isLast;

  const SubjectTile({
    super.key,
    required this.periodNumber,
    required this.subject,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      leading: Container(
        width: screenWidth * 0.25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? Radius.circular(15) : Radius.zero,
            bottomLeft: isLast ? Radius.circular(15) : Radius.zero,
          ),
          border: Border.all(
            color: AppColors.background,
            width: 0.5,
          ),
        ),
        child: Text(
          '$periodNumber.sat',
          style: GoogleFonts.inter(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.05,
          ),
        ),
      ),
      title: Text(
        subject,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04,
        ),
      ),
    );
  }
}
