// ignore_for_file: depend_on_referenced_packages, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/database/api/firebase_api.dart';
import 'package:odlikas_mobilna/database/models/notification_model.dart';

class NewNotificationsPage extends StatefulWidget {
  @override
  _NewNotificationsPageState createState() => _NewNotificationsPageState();
}

class _NewNotificationsPageState extends State<NewNotificationsPage> {
  final FirebaseApi _firebaseApi = FirebaseApi();
  bool _isLoading = false;

  @override
  void dispose() {
    // Clear all notifications when leaving the page
    _clearAllNotifications(showConfirmation: false);
    super.dispose();
  }

  // Modified to allow silent clearing without confirmation dialog
  void _clearAllNotifications({bool showConfirmation = true}) {
    if (showConfirmation) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Clear All Notifications'),
          content: Text('Are you sure you want to delete all notifications?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Clear All'),
              onPressed: () {
                Navigator.of(context).pop();
                _firebaseApi.clearAllNotifications();
              },
            ),
          ],
        ),
      );
    } else {
      // Clear directly without showing dialog
      _firebaseApi.clearAllNotifications();
    }
  }

  void _markAsRead(String notificationId) async {
    try {
      await _firebaseApi.markNotificationAsRead(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read')),
      );
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              SizedBox(height: 16),
              if (notification.data.isNotEmpty) ...[
                Text('Additional Data:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(notification.data.toString()),
              ],
              SizedBox(height: 16),
              Text(
                notification.timestamp != null
                    ? DateFormat('MMM d, yyyy · h:mm a')
                        .format(notification.timestamp!)
                    : 'Unknown time',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Obavijesti'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: Lottie.asset(
                      'assets/animations/loadingBird.json',
                      width: MediaQuery.of(context).size.width * 0.80,
                      height: 120,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firebaseApi.getNotificationsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: Center(
                          child: Lottie.asset(
                            'assets/animations/loadingBird.json',
                            width: MediaQuery.of(context).size.width * 0.80,
                            height: 120,
                          ),
                        ));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('Trenutno nemate obavijesti'));
                      }

                      final notifications = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return NotificationModel(
                          id: doc.id,
                          title: data['title'] ?? 'No Title',
                          body: data['body'] ?? 'No Body',
                          data: data['data'] ?? {},
                          timestamp:
                              (data['timestamp'] as Timestamp?)?.toDate(),
                          isRead: data['isRead'] ?? false,
                        );
                      }).toList();

                      return _buildNotificationsList(notifications);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationTile(notification);
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final formattedDate = notification.timestamp != null
        ? dateFormat.format(notification.timestamp!)
        : 'Unknown time';

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _firebaseApi.deleteNotification(notification.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Notification deleted')));
      },
      child: ListTile(
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: notification.isRead ? Colors.transparent : Colors.blue,
          ),
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: Icon(Icons.check_circle_outline),
                onPressed: () => _markAsRead(notification.id),
                tooltip: 'Mark as read',
              ),
        onTap: () {
          // Mark as read when tapped
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }

          // Show notification details
          _showNotificationDetails(notification);
        },
      ),
    );
  }
}
