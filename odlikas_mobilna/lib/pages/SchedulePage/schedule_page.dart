// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/daySelector.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/subjectTitle.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/timeSelector.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _homeViewModel = HomePageViewModel(ApiService());
  bool _isMorning = true;
  String _selectedDay = 'PON';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final box = await Hive.openBox('User');
      final email = box.get('email');
      final password = box.get('password');

      // Get cached data from Firebase first
      final cachedSchedule = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .get();

      if (cachedSchedule.exists && cachedSchedule.data()?['schedule'] != null) {
        // If we have data in Firebase, use that and don't fetch from API
        var scheduleData = cachedSchedule.data()!['schedule'];

        // Ensure each day's subjects array has 9 elements
        if (scheduleData['schedule'] is List) {
          for (var day in scheduleData['schedule']) {
            if (day['subjects'] is List) {
              var subjects = List<String>.from(day['subjects']);
              while (subjects.length < 8) {
                subjects.add('');
              }
              day['subjects'] = subjects;
            }
          }
        }

        _homeViewModel.updateSchedule(ScheduleSubject.fromJson(scheduleData));
        return;
      }

      // Only fetch from API if we don't have data in Firebase
      await _homeViewModel.fetchScheduleSubjects(email, password);

      // Ensure the schedule has 9 slots before saving to Firebase
      if (_homeViewModel.scheduleSubject != null) {
        for (var day in _homeViewModel.scheduleSubject!.schedule) {
          while (day.subjects.length < 8) {
            day.subjects.add('');
          }
        }
      }

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('studentProfiles')
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
        orElse: () =>
            DaySchedule(day: dayToFind, subjects: List<String>.filled(9, '')),
      );

      // Ensure we have 9 slots
      while (daySchedule.subjects.length < 8) {
        daySchedule.subjects.add('');
      }

      return daySchedule;
    } catch (e) {
      debugPrint('Error in _getSelectedDaySchedule: $e');
      return DaySchedule(day: dayToFind, subjects: List<String>.filled(9, ''));
    }
  }

  // In the ListView.builder, update the subject access:

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
        while (subjects.length < 9) {
          subjects.add('');
        }
      } else {
        subjects = List.filled(9, '');
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
            .collection('studentProfiles')
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

  Future<void> _showSubjectDialog(int periodNumber) async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Subject',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter subject name',
            hintStyle: GoogleFonts.inter(color: AppColors.tertiary),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.tertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateSubject(periodNumber, controller.text, false);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.inter(color: AppColors.accent),
            ),
          ),
        ],
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
                    selectedSchedule?.subjects ?? List.filled(9, '');

                return ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    String subject = '';
                    if (subjects != null && index < subjects.length) {
                      subject = subjects[index];
                    }

                    return SubjectTile(
                      periodNumber: index,
                      subject: subject,
                      isFirst: index == 0,
                      isLast: index == 7,
                      isEditMode: _isEditMode,
                      onAdd: () => _showSubjectDialog(index),
                      onRemove: () => _updateSubject(index, '', true),
                    );
                  },
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
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Raspored sati",
            style: GoogleFonts.inter(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: screenWidth * 0.06,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Kliknite ✎ da promijenite raspored',
            style: GoogleFonts.inter(
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
