// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class MyTextField extends StatefulWidget {
  const MyTextField({
    super.key,
    this.enabled,
    required this.controller,
    required this.labelText,
    required this.obscureText,
    this.hintText,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final bool? enabled;
  final String? hintText;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _obscureText;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled,
      onTap: () {
        if (_showHint) {
          setState(() {
            _showHint = false;
          });
        }
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: AppColors.tertiary,
            width: 2.0,
          ),
        ),
        labelText: widget.labelText,
        labelStyle: GoogleFonts.inter(
          color: AppColors.secondary,
          fontSize: 24.0,
          fontWeight: FontWeight.w800,
        ),
        hintText: _showHint ? widget.hintText : null,
        hintStyle: GoogleFonts.inter(
          color: AppColors.tertiary,
          fontSize: MediaQuery.of(context).size.width * 0.045,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.tertiary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: EdgeInsets.only(left: 30, top: 20, bottom: 20),
        // Add password visibility toggle button if it's a password field
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.tertiary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
