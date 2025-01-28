import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/HomePage/Widgets/gradesCard.dart';
import 'package:provider/provider.dart';

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
  @override
  void initState() {
    super.initState();
    fetchGrades(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Dobro došao \nAntonio",
                style: GoogleFonts.inter(
                  height: 1.1,
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.w700,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // Debug container to see the space
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return index == 0
                            ? SizedBox(
                                width: 325,
                                child: GradesCard(
                                    subjects: viewModel.grades?.subjects ?? []),
                              )
                            : SizedBox(
                                width: 300,
                                child: Container(
                                  color: Colors.black,
                                ), // Replace with your new widget
                              );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
