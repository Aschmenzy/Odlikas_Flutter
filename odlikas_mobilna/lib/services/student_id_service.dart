import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StudentIdService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _email => Hive.box('User').get('email') as String;

  static Future<Map<String, dynamic>?> fetchStudentId() async {
    final doc = await _firestore.collection('workingID').doc(_email).get();
    if (doc.exists && doc.data()?['workingId'] != null) {
      return doc.data()!['workingId'] as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> saveStudentId(Map<String, dynamic> formData) async {
    await _firestore.collection('workingID').doc(_email).set({
      'workingId': {
        'oib': formData['oib'],
        'address': formData['address'],
        'postalCode': formData['postalCode'],
        'city': formData['city'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
