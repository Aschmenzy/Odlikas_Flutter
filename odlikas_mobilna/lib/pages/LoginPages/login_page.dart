// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/preferences_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:odlikas_mobilna/utilities/text_field.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

Future<StudentProfile?> handleLogin(
    BuildContext context, String email, String password) async {
  final _homeViewModel = HomePageViewModel(ApiService());

  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef =
        firestore.collection('studentProfiles').doc(email);
    var profile = await _homeViewModel.fetchStudentProfile(email, password);

    //check for N/A values in profile data
    Map<String, String> fields = {
      'School': profile?.studentSchool ?? '',
      'City': profile?.studentSchoolCity ?? '',
      'School Year': profile?.studentSchoolYear ?? '',
      'Grade': profile?.studentGrade ?? '',
      'Name': profile?.studentName ?? '',
      'Class Master': profile?.classMaster ?? '',
      'Program': profile?.studentProgram ?? '',
    };

    for (var entry in fields.entries) {
      if (entry.value == 'N/A') {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Neispravni podatci',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Korisničko ime ili lozinka nisu ispravni. Molimo pokušajte ponovno.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        profile = null;
        break; // Exit the loop after showing the dialog
      }
    }

    if (profile != null) {
      // Save in the same format as your fromJson expects
      Map<String, dynamic> profileData = {
        'studentProfile': {
          'studentSchool': profile.studentSchool,
          'studentSchoolCity': profile.studentSchoolCity,
          'studentSchoolYear': profile.studentSchoolYear,
          'studentGrade': profile.studentGrade,
          'studentName': profile.studentName,
          'studentProgram': profile.studentProgram,
          'classMaster': profile.classMaster,
        }
      };

      await docRef.set(profileData);
      Navigator.replace(
        context,
        oldRoute: ModalRoute.of(context)!,
        newRoute: MaterialPageRoute(builder: (context) => PreferencesPage()),
      );
    } else {
      print('Profile data is null');
    }

    return profile;
  } catch (e) {
    print("Error fetching student profile: $e");

    // Show error dialog
    await showDialog(
      context: context, // You'll need to pass the BuildContext to this function
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content:
              const Text('Failed to fetch student profile. Please try again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return null;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                controller: emailController,
                labelText: "Tvoje korisničko ime",
                obscureText: false,
                hintText: "ime.prezime@skole.hr",
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.09),
              MyTextField(
                controller: passwordController,
                labelText: "Tvoja lozinka",
                obscureText: true,
                enabled: true,
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.11),
              MyButton(
                fontSize: 24,
                buttonText: "PRIJAVI SE",
                ontap: () {
                  handleLogin(
                      context, emailController.text, passwordController.text);
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
  }
}
