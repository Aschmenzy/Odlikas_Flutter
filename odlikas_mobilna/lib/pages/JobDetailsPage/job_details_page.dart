import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/QueryPage/query_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'dart:convert';

import 'package:provider/provider.dart';

class JobDetailsPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobDetailsPage({
    required this.jobId,
    required this.jobData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 30,
              color: AppColors.accent,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (jobData['image'] != null)
                          Container(
                            width: screenWidth * 0.35,
                            height: screenHeight * 0.15,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                base64Decode(jobData['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(
                          "${jobData['recruter']}",
                          style: fontService.font(
                              fontSize: screenWidth * 0.08,
                              color: AppColors.secondary,
                              height: 0.6,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/recruter.png',
                        height: screenHeight * 0.075,
                        width: screenWidth * 0.075,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Traži se ',
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    color: AppColors.secondary),
                              ),
                              TextSpan(
                                text: "${jobData['title']}",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/calendar.png',
                        height: screenHeight * 0.075,
                        width: screenWidth * 0.075,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Prijava do: ",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    color: AppColors.secondary),
                              ),
                              TextSpan(
                                text: "${jobData['until']}",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        height: screenHeight * 0.075,
                        width: screenWidth * 0.075,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Lokacija rada: ",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    color: AppColors.secondary),
                              ),
                              TextSpan(
                                text: "${jobData['location']}",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/pay.png',
                        height: screenHeight * 0.075,
                        width: screenWidth * 0.075,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Prosjećna neto plaća ',
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    color: AppColors.secondary),
                              ),
                              TextSpan(
                                text: "${jobData['pay']}",
                                style: fontService.font(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Opis posla:",
                    style: fontService.font(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    width: screenWidth,
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.3,
                    ),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: AppColors.tertiary, width: 0.6)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Text(
                          "${jobData['description']}",
                          style: fontService.font(
                              fontSize: screenWidth * 0.04,
                              color: AppColors.secondary),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  MyButton(
                      buttonText: "POŠALJI UPIT",
                      ontap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => QueryPage(
                                  jobId: jobId,
                                )));
                      },
                      height: screenHeight * 0.07,
                      width: screenWidth,
                      decorationColor: AppColors.primary,
                      borderColor: AppColors.primary,
                      textColor: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.05),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
