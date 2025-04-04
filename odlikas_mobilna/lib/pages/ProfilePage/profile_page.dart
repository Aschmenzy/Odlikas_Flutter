import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  String? _cvUrl;
  String? _pfpUrl;
  bool _isUploadingPDF = false;
  bool _isUploadingPFP = false;

  bool _isLoading = true;
  String? _userEmail;

  //funkcija koja horvaca podatke o korisniku
  //koristi email kako bi nasla dokument u collecitonu
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
          _cvUrl = docSnapshot.data()?['cvUrl'];
          _pfpUrl = docSnapshot.data()?['pfpUrl'];
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //funkcija koje sprema opis korisnika iz modala u studentProfiles collection
  Future<void> _saveDescription(String description) async {
    if (_userEmail == null) {
      print('Error: No email found in local storage');
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
      print('Error saving description: $e');
    }
  }

  // Funkcija koja uploada PDF na Firebase Storage i sprema URL u Firestore
  Future<void> _uploadPDF() async {
    try {
      setState(() => _isUploadingPDF = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && _userEmail != null) {
        final file = File(result.files.single.path!);

        // Check file size (max 1MB)
        final bytes = await file.readAsBytes();
        if (bytes.length > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF mora biti manji od 1MB')),
            );
          }
          return;
        }

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('odlikasFiles')
            .child(_userEmail!)
            .child('cv.pdf');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        // Save URL to Firestore
        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(_userEmail)
            .set({
          'cvUrl': downloadUrl,
        }, SetOptions(merge: true));

        setState(() => _cvUrl = downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Životopis uspješno prenesen')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingPDF = false);
    }
  }

  void _viewPDF() async {
    if (_cvUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prvo prenesite životopis')),
      );
      return;
    }

    try {
      // Show PDF viewer directly from URL
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                foregroundColor: AppColors.background,
                title: Text(
                  'Vaš životopis',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                  ),
                ),
                backgroundColor: AppColors.primary,
              ),
              body: SfPdfViewer.network(_cvUrl!),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri otvaranju PDF-a: $e')),
        );
      }
    }
  }

  Future<void> _uploadPFP() async {
    try {
      setState(() => _isUploadingPFP = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && _userEmail != null) {
        final file = File(result.files.single.path!);

        // Check file size (max 1MB)
        final bytes = await file.readAsBytes();
        if (bytes.length > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Slika mora biti manja od 1MB')),
            );
          }
          return;
        }

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('odlikasFiles')
            .child(_userEmail!)
            .child('profilePicture.jpg');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        // Save URL to Firestore
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
    } finally {
      setState(() => _isUploadingPFP = false);
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

              // Profile Picture upload
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

              // Student School
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

              // Student Program
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

              // PDF Upload Container
              GestureDetector(
                onTap: _isUploadingPDF ? null : _uploadPDF,
                child: Container(
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploadingPDF)
                        CircularProgressIndicator(color: AppColors.background)
                      else ...[
                        Image.asset("assets/images/upload.png",
                            width: screenWidth * 0.3),
                        SizedBox(height: screenHeight * 0.02),
                        _cvUrl != null
                            ? Text(
                                "Promijente životopis",
                                style: fontService.font(
                                  fontSize: screenWidth * 0.04,
                                  color: AppColors.background,
                                ),
                              )
                            : Text(
                                "Prenesi svoj životopis",
                                style: fontService.font(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.background,
                                ),
                              ),
                        SizedBox(height: screenHeight * 0.002),
                        Text(
                          "Podržava samo pdf",
                          style: fontService.font(
                            fontSize: screenWidth * 0.03,
                            color: AppColors.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // View PDF Container
              GestureDetector(
                onTap: _viewPDF,
                child: Container(
                  width: screenWidth * 0.85,
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    color:
                        _cvUrl != null ? AppColors.primary : AppColors.tertiary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      "Pogledaj životopis",
                      style: fontService.font(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
