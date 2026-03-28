// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/daySelector.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/subjectTitle.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/timeSelector.dart';
import 'package:provider/provider.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final HomePageViewModel _homeViewModel;
  bool _isMorning = true;
  String _selectedDay = 'PON';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _homeViewModel = context.read<HomePageViewModel>();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final box = await Hive.openBox('User');
      final email = box.get('email') as String?;

      // Get cached data from Firebase first
      final cachedSchedule = await FirebaseFirestore.instance
          .collection('studentSchedule')
          .doc(email)
          .get();

      if (cachedSchedule.exists && cachedSchedule.data()?['schedule'] != null) {
        // If we have data in Firebase, use that and don't fetch from API
        var scheduleData = cachedSchedule.data()!['schedule'];

        // Ensure each day's subjects and classrooms array have 8 elements
        if (scheduleData['schedule'] is List) {
          for (var day in scheduleData['schedule']) {
            if (day['subjects'] is List) {
              var subjects = List<String>.from(day['subjects']);
              var classrooms = List<String>.from(day['classrooms'] ?? []);

              while (subjects.length < 8) {
                subjects.add('');
              }
              while (classrooms.length < 8) {
                classrooms.add('');
              }

              day['subjects'] = subjects;
              day['classrooms'] = classrooms;
            }
          }
        }

        _homeViewModel.updateSchedule(ScheduleSubject.fromJson(scheduleData));
        return;
      }

      // Only fetch from API if we don't have data in Firebase
      await _homeViewModel.fetchScheduleSubjects();

      // Ensure the schedule has 8 slots before saving to Firebase
      if (_homeViewModel.scheduleSubject != null) {
        for (var day in _homeViewModel.scheduleSubject!.schedule) {
          while (day.subjects.length < 8) {
            day.subjects.add('');
          }
          while (day.classrooms.length < 8) {
            day.classrooms.add('');
          }
        }
      }

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('studentSchedule')
          .doc(email)
          .set({
        'schedule': _homeViewModel.scheduleSubject?.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  DaySchedule? _getSelectedDaySchedule(List<DaySchedule> schedule) {
    String dayToFind = '$_selectedDay ${_isMorning ? "Morning" : "Afternoon"}';
    try {
      var daySchedule = schedule.firstWhere(
        (day) => day.day == dayToFind,
        orElse: () => DaySchedule(
            day: dayToFind,
            subjects: List<String>.filled(8, ''),
            classrooms: List<String>.filled(8, '')),
      );

      // Ensure we have 8 slots for subjects and classrooms
      while (daySchedule.subjects.length < 8) {
        daySchedule.subjects.add('');
      }
      while (daySchedule.classrooms.length < 8) {
        daySchedule.classrooms.add('');
      }

      return daySchedule;
    } catch (e) {
      debugPrint('Error in _getSelectedDaySchedule: $e');
      return DaySchedule(
          day: dayToFind,
          subjects: List<String>.filled(8, ''),
          classrooms: List<String>.filled(8, ''));
    }
  }

  Future<void> _updateSubject(
      int periodNumber, String subject, bool isRemoving) async {
    try {
      final schedule = _homeViewModel.scheduleSubject;
      if (schedule == null) return;

      final currentDayString =
          '${_selectedDay} ${_isMorning ? "Morning" : "Afternoon"}';
      var dayIndex =
          schedule.schedule.indexWhere((day) => day.day == currentDayString);

      // Get or create subjects list
      List<String> subjects;
      if (dayIndex != -1) {
        subjects = List<String>.from(schedule.schedule[dayIndex].subjects);
        while (subjects.length < 8) {
          subjects.add('');
        }
      } else {
        subjects = List.filled(8, '');
      }

      // Update the subject at the given period number
      if (isRemoving) {
        subjects[periodNumber] = '';
      } else {
        subjects[periodNumber] = subject;
      }

      // Create updated schedule list
      List<DaySchedule> updatedSchedule =
          List<DaySchedule>.from(schedule.schedule);

      final updatedDaySchedule = DaySchedule(
        day: currentDayString,
        subjects: subjects,
        classrooms: dayIndex != -1
            ? schedule.schedule[dayIndex].classrooms
            : List.filled(8, ''),
      );

      if (dayIndex != -1) {
        updatedSchedule[dayIndex] = updatedDaySchedule;
      } else {
        updatedSchedule.add(updatedDaySchedule);
      }

      // Update view model
      _homeViewModel.updateSchedule(ScheduleSubject(schedule: updatedSchedule));

      // Update Firebase
      final box = await Hive.openBox('User');
      final email = box.get('email');

      if (email != null) {
        await FirebaseFirestore.instance
            .collection('studentSchedule')
            .doc(email)
            .set({
          'schedule': _homeViewModel.scheduleSubject?.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error updating subject: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update schedule: $e')),
      );
    }
  }

  Future<void> _updateSubjectClassroom(
      int periodNumber, String classroom, bool isRemoving) async {
    try {
      final schedule = _homeViewModel.scheduleSubject;
      if (schedule == null) return;

      final currentDayString =
          '${_selectedDay} ${_isMorning ? "Morning" : "Afternoon"}';
      var dayIndex =
          schedule.schedule.indexWhere((day) => day.day == currentDayString);

      debugPrint('Updating Classroom:');
      debugPrint('Day: $currentDayString');
      debugPrint('Period: $periodNumber');
      debugPrint('Classroom: $classroom');
      debugPrint('Day Index: $dayIndex');

      // Get or create classrooms list
      List<String> classrooms;
      if (dayIndex != -1) {
        classrooms = List<String>.from(schedule.schedule[dayIndex].classrooms);
        while (classrooms.length < 8) {
          classrooms.add('');
        }
      } else {
        classrooms = List.filled(8, '');
      }

      // Update the classroom at the given period number
      if (isRemoving) {
        classrooms[periodNumber] = '';
      } else {
        classrooms[periodNumber] = classroom;
      }

      // Create updated schedule list
      List<DaySchedule> updatedSchedule =
          List<DaySchedule>.from(schedule.schedule);

      final updatedDaySchedule = DaySchedule(
        day: currentDayString,
        subjects: dayIndex != -1
            ? schedule.schedule[dayIndex].subjects
            : List.filled(8, ''),
        classrooms: dayIndex != -1 ? classrooms : List.filled(8, ''),
      );

      if (dayIndex != -1) {
        updatedSchedule[dayIndex] = updatedDaySchedule;
      } else {
        updatedSchedule.add(updatedDaySchedule);
      }

      // Update view model
      _homeViewModel.updateSchedule(ScheduleSubject(schedule: updatedSchedule));

      // Update Firebase
      final box = await Hive.openBox('User');
      final email = box.get('email');

      if (email != null) {
        await FirebaseFirestore.instance
            .collection('studentSchedule')
            .doc(email)
            .set({
          'schedule': _homeViewModel.scheduleSubject?.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error updating classroom: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update classroom: $e')),
      );
    }
  }

  Future<void> _showSubjectDialog(int periodNumber) async {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController classroomController = TextEditingController();

    // Fetch the current subject and classroom for this period
    final schedule = _homeViewModel.scheduleSubject;
    final currentDayString =
        '${_selectedDay} ${_isMorning ? "Morning" : "Afternoon"}';
    var dayIndex =
        schedule?.schedule.indexWhere((day) => day.day == currentDayString);

    if (dayIndex != null && dayIndex != -1) {
      final currentDay = schedule!.schedule[dayIndex];
      if (periodNumber < currentDay.subjects.length) {
        subjectController.text = currentDay.subjects[periodNumber];
      }
      if (periodNumber < currentDay.classrooms.length) {
        classroomController.text = currentDay.classrooms[periodNumber];
      }
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  periodNumber == 0 ? '1.sat' : '${periodNumber + 1}.sat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.secondary,
                  ),
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject field
                    Text(
                      'Predmet:',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: 'Ime predmeta...',
                        hintStyle: TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w800),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        suffixIcon: Icon(Icons.edit,
                            color: AppColors.tertiary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Classroom field
                    Text(
                      'Učionica:',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: classroomController,
                      decoration: InputDecoration(
                        hintText: 'Broj ili ime učionice...',
                        hintStyle: TextStyle(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w800,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: AppColors.tertiary),
                        ),
                        suffixIcon: Icon(Icons.edit,
                            color: AppColors.tertiary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Cancel button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Submit button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.check,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              if (subjectController.text.isNotEmpty) {
                                // Update both subject and classroom
                                _updateSubject(periodNumber,
                                    subjectController.text, false);
                                _updateSubjectClassroom(periodNumber,
                                    classroomController.text, false);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 36,
          ),
          color: AppColors.accent,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              size: 36,
            ),
            color: AppColors.accent,
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
        ],
      ),
      body: Column(
        children: [
          const ScheduleHeader(),
          TimeSelector(
            isMorning: _isMorning,
            onChanged: (value) => setState(() => _isMorning = value),
          ),
          DaySelector(
            selectedDay: _selectedDay,
            onDaySelected: (day) => setState(() => _selectedDay = day),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _homeViewModel,
              builder: (context, child) {
                if (_homeViewModel.isLoading) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loadingBird.json',
                      width: MediaQuery.of(context).size.width * 0.80,
                      height: 120,
                    ),
                  );
                }

                if (_homeViewModel.error != null) {
                  return Center(child: Text('Error: ${_homeViewModel.error}'));
                }

                final schedule = _homeViewModel.scheduleSubject;
                if (schedule == null) {
                  return const Center(child: Text('No schedule available'));
                }

                final selectedSchedule =
                    _getSelectedDaySchedule(schedule.schedule);
                final subjects =
                    selectedSchedule?.subjects ?? List.filled(8, '');
                final classrooms =
                    selectedSchedule?.classrooms ?? List.filled(8, '');

                return Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20, bottom: 67),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.tertiary,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: 8,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        String subject = '';
                        String classroom = '';
                        if (subjects != null && index < subjects.length) {
                          subject = subjects[index];
                        }
                        if (classrooms != null && index < classrooms.length) {
                          classroom = classrooms[index];
                        }

                        return SubjectTile(
                          periodNumber: index,
                          subject: subject,
                          classroom: classroom,
                          isFirst: index == 0,
                          isLast: index == 7,
                          isEditMode: _isEditMode,
                          onAdd: () => _showSubjectDialog(index),
                          onRemove: () {
                            _updateSubject(index, '', true);
                            _updateSubjectClassroom(index, '', true);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Raspored sati",
            style: fontService.font(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: screenWidth * 0.06,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Kliknite ✎ da promijenite raspored',
            style: fontService.font(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.04,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
