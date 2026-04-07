import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:odlikas_mobilna/pages/HomePage/Widgets/workingIdCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/workingIdModal.dart';
import 'package:odlikas_mobilna/pages/newNotifications/new_notifications_page.dart';
import 'package:odlikas_mobilna/services/calendar_service.dart';
import 'package:odlikas_mobilna/services/notification_service.dart';
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
  String? studentEmail;
  String? studentOib;
  String? studentAddress;
  String? studentPostalCode;
  String? studentCity;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    // Inicijalizacija - dohvaćanje ocjena i podataka o korisniku
    fetchGrades(context).then((_) async {
      final box = await Hive.openBox('User');
      setState(() {
        studentName = box.get('studentName');
        studentEmail = box.get('email');
      });

      await _getStudentIdCardData();
      await _fetchHolidaysData();

      final testViewModel = context.read<TestViewmodel>();
      if (testViewModel.tests == null) {
        await testViewModel.fetchTests();
        setState(() {});
      }
    });

    // Listen for unread notifications via Firestore stream
    _setupNotificationStream();
  }

  void _setupNotificationStream() {
    final email = Hive.box('User').get('email') as String?;
    if (email == null) return;

    _notificationSub = NotificationService.hasUnreadNotifications().listen(
      (hasUnread) {
        if (mounted) setState(() => _hasUnreadNotifications = hasUnread);
      },
    );
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
      print('Error fetching holidays: $e');
    }
  }

  // Prikaz modalnog prozora za unos podataka o studentskoj iskaznici
  void _showStudentIdModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      context: context,
      builder: (context) => StudentIdModal(
        // Obrada nakon predaje forme
        onSubmit: (formData) async {
          final box = await Hive.openBox('User');
          final email = box.get('email');

          if (email == null) {
            print('Error: No email found in local storage');
            return;
          }

          try {
            // Spremanje podataka o iskaznici u Firestore
            // Podaci se spremaju u kolekciju workingID
            //kao podmapa workingId
            await FirebaseFirestore.instance
                .collection('workingID')
                .doc(email)
                .set({
              'workingId': {
                'oib': formData['oib'],
                'address': formData['address'],
                'postalCode': formData['postalCode'],
                'city': formData['city'],
                'createdAt': FieldValue.serverTimestamp(),
              },
            }, SetOptions(merge: true));

            // Osvježavanje podataka nakon spremanja
            await _getStudentIdCardData();

            // Prikaz poruke o uspjehu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Podaci su uspješno spremljeni'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('Error saving student ID data: $e');
            // Prikaz poruke o grešci
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Greška pri spremanju podataka'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  // Dohvaćanje podataka o studentskoj iskaznici iz Firebase-a
  Future<Map<String, dynamic>?> _getStudentIdCardData() async {
    final box = await Hive.openBox('User');
    final email = box.get('email');

    if (email == null) {
      print('Error: No email found in local storage');
      return null;
    }

    try {
      // Dohvaćanje dokumenta iz Firestore-a
      final doc = await FirebaseFirestore.instance
          .collection('workingID')
          .doc(email)
          .get();

      if (doc.exists && doc.data()?['workingId'] != null) {
        final workingIdData = doc.data()!['workingId'] as Map<String, dynamic>;

        // Ažuriranje stanja s podacima
        setState(() {
          studentOib = workingIdData['oib'];
          studentAddress = workingIdData['address'];
          studentPostalCode = workingIdData['postalCode'];
          studentCity = workingIdData['city'];
        });

        return workingIdData;
      } else {
        print('No working ID data found for this user');
        return null;
      }
    } catch (e) {
      print('Error fetching student ID data: $e');
      return null;
    }
  }

  // Odabrani datum
  DateTime _selectedDate = DateTime.now();

  // Funkcija koja se poziva kada korisnik odabere datum
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
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
      CalendarService.saveEvent(title: title, description: description, date: date);

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

  bool _hasUnreadNotifications = false;

  Widget _notificationIcon() {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewNotificationsPage()),
        );
      },
      icon: _hasUnreadNotifications
          ? Icon(
              Icons.notifications_active,
              color: AppColors.accent,
              size: 40,
            )
          : Icon(
              Icons.notifications_none,
              color: AppColors.primary,
              size: 40,
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
                  // Horizontalna lista kartica (ocjene i studentska iskaznica)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: size.height * 0.235,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 2,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return index == 0
                                ? SizedBox(
                                    // Kartica s ocjenama
                                    width: size.width * 0.835,
                                    child: GradesCard(
                                        subjects:
                                            viewModel.grades?.subjects ?? []),
                                  )
                                : GestureDetector(
                                    // Kartica s podacima studentske iskaznice
                                    onTap: () => _showStudentIdModal(context),
                                    child: SizedBox(
                                      width: size.width * 0.8,
                                      child: Workingidcard(
                                        name: studentName,
                                        oib: studentOib,
                                        address: studentAddress,
                                        postalCode: studentPostalCode,
                                        city: studentCity,
                                      ),
                                    ),
                                  );
                          },
                        ),
                      );
                    },
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
