import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class Workingidcard extends StatelessWidget {
  const Workingidcard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //image and title

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Učenička iskaznica',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'posredovanje pri zapošljvanju učenika',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset("assets/images/workingIdImage.png",
                      width: 50, height: 50),
                ],
              ),

              SizedBox(height: 5),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Broj iskaznice:', '123456'),
                      _buildInfoRow('Ime i prezime:', 'ANTONIO KOCIJAN'),
                      _buildInfoRow('OIB:', '12345678...'),
                      _buildInfoRow('Adresa:', 'NIKOLA TESLE 13F\n23000 ZADAR'),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.secondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
