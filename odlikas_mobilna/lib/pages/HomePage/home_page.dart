import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/testviewmodel.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/Widgets/dayDetailsDialog.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/calendar_page.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/calendarWidget.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/gradesCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/gradivoCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/scheduleCard.dart';
import 'package:odlikas_mobilna/pages/newNotifications/new_notifications_page.dart';
import 'package:odlikas_mobilna/services/calendar_service.dart';
import 'package:odlikas_mobilna/services/notification_service.dart';
import 'package:odlikas_mobilna/services/study_notifications_service.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<Grades?> fetchGrades(BuildContext context) async {
  return (await context.read<HomePageViewModel>().fetchGrades()) as Grades?;
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _holidays = [];
  String? studentName;
  StreamSubscription? _notificationSub;
  int _unreadCount = 0;
  int _pendingTasksCount = 0;

  @override
  void initState() {
    super.initState();
    // Inicijalizacija - dohvaćanje ocjena i podataka o korisniku
    fetchGrades(context).then((_) async {
      final box = await Hive.openBox('User');
      if (!mounted) return;
      setState(() {
        studentName = box.get('studentName');
      });

      await _fetchHolidaysData();

      if (!mounted) return;
      final testViewModel = context.read<TestViewmodel>();
      if (testViewModel.tests == null) {
        await testViewModel.fetchTests();
        if (mounted) setState(() {});
      }
    });

    _setupNotificationStream();
    _fetchPendingTasksCount();
  }

  void _setupNotificationStream() {
    final email = Hive.box('User').get('email') as String?;
    if (email == null) return;

    _notificationSub = NotificationService.unreadCount().listen(
      (n) {
        if (mounted) setState(() => _unreadCount = n);
      },
    );
  }

  Future<void> _fetchPendingTasksCount() async {
    try {
      final tasks = await StudyNotificationsService().getPendingTasks();
      if (mounted) setState(() => _pendingTasksCount = tasks.length);
    } catch (_) {
      // non-fatal — badge just won't include pending tasks
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  // Nova metoda za dohvaćanje podataka o praznicima
  Future<void> _fetchHolidaysData() async {
    try {
      // Prilagodite ovo vašoj strukturi baze za praznike
      final holidaysSnapshot =
          await FirebaseFirestore.instance.collection('SchoolHolidays').get();

      List<Map<String, dynamic>> holidays = [];

      for (var doc in holidaysSnapshot.docs) {
        var data = doc.data();
        holidays.add({
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
          'name': data['name'] as String,
        });
      }

      setState(() {
        _holidays = holidays;
      });
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }

  // Provjera je li određeni datum praznik
  bool _isHoliday(DateTime date) {
    for (var holiday in _holidays) {
      DateTime startDate = holiday['startDate'];
      DateTime endDate = holiday['endDate'];

      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      DateTime normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      DateTime normalizedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day);

      // Provjera je li datum unutar perioda praznika
      if ((normalizedDate.isAtSameMomentAs(normalizedStartDate) ||
              normalizedDate.isAtSameMomentAs(normalizedEndDate)) ||
          (normalizedDate.isAfter(normalizedStartDate) &&
              normalizedDate.isBefore(normalizedEndDate))) {
        return true;
      }
    }
    return false;
  }

  // Provjera je li određeni datum test
  bool _isTest(DateTime date) {
    final viewModel = context.read<TestViewmodel>();
    if (viewModel.tests == null) return false;

    // Iteracija kroz sve testove
    for (var monthTests in viewModel.tests!.testsByMonth.values) {
      for (var test in monthTests) {
        if (test.testDate.isEmpty || !test.testDate.contains('.')) continue;

        // Parsiranje datuma testa
        final dateParts = test.testDate.split('.');
        if (dateParts.length < 2) continue;

        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final testDate = DateTime(date.year, month, day);

        // Provjera podudara li se datum s datumom testa
        if (testDate.year == date.year &&
            testDate.month == date.month &&
            testDate.day == date.day) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<Map<String, String>>> _fetchEvents(DateTime date) =>
      CalendarService.fetchEvents(date);

  Future<void> saveEvent({
    required String title,
    required String description,
    required DateTime date,
  }) =>
      CalendarService.saveEvent(
          title: title, description: description, date: date);

  // Prikaz pop-up dijaloga s detaljima odabranog dana
  void _showDayDetailsPopup(BuildContext context, DateTime date) {
    final viewModel = context.read<TestViewmodel>();
    List<Map<String, String>> tests = [];

    // Priprema liste testova za odabrani datum
    if (viewModel.tests != null) {
      for (var monthTests in viewModel.tests!.testsByMonth.values) {
        for (var test in monthTests) {
          if (test.testDate.isNotEmpty && test.testDate.contains('.')) {
            final dateParts = test.testDate.split('.');
            if (dateParts.length >= 2) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final testDate = DateTime(date.year, month, day);

              // Provjera podudara li se datum testa s odabranim datumom
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

    // Prikaz dijaloga s detaljima dana
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

  Widget _notificationIcon() {
    final totalCount = _unreadCount + _pendingTasksCount;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewNotificationsPage()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            totalCount > 0
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: totalCount > 0 ? AppColors.accent : AppColors.primary,
            size: 40,
          ),
          if (totalCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  totalCount > 99 ? '99+' : '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final size = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: viewModel.isLoading
          ? Center(
              // Prikaz animacije učitavanja
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: MediaQuery.of(context).size.width * 0.80,
                height: 120,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // Razmak
                  // Pozdravna poruka s imenom studenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dobrodošao/la, \n$studentName",
                        style: fontService.font(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          color: AppColors.secondary,
                        ),
                      ),
                      _notificationIcon(),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  SizedBox(
                    height: size.height * 0.235,
                    child: GradesCard(subjects: viewModel.grades?.subjects ?? []),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  // Red s karticama za raspored i gradivo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [ScheduleCard(), GradivoCard()],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  // Widget kalendara s mogućnošću navigacije na stranicu kalendara
                  GestureDetector(
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalendarPage()),
                          ),
                      child: HorizontalCalendarWidget(
                        onDayTap: _showDayDetailsPopup,
                        isHoliday: _isHoliday,
                        isTest: _isTest,
                      )),
                ],
              ),
            ),
      // Donja navigacijska traka s aktivnim prvim elementom (Home)
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }
}
