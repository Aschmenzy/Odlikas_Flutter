// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/student_profile.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/preferences_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:odlikas_mobilna/pages/LoginPages/Widgets/text_field.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

Future<StudentProfile?> handleLogin(
    BuildContext context, String email, String password) async {
  final _homeViewModel = HomePageViewModel(ApiService());

  // Otvaranje Hive box-a za spremanje podataka korisnika na lokalnom uređaju
  final box = await Hive.openBox('User');

  try {
    // Inicijalizacija Firestore-a i reference na dokument korisnika
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef =
        firestore.collection('studentProfiles').doc(email);

    // Dohvaćanje profila učenika preko API-ja
    var profile = await _homeViewModel.fetchStudentProfile(email, password);

    // Provjera "N/A" vrijednosti u podacima profila
    // Ako postoji "N/A" vrijednost, to znači da su uneseni podaci nevažeći
    Map<String, String> fields = {
      'School': profile?.studentSchool ?? '',
      'City': profile?.studentSchoolCity ?? '',
      'School Year': profile?.studentSchoolYear ?? '',
      'Grade': profile?.studentGrade ?? '',
      'Name': profile?.studentName ?? '',
      'Class Master': profile?.classMaster ?? '',
      'Program': profile?.studentProgram ?? '',
    };

    // Prolazak kroz sve vrijednosti i provjera postoji li "N/A"
    for (var entry in fields.entries) {
      if (entry.value == 'N/A') {
        // Prikaz dijaloga o pogrešnom unosu
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Lottie.asset(
                        'assets/animations/error.json',
                        height: MediaQuery.of(context).size.width * 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Izgleda da ste unijeli krive podatke',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.w600,
                          color: AppColors.background),
                    ),
                    const SizedBox(height: 16),
                    MyButton(
                        buttonText: "Pokušajte ponovno",
                        ontap: () => Navigator.of(context).pop(),
                        height: MediaQuery.of(context).size.height * 0.04,
                        width: MediaQuery.of(context).size.width * 0.45,
                        decorationColor: AppColors.accent,
                        borderColor: AppColors.accent,
                        textColor: AppColors.background,
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.of(context).size.width * 0.035)
                  ],
                ),
              ),
            );
          },
        );
        // Postavljanje profila na null kako bi se spriječila daljnja obrada
        profile = null;
        break;
      }
    }

    // Ako je profil uspješno dohvaćen i provjeren
    if (profile != null) {
      // Priprema podataka profila za pohranu u Firestore
      // Podaci se pohranjuju u podkolekciju 'studentProfile' dokumenta korisnika
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

      // Pohrana podataka za prijavu i osnovnih informacija o korisniku lokalno
      // Podaci se pohranjuju u Hive box 'User'
      // lozinka se sprema lokalno kako bi se koristila kasnije u aplikaciji za dohvaćanje podataka pomocu API-a
      // i za prijavu korisnika na odlikas+ kada skeniraju QR kod
      await box.put('email', email);
      await box.put('password', password);
      await box.put('studentName', profile?.studentName);
      await box.put('studentSchool', profile?.studentSchool);
      await box.put('studentProgram', profile?.studentProgram);

      // Ažuriranje ili kreiranje dokumenta u Firestore bazi
      await docRef.set(profileData, SetOptions(merge: true));

      // Navigacija na stranicu postavki
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

    // Prikaz dijaloga o grešci
    await showDialog(
      context: context,
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
  bool isLoading = false;

  Future<void> _handleLogin() async {
    // Sprječava višestruke prijave
    if (isLoading) return;

    setState(() {
      // Postavlja indikator učitavanja
      isLoading = true;
    });

    try {
      // Poziv funkcije za prijavu s pretvorenim emailom u mala slova kako bi se izbjegli problemi s kreiranjem korisnika
      await handleLogin(
        context,
        emailController.text.toLowerCase(),
        passwordController.text,
      );
    } finally {
      // Vraćanje stanja učitavanja na false nakon završetka
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  // Naslov aplikacije
                  Text(
                    "Prijavi se i postani \nODLIKAŠ",
                    style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.08,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                  // Podnaslov
                  Text(
                    "Bez stresa i bez brige",
                    style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary,
                    ),
                  ),
                  // Slika za prijavu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/loginPasswHidden.png',
                        height: MediaQuery.of(context).size.width * 0.65,
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                  // Polje za unos korisničkog imena
                  MyTextField(
                    controller: emailController,
                    labelText: "Tvoje korisničko ime",
                    obscureText: false,
                    hintText: "ime.prezime@skole.hr",
                    enabled: !isLoading,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.12),
                  // Polje za unos lozinke
                  MyTextField(
                    controller: passwordController,
                    labelText: "Tvoja lozinka",
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  // Gumb za prijavu
                  MyButton(
                    fontSize: 24,
                    buttonText: "PRIJAVI SE",
                    ontap: isLoading ? null : _handleLogin,
                    height: MediaQuery.of(context).size.width * 0.175,
                    width: MediaQuery.of(context).size.width * 1,
                    decorationColor:
                        isLoading ? AppColors.tertiary : AppColors.primary,
                    borderColor:
                        isLoading ? AppColors.tertiary : AppColors.primary,
                    textColor: AppColors.background,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.08),
                  // Tekst o uvjetima korištenja
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
                              ),
                            ),
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
          // Overlay za prikaz animacije učitavanja
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/loadingBird.json',
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.width * 0.3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Prijava u tijeku...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
