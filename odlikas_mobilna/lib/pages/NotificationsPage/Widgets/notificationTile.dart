import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class NotificationTile extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final bool value;
  final Function(bool)? onChanged;
  final bool isLast;

  const NotificationTile({
    Key? key,
    required this.label,
    required this.iconWidget,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,

              SizedBox(width: 12),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),

              // Switch

              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.accent,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[350],
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),

        // Divider (if not the last item)
        if (!isLast)
          Divider(
            color: AppColors.tertiary,
            thickness: 0.5, // Thinner divider
            height: 8, // Reduced space around divider
          ),
      ],
    );
  }
}
