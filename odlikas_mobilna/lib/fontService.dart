import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FontService extends ChangeNotifier {
  // Default font configuration
  bool _isDyslexic = false;

  bool get isDyslexic => _isDyslexic;

  Future<void> initialize() async {
    try {
      final box = await Hive.openBox("User");
      String email = box.get("email");

      // Initial fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection("StudentNotificationsPreferences")
          .doc(email)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('dyslexic')) {
          _updateFontBasedOnDyslexicSetting(data['dyslexic'] as bool);
        }
      }

      // Set up a listener for real-time updates
      FirebaseFirestore.instance
          .collection("StudentNotificationsPreferences")
          .doc(email)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('dyslexic')) {
            _updateFontBasedOnDyslexicSetting(data['dyslexic'] as bool);
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing font service: $e');
    }
  }

  void _updateFontBasedOnDyslexicSetting(bool isDyslexic) {
    if (isDyslexic != _isDyslexic) {
      _isDyslexic = isDyslexic;
      notifyListeners();
    }
  }

  // Method to toggle dyslexic mode manually
  Future<void> toggleDyslexicMode() async {
    try {
      // Update the local state first
      _updateFontBasedOnDyslexicSetting(!_isDyslexic);

      // Then update Firestore
      final box = Hive.box("User");
      String email = box.get("email");

      await FirebaseFirestore.instance
          .collection("StudentNotificationsPreferences")
          .doc(email)
          .update({'dyslexic': _isDyslexic});
    } catch (e) {
      debugPrint('Error toggling dyslexic mode: $e');
      // Revert back if the update fails
      _updateFontBasedOnDyslexicSetting(!_isDyslexic);
    }
  }

  // Helper method to get font style
  TextStyle font({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    TextDecoration? decoration,
    double? height,
    double? letterSpacing,
    TextOverflow? overflow,
  }) {
    return _isDyslexic
        ? GoogleFonts.comicNeue(
            fontSize: fontSize * 1.1,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            height: height,
            letterSpacing: letterSpacing,
          )
        : GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
            height: height,
            letterSpacing: letterSpacing,
          );
  }
}
