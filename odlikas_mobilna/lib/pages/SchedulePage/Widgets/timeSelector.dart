import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class TimeSelector extends StatelessWidget {
  final bool isMorning;
  final ValueChanged<bool> onChanged;

  const TimeSelector({
    super.key,
    required this.isMorning,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 80.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _TimeButton(
            title: 'UJUTRO',
            isSelected: isMorning,
            onTap: () => onChanged(true),
          ),
          _TimeButton(
            title: 'POPODNE',
            isSelected: !isMorning,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
