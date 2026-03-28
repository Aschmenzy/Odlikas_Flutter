import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
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
  //funkcija koja se ucitava prije nego sto se pokaze page
  //dohvacanje lokalnih varijabli poput emaila i lozinke kako bi se koristile za dohvacanje API-a
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<HomePageViewModel>();
      await viewModel.fetchStudentProfile();
      await viewModel.fetchGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();
    final fontService = Provider.of<FontService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      //dok se viewModel ucitava pokazi animaciju
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
              'assets/animations/loadingBird.json',
              width: MediaQuery.of(context).size.width * 0.80,
              height: 120,
            ))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                   // app bar se pokazuje cim se srcolla prema gore
                  floating:
                      true,
                      // Snaps the app bar into view
                  snap: true, 
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 32,
                    color: AppColors.accent,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  centerTitle: true,
                  title: SizedBox(
                    width: screenWidth * 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //tekst koji prikazuje podatke o uceniku
                        Text(
                          viewModel.studentProfile?.studentProgram ??
                              "Loading...",
                          style: fontService.font(
                            color: AppColors.secondary,
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Razrednik/ca: ${viewModel.studentProfile?.classMaster ?? ''}",
                          style: fontService.font(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.009),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.01 +
                        30, 
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
    );
  }
}
