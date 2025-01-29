import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:odlikas_mobilna/constants/constants.dart';

class SettingsTile extends StatelessWidget {
  final bool? isLast;
  final String label;
  final String path;
  final Function()? onTap;

  const SettingsTile(
      {super.key,
      required this.label,
      this.isLast,
      required this.path,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                path,
                height: MediaQuery.of(context).size.width * 0.09,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (isLast != true) ...[
            Divider(
              color: AppColors.tertiary,
              thickness: 0.5,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          ],
        ],
      ),
    );
  }
}
