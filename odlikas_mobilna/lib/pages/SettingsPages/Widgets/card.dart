// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class ShareScreenCard extends StatelessWidget {
  ShareScreenCard({super.key, required this.isConnected});

  bool isConnected = false;

  @override
  Widget build(BuildContext context) {
    return isConnected
        ? Card(
            color: AppColors.background,
            margin: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Povežite se',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.013),
                        Text(
                          'Povežite svoj ekran da \nzapočnete sa učenjem',
                          style: GoogleFonts.inter(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/icon/odlikasPlusLogo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Card(
            color: AppColors.background,
            margin: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Povezani ste',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.013),
                        Text(
                          'Povezani ste sa svojim ekranom',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/icon/odlikasPlusLogo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
