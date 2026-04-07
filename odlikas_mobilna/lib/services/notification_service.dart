import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _email => Hive.box('User').get('email') as String;

  // Stream of whether there are any unread notifications — used by home page
  static Stream<bool> hasUnreadNotifications() {
    return _firestore
        .collection('newNotifications')
        .doc(_email)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Stream of all notifications ordered by timestamp — used by notifications list page
  static Stream<QuerySnapshot> getNotificationsStream() {
    return _firestore
        .collection('newNotifications')
        .doc(_email)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark a single notification as read
  static Future<void> markAsRead(String docId) async {
    await _firestore
        .collection('newNotifications')
        .doc(_email)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // Delete a single notification
  static Future<void> deleteNotification(String docId) async {
    await _firestore
        .collection('newNotifications')
        .doc(_email)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // Delete all notifications for the current user
  static Future<void> clearAllNotifications() async {
    final snapshot = await _firestore
        .collection('newNotifications')
        .doc(_email)
        .collection('notifications')
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
