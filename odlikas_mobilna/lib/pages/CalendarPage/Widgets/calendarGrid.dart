import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/dayCell.dart';

class CalendarGrid extends StatelessWidget {
  final double screenWidth;
  final Function(BuildContext, DateTime) onDayTap;
  final DateTime firstDayOfMonth;
  final Function(DateTime) isWithinCurrentMonth;
  final Function(DateTime) isHoliday;
  final Function(DateTime) isTest;

  const CalendarGrid({
    super.key,
    required this.screenWidth,
    required this.onDayTap,
    required this.firstDayOfMonth,
    required this.isWithinCurrentMonth,
    required this.isHoliday,
    required this.isTest,
  });

  DateTime _calculateDayForCell(int index) {
    int leadingDays = firstDayOfMonth.weekday - 1;
    return firstDayOfMonth
        .subtract(Duration(days: leadingDays))
        .add(Duration(days: index));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.01,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.7,
        ),
        itemCount: 36,
        itemBuilder: (context, index) {
          DateTime day = _calculateDayForCell(index);
          return DayCell(
            onTap: () => onDayTap(context, day),
            date: day,
            isWithinCurrentMonth: isWithinCurrentMonth(day),
            isHoliday: isHoliday(day),
            isTest: isTest(day),
          );
        },
      ),
    );
  }
}
