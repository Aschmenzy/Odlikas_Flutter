import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CalendarService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _email => Hive.box('User').get('email') as String;

  static Future<List<Map<String, String>>> fetchEvents(DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection('CalendarEvents')
          .doc(_email)
          .collection('events')
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'title': doc['title'] as String,
          'description': doc['description'] as String,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  static Future<void> saveEvent({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _firestore
          .collection('CalendarEvents')
          .doc(_email)
          .collection('events')
          .add({
        'title': title,
        'description': description,
        'date': date,
      });
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  static Future<void> deleteEvent(String docId) async {
    await _firestore
        .collection('CalendarEvents')
        .doc(_email)
        .collection('events')
        .doc(docId)
        .delete();
  }
}
