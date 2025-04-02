import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    this.timestamp,
    this.isRead = false,
  });

  // Factory method to create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No Body',
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : {},
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  // Helper methods to extract common properties
  bool get isGradeNotification =>
      data['type'] == 'grades' ||
      title.contains('ocjena') ||
      title.contains('bilješka');

  bool get isTestNotification =>
      data['type'] == 'tests' || title.contains('ispit');

  String? get gradeValue {
    if (!isGradeNotification) return null;

    if (body.contains('Dobili ste: ')) {
      final parts = body.replaceAll('Dobili ste: ', '').split(' za ');
      if (parts.isNotEmpty) {
        return parts[0];
      }
    }
    return null;
  }

  String? get subjectName {
    if (title.contains('predmet ')) {
      return title.split('predmet ').last;
    }
    return null;
  }

  String? get elementOfEvaluation {
    if (body.contains(' za ')) {
      final parts = body.split(' za ');
      if (parts.length > 1) {
        return parts.last;
      }
    } else if (body.contains('bilješku za ')) {
      return body.split('bilješku za ').last;
    }
    return null;
  }

  int get count {
    return int.tryParse(data['count'] ?? '0') ?? 0;
  }
}
