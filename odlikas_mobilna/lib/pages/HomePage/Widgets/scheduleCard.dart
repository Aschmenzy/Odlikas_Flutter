import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/schedule_page.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SchedulePage()),
      ),
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
                //there we will see the title of the card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      topRight: Radius.circular(15.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Raspored",
                        style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary),
                      ),
                      Text("Pogledaj i uredi svoj raspored",
                          style: GoogleFonts.inter(
                              fontSize: screenWidth * 0.025,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary)),
                    ],
                  ),
                ),

                //there we will see what is the next subject
                Container(
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15.0),
                      bottomRight: Radius.circular(15.0),
                    ),
                    color: AppColors.primary,
                  ),
                  child: Center(
                      child: Text(
                          "Placeholder text\nPlaceholder text\nPlaceholder text",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              height: 1.2,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background))),
                ),
              ],
            ),
          )),
    );
  }
}
