import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'Widgets/numberSelector.dart';

class UpdatePreferencesPage extends StatefulWidget {
  const UpdatePreferencesPage({super.key});

  @override
  State<UpdatePreferencesPage> createState() =>
      UpdatePreferencesPage_PreferencesPageState();
}

//acces to the local storage

Future<void> savePreferences(BuildContext context, int selectedDaysPerWeek,
    int selectedHoursPerDay) async {
  try {
    // Open the box first
    final box = await Hive.openBox('User');
    var email = box.get("email"); // Now use this box instance

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef =
        firestore.collection('studentProfiles').doc(email);

    await docRef.set({
      'preferences': {
        'daysLearning': selectedDaysPerWeek,
        'hoursLearning': selectedHoursPerDay
      }
    }, SetOptions(merge: true));

    //retunr to the settings
    Navigator.pop(
      context,
    );
  } catch (e) {
    print('Error saving learning metrics: $e');

    // Add error dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Failed to save preferences. Please try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UpdatePreferencesPage_PreferencesPageState
    extends State<UpdatePreferencesPage> {
  int selectedDaysPerWeek = 1;
  int selectedHoursPerDay = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Koliko vi voljeli učiti \ntjedno?",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.09,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              "Može se kasnije promijeniti",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w800,
                color: AppColors.tertiary,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Text(
              "Dana u tjednu:",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: MediaQuery.of(context).size.width * 0.05,
              ),
            ),
            SizedBox(height: 10),
            buildNumberSelector(
              context: context,
              numbers: [1, 2, 3, 4, 5, 6, 7],
              selectedValue: selectedDaysPerWeek,
              onSelect: (value) {
                setState(() {
                  selectedDaysPerWeek = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              "Sati u danu:",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: MediaQuery.of(context).size.width * 0.05,
              ),
            ),
            SizedBox(height: 10),
            buildNumberSelector(
              context: context,
              numbers: [1, 2, 3, 4],
              selectedValue: selectedHoursPerDay,
              onSelect: (value) {
                setState(() {
                  selectedHoursPerDay = value;
                });
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            MyButton(
              fontSize: 24,
              buttonText: "PROMIJENI",
              ontap: () {
                savePreferences(
                    context, selectedDaysPerWeek, selectedHoursPerDay);
              },
              height: MediaQuery.of(context).size.width * 0.175,
              width: MediaQuery.of(context).size.width * 1,
              decorationColor: AppColors.primary,
              borderColor: AppColors.primary,
              textColor: AppColors.background,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            MyButton(
              fontSize: 15,
              buttonText: "ODUSTANI",
              ontap: () {
                Navigator.pop(
                  context,
                );
              },
              height: MediaQuery.of(context).size.width * 0.1,
              width: MediaQuery.of(context).size.width * 1,
              decorationColor: Colors.transparent,
              borderColor: Colors.transparent,
              textColor: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
