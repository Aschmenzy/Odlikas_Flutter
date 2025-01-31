import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/ProfilePage/Widgets/descriptionModal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? studentName;
  String? studentSchool;
  String? studentProgram;
  String? _description;

  Future<void> _fetchProfile() async {
    final box = await Hive.openBox('User');
    final email = box.get('email');

    setState(() {
      studentName = box.get('studentName');
      studentSchool = box.get('studentSchool');
      studentProgram = box.get('studentProgram');
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _description = docSnapshot.data()?['description'];
        });
      }
    } catch (e) {
      print('Error fetching description: $e');
    }
  }

  Future<void> _saveDescription(String description) async {
    final box = await Hive.openBox('User');
    final email = box.get('email');

    if (email == null) {
      print('Error: No email found in local storage');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .set({
        'description': description,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving description: $e');
    }
  }

  void _showDescriptionModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      context: context,
      builder: (_) => DescriptionModal(
        initialValue: _description,
        onSave: (value) async {
          await _saveDescription(value);
          if (mounted) {
            setState(() {
              _description = value;
            });
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 30,
                    color: AppColors.accent,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: screenWidth * 0.24),
                  Text(
                    "Profil",
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.075,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Image.asset(
                "assets/images/pfpAdd.png",
                width: screenWidth * 0.22,
              ),
              SizedBox(height: screenHeight * 0.02),
              if (studentName != null)
                Text(
                  studentName!,
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              SizedBox(height: screenHeight * 0.005),
              if (studentSchool != null)
                Text(
                  studentSchool!,
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(height: screenHeight * 0.005),
              if (studentProgram != null)
                Text(
                  studentProgram!,
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(height: screenHeight * 0.03),
              Container(
                width: screenWidth * 0.6,
                height: screenHeight * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/upload.png",
                        width: screenWidth * 0.3),
                    SizedBox(height: screenHeight * 0.02),
                    Text("Prenesi svoj životopis",
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        )),
                    SizedBox(height: screenHeight * 0.002),
                    Text(
                      "Podržava samo pdf",
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.03,
                        color: AppColors.background,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    "Pogledaj životopis",
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Row(
                children: [
                  Text(
                    "Opis profila:",
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              GestureDetector(
                onTap: _showDescriptionModal,
                child: Container(
                  width: screenWidth * 0.85,
                  height: screenHeight * 0.09,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(15),
                    padding: EdgeInsets.zero,
                    color: AppColors.tertiary,
                    strokeWidth: 1,
                    dashPattern: const [5, 3],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Text(
                        _description ?? 'Recite nam nešto o sebi...',
                        style: GoogleFonts.inter(
                          color: AppColors.tertiary,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
