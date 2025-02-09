import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class PomodoroContainer extends StatefulWidget {
  final String currentPhase;
  final Duration currentDuration;
  final bool isRunning;
  final VoidCallback startTimer;
  final ValueNotifier<int> secondsNotifier;
  final VoidCallback stopTimer;
  final VoidCallback forwardTimer;
  final Function(String) onPhaseChanged;

  const PomodoroContainer({
    Key? key,
    required this.currentPhase,
    required this.secondsNotifier,
    required this.currentDuration,
    required this.isRunning,
    required this.startTimer,
    required this.stopTimer,
    required this.forwardTimer,
    required this.onPhaseChanged,
  }) : super(key: key);

  @override
  State<PomodoroContainer> createState() => _PomodoroContainerState();
}

class _PomodoroContainerState extends State<PomodoroContainer> {
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case "Pomodoro":
        return AppColors.accent;
      case "Kratka pauza":
        return const Color.fromRGBO(23, 148, 210, 1);
      default:
        return const Color.fromRGBO(20, 133, 186, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Container(
      width: screenSize.width * 0.95,
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.02,
        horizontal: screenSize.width * 0.03,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _getPhaseColor(widget.currentPhase),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phase selector tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhaseTab("Pomodoro", isSmallScreen, context),
                _buildPhaseTab("Kratka pauza", isSmallScreen, context),
                _buildPhaseTab("Duga pauza", isSmallScreen, context),
              ],
            ),
          ),

          // Timer display
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.04),
            child: ValueListenableBuilder<int>(
              valueListenable: widget.secondsNotifier,
              builder: (context, secondsLeft, child) {
                final duration = Duration(seconds: secondsLeft);
                return Text(
                  formatDuration(duration),
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 72 : 96,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start/Stop button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed:
                        widget.isRunning ? widget.stopTimer : widget.startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _getPhaseColor(widget.currentPhase),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      textStyle: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.isRunning ? "ZAUSTAVI" : "ZAPOČNI"),
                  ),
                ),
              ),

              // Forward button
              IconButton(
                onPressed: widget.forwardTimer,
                icon: Icon(
                  widget.isRunning
                      ? Icons.skip_next
                      : Icons.rotate_right_outlined,
                  size: isSmallScreen ? 36 : 48,
                  color: AppColors.background,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTab(
      String phase, bool isSmallScreen, BuildContext context) {
    final bool isSelected = widget.currentPhase == phase;

    return GestureDetector(
      onTap: () {
        if (!isSelected && !widget.isRunning) {
          // Only allow phase change when timer is not running
          widget.onPhaseChanged(phase);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          color: isSelected ? _getPhaseColor(phase) : Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isSelected ? _getPhaseColor(phase) : Colors.transparent,
            ),
            child: Text(
              phase,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.background : AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
