import 'package:flutter/material.dart';
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
  static const int _initialPage =
      1000; // Large number to allow scrolling both ways
  late int _currentPage;
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // Get the month date for a specific page
  DateTime _getMonthForPage(int page) {
    final monthDiff = page - _initialPage;
    return DateTime(
      DateTime.now().year + ((DateTime.now().month - 1 + monthDiff) ~/ 12),
      (DateTime.now().month - 1 + monthDiff) % 12 + 1,
      1,
    );
  }

  // Handle page changes
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _focusedDate = _getMonthForPage(page);
    });
  }

  // Build multiple month views vertically
  List<Widget> _buildMonthViews(BuildContext context, double screenWidth) {
    List<Widget> monthViews = [];

    // Build 12 months starting from current month
    for (int i = 0; i < 12; i++) {
      final monthDate = DateTime(
        _focusedDate.year + (((_focusedDate.month - 1) + i) ~/ 12),
        ((_focusedDate.month - 1) + i) % 12 + 1,
        1,
      );

      monthViews.add(
        Column(
          children: [
            // Month header for each month
            if (i > 0) // Skip the first month header as it's already shown
              MonthHeader(
                focusedDate: monthDate,
                screenWidth: screenWidth,
              ),

            // Month view
            MonthView(
              focusedDate: monthDate,
              screenWidth: screenWidth,
              onDayTap: widget.onDayTap,
              firstDayOfMonth: DateTime(monthDate.year, monthDate.month, 1),
              isWithinCurrentMonth: (date) =>
                  date.month == monthDate.month && date.year == monthDate.year,
              isHoliday: widget.isHoliday,
              isTest: widget.isTest,
            ),

            SizedBox(height: 20), // Space between months
          ],
        ),
      );
    }

    return monthViews;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return CustomScrollView(
      controller: _verticalScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Month header (fixed at top)
              MonthHeader(
                focusedDate: _focusedDate,
                screenWidth: screenWidth,
              ),

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

        // Scrollable months
        SliverList(
          delegate: SliverChildListDelegate(
            _buildMonthViews(context, screenWidth),
          ),
        ),
      ],
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
