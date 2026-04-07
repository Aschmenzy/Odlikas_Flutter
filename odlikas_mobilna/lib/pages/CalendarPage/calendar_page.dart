// Glavna datoteka koja sadrži definiciju CalendarPage klase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/services/calendar_service.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/testviewmodel.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/dayDetailsDialog.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/scrollableCalendaer.dart';
import 'package:provider/provider.dart';

// CalendarPage je StatefulWidget koji prima email i lozinku kao parametre
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDate = DateTime.now();
  List<Map<String, dynamic>> _holidays = [];

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  // Funkcija za dohvaćanje praznika iz Firestore baze podataka
  Future<void> _fetchHolidays() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('SchoolHolidays').get();

      setState(() {
        _holidays = snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'startDate': (doc['startDate'] as Timestamp).toDate(),
            'endDate': (doc['endDate'] as Timestamp).toDate(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }

  // Funkcija za provjeru je li dan praznik
  bool _isHoliday(DateTime date) {
    for (var holiday in _holidays) {
      DateTime startDate = holiday['startDate'];
      DateTime endDate = holiday['endDate'];

      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      DateTime normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      DateTime normalizedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day);

      if ((normalizedDate.isAtSameMomentAs(normalizedStartDate) ||
              normalizedDate.isAtSameMomentAs(normalizedEndDate)) ||
          (normalizedDate.isAfter(normalizedStartDate) &&
              normalizedDate.isBefore(normalizedEndDate))) {
        return true;
      }
    }
    return false;
  }

  Future<void> saveEvent({
    required String title,
    required String description,
    required DateTime date,
  }) =>
      CalendarService.saveEvent(
          title: title, description: description, date: date);

  Future<List<Map<String, String>>> _fetchEvents(DateTime date) =>
      CalendarService.fetchEvents(date);

  // Funkcija za provjeru je li datum unutar trenutnog mjeseca
  bool _isWithinCurrentMonth(DateTime date) {
    return date.month == _focusedDate.month;
  }

  // Funkcija za provjeru je li datum ispit
  bool isTest(DateTime date) {
    final viewModel = context.read<TestViewmodel>();
    if (viewModel.tests == null) return false;

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
          return true;
        }
      }
    }
    return false;
  }

  // Funkcija za prikaz detalja dana u popup prozoru
  void _showDayDetailsPopup(BuildContext context, DateTime date) {
    final viewModel = context.read<TestViewmodel>();
    List<Map<String, String>> tests = [];

    // Priprema popisa ispita
    if (viewModel.tests != null) {
      for (var monthTests in viewModel.tests!.testsByMonth.values) {
        for (var test in monthTests) {
          if (test.testDate.isNotEmpty && test.testDate.contains('.')) {
            final dateParts = test.testDate.split('.');
            if (dateParts.length >= 2) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final testDate = DateTime(date.year, month, day);

              if (testDate.year == date.year &&
                  testDate.month == date.month &&
                  testDate.day == date.day) {
                tests.add({
                  'name': test.testName,
                  'description': test.testDescription
                });
              }
            }
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => DayDetailsDialog(
        date: date,
        tests: tests,
        fetchEvents: _fetchEvents,
        saveEvent: saveEvent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TestViewmodel>();
    final screenWidth = MediaQuery.of(context).size.width;

    if (viewModel.tests == null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.fetchTests();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.background,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: screenWidth * 0.09,
          color: AppColors.accent,
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Kalendar",
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'PRAZNICI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.01),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'ISPITI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : viewModel.tests != null
              ? ScrollableCalendar(
                  onDayTap: _showDayDetailsPopup,
                  isWithinCurrentMonth: _isWithinCurrentMonth,
                  isHoliday: _isHoliday,
                  isTest: isTest,
                )
              : const Center(
                  child: Text("No data available"),
                ),
    );
  }
}
