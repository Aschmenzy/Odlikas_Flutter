import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/preferences_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/card.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/Widgets/settingsTile.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/connect_screen.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/profile_page.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                fontSize: MediaQuery.of(context).size.width * 0.09,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Text(
              "Profil",
              style: GoogleFonts.inter(
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            //profile settings
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              ),
              child: Row(
                children: [
                  Image(
                      image: AssetImage("assets/images/profile.png"),
                      width: MediaQuery.of(context).size.width * 0.16),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "antonio.kocijan@skole.hr",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        'Pokaži profil',
                        style: GoogleFonts.inter(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.w400,
                            color: AppColors.tertiary),
                      ),
                    ],
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Icon(
                    Ionicons.chevron_forward_outline,
                    color: AppColors.accent,
                    size: MediaQuery.of(context).size.width * 0.06,
                  )
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            //connect screen and phone
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConnectScreen()),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                height: MediaQuery.of(context).size.height * 0.17,
                child: ShareScreenCard(),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            //opcenito section
            Text(
              "Općenito",
              style: GoogleFonts.inter(
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

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
                MaterialPageRoute(builder: (context) => PreferencesPage()),
              ),
              label: "Mijenjane učenja",
              path: "assets/images/schedule.png",
            ),
            SettingsTile(
              isLast: true,
              label: "Odredbe i uvjeti",
              path: "assets/images/lawBook.png",
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.023),

            Text(
              "Podrška",
              style: GoogleFonts.inter(
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            SettingsTile(
              label: "Opis ODLIKAŠA",
              path: "assets/images/board.png",
            ),

            SettingsTile(
              label: "Centar za podršku",
              path: "assets/images/help.png",
            ),

            SettingsTile(
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
