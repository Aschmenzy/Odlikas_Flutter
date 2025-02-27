import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:provider/provider.dart';

class PomodoroContainer extends StatefulWidget {
  final String currentPhase;
  final Duration currentDuration;
  final bool isRunning;
  final VoidCallback startTimer;
  final ValueNotifier<int> secondsNotifier;
  final VoidCallback stopTimer;
  final VoidCallback forwardTimer;

  const PomodoroContainer({
    Key? key,
    required this.currentPhase,
    required this.secondsNotifier,
    required this.currentDuration,
    required this.isRunning,
    required this.startTimer,
    required this.stopTimer,
    required this.forwardTimer,
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

  Color _getPhaseColor() {
    switch (widget.currentPhase) {
      case "Pomodoro":
        return const Color.fromRGBO(236, 146, 31, 1);
      case "Kratka pauza":
        return const Color.fromRGBO(23, 148, 210, 1);
      default:
        return const Color.fromRGBO(20, 133, 186, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Container(
      width: screenSize.width * 0.9,
      height: screenSize.height * 0.32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: _getPhaseColor(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(height: screenSize.height * 0.015),
          // Phase Tabs

          _buildMobilePhaseSelector(),

          // Timer Display
          Expanded(
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.secondsNotifier,
                builder: (context, secondsLeft, child) {
                  final duration = Duration(seconds: secondsLeft);
                  return Text(
                    formatDuration(duration),
                    style: fontService.font(
                      fontSize: screenSize.width * 0.22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          // Controls
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: _buildControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePhaseSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhaseTab("Pomodoro"),
          _buildPhaseTab("Kratka pauza"),
          _buildPhaseTab("Duga pauza"),
        ],
      ),
    );
  }

  Widget _buildPhaseTab(String phase) {
    final bool isActive = widget.currentPhase == phase;
    final Color backgroundColor =
        isActive ? _getPhaseColor() : Colors.transparent;
    final fontService = Provider.of<FontService>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: backgroundColor,
      ),
      child: Text(
        phase,
        style: fontService.font(
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.white : Colors.white,
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: screenSize.width * 0.15,
        ),

        // Start/Stop Button
        Expanded(
          child: ElevatedButton(
            onPressed: widget.isRunning ? widget.stopTimer : widget.startTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _getPhaseColor(),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: widget.isRunning ? 0 : 5,
            ),
            child: Text(
              widget.isRunning ? "ZAUSTAVI" : "ZAPOČNITE",
              style: fontService.font(
                  fontWeight: FontWeight.w700,
                  fontSize: screenSize.width * 0.05),
            ),
          ),
        ),

        // Forward/Skip Button
        IconButton(
          onPressed: widget.forwardTimer,
          icon: Icon(
            widget.isRunning ? Icons.skip_next : Icons.rotate_right_outlined,
          ),
          iconSize: screenSize.width * 0.15,
          color: Colors.white,
        ),
      ],
    );
  }
}
