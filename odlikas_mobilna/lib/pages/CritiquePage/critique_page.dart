import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';

class CritiquePage extends StatefulWidget {
  const CritiquePage({super.key});

  @override
  State<CritiquePage> createState() => _CritiquePageState();
}

class _CritiquePageState extends State<CritiquePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveCritique() async {
    //get user email
    final box = await Hive.openBox('User');

    final critique = _controller.text;
    if (critique.isEmpty) {
      return;
    }

    //save critique to database
    try {
      await FirebaseFirestore.instance.collection('Critiques').add({
        'user': box.get('email'),
        'critique': critique,
        'date': DateTime.now(),
      });
    } catch (e) {
      print(e);
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.04),
              //navigator back button
              Row(
                children: [
                  IconButton(
                    iconSize: 36,
                    color: AppColors.accent,
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              //title
              Text("Kritike",
                  style: GoogleFonts.inter(
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary)),

              SizedBox(height: size.height * 0.015),
              Text(
                "Cijenimo vaše mišljenje! Ostavite nam svoj"
                "pozitivnu ili negativnu kritiku kako bismo bili još "
                "bolje.",
                style: GoogleFonts.inter(
                    fontSize: size.width * 0.035,
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w700,
                    height: 1),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: size.height * 0.03),

              //text field
              Expanded(
                child: TextField(
                  textAlignVertical: TextAlignVertical.top,
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: '...',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.tertiary,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.tertiary, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              //button
              MyButton(
                  buttonText: "Ocjenite nas",
                  ontap: _saveCritique,
                  height: size.height * 0.08,
                  width: size.width * 0.9,
                  decorationColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  textColor: AppColors.background,
                  fontWeight: FontWeight.w600,
                  fontSize: size.width * 0.06),

              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
