// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/database/firestore_pomodoro_service.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/Widgets/pomodoroContainer.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  late FirestorePomodoroService pomodoroService;
  String? _email;
  String _currentPhase = 'Pomodoro';
  bool _isRunning = false;
  int _cycleCount = 0;
  int _initialDuration = 25 * 60;
  Timestamp? _startTimestamp;
  final int _displayedSecondsLeft = 25 * 60;
  Timer? _localTimer;
  late ValueNotifier<int> _secondsNotifier;

  @override
  void initState() {
    super.initState();
    _secondsNotifier = ValueNotifier<int>(_displayedSecondsLeft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromHive();
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  Future<void> _initFromHive() async {
    final box = await Hive.openBox('User');
    final storedEmail = box.get('email') as String?;

    if (storedEmail == null) {
      debugPrint('No credentials found in Hive.');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _email = storedEmail;
    });

    pomodoroService = FirestorePomodoroService(_email!);
    pomodoroService.initializeTimer();
    _listenToPomodoroChanges();
  }

  void _listenToPomodoroChanges() {
    pomodoroService.listenToTimer().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          final mapData = data as Map<String, dynamic>;
          _currentPhase = mapData['currentPhase'] ?? 'Pomodoro';
          _cycleCount = mapData['cycleCount'] ?? 0;
          _isRunning = mapData['isRunning'] ?? false;
          _initialDuration = mapData['currentDuration'] ?? 25 * 60;
          _startTimestamp = mapData['startTimestamp'] as Timestamp?;
        });

        if (_isRunning && _startTimestamp != null) {
          final now = DateTime.now();
          final elapsed = now.difference(_startTimestamp!.toDate()).inSeconds;
          final secondsLeft =
              (_initialDuration - elapsed).clamp(0, _initialDuration);
          _secondsNotifier.value = secondsLeft;
          if (!(_localTimer?.isActive ?? false)) {
            _startLocalTicker();
          }
        } else {
          _secondsNotifier.value = _initialDuration;
          _stopLocalTicker();
        }
      }
    });
  }

  void _startLocalTicker() {
    if (_localTimer != null && _localTimer!.isActive) return;

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning || _startTimestamp == null) {
        _stopLocalTicker();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_startTimestamp!.toDate()).inSeconds;
      final secondsLeft =
          (_initialDuration - elapsed).clamp(0, _initialDuration);

      _secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        _stopLocalTicker();
        _forwardTimer();
      }
    });
  }

  void _stopLocalTicker() {
    _localTimer?.cancel();
    _localTimer = null;
  }

  void _forwardTimer() {
    if (_isRunning) {
      String nextPhase;
      int nextDuration;
      int updatedCycleCount = _cycleCount;

      if (_currentPhase == "Pomodoro") {
        if (_cycleCount % 4 == 3) {
          nextPhase = "Duga pauza";
          nextDuration = 15 * 60;
        } else {
          nextPhase = "Kratka pauza";
          nextDuration = 5 * 60;
        }
      } else if (_currentPhase == "Kratka pauza") {
        nextPhase = "Pomodoro";
        nextDuration = 25 * 60;
        updatedCycleCount++;
      } else {
        nextPhase = "Pomodoro";
        nextDuration = 25 * 60;
        updatedCycleCount = 0;
      }

      pomodoroService.forwardPhase(nextPhase, nextDuration, updatedCycleCount);
    } else {
      pomodoroService.forwardPhase("Pomodoro", 25 * 60, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: screenSize.height * 0.02),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PomodoroContainer(
                      currentPhase: _currentPhase,
                      currentDuration: Duration(seconds: _displayedSecondsLeft),
                      isRunning: _isRunning,
                      secondsNotifier: _secondsNotifier,
                      startTimer: () {
                        final leftover = _secondsNotifier.value;
                        pomodoroService.startTimer(
                            _currentPhase, leftover, _cycleCount);
                        setState(() {
                          _isRunning = true;
                          _startTimestamp = Timestamp.now();
                          _initialDuration = leftover;
                        });
                        _startLocalTicker();
                      },
                      stopTimer: () {
                        final now = DateTime.now();
                        final elapsed = _startTimestamp != null
                            ? now
                                .difference(_startTimestamp!.toDate())
                                .inSeconds
                            : 0;
                        final leftover = (_initialDuration - elapsed)
                            .clamp(0, _initialDuration);
                        pomodoroService.stopTimerWithLocalLeftover(leftover);
                        _stopLocalTicker();
                      },
                      forwardTimer: _forwardTimer,
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildCycleCount(),
                    SizedBox(height: screenSize.height * 0.01),
                    _buildPhaseHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          SizedBox(height: screenSize.height * 0.05),
          //title

          Center(
            child: Text(
              "Pomodoro mjerač vremena",
              style: GoogleFonts.inter(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildCycleCount() {
    return Text(
      "#${1 + _cycleCount}",
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        fontSize: 28,
        color: _getPhaseColor(),
      ),
    );
  }

  Widget _buildPhaseHint() {
    return Text(
      _currentPhase == "Pomodoro"
          ? "Vrijeme je za učiti!"
          : "Vrijeme je za pauzu!",
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: Colors.black,
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case "Pomodoro":
        return const Color.fromRGBO(236, 146, 31, 1);
      case "Kratka pauza":
        return const Color.fromRGBO(23, 148, 210, 1);
      default:
        return const Color.fromRGBO(20, 133, 186, 1);
    }
  }
}
