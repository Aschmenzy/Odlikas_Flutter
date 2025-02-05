import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/schenule_subject.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _homeViewModel = HomePageViewModel(ApiService());
  bool _isMorning = true;
  String _selectedDay = 'PON';

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
          icon: const Icon(Icons.arrow_back),
          color: Colors.orange,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Raspored sati'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
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
                  return const Center(child: CircularProgressIndicator());
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
                    if (index < subjects.length && index > 0) {
                      subject = subjects[index - 1];
                    }

                    return SubjectTile(
                      periodNumber: index + 1,
                      subject: subject,
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
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Kliknite ✎ da promijenite raspored',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class TimeSelector extends StatelessWidget {
  final bool isMorning;
  final ValueChanged<bool> onChanged;

  const TimeSelector({
    super.key,
    required this.isMorning,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TimeButton(
            title: 'UJUTRO',
            isSelected: isMorning,
            onTap: () => onChanged(true),
          ),
          _TimeButton(
            title: 'POPODNE',
            isSelected: !isMorning,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final ValueChanged<String> onDaySelected;
  final List<String> days = const ['PON', 'UTO', 'SRI', 'ČET', 'PET'];

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: days
            .map((day) => _DayButton(
                  day: day,
                  isSelected: selectedDay == day,
                  onTap: () => onDaySelected(day),
                ))
            .toList(),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            day.substring(0, 3),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class SubjectTile extends StatelessWidget {
  final int periodNumber;
  final String subject;

  const SubjectTile({
    super.key,
    required this.periodNumber,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            '$periodNumber.sat',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(subject),
        trailing: Icon(subject.isEmpty ? Icons.add : Icons.remove),
      ),
    );
  }
}
