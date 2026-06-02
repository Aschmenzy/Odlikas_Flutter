import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:odlikas_mobilna/services/pomodoro_notifier.dart';
import 'package:odlikas_mobilna/services/pomodoro_api_service.dart';

class MockPomodoroApiService extends Mock implements PomodoroApiService {}

void main() {
  late MockPomodoroApiService mockApi;
  late PomodoroNotifier notifier;

  setUp(() {
    mockApi = MockPomodoroApiService();
    notifier = PomodoroNotifier(api: mockApi);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('Initial state', () {
    test('starts idle with Pomodoro phase', () {
      expect(notifier.timerState, PomodoroTimerState.idle);
      expect(notifier.currentPhase, 'Pomodoro');
      expect(notifier.cycleCount, 0);
      expect(notifier.isCapped, isFalse);
    });

    test('secondsNotifier initialises to 25 minutes', () {
      expect(notifier.secondsNotifier.value, 25 * 60);
    });
  });

  group('start()', () {
    test('transitions idle to running', () {
      notifier.start();
      expect(notifier.timerState, PomodoroTimerState.running);
    });

    test('is a no-op when already running', () {
      notifier.start();
      notifier.start();
      expect(notifier.timerState, PomodoroTimerState.running);
    });

    test('is blocked when daily cap is reached', () {
      notifier.isCapped = true;
      notifier.start();
      expect(notifier.timerState, PomodoroTimerState.idle);
    });
  });

  group('pause()', () {
    test('transitions running to paused', () {
      notifier.start();
      notifier.pause();
      expect(notifier.timerState, PomodoroTimerState.paused);
    });

    test('is a no-op when idle', () {
      notifier.pause();
      expect(notifier.timerState, PomodoroTimerState.idle);
    });
  });

  group('reset()', () {
    test('returns to idle from running', () {
      notifier.start();
      notifier.reset();
      expect(notifier.timerState, PomodoroTimerState.idle);
    });

    test('restores secondsNotifier to current phase duration', () {
      notifier.skipToNext(); // advance to Kratka pauza (300s)
      notifier.secondsNotifier.value = 42; // simulate countdown
      notifier.reset();
      expect(notifier.secondsNotifier.value, 5 * 60);
    });
  });

  group('Phase cycling via skipToNext()', () {
    test('Pomodoro advances to Kratka pauza on first skip', () {
      notifier.skipToNext();
      expect(notifier.currentPhase, 'Kratka pauza');
      expect(notifier.timerState, PomodoroTimerState.idle);
    });

    test('Kratka pauza advances to Pomodoro and increments cycleCount', () {
      notifier.skipToNext(); // Pomodoro -> Kratka pauza
      notifier.skipToNext(); // Kratka pauza -> Pomodoro
      expect(notifier.currentPhase, 'Pomodoro');
      expect(notifier.cycleCount, 1);
    });

    test('4th Pomodoro (cycleCount==3) triggers Duga pauza', () {
      // 3 full cycles: Pomodoro->Kratka pauza->Pomodoro (cycleCount increments each time)
      for (int i = 0; i < 3; i++) {
        notifier.skipToNext(); // Pomodoro -> Kratka pauza
        notifier.skipToNext(); // Kratka pauza -> Pomodoro, cycleCount++
      }
      // cycleCount is now 3; next skip from Pomodoro should trigger long break
      notifier.skipToNext();
      expect(notifier.currentPhase, 'Duga pauza');
    });

    test('Duga pauza resets cycleCount to 0 and returns to Pomodoro', () {
      for (int i = 0; i < 3; i++) {
        notifier.skipToNext();
        notifier.skipToNext();
      }
      notifier.skipToNext(); // -> Duga pauza
      notifier.skipToNext(); // -> Pomodoro, cycleCount resets
      expect(notifier.currentPhase, 'Pomodoro');
      expect(notifier.cycleCount, 0);
    });

    test('phase durations are correct after each transition', () {
      expect(notifier.secondsNotifier.value, 25 * 60); // Pomodoro

      notifier.skipToNext(); // -> Kratka pauza
      expect(notifier.secondsNotifier.value, 5 * 60);

      notifier.skipToNext(); // -> Pomodoro (cycleCount=1)
      notifier.skipToNext(); // -> Kratka pauza
      notifier.skipToNext(); // -> Pomodoro (cycleCount=2)
      notifier.skipToNext(); // -> Kratka pauza
      notifier.skipToNext(); // -> Pomodoro (cycleCount=3)
      notifier.skipToNext(); // -> Duga pauza
      expect(notifier.secondsNotifier.value, 15 * 60);
    });
  });
}
