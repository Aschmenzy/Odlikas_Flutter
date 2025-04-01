// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/database/firestore_pomodoro_service.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/Widgets/horizontal_streak_progress.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/Widgets/pomodoroContainer.dart';
import 'package:provider/provider.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  late FirestorePomodoroService pomodoroService;
  var _isLoading = true;
  String? _email;
  String _currentPhase = 'Pomodoro';
  bool _isRunning = false;
  int _cycleCount = 0;
  int _initialDuration = 25 * 60;
  Timestamp? _startTimestamp;
  int? _clientStartTime;
  final int _displayedSecondsLeft = 25 * 60;
  Timer? _localTimer;
  late ValueNotifier<int> _secondsNotifier;
  int _daysLearning = 0;
  int _hoursLearning = 0;
  int _streakCount = 0;
  int _weeklySessions = 0;
  int _weeklyStreak = 0;

  @override
  void initState() {
    super.initState();
    _secondsNotifier = ValueNotifier<int>(_displayedSecondsLeft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromHive();
    });
    _getLearningStats();
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  // Funkcija za dosljedno računanje preostalih sekundi
  // Izračunava koliko je sekundi preostalo u trenutnom intervalu na temelju početnog vremena
  int calculateSecondsRemaining(
      int initialDuration, Timestamp? serverTimestamp, int? clientStartTime) {
    // Uvijek prednost daje klijentskom vremenu ako je dostupno za dosljedno praćenje
    if (clientStartTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMillis = now - clientStartTime;
      final elapsedSeconds = (elapsedMillis / 1000)
          .floor(); // Koristi floor() za dosljedno zaokruživanje
      return (initialDuration - elapsedSeconds).clamp(0, initialDuration);
    }
    // Koristi serversku vremensku oznaku kao rezervu ako klijentsko vrijeme nije dostupno
    else if (serverTimestamp != null) {
      final now = DateTime.now();
      final elapsed = now.difference(serverTimestamp.toDate()).inSeconds;
      return (initialDuration - elapsed).clamp(0, initialDuration);
    }

    // Ako nema podataka o vremenu, samo vrati početno trajanje
    return initialDuration;
  }

