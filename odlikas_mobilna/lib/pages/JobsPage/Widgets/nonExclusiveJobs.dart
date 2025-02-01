import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class NonExclusiveJob extends StatelessWidget {
  const NonExclusiveJob({
    super.key,
    required this.jobData,
    required this.screenHeight,
    required this.screenWidth,
  });

  final Map<String, dynamic> jobData;
  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(jobData['recruter'],
                style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
            Text(
              jobData['location'],
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Divider(
          color: AppColors.tertiary,
          thickness: 0.5,
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          jobData['title'],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.04,
          ),
        ),
        SizedBox(height: screenHeight * 0.001),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Prosječna neto plaća ",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: screenWidth * 0.03),
            ),
            Text(
              jobData['pay'],
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
            )
          ],
        ),
      ],
    );
  }
}
