// ignore_for_file: depend_on_referenced_packages, use_key_in_widget_constructors, library_private_types_in_public_api, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/notification_model.dart';
import 'package:odlikas_mobilna/services/notification_service.dart';

class NewNotificationsPage extends StatefulWidget {
  @override
  _NewNotificationsPageState createState() => _NewNotificationsPageState();
}

class _NewNotificationsPageState extends State<NewNotificationsPage> {
  @override
  void dispose() {
    NotificationService.clearAllNotifications();
    super.dispose();
  }

  void _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nije moguće označiti obavijest kao pročitanu')),
      );
    }
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
            child: StreamBuilder<QuerySnapshot>(
                    stream: NotificationService.getNotificationsStream(),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Trenutno nemate obavijesti',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final notifications = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return NotificationModel(
                          id: doc.id,
                          title: data['title'] ?? 'No Title',
                          body: data['body'] ?? 'No Body',
                          data: data['data'] != null
                              ? Map<String, dynamic>.from(data['data'])
                              : {},
                          timestamp:
                              (data['timestamp'] as Timestamp?)?.toDate(),
                          isRead: data['isRead'] ?? false,
                        );
                      }).toList();

                      // Sort notifications by timestamp (newest first)
                      notifications.sort((a, b) =>
                          (b.timestamp ?? DateTime.now())
                              .compareTo(a.timestamp ?? DateTime.now()));

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

    Color categoryColor = AppColors.primary;
    String categoryLabel = 'OCJENE';

    // Check notification data to determine if it's a grade or test notification
    if (notification.data.containsKey('type')) {
      if (notification.data['type'] == 'tests') {
        categoryColor = AppColors.accent;
        categoryLabel = 'ISPITI';
      }
    }

    // Check if it's specifically a note ("bilješka") and not a grade with number
    bool isNote = notification.title.contains('bilješka') ||
        notification.body.contains('bilješku');

    // Extract relevant data
    String gradeNumber = '';
    String elementOfEvaluation = '';
    String subjectName = '';

    // Extract additional details to display
    if (notification.data.containsKey('count')) {
      int count = int.tryParse(notification.data['count'] ?? '0') ?? 0;

      // This is structured to match your cloud function notification format
      if (count == 1) {
        // For single grade or test notifications, try to parse from the title/body
        if (notification.title.contains('Nova ocjena za predmet')) {
          subjectName =
              notification.title.replaceAll('Nova ocjena za predmet ', '');

          // Extract grade number and element from body
          // Example format: "Dobili ste: 5 za Usmena provjera"
          if (notification.body.contains('Dobili ste: ')) {
            String details = notification.body.replaceAll('Dobili ste: ', '');
            List<String> parts = details.split(' za ');
            if (parts.length == 2) {
              gradeNumber = parts[0];
              elementOfEvaluation = parts[1];
            }
          }
        } else if (notification.title.contains('Nova bilješka za predmet')) {
          subjectName =
              notification.title.replaceAll('Nova bilješka za predmet ', '');
          elementOfEvaluation = notification.body
                  .contains('Dobili ste novu bilješku za ')
              ? notification.body.replaceAll('Dobili ste novu bilješku za ', '')
              : '';
        } else if (notification.title.contains('Novi ispit iz predmeta')) {
          subjectName =
              notification.title.replaceAll('Novi ispit iz predmeta ', '');
          elementOfEvaluation = 'Ispit';
        }
      }
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
        NotificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Obavijest izbrisana')));
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
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with subject name
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF1D91D0), // Bright blue from image
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  subjectName.isNotEmpty
                      ? subjectName
                      : (isNote ? "Bilješka" : "Ocjena"),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Content area
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Grade or Date display
                    if (gradeNumber.isNotEmpty && !isNote)
                      Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        child: Text(
                          gradeNumber,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),

                    SizedBox(width: 16),

                    // Details column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "Bilješka:" label and value
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.secondary,
                              ),
                              children: [
                                TextSpan(
                                  text: "Bilješka: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: isNote ? notification.body : "Ocjena",
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),

                          // "Element:" label and value
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.secondary,
                              ),
                              children: [
                                TextSpan(
                                  text: "Element: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: elementOfEvaluation.isNotEmpty
                                      ? elementOfEvaluation
                                      : "primjena znanja",
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),

                          // "Ocjena:" label and value
                          if (gradeNumber.isNotEmpty && !isNote)
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppColors.secondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Ocjena: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: gradeNumber,
                                  ),
                                ],
                              ),
                            ),

                          // Unread indicator
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
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    // Determine notification category
    String categoryLabel = notification.data.containsKey('type') &&
            notification.data['type'] == 'tests'
        ? 'ISPITI'
        : 'OCJENE';

    // Format timestamp
    final dateTimeFormat = DateFormat('dd.MM.yyyy - HH:mm');
    final formattedDateTime = notification.timestamp != null
        ? dateTimeFormat.format(notification.timestamp!)
        : 'Nepoznato vrijeme';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: categoryLabel == 'ISPITI'
                    ? AppColors.accent
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Vrijeme obavijesti:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(formattedDateTime),

              // Only show additional data if not empty and relevant
              if (notification.data.isNotEmpty &&
                  !notification.data.keys.every((key) =>
                      ['type', 'timestamp', 'count'].contains(key))) ...[
                SizedBox(height: 16),
                Text(
                  'Dodatni detalji:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                // Display only relevant data fields
                for (var entry in notification.data.entries)
                  if (!['type', 'timestamp', 'count'].contains(entry.key))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Zatvori'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (!notification.isRead)
            TextButton(
              child: Text('Označi kao pročitano'),
              onPressed: () {
                _markAsRead(notification.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
