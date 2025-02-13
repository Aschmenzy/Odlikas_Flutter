import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/CalendarPage/calendar_page.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/gradesCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/gradivoCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/scheduleCard.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/workingIdCard.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<Grades?> fetchGrades(BuildContext context) async {
  final homeViewModel = context.read<HomePageViewModel>();
  final box = await Hive.openBox('User');
  final email = await box.get('email');
  final password = await box.get('password');

  var grades = await homeViewModel.fetchGrades(email, password);
  return grades;
}

class _HomePageState extends State<HomePage> {
  String? studentName;
  String? studentEmail;
  String? studentPassword;

  @override
  void initState() {
    super.initState();
    fetchGrades(context).then((_) async {
      final box = await Hive.openBox('User');
      var name = box.get('studentName');
      var email = box.get('email');
      var password = box.get('password');
      setState(() {
        studentName = name;
        studentPassword = password;
        studentEmail = email;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: MediaQuery.of(context).size.width * 0.80,
                height: 120,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Dobrodošao/la, \n$studentName",
                      style: GoogleFonts.inter(
                          height: 1.1,
                          fontSize: MediaQuery.of(context).size.width * 0.07,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                    // Debug container to see the space
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: screenHeight * 0.25,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 2,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return index == 0
                                  ? SizedBox(
                                      width: screenWidth * 0.8,
                                      child: GradesCard(
                                          subjects:
                                              viewModel.grades?.subjects ?? []),
                                    )
                                  : SizedBox(
                                      width: screenWidth * 0.8,
                                      child: Workingidcard(),
                                    );
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [ScheduleCard(), GradivoCard()],
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CalendarPage(
                                  email: studentEmail ?? '',
                                  password: studentPassword ?? '',
                                )),
                      ),
                      child: Container(
                        color: AppColors.accent,
                        width: screenWidth,
                        height: screenHeight * 0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }
}
