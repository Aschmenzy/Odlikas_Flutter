import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:odlikas_mobilna/services/pomodoro_notifier.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/Widgets/pomodoroContainer.dart';
import 'package:provider/provider.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  @override
  void initState() {
    super.initState();
    // Refresh streak data each time the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroNotifier>().init();
    });
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Pomodoro':
        return const Color.fromRGBO(236, 146, 31, 1);
      case 'Kratka pauza':
        return const Color.fromRGBO(23, 148, 210, 1);
      default:
        return const Color.fromRGBO(20, 133, 186, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Consumer<PomodoroNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isLoadingStreak) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: screenSize.width * 0.80,
                height: 120,
              ),
            ),
          );
        }

        final phaseColor = _phaseColor(notifier.currentPhase);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(height: screenSize.height * 0.05),
                      Center(
                        child: Text(
                          'Pomodoro mjerač vremena',
                          style: fontService.font(
                            fontSize: screenSize.width * 0.06,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Streak + session icons ──
                        _buildSessionRow(context, notifier, phaseColor, fontService),
                        SizedBox(height: screenSize.height * 0.02),

                        // ── Timer widget ──
                        PomodoroContainer(
                          currentPhase: notifier.currentPhase,
                          currentDuration: Duration(seconds: notifier.secondsNotifier.value),
                          isRunning: notifier.timerState == PomodoroTimerState.running,
                          secondsNotifier: notifier.secondsNotifier,
                          isDisabled: notifier.isCapped,
                          startTimer: notifier.start,
                          stopTimer: notifier.pause,
                          forwardTimer: notifier.skipToNext,
                        ),

                        SizedBox(height: screenSize.height * 0.02),

                        // ── Cycle count ──
                        Text(
                          '#${notifier.cycleCount + 1}',
                          style: fontService.font(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: phaseColor,
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.01),

                        // ── Phase hint ──
                        Text(
                          notifier.currentPhase == 'Pomodoro'
                              ? 'Vrijeme je za učiti!'
                              : 'Vrijeme je za pauzu!',
                          style: fontService.font(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),

                        // ── Cap message ──
                        if (notifier.isCapped) ...[
                          SizedBox(height: screenSize.height * 0.015),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Dostignut dnevni maksimum (${PomodoroNotifier.dailyCap}/${PomodoroNotifier.dailyCap})',
                              style: fontService.font(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: phaseColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        // ── API error ──
                        if (notifier.sessionError != null) ...[
                          SizedBox(height: screenSize.height * 0.015),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              notifier.sessionError!,
                              style: fontService.font(
                                fontSize: 13,
                                color: Colors.red.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        SizedBox(height: screenSize.height * 0.03),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildSessionRow(
    BuildContext context,
    PomodoroNotifier notifier,
    Color phaseColor,
    FontService fontService,
  ) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: phaseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Streak text
          Text(
            'Streak: ${notifier.currentStreak} dana',
            style: fontService.font(
              fontSize: screenSize.width * 0.038,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          // 8 session circles
          Row(
            children: List.generate(PomodoroNotifier.dailyCap, (i) {
              final filled = i < notifier.todaySessions;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
