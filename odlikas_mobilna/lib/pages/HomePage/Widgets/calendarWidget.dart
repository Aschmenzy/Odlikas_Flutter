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
      'Siječanj',
      'Veljača',
      'Ožujak',
      'Travanj',
      'Svibanj',
      'Lipanj',
      'Srpanj',
      'Kolovoz',
      'Rujan',
      'Listopad',
      'Studeni',
      'Prosinac'
    ];

    return monthNames[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: AppColors.tertiary,
      child: Container(
        height: 153,
        width: size.width * 0.9,
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            // Header with Kalendar and month name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left-aligned "Kalendar" text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kalendar',
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.03,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Centered month name
                  Text(
                    _getMonthName(_datesInView[_currentPage]),
                    style: GoogleFonts.inter(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Calendar cards with PageView
            SizedBox(
              height: 90,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _datesInView.length,
                itemBuilder: (context, pageIndex) {
                  final date = _datesInView[pageIndex];
                  final isSelected = pageIndex == _currentPage;
                  final hasTest = widget.isTest(date);
                  final testSubject = _getSubjectForDate(date);

                  // Determine card color based on selection and test status
                  Color cardColor;
                  if (hasTest) {
                    cardColor = AppColors.accent;
                  } else {
                    cardColor = AppColors.background;
                  }

                  // Determine text color based on selection or test
                  final textColor = hasTest
                      ? AppColors.background
                      : (isSelected ? AppColors.accent : AppColors.secondary);

                  return GestureDetector(
                    onTap: () => widget.onDayTap(context, date),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.tertiary,
                          width: 0.75,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isSelected && testSubject.isNotEmpty)
                            Expanded(
                              child: Text(
                                testSubject,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          //show if there is a test
                          if (hasTest && testSubject.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    height: 8,
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: textColor,
                                      shape: BoxShape.rectangle,
                                    ),
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
                },
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
