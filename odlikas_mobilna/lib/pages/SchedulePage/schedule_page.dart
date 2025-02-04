import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _homeViewModel = HomePageViewModel(ApiService());

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    await _homeViewModel.fetchScheduleSubjects("", "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: ListenableBuilder(
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

          return ListView.builder(
            itemCount: schedule.schedule.length,
            itemBuilder: (context, index) {
              final daySchedule = schedule.schedule[index];

              if (daySchedule.subjects.isEmpty) {
                return const SizedBox.shrink(); // Skip empty days
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(daySchedule.day),
                  children: daySchedule.subjects.map((subject) {
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(subject),
                      dense: false,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
