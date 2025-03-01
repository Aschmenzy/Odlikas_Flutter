import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';
import 'package:provider/provider.dart';

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

  // Funkcija za dohvaćanje prvog predmeta iz rasporeda za današnji dan
  Future<void> _fetchfistSubject() async {
    // Dohvaćanje email adrese korisnika iz lokalne pohrane
    final email = (await Hive.openBox('User')).get("email");

    String today = getTodaySchedule();

    print("start fetching first subject for $today");

    try {
      // Dohvaćanje dokumenta korisnika iz Firestore baze podataka
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("studentProfiles")
          .doc(email)
          .get();

      // Provjera postoji li dokument za korisnika
      if (doc.exists) {
        // Pretvaranje podataka dokumenta u Map strukturu
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Dohvaćanje glavnog kontejnera rasporeda
        Map<String, dynamic> scheduleContainer =
            data['schedule'] as Map<String, dynamic>;
        // Dohvaćanje liste rasporeda po danima
        List<dynamic> scheduleList =
            scheduleContainer['schedule'] as List<dynamic>;

        // Pronalaženje rasporeda za današnji dan
        // Ako ne postoji, vraća null kroz orElse funkciju
        var todaySchedule = scheduleList
            .firstWhere((item) => item['day'] == today, orElse: () => null);

        // Provjera je li pronađen raspored za danas
        if (todaySchedule != null) {
          // Dohvaćanje liste predmeta za današnji dan
          List<dynamic> subjects = todaySchedule['subjects'] as List<dynamic>;
          // Provjera postoji li barem jedan predmet u rasporedu
          if (subjects.isNotEmpty) {
            // Ažuriranje stanja widgeta s prvim predmetom
            setState(() {
              currentSubject = subjects[0].toString();
            });
            print("First subject set to: $currentSubject");
          }
        } else {
          // Poruka ako nema rasporeda za današnji dan
          print("No schedule found for today");
          // Postavljanje informacije da nema nastave
          setState(() {
            currentSubject = "Unesite raspored";
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
    final fontService = Provider.of<FontService>(context);

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
                        style: fontService.font(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary),
                      ),
                      Text("Pogledaj i uredi svoj raspored",
                          style: fontService.font(
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
                            style: fontService.font(
                              height: 1.2,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: screenHeight * 0.002,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: screenWidth * 0.083),
                          Text(
                            currentSubject ?? "Nema nastave",
                            textAlign: TextAlign.center,
                            style: fontService.font(
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
