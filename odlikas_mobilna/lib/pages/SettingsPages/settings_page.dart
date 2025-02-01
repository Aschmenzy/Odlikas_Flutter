import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/update_preferences_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/card.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/settingsTile.dart';
import 'package:odlikas_mobilna/pages/ConnectToScreenPage/connect_screen.dart';
import 'package:odlikas_mobilna/pages/ProfilePage/profile_page.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';
import 'package:odlikas_mobilna/pages/TermsAndConditionsPage/terms_and_conditions_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? email;
  String? studentSchool;
  String? studentProgram;
  late bool isConnected = false;
  String? _pfpBase64;

//getting user data from local storage
  Future<void> _fetchProfile() async {
    final box = await Hive.openBox('User');

    setState(() {
      email = box.get('email');
      isConnected = box.get('isConnected');
    });

    try {
      // Get the user profile data from firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(box.get('email'))
          .get();

      // Assign values to class variables
      if (docSnapshot.exists) {
        setState(() {
          _pfpBase64 = docSnapshot.data()?['pfp'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.only(left: 30, right: 30, top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Postavke",
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.09,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            Text(
              "Profil",
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            //profile settings
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              ),
              child: Row(
                children: [
                  _pfpBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_pfpBase64!),
                            width: screenWidth * 0.2,
                            height: screenWidth * 0.2,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          "assets/images/profile.png",
                          width: screenWidth * 0.2,
                        ),
                  SizedBox(width: screenWidth * 0.03),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$email",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.043,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        'Pokaži profil',
                        style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w400,
                            color: AppColors.tertiary),
                      ),
                    ],
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Icon(
                    Ionicons.chevron_forward_outline,
                    color: AppColors.accent,
                    size: screenWidth * 0.06,
                  )
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.012),

            //connect screen and phone
            GestureDetector(
              // da ako je connected da ne moze ici na connect screen
              onTap: isConnected
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ConnectScreen()),
                      );
                    },
              child: SizedBox(
                width: screenWidth * 1,
                height: screenHeight * 0.17,
                child: ShareScreenCard(
                  isConnected: isConnected,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            //opcenito section
            Text(
              "Općenito",
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            SettingsTile(
              label: "Obavjesti",
              path: "assets/images/notification.png",
            ),

            SettingsTile(
              label: "Dislekcijski tekst",
              path: "assets/images/dyslexia.png",
            ),
            SettingsTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SchedulePage()),
              ),
              label: "Upisivanje rasporeda",
              path: "assets/images/board.png",
            ),
            SettingsTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UpdatePreferencesPage()),
              ),
              label: "Mijenjane učenja",
              path: "assets/images/schedule.png",
            ),
            SettingsTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TermsAndConditionsPage()),
              ),
              isLast: true,
              label: "Odredbe i uvjeti",
              path: "assets/images/lawBook.png",
            ),

            SizedBox(height: screenHeight * 0.023),

            Text(
              "Podrška",
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            SettingsTile(
              label: "Opis ODLIKAŠA",
              path: "assets/images/board.png",
            ),

            SettingsTile(
              label: "Centar za podršku",
              path: "assets/images/help.png",
            ),

            SettingsTile(
              isLast: true,
              label: "Kritike",
              path: "assets/images/thumbs.png",
            ),
          ],
        ),
      )),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }
}
