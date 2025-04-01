import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Horizontalna verzija widgeta za prikaz niza napretka
class HorizontalStreakProgress extends StatelessWidget {
  final int daysLearning;
  final int hoursLearning;
  final int streakCount;
  final Color color;
  final VoidCallback? onTap;

  const HorizontalStreakProgress({
    super.key,
    required this.daysLearning,
    required this.hoursLearning,
    required this.streakCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (daysLearning == 0 || hoursLearning == 0) return const SizedBox.shrink();

    // Izracunaj sesije po danu - koliko 30-minutnih pomodoro sesija cini dnevni cilj
    final double sessionsPerDay = (hoursLearning * 60) / 30;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size.width * 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(daysLearning, (index) {
            // Izracunaj kolicinu popunjenosti za ovaj dan na temelju broja niza
            final double start = index * sessionsPerDay;
            final double end = (index + 1) * sessionsPerDay;
            double fill = 0.0;

            if (streakCount >= end) {
              fill = 1.0; // Dan je potpuno ispunjen
            } else if (streakCount > start) {
              fill = (streakCount - start) / sessionsPerDay;
              fill = fill.clamp(0.0, 1.0); // Djelomicno ispunjeno
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: CircleProgressPainter(
                    progress: fill,
                    backgroundColor: Colors.white,
                    fillColor: Colors.white,
                    numberColor: color,
                    number: fill == 1.0 ? index + 1 : null,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// Crtac krugova za prikaz napretka - prilagodjen za horizontalni raspored
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color fillColor;
  final int? number;
  final Color numberColor;

  CircleProgressPainter({
    required this.progress,
    this.backgroundColor = Colors.grey,
    required this.fillColor,
    this.number,
    required this.numberColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // Nacrtaj ispunjeni dio s lijeva na desno
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      // Izracunaj sirinu ispunjenog dijela
      final filledWidth = size.width * progress;

      canvas.save();
      canvas.clipRect(Rect.fromLTRB(
        0, // Pocni s lijeve strane
        0,
        filledWidth, // Ispuni do izracunate sirine
        size.height,
      ));

      // Nacrtaj ispunjeni krug
      canvas.drawCircle(center, radius, fillPaint);
      canvas.restore();
    }

    // Nacrtaj broj u sredini ako je krug ispunjen
    if (number != null && progress == 1.0) {
      final textStyle = TextStyle(
        color: numberColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(
        text: number.toString(),
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Centriraj tekst
      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Nacrtaj obrub
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, backgroundPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is CircleProgressPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.fillColor != fillColor);
  }
}
