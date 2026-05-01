import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:odlikas_mobilna/database/api/auth_storage.dart';
import 'package:safe_device/safe_device.dart';
import 'package:odlikas_mobilna/database/api/firebase_api.dart';
import 'package:odlikas_mobilna/database/api/login_service.dart';
import 'package:odlikas_mobilna/database/models/testviewmodel.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';
import 'package:odlikas_mobilna/pages/BannerPage/banner_page.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/pages/PomodoroPage/pomodoro_page.dart';
import 'package:odlikas_mobilna/pages/LeaderboardPage/leaderboard_page.dart';
import 'package:odlikas_mobilna/pages/SettingsPages/settings_page.dart';
import 'package:odlikas_mobilna/pages/SubjectsPage/subjects_page.dart';
import 'package:odlikas_mobilna/pages/newNotifications/new_notifications_page.dart';
import 'package:odlikas_mobilna/pages/PendingTasksPage/pending_tasks_page.dart';
import 'package:provider/provider.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/services/pomodoro_notifier.dart';
import 'database/firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> _checkDeviceSecurity() async {
  try {
    final isJailbroken = await SafeDevice.isJailBroken;
    if (isJailbroken) {
      // Device is rooted/jailbroken — OS encryption guarantees may be bypassed.
      // We warn but do not block, letting the user proceed at their own risk.
      debugPrint('Warning: device is rooted or jailbroken.');
    }
  } catch (_) {
    // Detection failed — proceed normally.
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.saveNotifications(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  Timer.periodic(const Duration(seconds: 3), (_) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  });

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));

  await Hive.openBox('User');
  // Best-effort — notification setup must not block app startup
  try {
    await FirebaseApi().initNotifications();
  } catch (e) {
    debugPrint('initNotifications failed (non-fatal): $e');
  }
  await _checkDeviceSecurity();

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
    _fontService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _fontService),
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, HomePageViewModel>(
          create: (context) => HomePageViewModel(context.read<ApiService>()),
          update: (_, apiService, __) => HomePageViewModel(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, TestViewmodel>(
          create: (context) => TestViewmodel(context.read<ApiService>()),
          update: (_, apiService, __) => TestViewmodel(apiService),
        ),
        ChangeNotifierProvider(create: (_) => PomodoroNotifier()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const StartupRouter(),
        navigatorKey: navigatorKey,
        routes: {
          '/home': (_) => const HomePage(),
          '/pomodoro': (_) => const PomodoroPage(),
          '/leaderboard': (_) => const LeaderboardPage(),
          '/settings': (_) => const SettingsPage(),
          '/grades': (_) => const SubjectsPage(),
          '/newNotifications': (_) => NewNotificationsPage(),
          '/pendingTasks': (_) => const PendingTasksPage(),
        },
      ),
    );
  }
}

/// Checks secure storage for a valid token and routes accordingly.
/// Also runs a one-time migration of legacy plaintext Hive credentials.
class StartupRouter extends StatelessWidget {
  const StartupRouter({super.key});

  Future<bool> _resolveDestination() async {
    await _migrateLegacyCredentials();
    final token = await AuthStorage.readToken();
    return token != null;
  }

  /// One-time migration: if old plaintext credentials exist in Hive,
  /// log in to get a token, move everything to secure storage, then
  /// delete plaintext values from Hive regardless of outcome.
  Future<void> _migrateLegacyCredentials() async {
    final box = Hive.box('User');
    final legacyEmail = box.get('email') as String?;
    final legacyPassword = box.get('password') as String?;

    if (legacyEmail == null || legacyPassword == null) return;

    try {
      final result = await LoginService.login(legacyEmail, legacyPassword);
      await AuthStorage.saveToken(result.token);
      await AuthStorage.saveCredentials(
          email: legacyEmail, password: legacyPassword);
    } catch (_) {
      // Migration login failed — user will be prompted to log in manually.
    } finally {
      // Always remove plaintext credentials from Hive.
      await box.delete('password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _resolveDestination(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const HomePage() : const BannerPage();
      },
    );
  }
}
