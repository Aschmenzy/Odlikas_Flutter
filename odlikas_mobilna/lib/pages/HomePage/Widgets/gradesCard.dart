import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'dart:math';
import 'package:odlikas_mobilna/database/models/grades.dart';
import 'package:odlikas_mobilna/pages/SubjectsPage/subjects_page.dart';
import 'package:provider/provider.dart';

class GradesCard extends StatelessWidget {
  final List<Subject> subjects;

  const GradesCard({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    const double xOffset = 2.5;
    Map<String, double> gradePercentages = calculateGradePercentages(subjects);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubjectsPage(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 20, top: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OCJENE',
              style: fontService.font(
                height: 1.1,
                color: AppColors.background,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: screenHeight * 0.007),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.003,
                            color: AppColors.odlican,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          _buildGradeLabel(
                            'Odličan',
                            '${(gradePercentages['5.0'] ?? 0).toStringAsFixed(0)}%',
                            context,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          Container(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.003,
                            color: AppColors.vrloDobar,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          _buildGradeLabel(
                            'Vrlo dobar',
                            '${(gradePercentages['4.0'] ?? 0).toStringAsFixed(0)}%',
                            context,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          Container(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.003,
                            color: AppColors.dobar,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          _buildGradeLabel(
                            'Dobar',
                            '${(gradePercentages['3.0'] ?? 0).toStringAsFixed(0)}%',
                            context,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          Container(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.003,
                            color: AppColors.dovoljan,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          _buildGradeLabel(
                            'Dovoljan',
                            '${(gradePercentages['2.0'] ?? 0).toStringAsFixed(0)}%',
                            context,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          Container(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.003,
                            color: AppColors.nedovoljan,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          _buildGradeLabel(
                            'Nedovoljan',
                            '${(gradePercentages['1.0'] ?? 0).toStringAsFixed(0)}%',
                            context,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: GradesCardPainter(
                            subjects,
                            xOffset,
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.078,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeLabel(
      String label, String percentage, BuildContext context) {
    final fontService = Provider.of<FontService>(context);

    return Padding(
      padding: const EdgeInsets.only(left: 1.5, right: 1.5, top: 1.5),
      child: Row(
        children: [
          Text(
            '$label - ',
            style: fontService.font(
                fontSize: MediaQuery.of(context).size.height * 0.018,
                color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
          Text(
            percentage,
            style: fontService.font(
                fontSize: MediaQuery.of(context).size.height * 0.0185,
                color: Colors.white,
                fontWeight: FontWeight.w600),
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
  final TextStyle? textStyle;

  GradesCardPainter(this.subjects, this.xOffset, {this.textStyle});

  @override
  void paint(Canvas canvas, Size size) {
    // Increase the radius to make the circle larger
    final center = Offset(size.width / xOffset, size.height / 2);
    final radius = size.width / 1.6; // Increased from 1.8 to 1.6 to make larger

    final Map<double, int> gradeCounts = {};
    for (var subject in subjects) {
      if (subject.grade != 'N/A') {
        double grade = double.parse(subject.grade.replaceAll(',', '.'));
        double roundedGrade = (grade >= 4.5) ? 5.0 : grade.roundToDouble();
        gradeCounts[roundedGrade] = (gradeCounts[roundedGrade] ?? 0) + 1;
      }
    }

    final int totalSubjects = gradeCounts.values.fold(0, (a, b) => a + b);
    double startAngle = 0;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.165
      ..strokeCap =
          StrokeCap.butt; // Changed from round to butt for straight ends

    // Draw background circle
    canvas.drawCircle(center, radius, paint);

    // Draw arcs for each grade
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

    // Calculate average grade
    double totalGradePoints = 0;
    int gradedSubjects = 0;

    for (var subject in subjects) {
      if (subject.grade != 'N/A') {
        totalGradePoints += double.parse(subject.grade.replaceAll(',', '.'));
        gradedSubjects++;
      }
    }

    double averageGrade =
        gradedSubjects > 0 ? totalGradePoints / gradedSubjects : 0;

    // Draw average text in the center
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: averageGrade.toStringAsFixed(2),
        style: textStyle ??
            TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.2,
              fontWeight: FontWeight.bold,
            ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center the text exactly in the middle
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  Color getColorForGrade(double grade) {
    if (grade == 5.0) return AppColors.odlican;
    if (grade == 4.0) return AppColors.vrloDobar;
    if (grade == 3.0) return AppColors.dobar;
    if (grade == 2.0) return AppColors.dovoljan;
    return AppColors.nedovoljan;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
