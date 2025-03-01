import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/LoginPages/Login_Page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),

            //postavljanje slike i animacije
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/spiningGlobeBackground.png',
                  width: MediaQuery.of(context).size.width,
                ),
                Image.asset(
                  'assets/animations/globeSpinning.gif',
                  width: MediaQuery.of(context).size.width,
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            Text(
              "Dobrodošli u\nODLIKAŠ",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Vaš osobni asistent za uspješno učenje. "
                "Pratite svoj e-dnevnik, primajte obavijesti o nadolazećim "
                "ispitima,  koristite Pomodoro timer za učinkovito učenje i "
                "organizirajte svoj raspored s kalendarom ispita.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                ),
              ),
            ),
            Spacer(),

            // botun za nastavak
            MyButton(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              buttonText: "NASTAVI",
              ontap: () {
                Navigator.replace(
                  context,
                  oldRoute: ModalRoute.of(context)!,
                  newRoute:
                      MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              height: MediaQuery.of(context).size.width * 0.175,
              width: MediaQuery.of(context).size.width * 190,
              decorationColor: AppColors.primary,
              borderColor: AppColors.primary,
              textColor: AppColors.background,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          ],
        ),
      ),
    );
  }
}
