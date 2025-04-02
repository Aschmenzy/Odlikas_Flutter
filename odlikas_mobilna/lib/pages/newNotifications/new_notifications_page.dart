// ignore_for_file: depend_on_referenced_packages, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.background,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: screenWidth * 0.09,
          color: AppColors.accent,
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Obavijesti",
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'OCJENE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.01),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'ISPITI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                          child: Lottie.asset(
                            'assets/animations/loadingBird.json',
                            width: MediaQuery.of(context).size.width * 0.80,
                            height: 120,
                          ),
                        );
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
    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = notification.timestamp != null
        ? dateFormat.format(notification.timestamp!)
        : '';

    // Determine notification category and color
    Color categoryColor = AppColors.primary; // Default to primary (OCJENE)
    String categoryLabel = 'OCJENE';

    // Check notification data to determine category
    // You might want to adjust this logic based on your actual data structure
    if (notification.data.containsKey('type')) {
      if (notification.data['type'] == 'exam') {
        categoryColor = AppColors.accent;
        categoryLabel = 'ISPITI';
      }
    }

    // Extract score if available (assuming it might be in the data)
    String score = '';
    if (notification.data.containsKey('score')) {
      score = notification.data['score'].toString();
    } else if (notification.title.contains(':')) {
      // Fallback: Try to extract from title if in format "Score: X"
      score = notification.title.split(':').last.trim();
    }

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
      child: GestureDetector(
        onTap: () {
          // Mark as read when tapped
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          // Show notification details
          _showNotificationDetails(notification);
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score display (if available)
                if (score.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (formattedDate.isNotEmpty)
                            Text(
                              formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(width: 16),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Label
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            categoryLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Notification title - using Croatian language term "Bilješka" if appropriate
                      Row(
                        children: [
                          Text(
                            "Bilješka: ",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              notification.body,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Element label (using a default if not in the data)
                      Row(
                        children: [
                          Text(
                            "Element: ",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            notification.data['element'] ?? "",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Only show unread indicator or mark as read if needed
                      if (!notification.isRead)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: EdgeInsets.only(top: 8),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
