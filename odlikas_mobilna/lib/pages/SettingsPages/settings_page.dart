import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/pages/AboutPage/about_page.dart';
import 'package:odlikas_mobilna/pages/ConnectToScreenPage/in_between_page.dart';
import 'package:odlikas_mobilna/pages/CritiquePage/critique_page.dart';
import 'package:odlikas_mobilna/pages/IntroPage/intro_page.dart';
import 'package:odlikas_mobilna/pages/NotificationsPage/notifications_page.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/update_preferences_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/card.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/dislexycTile.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/settingsTile.dart';
import 'package:odlikas_mobilna/pages/ProfilePage/profile_page.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';
import 'package:odlikas_mobilna/pages/TermsAndConditionsPage/terms_and_conditions_page.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDyslexic = false;
  String? userEmail;
  bool isLoading = true;

  late Future<Map<String, dynamic>> _profileFuture;

  Future<void> _loadUserData() async {
    final box = await Hive.openBox('User');
    userEmail = box.get('email');

    print('Loading user data for email: $userEmail'); // Debug log

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
            print('Loaded preferences data: $data'); // Debug log
            setState(() {
              isDyslexic = data['dyslexic'] ?? false;
            });
          }
        }
      } catch (e) {
        print('Error loading notification preferences: $e');
      }
    } else {
      print('Cannot load preferences: User email is null');
    }

    setState(() {
      isLoading = false;
    });
  }

// Replace your _saveNotificationPreferences function with this version:
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

// Update the _fetchProfile function to use userEmail instead of Email
  Future<Map<String, dynamic>> _fetchProfile() async {
    final box = await Hive.openBox('User');
    userEmail = box.get('email');
    final isConnected = box.get('isConnected') ?? false;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(userEmail)
          .get();

      return {
        'email': userEmail,
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

  void _signOut() async {
    final box = await Hive.openBox('User');
    await box.clear();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => IntroPage()));
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);

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
                    style: fontService.font(
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    "Profil",
                    style: fontService.font(
                        fontSize: screenWidth * 0.075,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                        height: 1.1),
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
                              style: fontService.font(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              'Pokaži profil',
                              style: fontService.font(
                                fontSize: screenWidth * 0.044,
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
                                  builder: (context) => InBetweenPage()),
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
                    style: fontService.font(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  SettingsTile(
                    label: "Obavjesti",
                    path: "assets/images/notification.png",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsPage()),
                    ),
                  ),
                  DislexycTile(
                    label: "Dislekcijski tekst",
                    path: "assets/images/dyslexia.png",
                    value: isDyslexic,
                    onChanged: (newValue) {
                      setState(() {
                        isDyslexic = newValue;
                      });
                      _saveNotificationPreferences(
                        field: 'dyslexic',
                        value: newValue,
                      );

                      //change the font of the app
                      context.read<FontService>().toggleDyslexicMode();
                    },
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
                    style: fontService.font(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  SettingsTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutPage()),
                    ),
                    label: "Opis ODLIKAŠA",
                    path: "assets/icon/odlikasIconLogo.png",
                  ),
                  SettingsTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CritiquePage()),
                    ),
                    label: "Kritike",
                    path: "assets/images/thumbs.png",
                  ),
                  SettingsTile(
                    isLast: true,
                    label: "Odjavite se",
                    path: "assets/images/logOut.png",
                    onTap: _signOut,
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
