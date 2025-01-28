import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'dart:math';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/pages/SubjectsPage/subjects_page.dart';

class GradesCard extends StatelessWidget {
  final List<Subject> subjects;

  const GradesCard({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    const double xOffset = 2.5;
    double averageGrade = calculateAverageGrade(subjects);
    Map<String, double> gradePercentages = calculateGradePercentages(subjects);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubjectsPage(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OCJENE',
              style: TextStyle(
                height: 1.1,
                color: AppColors.background,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGradeLabel(
                        'Odličan',
                        '${(gradePercentages['5.0'] ?? 0).toStringAsFixed(0)}%',
                      ),
                      _buildGradeLabel(
                        'Vrlo dobar',
                        '${(gradePercentages['4.0'] ?? 0).toStringAsFixed(0)}%',
                      ),
                      _buildGradeLabel(
                        'Dobar',
                        '${(gradePercentages['3.0'] ?? 0).toStringAsFixed(0)}%',
                      ),
                      _buildGradeLabel(
                        'Dovoljan',
                        '${(gradePercentages['2.0'] ?? 0).toStringAsFixed(0)}%',
                      ),
                      _buildGradeLabel('Nedovoljan',
                          '${(gradePercentages['1.0'] ?? 0).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: GradesCardPainter(subjects,
                              xOffset), // Pass the offset to the painter
                        ),
                        Transform.translate(
                          offset: Offset(-((180 / xOffset) - 120 / 2), 0),
                          child: Text(
                            averageGrade.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeLabel(String label, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label - ',
            style: GoogleFonts.inter(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800),
          ),
          Text(
            percentage,
            style: GoogleFonts.inter(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Map<String, double> calculateGradePercentages(List<Subject> subjects) {
    Map<String, int> gradeCounts = {};
    int totalGrades = 0;

    for (var subject in subjects) {
      if (subject.grade != 'N/A') {
        double grade = double.parse(subject.grade.replaceAll(',', '.'));
        double roundedGrade = roundGradeCroatian(grade);
        String gradeKey = roundedGrade.toStringAsFixed(1);
        gradeCounts[gradeKey] = (gradeCounts[gradeKey] ?? 0) + 1;
        totalGrades++;
      }
    }

    Map<String, double> percentages = {};
    gradeCounts.forEach((grade, count) {
      percentages[grade] = (count / totalGrades) * 100;
    });

    return percentages;
  }

  double calculateAverageGrade(List<Subject> subjects) {
    double totalGrades = 0.0;
    int count = 0;

    for (var subject in subjects) {
      if (subject.grade != 'N/A') {
        double grade = double.parse(subject.grade.replaceAll(',', '.'));
        double roundedGrade = roundGradeCroatian(grade);
        totalGrades += roundedGrade;
        count++;
      }
    }

    return count > 0 ? totalGrades / count : 0.0;
  }

  double roundGradeCroatian(double grade) {
    return (grade >= 4.5) ? 5.0 : grade.roundToDouble();
  }
}

class GradesCardPainter extends CustomPainter {
  final List<Subject> subjects;
  final double xOffset;

  GradesCardPainter(this.subjects, this.xOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / xOffset, size.height / 2);
    final radius = size.width / 1.8;

    final Map<double, int> gradeCounts = {};
    for (var subject in subjects) {
      if (subject.grade != 'N/A') {
        double grade = double.parse(subject.grade.replaceAll(',', '.'));
        double roundedGrade = (grade >= 4.5) ? 5.0 : grade.roundToDouble();
        gradeCounts[roundedGrade] = (gradeCounts[roundedGrade] ?? 0) + 1;
      }
    }

    final int totalSubjects = gradeCounts.values.fold(0, (a, b) => a + b);
    double startAngle = -pi / 2;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.165
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);

    gradeCounts.forEach((grade, count) {
      final sweepAngle = (count / totalSubjects) * 2 * pi;
      paint.color = getColorForGrade(grade);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    });
  }

  Color getColorForGrade(double grade) {
    if (grade == 5.0) return Colors.green;
    if (grade == 4.0) return Colors.yellow;
    if (grade == 3.0) return Colors.orange;
    if (grade == 2.0) return Colors.red;
    return Colors.red.shade900;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
