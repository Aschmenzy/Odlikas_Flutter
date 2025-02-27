import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/SpecificSubjectPage/Widgets/evaluationTable.dart';
import 'package:odlikas_mobilna/pages/SpecificSubjectPage/Widgets/finalGrade.dart';
import 'package:odlikas_mobilna/pages/SpecificSubjectPage/Widgets/notesTabe.dart';
import 'package:provider/provider.dart';

class SubjectDetailsPage extends StatefulWidget {
  final String subjectId;

  const SubjectDetailsPage({super.key, required this.subjectId});

  @override
  _SubjectDetailsPageState createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = await Hive.openBox('User');
      final email = await box.get('email');
      final password = await box.get('password');
      final viewModel = context.read<HomePageViewModel>();
      viewModel.fetchSpecificSubjectGrades(
        email,
        password,
        widget.subjectId,
      );
      viewModel.fetchGrades(email, password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final fontService = Provider.of<FontService>(context);

    final selectedSubject = viewModel.grades!.subjects.firstWhere(
      (subject) => subject.subjectId == widget.subjectId,
      orElse: () => Subject(
        subjectName: "N/A",
        grade: "",
        professor: "N/A",
        subjectId: widget.subjectId,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
              'assets/animations/loadingBird.json',
              width: MediaQuery.of(context).size.width * 0.80,
              height: 120,
            ))
          : viewModel.subjectGrades != null &&
                  viewModel.evaluationElements != null
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  iconSize: 30,
                                  color: AppColors.accent,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                            Text(
                              selectedSubject.subjectName,
                              style: fontService.font(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Nastavnik/ca: ${selectedSubject.professor}",
                              style: fontService.font(
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                                color: Color.fromRGBO(113, 113, 113, 1),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Evaluation Elements Table + Zakljuceno
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            EvaluationTable(viewModel: viewModel),
                            ZakljucenoRow(viewModel: viewModel),
                          ],
                        ),
                      ),
                    ),

                    // Notes Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            NotesTable(viewModel: viewModel),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text("No grades available for this subject."),
                ),
    );
  }
}
