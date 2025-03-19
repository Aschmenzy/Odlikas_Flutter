import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePomodoroService {
  final String timerId;

  FirestorePomodoroService(this.timerId);

  DocumentReference get timerDoc =>
      FirebaseFirestore.instance.collection('pomodoroTimers').doc(timerId);

  Future<void> initializeTimer() async {
    final docSnapshot = await timerDoc.get();
    if (!docSnapshot.exists) {
      await timerDoc.set({
        'currentPhase': 'Pomodoro',
        'currentDuration': 25 * 60,
        'isRunning': false,
        'cycleCount': 0,
        'startTimestamp': null,
        // Add new streak-related fields
        'streakCount': 0,
        'weeklySessions': 0,
        'weeklyStreak': 0,
        'lastSessionDate': null,
      });
    }
  }

  Future<void> startTimer(
      String currentPhase, int duration, int cycleCount) async {
    // Combine the updates in a single operation to prevent double triggers
    final docSnapshot = await timerDoc.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final now = Timestamp.now();
    final updateData = {
      'currentPhase': currentPhase,
      'currentDuration': duration,
      'isRunning': true,
      'cycleCount': cycleCount,
      'startTimestamp':
          now, // Use explicit timestamp instead of FieldValue.serverTimestamp()
    };

    // Merge streak updates into the same operation
    final streakUpdates = await _calculateStreakUpdates(data, now);
    if (streakUpdates.isNotEmpty) {
      updateData.addAll(streakUpdates.cast<String, Object>());
    }

    // Apply all updates in a single write operation
    await timerDoc.set(updateData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _calculateStreakUpdates(
      Map<String, dynamic> data, Timestamp now) async {
    final lastSessionTimestamp = data['lastSessionDate'] as Timestamp?;
    int streakCount = data['streakCount'] ?? 0;
    int weeklySessions = data['weeklySessions'] ?? 0;
    int weeklyStreak = data['weeklyStreak'] ?? 0;

    final currentDate = now.toDate();

    // If this is the first session ever
    if (lastSessionTimestamp == null) {
      return {
        'lastSessionDate': now,
        'streakCount': 1,
        'weeklySessions': 1,
        'weeklyStreak': 1,
      };
    }

    final lastSessionDate = lastSessionTimestamp.toDate();

    // Check if this is a new day
    final isNewDay = currentDate.day != lastSessionDate.day ||
        currentDate.month != lastSessionDate.month ||
        currentDate.year != lastSessionDate.year;

    // Check if we're in a new week
    final lastWeekNumber = (lastSessionDate
                .difference(DateTime(lastSessionDate.year, 1, 1))
                .inDays /
            7)
        .floor();
    final currentWeekNumber =
        (currentDate.difference(DateTime(currentDate.year, 1, 1)).inDays / 7)
            .floor();
    final isNewWeek = lastWeekNumber != currentWeekNumber ||
        lastSessionDate.year != currentDate.year;

    // Skip streak updates if it's the same day to prevent multiple increments
    if (!isNewDay) {
      return {};
    }

    // Reset weekly sessions if it's a new week
    if (isNewWeek) {
      // If we completed the target number of sessions last week, increment the streak
      final targetSessions =
          4; // This should ideally be derived from user preferences
      if (weeklySessions >= targetSessions) {
        weeklyStreak++;
      } else {
        weeklyStreak = 0; // Reset streak if target wasn't met
      }

      weeklySessions = 1; // Reset for the new week and count this session
    } else {
      // If it's a new day in the same week, increment sessions
      weeklySessions++;
    }

    // Increment streak count for new sessions
    streakCount++;

    return {
      'lastSessionDate': now,
      'streakCount': streakCount,
      'weeklySessions': weeklySessions,
      'weeklyStreak': weeklyStreak,
    };
  }

  Future<void> stopTimerWithLocalLeftover(int localLeftover) async {
    // localLeftover is your local _secondsNotifier.value
    final docSnapshot = await timerDoc.get();
    if (docSnapshot.exists) {
      await timerDoc.update({
        'currentDuration': localLeftover,
        'isRunning': false,
        'startTimestamp': null,
      });
    }
  }

  Future<void> forwardPhase(
      String newPhase, int newDuration, int cycleCount) async {
    // If tracking completed Pomodoro sessions, do that here
    final docSnapshot = await timerDoc.get();
    final data = docSnapshot.exists
        ? (docSnapshot.data() as Map<String, dynamic>)
        : null;
    final currentPhase = data?['currentPhase'];

    // Check if a Pomodoro was completed
    bool completedPomodoro = currentPhase == 'Pomodoro' &&
        (newPhase == 'Kratka pauza' || newPhase == 'Duga pauza');

    final updateData = {
      'currentPhase': newPhase,
      'currentDuration': newDuration,
      'cycleCount': cycleCount,
      'isRunning': false,
      'startTimestamp': null,
    };

    // If we've completed a Pomodoro, we might want to update session stats
    // Only do this if we need to track completed sessions separately
    if (completedPomodoro) {
      // Get current values
      int completedSessions = data?['completedSessions'] ?? 0;
      completedSessions++;

      // Add the updates
      updateData['completedSessions'] = completedSessions;
    }

    // Set the new phase data
    await timerDoc.set(updateData, SetOptions(merge: true));
  }

  // Listen to timer changes
  Stream<DocumentSnapshot> listenToTimer() {
    return timerDoc.snapshots();
  }

  // Reset streak data (useful if you need to provide a reset option)
  Future<void> resetStreakData() async {
    await timerDoc.update({
      'streakCount': 0,
      'weeklySessions': 0,
      'weeklyStreak': 0,
      'lastSessionDate': null,
    });
  }

  // Update streak goals (if you implement custom goal setting)
  Future<void> updateStreakGoals(int daysPerWeek, int hoursPerDay) async {
    await timerDoc.update({
      'targetDaysPerWeek': daysPerWeek,
      'targetHoursPerDay': hoursPerDay,
    });
  }

  // Get streak statistics as a single object (could be useful for detailed reports)
  Future<Map<String, dynamic>> getStreakStats() async {
    final docSnapshot = await timerDoc.get();
    if (!docSnapshot.exists) return {};

    final data = docSnapshot.data() as Map<String, dynamic>;
    return {
      'streakCount': data['streakCount'] ?? 0,
      'weeklySessions': data['weeklySessions'] ?? 0,
      'weeklyStreak': data['weeklyStreak'] ?? 0,
      'lastSessionDate': data['lastSessionDate'],
      'completedSessions': data['completedSessions'] ?? 0,
      'targetDaysPerWeek': data['targetDaysPerWeek'] ?? 0,
      'targetHoursPerDay': data['targetHoursPerDay'] ?? 0,
    };
  }
}
