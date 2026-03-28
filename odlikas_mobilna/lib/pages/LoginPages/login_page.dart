import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/api/auth_storage.dart';
import 'package:odlikas_mobilna/database/api/login_service.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/exceptions/app_exceptions.dart';
import 'package:odlikas_mobilna/pages/PreferencesPage/preferences_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:odlikas_mobilna/pages/LoginPages/Widgets/text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _initNotifications(String email) async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .update({'studentProfile.fcmToken': token});
    }
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      Navigator.pushNamed(context, '/grades');
    });
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      // 1 — Get Bearer token from the API
      final token = await LoginService.login(email, password);

      // 2 — Store token + credentials in secure storage
      await AuthStorage.saveToken(token);
      await AuthStorage.saveCredentials(email: email, password: password);

      // 3 — Fetch profile using the token (interceptor attaches it automatically)
      final profile = await ApiService().fetchStudentProfile();

      // 4 — Validate profile (N/A means bad credentials slipped through)
      final fields = {
        'School': profile.studentSchool,
        'City': profile.studentSchoolCity,
        'Year': profile.studentSchoolYear,
        'Grade': profile.studentGrade,
        'Name': profile.studentName,
        'Master': profile.classMaster,
        'Program': profile.studentProgram,
      };
      if (fields.values.any((v) => v == 'N/A')) {
        await AuthStorage.clearAll();
        _showErrorDialog('Izgleda da ste unijeli krive podatke');
        return;
      }

      // 5 — Save non-sensitive display data to Hive (used throughout the app)
      final box = await Hive.openBox('User');
      await box.put('email', email);
      await box.put('studentName', profile.studentName);
      await box.put('studentSchool', profile.studentSchool);
      await box.put('studentProgram', profile.studentProgram);

      // 6 — Save profile to Firestore — no password field
      await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .set({
        'studentProfile': {
          'studentSchool': profile.studentSchool,
          'studentSchoolCity': profile.studentSchoolCity,
          'studentSchoolYear': profile.studentSchoolYear,
          'studentGrade': profile.studentGrade,
          'studentName': profile.studentName,
          'studentProgram': profile.studentProgram,
          'classMaster': profile.classMaster,
          'studentEmail': email,
        }
      }, SetOptions(merge: true));

      await _initNotifications(email);

      if (!mounted) return;
      Navigator.replace(
        context,
        oldRoute: ModalRoute.of(context)!,
        newRoute: MaterialPageRoute(builder: (_) => PreferencesPage()),
      );
    } on RateLimitException catch (e) {
      _showErrorDialog(e.message);
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog('Prijava nije uspjela. Provjeri internet vezu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.w600,
                  color: AppColors.background,
                ),
              ),
              const SizedBox(height: 16),
              MyButton(
                buttonText: 'Pokušajte ponovno',
                ontap: () => Navigator.of(context).pop(),
                height: MediaQuery.of(context).size.height * 0.04,
                width: MediaQuery.of(context).size.width * 0.45,
                decorationColor: AppColors.accent,
                borderColor: AppColors.accent,
                textColor: AppColors.background,
                fontWeight: FontWeight.w700,
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ],
          ),
        ),
      ),
    );
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
                        'assets/images/loginPasswHidden.png',
                        height: MediaQuery.of(context).size.width * 0.65,
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                  MyTextField(
                    controller: _emailController,
                    labelText: "Tvoje korisničko ime",
                    obscureText: false,
                    hintText: "ime.prezime@skole.hr",
                    enabled: !_isLoading,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.12),
                  MyTextField(
                    controller: _passwordController,
                    labelText: "Tvoja lozinka",
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  MyButton(
                    fontSize: 24,
                    buttonText: "PRIJAVI SE",
                    ontap: _isLoading ? null : _handleLogin,
                    height: MediaQuery.of(context).size.width * 0.175,
                    width: MediaQuery.of(context).size.width * 1,
                    decorationColor:
                        _isLoading ? AppColors.tertiary : AppColors.primary,
                    borderColor:
                        _isLoading ? AppColors.tertiary : AppColors.primary,
                    textColor: AppColors.background,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.08),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
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
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
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
                    const SizedBox(height: 20),
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