// Funkcija za pokretanje lokalnog brojača s dosljednim praćenjem vremena
// Pokreće odbrojavanje koje se ažurira svake sekunde
  void startLocalTicker(
      Timer? localTimer,
      ValueNotifier<int> secondsNotifier,
      bool isRunning,
      Timestamp? startTimestamp,
      int initialDuration,
      int? clientStartTime,
      VoidCallback? onTimerEnd) {
    // Otkaži postojeći brojač ako postoji
    localTimer?.cancel();

    if (!isRunning) return;

    localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }

      // Koristi dosljednu funkciju za izračun
      final secondsLeft = calculateSecondsRemaining(
          initialDuration, startTimestamp, clientStartTime);

      secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        timer.cancel();
        if (onTimerEnd != null) {
          onTimerEnd();
        }
      }
    });
  }

  // Inicijalizira podatke korisnika iz Hive lokalne baze
  // Učitava email i postavlja servis za Pomodoro
  Future<void> _initFromHive() async {
    final box = await Hive.openBox('User');
    final storedEmail = box.get('email') as String?;

    if (storedEmail == null) {
      debugPrint('Nisu pronađeni podaci u Hive bazi.');
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

  // Sluša promjene Pomodoro podataka u Firebase bazi
  // Ažurira aplikaciju kad se podaci promijene
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
          _clientStartTime = mapData['clientStartTime'] as int?;
          _streakCount = mapData['streakCount'] ?? 0;
          _weeklySessions = mapData['weeklySessions'] ?? 0;
          _weeklyStreak = mapData['weeklyStreak'] ?? 0;
        });

        if (_isRunning) {
          _secondsNotifier.value = calculateSecondsRemaining(
              _initialDuration, _startTimestamp, _clientStartTime);

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

  // Pokreće lokalni brojač koji odbrojava vrijeme
  void _startLocalTicker() {
    if (_localTimer != null && _localTimer!.isActive) return;

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        _stopLocalTicker();
        return;
      }

      final secondsLeft = calculateSecondsRemaining(
          _initialDuration, _startTimestamp, _clientStartTime);

      _secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        _stopLocalTicker();
        _forwardTimer();
      }
    });
  }

  // Zaustavlja lokalni brojač
  void _stopLocalTicker() {
    _localTimer?.cancel();
    _localTimer = null;
  }

  // Prelazi na sljedeću fazu u Pomodoro ciklusu
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

  // Dohvaca statistike ucenja iz Firestore baze i ucitava podatke o danima, satima učenja i druge statistike
  Future<void> _getLearningStats() async {
    final _email = await Hive.openBox('User').then((box) => box.get('email'));

    try {
      final doc = await FirebaseFirestore.instance
          .collection("studentProfiles")
          .doc(_email)
          .get();

      // Provjeri postoji li dokument
      if (!doc.exists) {
        debugPrint('Dokument ne postoji za email: $_email');
        return;
      }

      final data = doc.data();

      // Provjeri jesu li podaci null
      if (data == null) {
        debugPrint('Podaci dokumenta su null');
        return;
      }

      // Provjeri postoje li postavke
      if (!data.containsKey('preferences') || data['preferences'] == null) {
        debugPrint('Polje postavki ne postoji ili je null');
        return;
      }

      // Pokusaj pretvoriti u Map<String, dynamic> ali barataj potencijalnim različitim tipovima mape
      final preferences = data['preferences'];
      if (!(preferences is Map)) {
        debugPrint('Postavke nisu Mapa: ${preferences.runtimeType}');
        return;
      }

      // Pristupi vrijednostima mape ali obradi potencijalne razlike u tipu
      final daysLearning = preferences.containsKey('daysLearning')
          ? (preferences['daysLearning'] is int
              ? preferences['daysLearning'] as int
              : int.tryParse(preferences['daysLearning'].toString()) ?? 0)
          : 0;

      final hoursLearning = preferences.containsKey('hoursLearning')
          ? (preferences['hoursLearning'] is int
              ? preferences['hoursLearning'] as int
              : int.tryParse(preferences['hoursLearning'].toString()) ?? 0)
          : 0;

      setState(() {
        _daysLearning = daysLearning;
        _hoursLearning = hoursLearning;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Greška pri dohvaćanju statistika učenja: $e');
    }
  }

  // Prikazuje detalje o napretku i nizu učenja i otvara dijaloški okvir s detaljnim statistikama
  void _showStreakDetails() {
    final targetSessions = _daysLearning * (_hoursLearning * 60 ~/ 25);
    final progress =
        targetSessions > 0 ? (_weeklySessions / targetSessions).clamp(0, 1) : 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistika Učenja',
                style: Provider.of<FontService>(context).font(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildStatItem('🔥 Trenutni Niz', '$_weeklyStreak tjedan'),
              const SizedBox(height: 15),
              _buildStatItem('📅 Cilj tjedno', '$_daysLearning dana/tjedno'),
              const SizedBox(height: 15),
              _buildStatItem('⏳ Dnevni cilj', '$_hoursLearning sati/dan'),
              const SizedBox(height: 15),
              _buildStatItem('✅ Održane sesije', '$_weeklySessions sesija '),
              const Spacer(),
              LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.black.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(_getPhaseColor()),
                minHeight: 20,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Napredak:',
                    style: Provider.of<FontService>(context).font(
                      fontSize: 16,
                      color: _getPhaseColor(),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: Provider.of<FontService>(context).font(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getPhaseColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _getPhaseColor(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'UREDU',
                    style: Provider.of<FontService>(context).font(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pomoćna metoda za stvaranje stavke statistike u dijalogu
  // Oblikuje pojedinu stavku statistike s oznakom i vrijednosti
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Provider.of<FontService>(context).font(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Provider.of<FontService>(context).font(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: Lottie.asset(
              'assets/animations/loadingBird.json',
              width: MediaQuery.of(context).size.width * 0.80,
              height: 120,
            ))
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  SizedBox(height: screenSize.height * 0.02),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HorizontalStreakProgress(
                            daysLearning: _daysLearning,
                            hoursLearning: _hoursLearning,
                            streakCount: _weeklySessions,
                            color: _getPhaseColor(),
                            onTap:
                                _showStreakDetails, // Dodaj handler za dodir za prikaz detalja niza
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          PomodoroContainer(
                            currentPhase: _currentPhase,
                            currentDuration:
                                Duration(seconds: _displayedSecondsLeft),
                            isRunning: _isRunning,
                            secondsNotifier: _secondsNotifier,
                            startTimer: () {
                              final leftover = _secondsNotifier.value;
                              pomodoroService.startTimer(
                                  _currentPhase, leftover, _cycleCount);
                            },
                            stopTimer: () {
                              final secondsLeft = calculateSecondsRemaining(
                                  _initialDuration,
                                  _startTimestamp,
                                  _clientStartTime);

                              pomodoroService
                                  .stopTimerWithLocalLeftover(secondsLeft);
                              // Nema potrebe zaustavljati lokalni brojač, osluškivač će to obraditi
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
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 2),
    );
  }

  // Stvara zaglavlje stranice s naslovom
  // Prikazuje glavni naslov Pomodoro mjerača
  Widget _buildHeader(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          SizedBox(height: screenSize.height * 0.05),
          //naslov

          Center(
            child: Text(
              "Pomodoro mjerač vremena",
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
    );
  }

  // Stvara prikaz trenutnog broja ciklusa
  // Prikazuje broj trenutnog Pomodoro ciklusa s bojom ovisno o fazi
  Widget _buildCycleCount() {
    final fontService = Provider.of<FontService>(context);
    return Text(
      "#${1 + _cycleCount}",
      style: fontService.font(
        fontWeight: FontWeight.w800,
        fontSize: 28,
        color: _getPhaseColor(),
      ),
    );
  }

  // Stvara poruku koja objašnjava trenutnu fazu
  // Prikazuje tekst koji opisuje je li vrijeme za učenje ili pauzu
  Widget _buildPhaseHint() {
    final fontService = Provider.of<FontService>(context);
    return Text(
      _currentPhase == "Pomodoro"
          ? "Vrijeme je za učiti!"
          : "Vrijeme je za pauzu!",
      style: fontService.font(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: Colors.black,
      ),
    );
  }

  // Vraća boju ovisno o trenutnoj fazi Pomodoro ciklusa
  // Narančasta za Pomodoro, svijetlo plava za kratku pauzu, tamnija plava za dugu pauzu
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
