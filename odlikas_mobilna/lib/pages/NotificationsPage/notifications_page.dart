import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/NotificationsPage/Widgets/notificationTile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // State for switches
  bool ispitiEnabled = false;
  bool ucenjeEnabled = false;
  bool prviSatEnabled = false;
  bool odgovoriEnabled = false;
  bool novaOcjenaEnabled = false;

  // User email from Hive
  String? userEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data and notification preferences
  Future<void> _loadUserData() async {
    final box = await Hive.openBox('User');
    userEmail = box.get('email');

    if (userEmail != null) {
      // Try to load existing preferences
      try {
        final doc = await FirebaseFirestore.instance
            .collection("StudentNotificationsPreferences")
            .doc(userEmail)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              ispitiEnabled = data['ispiti'] ?? false;
              ucenjeEnabled = data['ucenje'] ?? false;
              prviSatEnabled = data['prviSat'] ?? false;
              odgovoriEnabled = data['odgovoriPoslodavaca'] ?? false;
              novaOcjenaEnabled = data['novaOcjena'] ?? false;
            });
          }
        }
      } catch (e) {
        print('Error loading notification preferences: $e');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // Save notification preferences to Firebase
  Future<void> _saveNotificationPreferences({
    required String field,
    required bool value,
  }) async {
    if (userEmail == null) {
      print('Cannot save preferences: User email is null');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("StudentNotificationsPreferences")
          .doc(userEmail)
          .set({
        field: value,
      }, SetOptions(merge: true));

      print('Successfully updated $field to $value');
    } catch (e) {
      print('Error saving notification preference: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri spremanju postavki obavijesti'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Lottie.asset(
            'assets/animations/loadingBird.json',
            width: MediaQuery.of(context).size.width * 0.80,
            height: 120,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.02),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.accent),
                  iconSize: 35,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // "Obavijesti" header
              Center(
                child: Text(
                  "Obavijesti",
                  style: GoogleFonts.inter(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // Notification tiles
              NotificationTile(
                label: "Ispiti",
                iconWidget: Image.asset(
                  'assets/images/tests.png',
                  width: 35,
                  height: 35,
                ),
                value: ispitiEnabled,
                onChanged: (newValue) {
                  setState(() {
                    ispitiEnabled = newValue;
                  });
                  _saveNotificationPreferences(
                    field: 'ispiti',
                    value: newValue,
                  );
                },
              ),

              NotificationTile(
                label: "Učenje",
                iconWidget: Image.asset(
                  'assets/images/learning.png',
                  width: 35,
                  height: 35,
                ),
                value: ucenjeEnabled,
                onChanged: (newValue) {
                  setState(() {
                    ucenjeEnabled = newValue;
                  });
                  _saveNotificationPreferences(
                    field: 'ucenje',
                    value: newValue,
                  );
                },
              ),

              NotificationTile(
                label: "Prvi sat",
                iconWidget: Image.asset(
                  'assets/images/firstPeriod.png',
                  width: 35,
                  height: 35,
                ),
                value: prviSatEnabled,
                onChanged: (newValue) {
                  setState(() {
                    prviSatEnabled = newValue;
                  });
                  _saveNotificationPreferences(
                    field: 'prviSat',
                    value: newValue,
                  );
                },
              ),

              NotificationTile(
                label: "Odgovori poslodavaca",
                iconWidget: Image.asset(
                  'assets/images/answers.png',
                  width: 35,
                  height: 35,
                ),
                value: odgovoriEnabled,
                onChanged: (newValue) {
                  setState(() {
                    odgovoriEnabled = newValue;
                  });
                  _saveNotificationPreferences(
                    field: 'odgovoriPoslodavaca',
                    value: newValue,
                  );
                },
              ),

              NotificationTile(
                label: "Nova ocjena",
                iconWidget: Image.asset(
                  'assets/images/newGrade.png',
                  width: 35,
                  height: 35,
                ),
                value: novaOcjenaEnabled,
                onChanged: (newValue) {
                  setState(() {
                    novaOcjenaEnabled = newValue;
                  });
                  _saveNotificationPreferences(
                    field: 'novaOcjena',
                    value: newValue,
                  );
                },
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
