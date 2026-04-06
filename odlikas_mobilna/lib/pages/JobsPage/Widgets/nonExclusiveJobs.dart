import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/font_service.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/JobDetailsPage/job_details_page.dart';
import 'package:provider/provider.dart';

class NonExclusiveJob extends StatelessWidget {
  //varijavle koje widget zahtjeva
  const NonExclusiveJob({
    super.key,
    required this.jobData,
    required this.screenHeight,
    required this.screenWidth,
    required this.jobId,
  });
  //jobData je mapa iz koje ce stranica uzimati podatke
  final Map<String, dynamic> jobData;
  final double screenHeight;
  final double screenWidth;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);
    return GestureDetector(
      //funkcija koja prebacuje na drugi page zajedno s potrebnim podatcima
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    JobDetailsPage(jobId: jobId, jobData: jobData)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (jobData['image'] != null)
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      child: ClipRRect(
                        child: Image.memory(
                          base64Decode(jobData['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: VerticalDivider(
                        color: Color.fromARGB(255, 192, 192, 192),
                        thickness: 1,
                        width: 10,
                      ),
                    ),
                  ],
                ),
              Text(jobData['recruter'],
                  style: fontService.font(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary)),
              Spacer(),
              Text(
                jobData['location'],
                style: fontService.font(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                    fontSize: screenWidth * 0.05),
              ),
            ],
          ),
          Divider(
            color: AppColors.tertiary,
            thickness: 0.5,
          ),
          Text(
            jobData['title'],
            style: fontService.font(
                fontWeight: FontWeight.w700,
                fontSize: screenWidth * 0.04,
                color: AppColors.secondary),
          ),
          SizedBox(height: screenHeight * 0.001),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Prosječna neto plaća ",
                style: fontService.font(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.03,
                    color: AppColors.secondary),
              ),
              Text(
                jobData['pay'],
                style: fontService.font(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05,
                    color: AppColors.secondary),
              )
            ],
          ),
        ],
      ),
    );
  }
}
