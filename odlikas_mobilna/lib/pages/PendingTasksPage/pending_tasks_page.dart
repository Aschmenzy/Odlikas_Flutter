import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/services/study_notifications_service.dart';

class PendingTasksPage extends StatefulWidget {
  const PendingTasksPage({super.key});

  @override
  State<PendingTasksPage> createState() => _PendingTasksPageState();
}

class _PendingTasksPageState extends State<PendingTasksPage> {
  final _service = StudyNotificationsService();
  late Future<List<PendingTaskSet>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _service.getPendingTasks();
  }

  Future<void> _completeTaskSet(int id) async {
    try {
      await _service.completeTaskSet(id);
      setState(() {
        _tasksFuture = _service.getPendingTasks();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nije moguće označiti zadatke kao završene')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.background,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: sw * 0.09,
          color: AppColors.accent,
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Zadaci za vježbu',
          style: GoogleFonts.inter(
            fontSize: sw * 0.06,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
      ),
      body: FutureBuilder<List<PendingTaskSet>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: sw * 0.5,
                height: sw * 0.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Greška pri dohvaćanju zadataka',
                style: GoogleFonts.inter(
                  fontSize: sw * 0.04,
                  color: AppColors.tertiary,
                ),
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: sw * 0.2, color: AppColors.odlican),
                  SizedBox(height: sw * 0.04),
                  Text(
                    'Nema zadataka za vježbu',
                    style: GoogleFonts.inter(
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: sw * 0.02),
                  Text(
                    'Odličan posao!',
                    style: GoogleFonts.inter(
                      fontSize: sw * 0.04,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(sw * 0.04),
            itemCount: tasks.length,
            itemBuilder: (context, index) =>
                _TaskCard(taskSet: tasks[index], onComplete: _completeTaskSet),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final PendingTaskSet taskSet;
  final Future<void> Function(int id) onComplete;

  const _TaskCard({required this.taskSet, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final dateStr = DateFormat('dd.MM.yyyy').format(taskSet.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: sw * 0.03, horizontal: sw * 0.04),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  taskSet.subjectName,
                  style: GoogleFonts.inter(
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: sw * 0.032,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Task list
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...taskSet.tasks.map(
                  (task) => Padding(
                    padding: EdgeInsets.only(bottom: sw * 0.02),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: sw * 0.005),
                          child: Icon(Icons.circle,
                              size: sw * 0.02, color: AppColors.accent),
                        ),
                        SizedBox(width: sw * 0.025),
                        Expanded(
                          child: Text(
                            task,
                            style: GoogleFonts.inter(
                              fontSize: sw * 0.038,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sw * 0.02),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => onComplete(taskSet.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.odlican,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Završeno',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
