// Glavna datoteka koja sadrži definiciju CalendarPage klase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late DateTime _firstDayOfMonth;
  late DateTime _lastDayOfMonth;
  List<Map<String, dynamic>> _holidays = [];

  // Definiranje naziva mjeseci
  final List<String> _monthNames = [
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

  @override
  void initState() {
    // Inicijalno postavljanje prvog i zadnjeg dana mjeseca
    _updateMonth(_focusedDate);
    super.initState();
    // Dohvaćanje praznika iz Firestore baze podataka
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

  // Funkcija za ažuriranje mjeseca
  void _updateMonth(DateTime date) {
    _firstDayOfMonth = DateTime(date.year, date.month, 1);
    _lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
  }

  // Funkcija za prelazak na sljedeći mjesec
  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
      _updateMonth(_focusedDate);
    });
  }

  // Funkcija za prelazak na prethodni mjesec
  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
      _updateMonth(_focusedDate);
    });
  }

  // Funkcija za spremanje događaja u Firestore bazu podataka
  Future<void> saveEvent({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    try {
      final email = Hive.box('User').get('email') as String?;
      await FirebaseFirestore.instance
          .collection('CalendarEvents')
          .doc(email)
          .collection('events')
          .add({
        'title': title,
        'description': description,
        'date': date,
      });

      debugPrint('Event saved successfully');
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  // Funkcija za dohvaćanje događaja iz Firestore baze podataka za određeni datum
  Future<List<Map<String, String>>> _fetchEvents(DateTime date) async {
    try {
      final email = Hive.box('User').get('email') as String?;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('CalendarEvents')
          .doc(email)
          .collection('events')
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'title': doc['title'] as String,
          'description': doc['description'] as String,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  // Funkcija za provjeru je li datum unutar trenutnog mjeseca
  bool _isWithinCurrentMonth(DateTime date) {
    return date.month == _focusedDate.month;
  }

  // Funkcija za izračunavanje dana za određenu ćeliju u kalendaru
  DateTime _calculateDayForCell(int index) {
    int leadingDays = _firstDayOfMonth.weekday - 1;
    return _firstDayOfMonth
        .subtract(Duration(days: leadingDays))
        .add(Duration(days: index));
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

