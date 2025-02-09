import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final ValueChanged<String> onDaySelected;
  final List<String> days = const ['PON', 'UTO', 'SRI', 'ČET', 'PET'];

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: days
            .map((day) => _DayButton(
                  day: day,
                  isSelected: selectedDay == day,
                  onTap: () => onDaySelected(day),
                ))
            .toList(),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            day.substring(0, 3),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.045,
            ),
          ),
        ),
      ),
    );
  }
}
