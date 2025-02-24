import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:odlikas_mobilna/database/models/testviewmodel.dart';

class HorizontalCalendarWidget extends StatefulWidget {
  final Function(BuildContext, DateTime) onDayTap;
  final Function(DateTime) isHoliday;
  final Function(DateTime) isTest;

  const HorizontalCalendarWidget({
    Key? key,
    required this.onDayTap,
    required this.isHoliday,
    required this.isTest,
  }) : super(key: key);

  @override
  _HorizontalCalendarWidgetState createState() =>
      _HorizontalCalendarWidgetState();
}

class _HorizontalCalendarWidgetState extends State<HorizontalCalendarWidget> {
  late PageController _pageController;
  late List<DateTime> _datesInView;
  late int _currentPage;
  late int _todayIndex;

  @override
  void initState() {
    super.initState();
    _initDates();
    // Set current page to today's index
    _currentPage = _todayIndex;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.33,
    );
  }

  void _initDates() {
    final DateTime now = DateTime.now();
    // Generate dates centered around today (10 days before and 10 days after)
    _datesInView = List.generate(
      21,
      (index) => now.subtract(Duration(days: 10)).add(Duration(days: index)),
    );
    // Find today's index in the list
    _todayIndex = _datesInView.indexWhere((date) => _isToday(date));
    if (_todayIndex == -1) {
      // Fallback if today isn't found for some reason
      _todayIndex = 10;
    }
  }

  void _updateDatesForward() {
    setState(() {
      final lastDate = _datesInView.last;
      _datesInView = List.generate(
        21,
        (index) => lastDate.add(Duration(days: index - 6)),
      );
    });
  }

  void _updateDatesBackward() {
    setState(() {
      final firstDate = _datesInView.first;
      _datesInView = List.generate(
        21,
        (index) => firstDate.subtract(Duration(days: 14 - index)),
      );
    });
  }

  void _onPageChanged(int page) {
    if (page < _currentPage) {
      // Scrolled left
      if (page == 0) {
        _updateDatesBackward();
        _pageController.jumpToPage(7);
        _currentPage = 7;
      } else {
        _currentPage = page;
      }
    } else if (page > _currentPage) {
      // Scrolled right
      if (page == 20) {
        _updateDatesForward();
        _pageController.jumpToPage(13);
        _currentPage = 13;
      } else {
        _currentPage = page;
      }
    }
  }

  // Get the appropriate background color for a date card
  Color _getCardColor(DateTime date) {
    final isToday = _isToday(date);

    if (widget.isTest(date)) {
      return AppColors.accent;
    } else if (widget.isHoliday(date)) {
      // Highlight holidays with a light blue or other color
      return Colors.lightBlue.shade100;
    } else if (isToday) {
      return Colors.grey.shade200;
    }

    return Colors.white;
  }

  Color _getTextColor(DateTime date) {
    if (widget.isTest(date)) {
      return Colors.white;
    }

    return AppColors.secondary;
  }

  // Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Get test subject for a date from TestViewModel
  String _getSubjectForDate(DateTime date) {
    final viewModel = Provider.of<TestViewmodel>(context, listen: false);
    if (viewModel.tests == null) return '';

    for (var monthTests in viewModel.tests!.testsByMonth.values) {
      for (var test in monthTests) {
        if (test.testDate.isEmpty || !test.testDate.contains('.')) continue;

        final dateParts = test.testDate.split('.');
        if (dateParts.length < 2) continue;

        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final testDate = DateTime(date.year, month, day);

        if (testDate.year == date.year &&
            testDate.month == date.month &&
            testDate.day == date.day) {
          return '${test.testName} - ispit';
        }
      }
    }
    return '';
  }

  // Get month name
  String _getMonthName(DateTime date) {
    final monthNames = [
      'SIJEČANJ',
      'VELJAČA',
      'OŽUJAK',
      'TRAVANJ',
      'SVIBANJ',
      'LIPANJ',
      'SRPANJ',
      'KOLOVOZ',
      'RUJAN',
      'LISTOPAD',
      'STUDENI',
      'PROSINAC'
    ];

    return monthNames[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with month name
            Container(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left-aligned "Kalendar" text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kalendar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  // Centered month name
                  Text(
                    _getMonthName(_datesInView[_currentPage]),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendar cards
            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _datesInView.length,
                itemBuilder: (context, pageIndex) {
                  final date = _datesInView[pageIndex];
                  return _buildDateCard(date, true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(DateTime date, bool isCenter) {
    final hasTest = widget.isTest(date);
    final backgroundColor = _getCardColor(date);
    final textColor = _getTextColor(date);
    final testSubject = _getSubjectForDate(date);

    return GestureDetector(
      onTap: () => widget.onDayTap(context, date),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCenter ? AppColors.accent : AppColors.secondary,
            width: isCenter ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date.day.toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (hasTest && testSubject.isNotEmpty)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 16,
                      color: Colors.white,
                      margin: EdgeInsets.only(right: 6),
                    ),
                    Expanded(
                      child: Text(
                        testSubject,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
