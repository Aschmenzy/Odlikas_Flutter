import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/dayCell.dart';
import 'package:intl/intl.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime focusedDate;
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
    required this.focusedDate,
  });

  static const List<String> monthNames = [
    'SIJ',
    'VELJ',
    'OŽU',
    'TRA',
    'SVI',
    'LIP',
    'SRP',
    'KOL',
    'RUJ',
    'LIS',
    'STU',
    'PRO'
  ];

  Map<String, int> _calculatePositions() {
    int startOffset = firstDayOfMonth.weekday - 1;

    // Define target positions for each weekday (1 = Monday, 7 = Sunday)
    Map<int, int> targetPositions = {
      1: 14, // Monday -> position 14
      2: 1, // Tuesday -> position 1
      3: 2, // Wednesday -> position 2
      4: 3, // Thursday -> position 3
      5: 4, // Friday -> position 4
      6: 5, // Saturday -> position 5
      7: 6, // Sunday -> position 6
    };

    int desiredPosition = targetPositions[firstDayOfMonth.weekday] ?? 0;
    int currentPosition = startOffset;
    int emptySpacesNeeded;

    // Calculate needed empty spaces
    if (desiredPosition > currentPosition) {
      emptySpacesNeeded = desiredPosition - currentPosition;
    } else {
      emptySpacesNeeded = (7 - currentPosition) + desiredPosition;
    }

    // Calculate label column based on where first day will actually appear
    int labelColumn = (startOffset + emptySpacesNeeded) % 7;

    return {
      'startOffset': startOffset,
      'desiredPosition': desiredPosition,
      'emptySpacesNeeded': emptySpacesNeeded,
      'labelColumn': labelColumn,
    };
  }

  List<Widget> _buildCalendarCells(
      BuildContext context, Map<String, int> positions) {
    List<Widget> cells = [];

    // Add cells for previous month's days
    for (int i = 0; i < positions['startOffset']!; i++) {
      DateTime day = firstDayOfMonth
          .subtract(Duration(days: positions['startOffset']! - i));
      cells.add(DayCell(
        onTap: () => onDayTap(context, day),
        date: day,
        isWithinCurrentMonth: isWithinCurrentMonth(day),
        isHoliday: isHoliday(day),
        isTest: isTest(day),
      ));
    }

    // Add empty spaces
    for (int i = 0; i < positions['emptySpacesNeeded']!; i++) {
      cells.add(Container());
    }

    // Add remaining days
    int remainingCells = 42 - cells.length;
    for (int i = 0; i < remainingCells; i++) {
      DateTime day = firstDayOfMonth.add(Duration(days: i));
      cells.add(DayCell(
        onTap: () => onDayTap(context, day),
        date: day,
        isWithinCurrentMonth: isWithinCurrentMonth(day),
        isHoliday: isHoliday(day),
        isTest: isTest(day),
      ));
    }

    return cells;
  }

  String _getMonthLabel(DateTime date) {
    return monthNames[focusedDate.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final positions = _calculatePositions();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.01,
      ),
      child: Column(
        children: [
          // Month label row
          SizedBox(
            height: 20,
            child: Row(
              children: List.generate(7, (index) {
                if (index == positions['labelColumn']) {
                  return Expanded(
                    child: Text(
                      _getMonthLabel(firstDayOfMonth),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }
                return const Expanded(child: SizedBox());
              }),
            ),
          ),
          // Calendar grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 0.7,
            children: _buildCalendarCells(context, positions),
          ),
        ],
      ),
    );
  }
}
