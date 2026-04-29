import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/pages/PaywallPage/paywall_modal.dart';

class SubjectSelectionPage extends StatefulWidget {
  const SubjectSelectionPage({super.key});

  @override
  State<SubjectSelectionPage> createState() => _SubjectSelectionPageState();
}

class _SubjectSelectionPageState extends State<SubjectSelectionPage> {
  late Future<Grades> _gradesFuture;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  bool _isSaving = false;
  bool _isOdlikasPlus = false;

  @override
  void initState() {
    super.initState();
    _gradesFuture = ApiService().fetchGrades();
    _loadOdlikasPlus();
  }

  Future<void> _loadOdlikasPlus() async {
    final box = await Hive.openBox('User');
    setState(() {
      _isOdlikasPlus = box.get('isOdlikasPlus') as bool? ?? false;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedSubjectId == null) return;

    setState(() => _isSaving = true);

    try {
      final box = await Hive.openBox('User');
      final email = box.get('email') as String;

      await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(email)
          .set({
        'monitoredSubjectId': _selectedSubjectId,
        'monitoredSubjectName': _selectedSubjectName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await box.put('onboardingDone', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      debugPrint('Error saving subject selection: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri spremanju. Pokušaj ponovno.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.06),
              Text(
                'Odaberi predmet\nza praćenje',
                style: GoogleFonts.inter(
                  fontSize: screenWidth * 0.075,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Odlikaš će ti pratiti ocjene iz odabranog predmeta.',
                style: GoogleFonts.inter(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w400,
                  color: AppColors.tertiary,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                child: FutureBuilder<Grades>(
                  future: _gradesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset(
                          'assets/animations/loadingBird.json',
                          width: screenWidth * 0.8,
                          height: 120,
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Greška pri dohvaćanju predmeta.',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      );
                    }

                    final subjects = snapshot.data!.subjects;

                    return ListView.separated(
                      itemCount: subjects.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: screenHeight * 0.012),
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        final isSelected =
                            _selectedSubjectId == subject.subjectId;

                        return GestureDetector(
                          onTap: () async {
                            final isAlreadySelected = _selectedSubjectId != null &&
                                _selectedSubjectId != subject.subjectId;

                            if (isAlreadySelected && !_isOdlikasPlus) {
                              final upgraded = await PaywallModal.show(context);
                              if (upgraded && mounted) setState(() => _isOdlikasPlus = true);
                              return;
                            }

                            setState(() {
                              _selectedSubjectId = subject.subjectId;
                              _selectedSubjectName = subject.subjectName;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.018,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.tertiary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              subject.subjectName,
                              style: GoogleFonts.inter(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  onPressed: _selectedSubjectId == null || _isSaving
                      ? null
                      : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor:
                        AppColors.tertiary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Nastavi',
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
