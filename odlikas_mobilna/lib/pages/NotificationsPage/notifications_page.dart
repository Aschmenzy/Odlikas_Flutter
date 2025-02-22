import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/NotificationsPage/Widgets/notificationTile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 30, right: 30, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.04),
              Row(
                children: [
                  IconButton(
                    iconSize: 36,
                    color: AppColors.accent,
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Text("Obavijesti",
                  style: GoogleFonts.inter(
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary)),

              SizedBox(height: size.height * 0.04),

              //notifications options
              NotificationTile(
                label: "Ispiti",
                path: "assets/images/tests.png",
                value: false,
              ),
              NotificationTile(
                  label: "Učenje",
                  path: "assets/images/learning.png",
                  value: false),
              NotificationTile(
                  label: "Prvi sat",
                  path: "assets/images/firstPeriod.png",
                  value: false),
              NotificationTile(
                  label: "Odgovori poslodavaca",
                  path: "assets/images/answers.png",
                  value: false),
              NotificationTile(
                label: "Nova ocjena",
                path: "assets/images/newGrade.png",
                value: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
