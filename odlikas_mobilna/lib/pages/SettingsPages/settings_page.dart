import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/database/api/auth_storage.dart';
import 'package:odlikas_mobilna/database/api/dio_client.dart';
import 'package:odlikas_mobilna/database/api/login_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/pages/AboutPage/about_page.dart';
import 'package:odlikas_mobilna/pages/ConnectToScreenPage/in_between_page.dart';
import 'package:odlikas_mobilna/pages/IntroPage/intro_page.dart';
import 'package:odlikas_mobilna/pages/NotificationsPage/notifications_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/card.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/dislexycTile.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/settingsTile.dart';
import 'package:odlikas_mobilna/pages/ProfilePage/profile_page.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';
import 'package:odlikas_mobilna/pages/TermsAndConditionsPage/terms_and_conditions_page.dart';
import 'package:odlikas_mobilna/pages/UploadFilesOdlikasPlus/upload_files_odlikas_plus.dart';
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

    print('Loading user data for email: $userEmail');

    if (userEmail != null) {
      // Try to load existing preferences
      try {
        final doc = await FirebaseFirestore.instance
            .collection("dyslexicUsers")
            .doc(userEmail)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            print('Loaded preferences data: $data');
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

// funkcija koja sprema korisnike koji imaju dislekciju u posebnu bazu podataka kako bi se aplikacija lakše prilagodila njima
  Future<void> _saveDyslexicUsers({
    required String field,
    required bool value,
  }) async {
    if (userEmail == null) {
      print('Cannot save preferences: User email is null');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("dyslexicUsers")
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

  //funkcija koja dohavca podatke okorisniku i vrcaca je li korisnik povezan s ekranom ili nije
  Future<Map<String, dynamic>> _fetchProfile() async {
    final box = await Hive.openBox('User');
    userEmail = box.get('email');

    if (userEmail == null) {
      throw Exception("User email is null. Cannot fetch profile.");
    }

    final isConnected = box.get('screenConnected') ?? false;

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

  //funkcija koja vraca korisnika na into page i brise sve podatke iz lokalnog storega
  Future<void> _signOut() async {
    // Invalidate server session (best-effort)
    final token = await AuthStorage.readToken();
    if (token != null) await LoginService.logout(token);

    // Wipe secure storage and reset Dio so no stale token is cached
    await AuthStorage.clearAll();
    DioClient.reset();

    // Clear non-sensitive Hive display data
    final box = await Hive.openBox('User');
    await box.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => IntroPage()),
    );
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
                'Error loading profile: ${snapshot.error}',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No profile data available',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
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
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    "Profil",
                    style: fontService.font(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w600,
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
                    label: "Obavijesti",
                    path: "assets/images/notification.png",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsPage()),
                    ),
                  ),
                  data['isConnected']
                      ? SettingsTile(
                          label: "Prenesi datoteke - Odlikaš+",
                          path: "assets/images/odlikas_plus_upload_90x90.png",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UploadFilesOdlikasPlus()),
                          ),
                        )
                      : Container(),
                  DislexycTile(
                    label: "Dislekcijski tekst",
                    path: "assets/images/dyslexia.png",
                    value: isDyslexic,
                    onChanged: (newValue) {
                      setState(() {
                        isDyslexic = newValue;
                      });
                      _saveDyslexicUsers(
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
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 2),
    );
  }
}
