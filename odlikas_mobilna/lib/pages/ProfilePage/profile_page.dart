import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  String? _pdfBase64;
  bool _isUploading = false;
  bool _isLoading = true;

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
          _pdfBase64 = docSnapshot.data()?['cv'];
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

  Future<void> _uploadPDF() async {
    try {
      setState(() => _isUploading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
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

        // Convert to base64
        final base64PDF = base64Encode(bytes);

        // Save to Firestore
        final box = await Hive.openBox('User');
        final email = box.get('email');

        await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(email)
            .set({
          'cv': base64PDF,
        }, SetOptions(merge: true));

        setState(() => _pdfBase64 = base64PDF);

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
      setState(() => _isUploading = false);
    }
  }

  void _viewPDF() async {
    if (_pdfBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prvo prenesite životopis')),
      );
      return;
    }

    try {
      // Convert base64 back to PDF file
      final bytes = base64Decode(_pdfBase64!);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cv.pdf');
      await file.writeAsBytes(bytes);

      // Show PDF viewer
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  'Vaš životopis',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                  ),
                ),
                backgroundColor: AppColors.primary,
              ),
              body: SfPdfViewer.file(file),
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

              // PDF Upload Container
              GestureDetector(
                onTap: _isUploading ? null : _uploadPDF,
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
                      if (_isUploading)
                        CircularProgressIndicator(color: AppColors.background)
                      else ...[
                        Image.asset("assets/images/upload.png",
                            width: screenWidth * 0.3),
                        SizedBox(height: screenHeight * 0.02),
                        _pdfBase64 != null
                            ? Text(
                                "Promijente životopis",
                                style: GoogleFonts.inter(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.background,
                                ),
                              )
                            : Text(
                                "Prenesi svoj životopis",
                                style: GoogleFonts.inter(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.background,
                                ),
                              ),
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
                    color: _pdfBase64 != null
                        ? AppColors.primary
                        : AppColors.tertiary,
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
