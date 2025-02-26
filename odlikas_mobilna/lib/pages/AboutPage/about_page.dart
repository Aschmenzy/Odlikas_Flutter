import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content on top
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.02),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: size.width * 0.09,
                          color: AppColors.accent,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Text(
                      "ODLIKAŠ",
                      style: GoogleFonts.inter(
                        fontSize: size.width * 0.075,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      width: size.width * 0.8, // Constrain text width
                      child: Text(
                        "Tvoj Pametni Prijatelj za Školu",
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.inter(
                          fontSize: size.width * 0.055,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Container(
                      width: size.width,
                      height: size.height * 0.25,
                      child: Image.asset(
                        'assets/images/odlikasAboutPagerLogo.png',
                        width: 275,
                        height: 275,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Background image at the bottom (positioned as a background)
          Positioned(
            bottom: 0,
            left: size.width * -0.03,
            right: size.width * -0.25,
            child: Container(
              width: size.width * 1.28,
              height: size.height * 0.55,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/abouPagePozadina.png"),
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: size.height * 0.03,
                  left: size.width * 0.1,
                  right: size.width * 0.3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.05),
                    Container(
                      width: size.width * 0.9,
                      child: Column(
                        children: [
                          Text(
                            "ODLIKAŠ je inovativna aplikacija stvorena kako bi osnovnoškolcima i srednjoškolcima pomogla u organizaciji školskih obaveza i učenju.",
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            "Prvotno razvijena kao projekt za natjecanje Razvoj softvera 2024/2025, aplikacija je brzo postala mnogo više, nezaobilazan alat za svakog učenika koji želi postići bolje rezultate uz bolju organizaciju i manje stresa.",
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            "ODLIKAŠ je više od obične aplikacije,   to je osobni asistent za školu koji pomaže učenicima da ostanu organizirani, smanje stres i postignu najbolje moguće rezultate.",
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
