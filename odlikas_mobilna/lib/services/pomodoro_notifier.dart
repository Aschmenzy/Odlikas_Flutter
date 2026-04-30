import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';

enum PomodoroTimerState { idle, running, paused }

class PomodoroNotifier extends ChangeNotifier {
  final ApiService _api;

  PomodoroNotifier(this._api);

  // Drives only the countdown display — avoids rebuilding the whole page each tick
  final ValueNotifier<int> secondsNotifier = ValueNotifier(25 * 60);

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

    // TODO: remove mock once backend endpoints are live
    await Future.delayed(const Duration(milliseconds: 300));
    todaySessions = 2;
    currentStreak = 5;
    isCapped = false;
    isLoadingStreak = false;
    notifyListeners();

    // try {
    //   final data = await _api.getPomodoroStreak();
    //   todaySessions = (data['todaySessions'] as num?)?.toInt() ?? 0;
    //   currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
    //   isCapped = data['isCapped'] as bool? ?? false;
    // } catch (e) {
    //   if (kDebugMode) debugPrint('PomodoroNotifier.init error: $e');
    //   sessionError = 'Nije moguće dohvatiti statistiku. Provjeri internetsku vezu.';
    // } finally {
    //   isLoadingStreak = false;
    //   notifyListeners();
    // }
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
    // Fire notification immediately — works even when app is backgrounded
    await _showCompletionNotification();

    if (currentPhase == 'Pomodoro') {
      // TODO: remove mock once backend endpoints are live
      todaySessions = (todaySessions + 1).clamp(0, dailyCap);
      isCapped = todaySessions >= dailyCap;
      sessionError = null;

      // try {
      //   final data = await _api.completePomodoroSession();
      //   todaySessions = (data['todaySessions'] as num?)?.toInt() ?? todaySessions;
      //   currentStreak = (data['currentStreak'] as num?)?.toInt() ?? currentStreak;
      //   isCapped = data['isCapped'] as bool? ?? isCapped;
      //   sessionError = null;
      // } catch (e) {
      //   if (kDebugMode) debugPrint('CompleteSession error: $e');
      //   sessionError = 'Sesija nije snimljena. Provjeri internetsku vezu.';
      //   timerState = PomodoroTimerState.idle;
      //   notifyListeners();
      //   return;
      // }
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
        return 10; // TEST — revert to 25 * 60 before release
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

  Future<void> _showCompletionNotification() async {
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
        'Sesija završena!',
        'Zabilježi svoju Pomodoro sesiju.',
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
