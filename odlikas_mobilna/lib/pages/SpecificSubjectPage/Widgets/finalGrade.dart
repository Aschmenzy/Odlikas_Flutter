import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

class ZakljucenoRow extends StatelessWidget {
  const ZakljucenoRow({super.key, required this.viewModel});

  final HomePageViewModel viewModel;

  double _calculateAverageGrade(HomePageViewModel viewModel) {
    final List<double> allGrades = [];

    for (final element in viewModel.evaluationElements ?? []) {
      for (final gradeString in element.gradesByMonth) {
        if (gradeString.isNotEmpty) {
          final parsed = double.tryParse(gradeString);
          if (parsed != null) {
            allGrades.add(parsed);
          }
        }
      }
    }

    return allGrades.isEmpty
        ? 0
        : allGrades.reduce((a, b) => a + b) / allGrades.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromRGBO(113, 113, 113, 1),
          width: 0.4,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          // Average grade row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'PROSJEK OCJENA: ',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.secondary),
                ),
                const SizedBox(width: 4),
                Text(
                  _calculateAverageGrade(viewModel).toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.info_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            thickness: 0.4,
            color: AppColors.secondary,
          ),

          // Final grade row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'ZAKLJUČENO: ',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.secondary),
                ),
                const SizedBox(width: 4),
                Text(
                  viewModel.finalGrade ?? '--',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
