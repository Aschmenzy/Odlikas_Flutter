class ScheduleSubject {
  final List<DaySchedule> schedule;

  ScheduleSubject({required this.schedule});

  factory ScheduleSubject.fromJson(Map<String, dynamic> json) {
    return ScheduleSubject(
      schedule: (json['schedule'] as List)
          .map((daySchedule) => DaySchedule.fromJson(daySchedule))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule.map((daySchedule) => daySchedule.toJson()).toList(),
    };
  }
}

class DaySchedule {
  final String day;
  final List<String> subjects;
  List<String> classrooms;

  DaySchedule({
    required this.day,
    required this.subjects,
    List<String>? classrooms,
  }) : classrooms = classrooms ?? List.filled(8, '');

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'],
      subjects: List<String>.from(json['subjects'] ?? []),
      classrooms: json['classrooms'] != null
          ? List<String>.from(json['classrooms'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'subjects': subjects,
      'classrooms': classrooms,
    };
  }
}
