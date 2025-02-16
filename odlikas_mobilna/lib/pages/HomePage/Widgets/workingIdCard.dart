import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class Workingidcard extends StatelessWidget {
  final String? name;
  final String? oib;
  final String? address;
  final String? postalCode;
  final String? city;
  const Workingidcard(
      {super.key,
      required this.name,
      this.oib,
      this.address,
      this.postalCode,
      this.city});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.normal,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'posredovanje pri zapošljvanju učenika',
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.normal,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 5),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Broj iskaznice:', '123456', context),
                      _buildInfoRow('Ime i prezime:', name, context),
                      _buildInfoRow('OIB:', oib, context),
                      _buildInfoRow(
                          'Adresa:',
                          '${address ?? ''}\n${postalCode ?? ''} ${city ?? ''}',
                          context),
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

  Widget _buildInfoRow(String label, String? value, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.025,
            color: AppColors.secondary,
          ),
        ),
        Text(
          value ?? '',
          style: GoogleFonts.inter(
            fontSize: screenWidth * 0.03,
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
