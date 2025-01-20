import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/preferences_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:odlikas_mobilna/utilities/text_field.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _homeViewModel = HomePageViewModel(ApiService());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _homeViewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 50,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Prijavi se i postani \nODLIKAŠ",
                    style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.09,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    "Bez stresa i bez brige",
                    style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/login.png',
                        height: MediaQuery.of(context).size.width * 0.65,
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                  MyTextField(
                    controller: TextEditingController(),
                    labelText: "Tvoje korisničko ime",
                    obscureText: false,
                    hintText: "ime.prezime@skole.hr",
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.09),
                  MyTextField(
                    controller: TextEditingController(),
                    labelText: "Tvoja lozinka",
                    obscureText: true,
                    enabled: true,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.11),
                  MyButton(
                    fontSize: 24,
                    buttonText: "PRIJAVI SE",
                    ontap: () {
                      Navigator.replace(
                        context,
                        oldRoute: ModalRoute.of(context)!,
                        newRoute: MaterialPageRoute(
                            builder: (context) => PreferencesPage()),
                      );
                    },
                    height: MediaQuery.of(context).size.width * 0.175,
                    width: MediaQuery.of(context).size.width * 1,
                    decorationColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    textColor: AppColors.background,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                          children: [
                            TextSpan(
                                text:
                                    'Kliknućem tipke PRIJAVI SE slažete se sa \n    ODLIKAŠEVIM',
                                style: GoogleFonts.inter(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  color: AppColors.tertiary,
                                  fontWeight: FontWeight.w800,
                                )),
                            TextSpan(
                              text: ' odredbama i uvjetima',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
