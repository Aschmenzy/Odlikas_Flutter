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

      // Get cached data from Firebase
      final cachedSchedule = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .get();

      if (cachedSchedule.exists) {
        final scheduleData = cachedSchedule.data()?['schedule'];
        if (scheduleData != null) {
          _homeViewModel.updateSchedule(ScheduleSubject.fromJson(scheduleData));
        }
      }

      // Fetch fresh data from API
      await _homeViewModel.fetchScheduleSubjects(email, password);

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

  Future<void> _updateSubject(
      int periodNumber, String subject, bool isRemoving) async {
    try {
      final schedule = _homeViewModel.scheduleSubject;
      if (schedule == null) return;

      final selectedSchedule = _getSelectedDaySchedule(schedule.schedule);
      if (selectedSchedule == null) return;

      // Create a copy of the current subjects list
      List<String> updatedSubjects = List.from(selectedSchedule.subjects);

      if (isRemoving) {
        // For removing, we just remove the subject at the given index
        if (periodNumber - 1 < updatedSubjects.length) {
          updatedSubjects.removeAt(periodNumber - 1);
        }
      } else {
        // For adding, we might need to pad the list with empty strings
        while (updatedSubjects.length < periodNumber) {
          updatedSubjects.add('');
        }
        updatedSubjects[periodNumber - 1] = subject;
      }

      // Create the updated day schedule
      final updatedDaySchedule = DaySchedule(
        day: '${_selectedDay} ${_isMorning ? "Morning" : "Afternoon"}',
        subjects: updatedSubjects,
      );

      // Create a copy of the full schedule
      final updatedSchedule = List<DaySchedule>.from(schedule.schedule);

      // Find and update the specific day
      final dayIndex = updatedSchedule.indexWhere((day) =>
          day.day == '${_selectedDay} ${_isMorning ? "Morning" : "Afternoon"}');

      if (dayIndex != -1) {
        updatedSchedule[dayIndex] = updatedDaySchedule;
      } else {
        updatedSchedule.add(updatedDaySchedule);
      }

      // Update local state
      _homeViewModel.updateSchedule(ScheduleSubject(schedule: updatedSchedule));

      // Update Firebase
      final box = await Hive.openBox('User');
      final email = box.get('email');

      await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .set({
        'schedule': _homeViewModel.scheduleSubject?.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Refresh the UI
      setState(() {});
    } catch (e) {
      debugPrint('Error updating subject: $e');
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

  DaySchedule? _getSelectedDaySchedule(List<DaySchedule> schedule) {
    String dayToFind = '$_selectedDay ${_isMorning ? "Morning" : "Afternoon"}';
    return schedule.firstWhere(
      (day) => day.day == dayToFind,
      orElse: () => DaySchedule(day: dayToFind, subjects: []),
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
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
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
                final subjects = selectedSchedule?.subjects ?? [];

                return ListView.builder(
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    String subject = '';
                    if (index < subjects.length) {
                      subject = subjects[index];
                    }

                    return SubjectTile(
                      periodNumber: index + 1,
                      subject: subject,
                      isFirst: index == 0,
                      isLast: index == 8,
                      isEditMode: _isEditMode,
                      onAdd: () => _showSubjectDialog(index + 1),
                      onRemove: () => _updateSubject(index + 1, '', true),
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
