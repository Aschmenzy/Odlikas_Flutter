import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';

class ScheduleCard extends StatefulWidget {
  const ScheduleCard({Key? key}) : super(key: key);

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  String? currentSubject;

  String getTodaySchedule() {
    DateTime now = DateTime.now();
    String day = '';

    switch (now.weekday) {
      case DateTime.monday:
        day = "PON Morning";
        break;
      case DateTime.tuesday:
        day = "UTO Morning";
        break;
      case DateTime.wednesday:
        day = "SRI Morning";
        break;
      case DateTime.thursday:
        day = "CET Morning";
        break;
      case DateTime.friday:
        day = "PET Morning";
        break;
      case DateTime.saturday:
      case DateTime.sunday:
        day = "PON Morning";
        break;
    }

    print("Today is: $day");
    return day;
  }

  Future<void> _fetchfistSubject() async {
    final box = await Hive.openBox('User');
    final email = await box.get('email');
    String today = getTodaySchedule();

    print("start fetching first subject for $today");

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("studentProfiles")
          .doc(email)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Navigate through the nested schedule structure
        Map<String, dynamic> scheduleContainer =
            data['schedule'] as Map<String, dynamic>;
        List<dynamic> scheduleList =
            scheduleContainer['schedule'] as List<dynamic>;

        // Find today's schedule
        var todaySchedule = scheduleList
            .firstWhere((item) => item['day'] == today, orElse: () => null);

        if (todaySchedule != null) {
          List<dynamic> subjects = todaySchedule['subjects'] as List<dynamic>;
          if (subjects.isNotEmpty) {
            setState(() {
              currentSubject = subjects[0].toString();
            });
            print("First subject set to: $currentSubject");
          }
        } else {
          print("No schedule found for today");
          setState(() {
            currentSubject = "Nema nastave";
          });
        }
      }
    } catch (e) {
      print("Error fetching schedule: $e");
      setState(() {
        currentSubject = "Error loading schedule";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchfistSubject();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SchedulePage()),
      ),
      child: Card(
          color: AppColors.background,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: SizedBox(
            width: screenWidth * 0.4,
            height: screenHeight * 0.15,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      topRight: Radius.circular(15.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Raspored",
                        style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary),
                      ),
                      Text("Pogledaj i uredi svoj raspored",
                          style: GoogleFonts.inter(
                              fontSize: screenWidth * 0.025,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15.0),
                      bottomRight: Radius.circular(15.0),
                    ),
                    color: AppColors.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: screenWidth * 0.02),
                          Image.asset(
                            "assets/images/scheduleWidgetIcon.png",
                            scale: 1.8,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            "Prvi sat",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              height: 1.2,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentSubject ?? "Nema nastave",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              height: 1.2,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
