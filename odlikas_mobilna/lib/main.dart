import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/database/models/testviewmodel.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/BannerPage/banner_page.dart';
import 'package:odlikas_mobilna/pages/SubjectsPage/subjects_page.dart';
import 'package:provider/provider.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/pages/JobsPage/jobs_page.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/pomodoro_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/settings_page.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'database/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // pozadinske notifikacije
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Hive.openBox('User');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FontService _fontService = FontService();

  @override
  void initState() {
    super.initState();
    // Initialize the font service
    _fontService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('User');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _fontService),
        ChangeNotifierProvider(create: (_) => HomePageViewModel(ApiService())),
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProxyProvider<ApiService, TestViewmodel>(
          create: (context) => TestViewmodel(context.read<ApiService>()),
          update: (_, apiService, previous) => TestViewmodel(apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: box.isEmpty ? const BannerPage() : const HomePage(),
        routes: {
          '/home': (context) => const HomePage(),
          '/jobs': (context) => const JobsPage(),
          '/pomodoro': (context) => const PomodoroPage(),
          '/settings': (context) => const SettingsPage(),
          '/grades': (context) => const SubjectsPage(),
        },
      ),
    );
  }
}
