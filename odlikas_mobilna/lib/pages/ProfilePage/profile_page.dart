import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:provider/provider.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/ProfilePage/Widgets/descriptionModal.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String? _pfpUrl;

  bool _isLoading = true;
  String? _userEmail;

  Future<void> _fetchProfile() async {
    final box = await Hive.openBox('User');
    final email = box.get('email');
    _userEmail = email;

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
          _pfpUrl = docSnapshot.data()?['pfpUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDescription(String description) async {
    if (_userEmail == null) {
      debugPrint('Error: No email found in local storage');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(_userEmail)
          .set({
        'description': description,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving description: $e');
    }
  }

  Future<void> _uploadPFP() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && _userEmail != null) {
        final file = File(result.files.single.path!);

        final bytes = await file.readAsBytes();
        if (bytes.length > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Slika mora biti manja od 1MB')),
            );
          }
          return;
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('odlikasFiles')
            .child(_userEmail!)
            .child('profilePicture.jpg');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(_userEmail)
            .set({
          'pfpUrl': downloadUrl,
        }, SetOptions(merge: true));

        setState(() => _pfpUrl = downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profilna slika uspješno prenesena')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
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
    final fontService = Provider.of<FontService>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Lottie.asset(
            'assets/animations/loadingBird.json',
            width: MediaQuery.of(context).size.width * 0.80,
            height: 120,
          ),
        ),
      );
    }

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
                  SizedBox(width: screenWidth * 0.25),
                  Text(
                    "Profil",
                    style: fontService.font(
                        fontSize: screenWidth * 0.075,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  )
                ],
              ),
              SizedBox(height: screenHeight * 0.01),

              // Profile picture
              GestureDetector(
                onTap: _uploadPFP,
                child: Container(
                  width: screenWidth * 0.22,
                  height: screenWidth * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                  child: _pfpUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _pfpUrl!,
                            width: screenWidth * 0.22,
                            height: screenWidth * 0.22,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        )
                      : Image.asset(
                          "assets/images/pfpAdd.png",
                          width: screenWidth * 0.22,
                        ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Student name
              if (studentName != null)
                Text(
                  studentName!,
                  style: fontService.font(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary),
                ),

              SizedBox(height: screenHeight * 0.005),

              // Student school
              if (studentSchool != null)
                Text(
                  studentSchool!,
                  style: fontService.font(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              SizedBox(height: screenHeight * 0.005),

              // Student program (smjer)
              if (studentProgram != null)
                Text(
                  studentProgram!,
                  style: fontService.font(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),

              // Opis profila
              Row(
                children: [
                  Text(
                    "Opis profila:",
                    style: fontService.font(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
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
                        style: fontService.font(
                          color: AppColors.tertiary,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
