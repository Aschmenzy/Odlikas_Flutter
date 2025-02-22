import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class NotificationTile extends StatelessWidget {
  final bool? isLast;
  final String label;
  final String path;
  final bool value;
  final Function(bool)? onChanged;
  final Function()? onTap;

  const NotificationTile({
    super.key,
    required this.label,
    this.isLast,
    required this.path,
    this.onTap,
    required this.value,
    this.onChanged,
  });

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
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          if (isLast != true) ...[
            Divider(
              color: AppColors.tertiary,
              thickness: 0.5,
            ),
          ],
        ],
      ),
    );
  }
}
