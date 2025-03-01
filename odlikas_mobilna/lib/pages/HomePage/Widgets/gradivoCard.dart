import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GradivoCard extends StatelessWidget {
  const GradivoCard({Key? key}) : super(key: key);

// funkcija koja poziva url i otvara ga u browseru
  Future<void> _launchURL() async {
    final Uri url = Uri.parse(
        'https://gradivo.hr?utm_source=odlikas&utm_medium=banner&utm_campaign=odlikas25');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);

    return GestureDetector(
      onTap: _launchURL,
      child: Card(
          color: AppColors.background,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: SizedBox(
            width: screenWidth * 0.4,
            height: screenHeight * 0.15,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    height: screenHeight * 0.08,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
                      color: AppColors.gradivo,
                    ),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Jedine ",
                              style: fontService.font(
                                height: 1.2,
                                fontSize: screenWidth * 0.034,
                                fontWeight: FontWeight.w800,
                                color: AppColors.background,
                              ),
                            ),
                            TextSpan(
                              text: "pripreme za maturu ",
                              style: fontService.font(
                                height: 1.2,
                                fontSize: screenWidth * 0.034,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gradivoAccent,
                              ),
                            ),
                            TextSpan(
                              text: "\nkoje ti trebaju!",
                              style: fontService.font(
                                height: 1.2,
                                fontSize: screenWidth * 0.034,
                                fontWeight: FontWeight.w800,
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/gradivo.png',
                          fit: BoxFit.contain,
                          width: screenWidth * 0.35,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
