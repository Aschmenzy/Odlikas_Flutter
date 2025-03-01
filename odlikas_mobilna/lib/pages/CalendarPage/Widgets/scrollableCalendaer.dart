import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/dayCell.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/monthHeader.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/weeklyHeader.dart';

class ScrollableCalendar extends StatefulWidget {
  final Function(BuildContext, DateTime) onDayTap;
  final Function(DateTime) isWithinCurrentMonth;
  final Function(DateTime) isHoliday;
  final Function(DateTime) isTest;

  const ScrollableCalendar({
    super.key,
    required this.onDayTap,
    required this.isWithinCurrentMonth,
    required this.isHoliday,
    required this.isTest,
  });

  @override
  State<ScrollableCalendar> createState() => _ScrollableCalendarState();
}

class _ScrollableCalendarState extends State<ScrollableCalendar> {
  late PageController _pageController;
  late DateTime _focusedDate;
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);

    // Initialize the list of months
    DateTime currentDate = DateTime.now();
    DateTime firstMonth = DateTime(currentDate.year, currentDate.month, 1);

    for (int i = 0; i < 12; i++) {
      _months.add(DateTime(
        firstMonth.year,
        firstMonth.month + i,
        1,
      ));
    }

    // Add scroll listener to detect month changes
    _scrollController.addListener(_updateCurrentMonth);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCurrentMonth);
    _scrollController.dispose();
    super.dispose();
  }

  // Estimate visible month based on scroll position
  void _updateCurrentMonth() {
    if (!_scrollController.hasClients) return;

    // Get current scroll position
    double scrollPosition = _scrollController.position.pixels;

    // Estimate which month is currently visible (adjust these values based on your actual layout)
    const double monthHeaderHeight = 70.0; // Height of the month header
    const double calendarMonthHeight =
        350.0; // Approximate height of one month's worth of cells
    const double monthSpacing = 20.0; // Space between months

    double totalMonthHeight =
        monthHeaderHeight + calendarMonthHeight + monthSpacing;

    // Calculate current visible month index
    int currentMonthIndex = scrollPosition ~/ totalMonthHeight;

    // Ensure index is within bounds
    currentMonthIndex =
        math.max(0, math.min(currentMonthIndex, _months.length - 1));

    // Update focused date if it changed
    if (_months[currentMonthIndex].month != _focusedDate.month ||
        _months[currentMonthIndex].year != _focusedDate.year) {
      setState(() {
        _focusedDate = _months[currentMonthIndex];
        print("Month changed to: ${_focusedDate.month}/${_focusedDate.year}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: AppColors.background,
        title: MonthHeader(
          focusedDate: _focusedDate,
          screenWidth: screenWidth,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Column(
            children: [
              const WeekDayHeader(),
              Divider(
                color: AppColors.tertiary,
                thickness: 0.5,
                indent: screenWidth * 0.05,
                endIndent: screenWidth * 0.05,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _months.length,
          itemBuilder: (context, index) {
            final monthDate = _months[index];
            return Column(
              children: [
                if (index >
                    0) // Don't show month header for first month (it's in the app bar)
                  MonthHeader(
                    focusedDate: monthDate,
                    screenWidth: screenWidth,
                  ),
                MonthView(
                  focusedDate: monthDate,
                  screenWidth: screenWidth,
                  onDayTap: widget.onDayTap,
                  firstDayOfMonth: monthDate,
                  isWithinCurrentMonth: (date) =>
                      date.month == monthDate.month &&
                      date.year == monthDate.year,
                  isHoliday: widget.isHoliday,
                  isTest: widget.isTest,
                ),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

// This is a modified version of your CalendarGrid that works with PageView
class MonthView extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime firstDayOfMonth;
  final double screenWidth;
  final Function(BuildContext, DateTime) onDayTap;
  final Function(DateTime) isWithinCurrentMonth;
  final Function(DateTime) isHoliday;
  final Function(DateTime) isTest;

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

  const MonthView({
    super.key,
    required this.focusedDate,
    required this.firstDayOfMonth,
    required this.screenWidth,
    required this.onDayTap,
    required this.isWithinCurrentMonth,
    required this.isHoliday,
    required this.isTest,
  });

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
    return monthNames[date.month - 1];
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
