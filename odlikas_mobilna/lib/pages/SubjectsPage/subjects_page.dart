import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/SubjectsPage/Widgets/gradesTile.dart';
import 'package:provider/provider.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = await Hive.openBox('User');
      final email = await box.get('email');
      final password = await box.get('password');
      final viewModel = context.read<HomePageViewModel>();
      await viewModel.fetchStudentProfile(email, password);
      await viewModel.fetchGrades(email, password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            iconSize: 30,
                            color: AppColors.accent,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),

                              //student program and class master
                              SizedBox(
                                width: screenWidth * 0.7,
                                child: Text(
                                  viewModel.studentProfile?.studentProgram ??
                                      "Loading...",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Razrednik/ca: ${viewModel.studentProfile?.classMaster ?? ''}",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromRGBO(113, 113, 113, 1),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenWidth * 0.009),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                      vertical: screenHeight * 0.01,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        crossAxisSpacing: screenWidth * 0.04,
                        mainAxisSpacing: screenHeight * 0.015,
                        childAspectRatio: screenHeight * 0.0052,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = viewModel.grades?.subjects[index];
                          return subject != null
                              ? GradeTile(
                                  subjectName: subject.subjectName,
                                  professor: subject.professor,
                                  grade: subject.grade,
                                  subjectId: subject.subjectId,
                                )
                              : const SizedBox.shrink();
                        },
                        childCount: viewModel.grades?.subjects.length ?? 0,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
    );
  }
}
