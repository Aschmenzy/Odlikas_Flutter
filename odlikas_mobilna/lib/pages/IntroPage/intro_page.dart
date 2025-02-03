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
            Image.asset(
              'assets/images/globe.png',
              width: MediaQuery.of(context).size.width * 1,
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
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                "Quisque luctus justo sed fermentum rhoncus. "
                "Aliquam sed leo in metus placerat scelerisque.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tertiary,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            MyButton(
              fontSize: 24,
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
          ],
        ),
      ),
    );
  }
}
