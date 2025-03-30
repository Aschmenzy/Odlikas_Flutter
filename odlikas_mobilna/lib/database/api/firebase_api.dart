import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  // Instance of firebase messaging
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this for local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // New method to set up notification channels
  Future<void> setupNotificationChannels() async {
    // Only needed for Android 8.0 or higher
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Same ID as in AndroidManifest.xml
      'High Importance Notifications', // Title visible in app settings
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Create the Android notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize local notifications
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
        // Handle notification tap
        print('Local notification tapped: ${notificationResponse.payload}');
      },
    );

    print('Notification channels set up successfully');
  }

  // Method to initialize notifications - updated to set up channels first
  Future<void> initNotifications() async {
    // Set up notification channels first
    await setupNotificationChannels();

    final email =
        await Hive.openBox('User').then((value) => value.get('email'));
    final password =
        await Hive.openBox('User').then((value) => value.get('password'));
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token'); // Debug print to verify token is generated

    if (email != null) {
      await _firestore.collection('newNotifications').doc(email).set({
        'fcmToken': token,
        'email': email,
        'password': password,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Saved token for user: $email'); // Debug print
    } else {
      print('No email found in Hive storage'); // Debug print
    }

    // Initialize push notifications
    await initPushNotifications();
  }

  // Show a local notification when app is in foreground
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
            // other properties...
          ),
        ),
        payload: message.data.toString(),
      );

      print('Showed local notification: ${notification.title}');
    }
  }

  // The rest of your methods remain the same
  // Saving notification in the database
  Future<void> saveNotifications(RemoteMessage message) async {
    print(
        'Attempting to save notification: ${message.notification?.title}'); // Debug print

    // Open Hive box and get email
    final box = await Hive.openBox('User');
    final email = box.get('email');

    print('User email from Hive: $email'); // Debug print

    try {
      if (email != null) {
        // Create notification data
        final notificationData = {
          'title': message.notification?.title ?? 'No Title',
          'body': message.notification?.body ?? 'No Body',
          'data': message.data,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        };

        print('Notification data: $notificationData'); // Debug print

        // Save to Firestore
        await _firestore
            .collection('newNotifications')
            .doc(email)
            .collection('notifications')
            .add(notificationData);

        print('Successfully saved notification to Firestore'); // Debug print
      } else {
        print('Cannot save notification: email is null'); // Debug print
      }
    } catch (e) {
      print('Error saving notification: $e'); // Debug print
    }
  }

  // Handle navigation when notification is tapped
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    print(
        'Handling message tap: ${message.notification?.title}'); // Debug print

    // Navigate to notifications page
    navigatorKey.currentState?.pushNamed(
      '/newNotifications',
      arguments: message,
    );
  }

  // Initialize push notifications - updated to show local notifications
  Future<void> initPushNotifications() async {
    print('Initializing push notifications'); // Debug print

    // Handle notification when app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('Initial message: ${message?.notification?.title}'); // Debug print
      if (message != null) {
        saveNotifications(message);
        handleMessage(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(
          'onMessageOpenedApp: ${message.notification?.title}'); // Debug print
      saveNotifications(message);
      handleMessage(message);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print(
          'Foreground message received: ${message.notification?.title}'); // Debug print
      saveNotifications(message);

      // Show a local notification when app is in foreground
      showLocalNotification(message);
    });

    print('Push notification listeners initialized'); // Debug print
  }

  // Rest of your methods remain unchanged
  // Fetch all notifications for current user
  Stream<QuerySnapshot> getNotificationsStream() async* {
    final email =
        await Hive.openBox('User').then((value) => value.get('email'));

    if (email == null) {
      print('No email found, returning empty stream'); // Debug print
      yield* Stream.empty();
      return;
    }

    print('Getting notifications stream for: $email'); // Debug print

    yield* _firestore
        .collection('newNotifications')
        .doc(email)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
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

  // Delete notification
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

  // Get unread notifications count
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

  // Clear all notifications
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
    snapshot.docs.forEach((doc) {
      batch.delete(doc.reference);
    });

    await batch.commit();
  }
}
