import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:odlikas_mobilna/services/pomodoro_api_service.dart';

enum PomodoroTimerState { idle, running, paused }

class PomodoroNotifier extends ChangeNotifier {
  final _api = PomodoroApiService();

  // Drives only the countdown display — avoids rebuilding the whole page each tick
  final ValueNotifier<int> secondsNotifier = ValueNotifier(5); // TEST — revert to 25 * 60 before release

  PomodoroTimerState timerState = PomodoroTimerState.idle;
  String currentPhase = 'Pomodoro';
  int cycleCount = 0;

  // State from API
  int todaySessions = 0;
  int currentStreak = 0;
  bool isCapped = false;
  bool isLoadingStreak = true;
  String? sessionError;

  static const int dailyCap = 8;

  Timer? _ticker;
  bool _notificationsInitialised = false;
  final _plugin = FlutterLocalNotificationsPlugin();

  // ──────────────────────────────────────────────
  // Init — call from page's initState()
  // ──────────────────────────────────────────────

  Future<void> init() async {
    await _ensureNotificationsReady();
    isLoadingStreak = true;
    sessionError = null;
    notifyListeners();

    try {
      final data = await _api.getStreak();
      todaySessions = data.todaySessions;
      currentStreak = data.currentStreak;
      isCapped = data.capped ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('PomodoroNotifier.init error: $e');
      sessionError =
          'Nije moguće dohvatiti statistiku. Provjeri internetsku vezu.';
    } finally {
      isLoadingStreak = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Timer controls
  // ──────────────────────────────────────────────

  void start() {
    if (isCapped || timerState == PomodoroTimerState.running) return;
    timerState = PomodoroTimerState.running;
    sessionError = null;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (timerState != PomodoroTimerState.running) return;
    timerState = PomodoroTimerState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    timerState = PomodoroTimerState.idle;
    secondsNotifier.value = _durationFor(currentPhase);
    sessionError = null;
    notifyListeners();
  }

  void skipToNext() {
    _ticker?.cancel();
    _advancePhase();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Internal timer logic
  // ──────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsNotifier.value > 0) {
        secondsNotifier.value--;
        // No notifyListeners() — ValueNotifier handles its own rebuilds
      } else {
        _ticker?.cancel();
        _onTimerFinished();
      }
    });
  }

  Future<void> _onTimerFinished() async {
    if (currentPhase == 'Pomodoro') {
      // Optimistically fill circle so UI feels instant
      todaySessions = (todaySessions + 1).clamp(0, dailyCap);
      notifyListeners();

      try {
        final data = await _api.completeSession();
        todaySessions = data.todaySessions;
        currentStreak = data.currentStreak;
        isCapped = data.capped ?? false;
        sessionError = null;
        await _showNotification(
          'Sesija zabilježena!',
          isCapped
              ? 'Dostignut dnevni maksimum. Odlično!'
              : 'Sad pauza — dobro si radio!',
        );
      } catch (e) {
        if (kDebugMode) debugPrint('CompleteSession error: $e');
        todaySessions = (todaySessions - 1).clamp(0, dailyCap);
        sessionError = 'Sesija nije snimljena. Provjeri internetsku vezu.';
        timerState = PomodoroTimerState.idle;
        notifyListeners();
        return;
      }
    } else {
      await _showNotification('Pauza završena!', 'Vrijeme je za učenje.');
    }

    _advancePhase();
    notifyListeners();
  }

  void _advancePhase() {
    timerState = PomodoroTimerState.idle;

    if (currentPhase == 'Pomodoro') {
      currentPhase = (cycleCount % 4 == 3) ? 'Duga pauza' : 'Kratka pauza';
    } else {
      if (currentPhase == 'Kratka pauza') {
        cycleCount++;
      } else {
        cycleCount = 0;
      }
      currentPhase = 'Pomodoro';
    }

    secondsNotifier.value = _durationFor(currentPhase);
  }

  int _durationFor(String phase) {
    switch (phase) {
      case 'Kratka pauza':
        return 5 * 60;
      case 'Duga pauza':
        return 15 * 60;
      default:
        return 5;
    }
  }

  // ──────────────────────────────────────────────
  // Local notifications
  // ──────────────────────────────────────────────

  Future<void> _ensureNotificationsReady() async {
    if (_notificationsInitialised) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _notificationsInitialised = true;
  }

  Future<void> _showNotification(String title, String body) async {
    try {
      const android = AndroidNotificationDetails(
        'pomodoro_timer',
        'Pomodoro Timer',
        channelDescription: 'Pomodoro session completion alerts',
        importance: Importance.high,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      await _plugin.show(
        42,
        title,
        body,
        const NotificationDetails(android: android, iOS: ios),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification error: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    secondsNotifier.dispose();
    super.dispose();
  }
}
