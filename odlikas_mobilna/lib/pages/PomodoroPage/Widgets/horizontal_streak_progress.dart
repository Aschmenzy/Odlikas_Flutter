import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';

class HorizontalStreakProgress extends StatelessWidget {
  final int daysLearning;
  final int hoursLearning;
  final int streakCount;
  final Color color;
  final VoidCallback? onTap;

  const HorizontalStreakProgress({
    super.key,
    required this.daysLearning,
    required this.hoursLearning,
    required this.streakCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (daysLearning == 0 || hoursLearning == 0) return const SizedBox.shrink();

    // Calculate which days are completed based on streak count
    final completedDays = (streakCount > 0)
        ? min((streakCount / hoursLearning).ceil(), daysLearning)
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size.width * 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Allow container to size based on content
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(daysLearning, (index) {
            final dayNumber = index + 1;
            final bool isCompleted = dayNumber <= completedDays;
            final bool isCurrentDay =
                dayNumber == completedDays && streakCount > 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildCircleDay(
                number: dayNumber,
                isCompleted: isCompleted,
                isCurrentDay: isCurrentDay,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCircleDay(
      {required int number,
      required bool isCompleted,
      required bool isCurrentDay}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: isCurrentDay ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: GoogleFonts.inter(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
