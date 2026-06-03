import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/database/api/dio_client.dart';
import 'package:odlikas_mobilna/main.dart';

class FirebaseApi {
  static Future<void> registerFcmToken(String fcmToken) async {
    try {
      await DioClient.instance.post('/api/Device/RegisterToken', data: {'fcmToken': fcmToken});
    } catch (e) {
      debugPrint('FCM token registration failed (non-fatal): $e');
    }
  }

  final _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> setupNotificationChannels() async {
    // Only needed for Android 8.0 or higher
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        debugPrint('Local notification tapped: ${notificationResponse.payload}');
      },
    );

    debugPrint('Notification channels set up successfully');
  }

  Future<void> initNotifications() async {
    await setupNotificationChannels();

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await initPushNotifications();
  }

  void showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/launcher_icon',
          ),
        ),
        payload: message.data.toString(),
      );

      debugPrint('Showed local notification: ${notification.title}');
    }
  }

  Future<void> saveNotifications(RemoteMessage message) async {
    debugPrint('Attempting to save notification: ${message.notification?.title}');

    final box = await Hive.openBox('User');
    final email = box.get('email');

    debugPrint('User email from Hive: $email');

    try {
      if (email != null) {
        final notificationData = {
          'title': message.notification?.title ?? 'No Title',
          'body': message.notification?.body ?? 'No Body',
          'data': message.data,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        };

        debugPrint('Notification data: $notificationData');

        await _firestore
            .collection('newNotifications')
            .doc(email)
            .collection('notifications')
            .add(notificationData);

        debugPrint('Successfully saved notification to Firestore');
      } else {
        debugPrint('Cannot save notification: email is null');
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    if (message.data['type'] == 'grade_drop') {
      navigatorKey.currentState?.pushNamed('/pendingTasks');
    } else {
      navigatorKey.currentState?.pushNamed('/newNotifications', arguments: message);
    }
  }

  Future<void> initPushNotifications() async {
    debugPrint('Initializing push notifications');

    // Re-register FCM token whenever it rotates
    FirebaseMessaging.instance.onTokenRefresh.listen(registerFcmToken);

    // Handle notification when app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      debugPrint('Initial message: ${message?.notification?.title}');
      if (message != null) {
        saveNotifications(message);
        handleMessage(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('onMessageOpenedApp: ${message.notification?.title}');
      saveNotifications(message);
      handleMessage(message);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      saveNotifications(message);
      showLocalNotification(message);
    });

    debugPrint('Push notification listeners initialized');
  }

  Stream<QuerySnapshot> getNotificationsStream() async* {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) {
      debugPrint('No email found, returning empty stream');
      yield* Stream.empty();
      return;
    }

    debugPrint('Getting notifications stream for: $email');

    yield* _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) return;

    await _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) return;

    await _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<int> getUnreadNotificationsCount() async {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) return 0;

    final snapshot = await _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<void> clearAllNotifications() async {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) return;

    final snapshot = await _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
