import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
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
  late Future<Map<String, dynamic>> _profileFuture;

  Future<Map<String, dynamic>> _fetchProfile() async {
    final box = await Hive.openBox('User');
    final email = box.get('email');
    final isConnected = box.get('isConnected') ?? false;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .get();

      return {
        'email': email,
        'isConnected': isConnected,
        'pfp': docSnapshot.exists && docSnapshot.data() != null
            ? docSnapshot.data()!['pfp']
            : null,
      };
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Lottie.asset(
                "assets/animations/loadingBird.json",
                width: MediaQuery.of(context).size.width * 0.80,
                height: 120,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: screenWidth * 0.05,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
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
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    "Profil",
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    ),
                    child: Row(
                      children: [
                        data['pfp'] != null
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(data['pfp']!),
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
                              "${data['email']}",
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: screenWidth * 0.043,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              'Pokaži profil',
                              style: GoogleFonts.inter(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w400,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(
                          Ionicons.chevron_forward_outline,
                          color: AppColors.accent,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  GestureDetector(
                    onTap: data['isConnected']
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
                        isConnected: data['isConnected'],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "Općenito",
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
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
                      color: AppColors.secondary,
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
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }
}
