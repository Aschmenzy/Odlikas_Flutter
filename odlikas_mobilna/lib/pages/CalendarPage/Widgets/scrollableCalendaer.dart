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

    // Estimate which month is currently visible
    const double monthHeaderHeight = 70.0; // Height of the month header
    const double calendarMonthHeight = 350.0; // Approximate height of calendar
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
                _buildCalendarMonth(context, monthDate),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarMonth(BuildContext context, DateTime month) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = (screenWidth * 0.9) / 7; // Equal width for all 7 days
    final cellHeight =
        cellWidth * 1.4; // Use aspect ratio of 0.7 (same as original)

    // Get the number of days in the month
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Get the first day of the month
    final firstDay = DateTime(month.year, month.month, 1);

    // Calculate the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDay.weekday;

    // Build calendar cells - one for each day of the month
    List<Widget> calendarRows = [];
    List<Widget> weekRow = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      weekRow.add(
        SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: Container(),
        ),
      );
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);

      weekRow.add(
        SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: DayCell(
            onTap: () => widget.onDayTap(context, date),
            date: date,
            isWithinCurrentMonth: true,
            isHoliday: widget.isHoliday(date),
            isTest: widget.isTest(date),
          ),
        ),
      );

      // Start a new row when we reach Sunday or the end of the month
      if ((firstWeekday + day - 1) % 7 == 0 || day == daysInMonth) {
        // If we're at the end of the month but not Sunday, add empty cells to complete the week
        if (day == daysInMonth && (firstWeekday + day - 1) % 7 != 0) {
          final remainingDays = 7 - ((firstWeekday + day - 1) % 7);
          for (int i = 0; i < remainingDays; i++) {
            weekRow.add(
              SizedBox(
                width: cellWidth,
                height: cellHeight,
                child: Container(),
              ),
            );
          }
        }

        // Add the completed row with proper spacing
        calendarRows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [...weekRow],
          ),
        );

        // Clear the week row for the next week
        weekRow = [];
      }
    }

    // Return the calendar grid
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
      ),
      child: Column(
        children: calendarRows,
      ),
    );
  }
}
