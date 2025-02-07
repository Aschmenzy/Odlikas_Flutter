import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class QueryPage extends StatefulWidget {
  final String jobId;
  const QueryPage({super.key, required this.jobId});

  @override
  State<QueryPage> createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> {
  String? _pdfBase64;
  bool _isLoading = true;
  TextEditingController motivationLetter = TextEditingController();
  TextEditingController questions = TextEditingController();
  late String dquestions;

  Future<void> _fetchProfile() async {
    final box = await Hive.openBox('User');
    final email = box.get('email');

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('studentProfiles')
          .doc(email)
          .get();

      if (docSnapshot.exists) {
        setState(() {
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

  Future<void> _handleSubmit() async {
    // Validate CV
    if (_pdfBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prvo prenesite životopis')),
      );
      return;
    }

    // Validate motivation letter
    if (motivationLetter.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite motivacijsko pismo')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final box = await Hive.openBox('User');
      final userEmail = box.get('email');

      // Create a subcollection for this job's queries
      await FirebaseFirestore.instance
          .collection('Jobs')
          .doc(widget.jobId)
          .collection('jobQueries_$userEmail')
          .add({
        'cv': _pdfBase64,
        'motivationLetter': motivationLetter.text,
        'questions': questions.text,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upit uspješno poslan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri slanju upita: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                      color: AppColors.accent,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    //make the title in the page in the middle
                    SizedBox(width: screenWidth * 0.25),
                    Text(
                      "Upit",
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    )
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),

                //CV text and container
                Text(
                  "Životopis:",
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                GestureDetector(
                  onTap: _viewPDF,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight * 0.06,
                    decoration: BoxDecoration(
                      color: _pdfBase64 != null
                          ? AppColors.primary
                          : AppColors.tertiary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        "Pogledaj svoj životopis",
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                //Query text and container
                Text(
                  "Motivacijsko pismo:",
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.35,
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                      border:
                          Border.all(color: AppColors.tertiary, width: 0.6)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: motivationLetter,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Unesite vaše motivacijsko pismo...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.tertiary,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                ),

                //optional questions
                SizedBox(height: screenHeight * 0.03),

                Text(
                  "Pitanja (opcionalno):",
                  style: GoogleFonts.inter(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                Container(
                  width: screenWidth,
                  height: screenHeight * 0.1,
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                      border:
                          Border.all(color: AppColors.tertiary, width: 0.6)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: questions,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Npr. kandidat ima pitanja u vezi s pozicijom...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.tertiary,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                //Submit button
                MyButton(
                    buttonText: "POŠALJI UPIT",
                    ontap: () {
                      _handleSubmit();
                    },
                    height: screenHeight * 0.08,
                    width: double.infinity,
                    decorationColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    textColor: AppColors.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),

                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
