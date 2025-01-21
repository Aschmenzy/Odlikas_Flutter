import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/pages/IntroPage/intro_page.dart';
import 'package:odlikas_mobilna/pages/JobsPage/jobs_page.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/pomodoro_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/settings_page.dart';
import 'database/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.openBox('User');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const IntroPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/jobs': (context) => const JobsPage(),
        '/pomodoro': (context) => const PomodoroPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
